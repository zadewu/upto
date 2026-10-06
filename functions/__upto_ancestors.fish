# Prints ancestor directory names of <pwd>, one per line, nearest-first.
# Current dir excluded; repeated names are printed once (at their nearest position),
# mirroring which directory `upto <name>` would pick. Used by tab completion.
function __upto_ancestors -a pwd
    set -l segs (string split -n / -- $pwd)
    set -l seen
    set -l i (math (count $segs) - 1)
    while test $i -ge 1
        if not contains -- $segs[$i] $seen
            set -a seen $segs[$i]
            printf '%s\n' $segs[$i]
        end
        set i (math $i - 1)
    end
end
