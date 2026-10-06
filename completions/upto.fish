# -k keeps the nearest-first order instead of sorting alphabetically.
complete -c upto -f -k -a "(__upto_ancestors \$PWD)"
complete -c upto -s h -l help -d "Show help"
