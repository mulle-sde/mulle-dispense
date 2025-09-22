_mulle_dispense_complete()
{
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    # Global options
    local global_options="-f --force -h --help --version -ls"

    # Top-level commands
    local commands="copy version libexec-dir library-path uname"

    local i cmd

    # Find command position, skipping global options
    for ((i=1; i<cword; i++)); do
        if [[ "${words[i]}" =~ ^(-f|--force|-h|--help|--version|-ls)$ ]]; then
            continue
        elif [[ "${words[i]}" =~ ^(-|src|dst) ]]; then
            continue
        else
            cmd="${words[i]}"
            break
        fi
    done

    # If no command yet, suggest global options or commands
    if [[ -z "$cmd" ]]; then
        case "$prev" in
            -f|--force)
                COMPREPLY=()
                return
                ;;
            -h|--help)
                COMPREPLY=()
                return
                ;;
            --version)
                COMPREPLY=()
                return
                ;;
            -ls)
                COMPREPLY=()
                return
                ;;
            -f*|--force*|-h*|--help*|--version*|-ls*)
                COMPREPLY=()
                return
                ;;
            -*)
                # Unknown global option
                COMPREPLY=()
                return
                ;;
        esac
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$global_options" -- "$cur"))
        else
            COMPREPLY=($(compgen -W "$commands copy" -- "$cur"))
        fi
        return
    fi

    # Handle specific commands
    case "$cmd" in
        copy)
            local copy_options="-c --copy -m --move -n --name --project-name --no-executables --executables --no-share --share --no-resources --resources --no-frameworks --frameworks --headers --no-headers --lift-headers --no-lift-headers --only-headers --header-dir --mapper-file"
            local copy_option_with_arg="--name --project-name --header-dir --mapper-file"
            local cmd_index=$i

            local j pos_arg_count=0
            local seen_options=()

            # Parse up to cword
            for ((j=1; j<=cword; j++)); do
                if [[ "${words[j]}" == "$cmd" ]]; then
                    cmd_index=$j
                    continue
                fi
                if [[ "$j" -lt "$cmd_index" || j == cword ]]; then
                    continue
                fi
                if [[ "${words[j]}" =~ ^(-.*)$ ]]; then
                    if [[ " ${copy_option_with_arg[*]} " =~ " ${words[j]} " ]]; then
                        continue  # Next word is argument
                    fi
                    if [[ "${words[j]}" =~ ^(--name|--project-name|--header-dir|--mapper-file)$ ]]; then
                        ((j++))  # Skip the argument
                        continue
                    fi
                    seen_options+=("${words[j]}")
                else
                    ((pos_arg_count++))
                fi
            done

            case "$prev" in
                --name|--project-name)
                    # Project name, free form
                    COMPREPLY=()
                    return
                    ;;
                --header-dir)
                    # Directory path
                    COMPREPLY=($(compgen -d -- "$cur"))
                    return
                    ;;
                --mapper-file)
                    # File path, likely script
                    COMPREPLY=($(compgen -f -- "$cur"))
                    return
                    ;;
                *)
                    ;;
            esac

            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$copy_options" -- "$cur"))
            else
                # Positional arguments: srcdir, dstdir
                if [[ "$pos_arg_count" -eq 0 ]]; then
                    # First positional: srcdir, directory
                    COMPREPLY=($(compgen -d -- "$cur"))
                elif [[ "$pos_arg_count" -eq 1 ]]; then
                    # Second positional: dstdir, directory
                    COMPREPLY=($(compgen -d -- "$cur"))
                else
                    # Extra args, maybe files?
                    COMPREPLY=($(compgen -f -- "$cur"))
                fi
            fi
            ;;
        libexec-dir|library-path|uname|version)
            # No additional options, just global
            COMPREPLY=()
            ;;
        *)
            # Unknown command
            COMPREPLY=()
            ;;
    esac
}

complete -F _mulle_dispense_complete mulle-dispense
