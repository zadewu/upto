function upto -d "Jump to an ancestor directory by name"
    argparse -n upto h/help -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: upto [NAME]"
        echo
        echo "Jump to the nearest ancestor directory named NAME (exact match first,"
        echo "then prefix match). Without NAME, jump to the top directory below \$HOME"
        echo "(or below / when outside \$HOME)."
        echo
        echo "Options:"
        echo "  -h, --help  Show this help"
        return 0
    end

    if test (count $argv) -gt 1
        echo "upto: too many arguments" >&2
        return 1
    end
    if string match -q -- '*/*' "$argv[1]"
        echo "upto: name must not contain '/'" >&2
        return 1
    end
    # An empty name (e.g. from an unset variable) must not silently act as bare `upto`.
    if set -q argv[1]; and test -z "$argv[1]"
        echo "upto: name must not be empty" >&2
        return 1
    end
    # . and .. would otherwise prefix-match hidden directories.
    if contains -- "$argv[1]" . ..
        echo "upto: invalid name '$argv[1]'" >&2
        return 1
    end

    set -l target (__upto_target "$PWD" "$HOME" "$argv[1]")
    switch $status
        case 1
            echo "upto: no ancestor matching '$argv[1]'" >&2
            return 1
        case 2
            echo "upto: already at top" >&2
            return 1
    end
    # Command substitution split a path containing newlines into several items; rejoin.
    # Plain cd keeps dirprev/dirhist, so `cd -` and `prevd` work afterwards.
    cd (string join \n -- $target | string collect)
end
