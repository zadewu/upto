# Pure resolver: prints the ancestor of <pwd> that `upto [name]` should cd to.
# Silent on failure; status 1 = no ancestor matches <name>, 2 = already at top (no-arg form).
# Takes pwd/home as args (instead of reading $PWD/$HOME) so it is deterministic and testable.
function __upto_target -a pwd home name
    # -n drops empty items from the leading "/" and any trailing "/"
    set -l segs (string split -n / -- $pwd)
    set -l n (count $segs)

    if test -z "$name"
        # No name: jump to the top segment below $HOME when inside it, otherwise below /.
        # Compared element-wise so /home/u is not treated as a prefix of /home/user2.
        set -l hsegs (string split -n / -- $home)
        set -l base (count $hsegs)
        test $n -lt $base; and set base 0
        set -l i 1
        while test $i -le $base
            if test "$segs[$i]" != "$hsegs[$i]"
                set base 0
                break
            end
            set i (math $i + 1)
        end
        set -l top (math $base + 1)
        test $n -le $top; and return 2
        printf '/%s' $segs[1..$top]
        echo
        return 0
    end

    # Walk ancestors nearest-first (current dir excluded). An exact match anywhere wins;
    # otherwise the nearest prefix match. string sub/test compare literally (no globbing).
    set -l len (string length -- $name)
    set -l prefix_at 0
    set -l i (math $n - 1)
    while test $i -ge 1
        if test "$segs[$i]" = "$name"
            printf '/%s' $segs[1..$i]
            echo
            return 0
        end
        if test $prefix_at -eq 0; and test (string sub -l $len -- $segs[$i] | string collect) = "$name"
            set prefix_at $i
        end
        set i (math $i - 1)
    end

    test $prefix_at -eq 0; and return 1
    printf '/%s' $segs[1..$prefix_at]
    echo
end
