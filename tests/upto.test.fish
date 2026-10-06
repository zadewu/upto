# Behavior spec for upto. Run: fishtape tests/*.fish
# Sources functions/completions from this repo (not an installed copy).
# Not `status dirname`: that needs fish 3.2, plugin supports 3.1.
set -l root (string replace -r '/[^/]*$' '' -- (status filename))/..
for f in $root/functions/*.fish $root/completions/*.fish
    source $f
end

set -l H /home/u

# --- __upto_target: named lookup (pure; pwd + home passed explicitly) ---
@test "exact match" (__upto_target /a/b/c/test/d/e/f $H d) = /a/b/c/test/d
@test "prefix fallback" (__upto_target /a/b/c/test/d/e/f $H te) = /a/b/c/test
@test "exact anywhere beats nearer prefix" (__upto_target /a/test/b/testing/c $H test) = /a/test
@test "nearest duplicate wins" (__upto_target /a/test/b/test/c $H test) = /a/test/b/test
@test "nearest prefix wins" (__upto_target /x/tmp/test/y $H t) = /x/tmp/test
@test "current dir excluded" (__upto_target /a/b/c $H c >/dev/null; echo $status) -eq 1
@test "no match" (__upto_target /a/b/c $H zz >/dev/null; echo $status) -eq 1
@test "at root" (__upto_target / $H a >/dev/null; echo $status) -eq 1
@test "spaces in segment" (__upto_target "/a/my dir/b/c" $H my) = "/a/my dir"
@test "trailing slash pwd" (__upto_target /a/b/c/ $H b) = /a/b
@test "case-sensitive" (__upto_target /a/Test/b $H test >/dev/null; echo $status) -eq 1
@test "glob '*' is literal (no match)" (__upto_target /a/b/c $H '*' >/dev/null; echo $status) -eq 1
@test "glob '*' is literal (prefix match)" (__upto_target '/a/*x/b' $H '*') = '/a/*x'
@test "glob '?' is literal" (__upto_target /a/bc/d $H '?' >/dev/null; echo $status) -eq 1

# --- __upto_target: no-arg (top segment below $HOME or /) ---
@test "no-arg under home" (__upto_target /home/u/projects/x/y $H) = /home/u/projects
@test "no-arg outside home" (__upto_target /opt/x/y $H) = /opt
@test "no-arg at home" (__upto_target /home/u $H >/dev/null; echo $status) -eq 2
@test "no-arg at top seg under home" (__upto_target /home/u/projects $H >/dev/null; echo $status) -eq 2
@test "no-arg at /" (__upto_target / $H >/dev/null; echo $status) -eq 2
@test "no-arg at top seg outside home" (__upto_target /opt $H >/dev/null; echo $status) -eq 2
@test "no-arg home check is segment-aware" (__upto_target /home/user2/x/y $H) = /home

# --- __upto_ancestors: nearest-first, deduped, current dir excluded ---
@test "ancestors nearest-first deduped" (__upto_ancestors /a/test/b/test/c | string join ,) = test,b,a
@test "ancestors at root empty" -z (__upto_ancestors /)
@test "ancestors keep spaces" (__upto_ancestors "/a/my dir/b" | string join ,) = "my dir,a"

# --- upto: integration in a real temp tree ---
# Explicit template: BSD mktemp ignores $TMPDIR without one.
set -q TMPDIR; or set -l TMPDIR /tmp
set -l tmp (mktemp -d $TMPDIR/upto-test.XXXXXX)
or exit 1 # never fall through to mkdir/rm with an empty $tmp
# Normalize to the form fish reports in $PWD: macOS $TMPDIR ends in "/", giving "T//upto-test…".
# Logical path kept (no realpath), matching upto's symlink-preserving behavior.
set tmp (builtin cd $tmp; and echo $PWD)
or exit 1
@test "temp root matches logical PWD form" (builtin cd $tmp; and echo $PWD) = $tmp
set -l leaf $tmp/a/b/c/test/d/e/f
mkdir -p $leaf

cd $leaf
upto d
@test "upto cds to ancestor" $PWD = $tmp/a/b/c/test/d

cd $leaf
@test "no match exit status" (upto zz 2>/dev/null; echo $status) -eq 1
@test "no match message" (upto zz 2>&1) = "upto: no ancestor matching 'zz'"
@test "no match keeps PWD" $PWD = $leaf

@test "-h prints usage" (upto -h | string match -q '*Usage*'; echo $status) -eq 0
@test "--help exits 0" (upto --help >/dev/null; echo $status) -eq 0
@test "unknown option fails" (upto -x 2>/dev/null; echo $status) -eq 1
@test "name with slash fails" (upto a/b 2>/dev/null; echo $status) -eq 1
@test "too many args fails" (upto x y 2>/dev/null; echo $status) -eq 1
@test "empty name fails" (upto '' 2>&1) = "upto: name must not be empty"
@test "'.' rejected" (upto . 2>/dev/null; echo $status) -eq 1
@test "'..' rejected" (upto .. 2>&1) = "upto: invalid name '..'"
@test "invalid args keep PWD" $PWD = $leaf

set -l old_home $HOME
set -gx HOME $tmp
cd $tmp/a/b/c
upto
@test "no-arg jumps to top seg under HOME" $PWD = $tmp/a
@test "no-arg at top seg errors" (upto 2>&1) = "upto: already at top"
set -gx HOME $old_home

cd $leaf
upto test
cd -
@test "cd - returns after upto" $PWD = $leaf

# Prefix check only: $TMPDIR's own segments vary per machine (and may dedupe).
@test "completion lists ancestors nearest-first" (complete -C 'upto ' | string join , | string match -q 'e,d,test,c,b,a*'; echo $status) -eq 0

mkdir -p "$tmp/x"\n"y/z"
cd "$tmp/x"\n"y/z"
upto x
@test "newline in ancestor name" $PWD = "$tmp/x"\n"y"

cd $leaf
set -e HOME
upto test
@test "named lookup works with HOME unset" $PWD = $tmp/a/b/c/test
set -gx HOME $old_home

cd /
rm -rf $tmp
