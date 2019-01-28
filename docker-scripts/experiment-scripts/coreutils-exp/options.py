def get_klee_option(target) :
    if target == "dd" :
        return "--sym-args 0 3 10 --sym-files 1 8 --sym-stdin 8 --sym-stdout"
    elif target == "dircolors" :
        return "--sym-args 0 3 10 --sym-files 2 12 --sym-stdin 12 --sym-stdout"
    elif target == "echo" :
        return "--sym-args 0 4 300 --sym-files 2 30 --sym-stdin 30 --sym-stdout"
    elif target == "expr" :
        return "--sym-args 0 1 10 --sym-args 0 3 2 --sym-stdout"
    elif target == "mknod" :
        return "--sym-args 0 1 10 --sym-args 0 3 2 --sym-files 1 8 --sym-stdin 8 --sym-stdout"
    elif target == "od":
        return "--sym-args 0 3 10 --sym-files 2 12 --sym-stdin 12 --sym-stdout"
    elif target == "pathchk":
        return "--sym-args 0 1 2 --sym-args 0 1 300 --sym-files 1 8 --sym-stdin 8 --sym-stdout"
    elif target == "printf":
        return "--sym-args 0 3 10 --sym-files 2 12 --sym-stdin 12 --sym-stdout"
    else :
        return "--sym-args 0 1 10 --sym-args 0 2 2 --sym-files 1 8 --sym-stdin 8 --sym-stdout"

def get_eclipser_option(target):
    klee_option = get_klee_option(target)

    arg_option = "--maxarglen"
    file_option = ""
    stdin_option = ""

    # Convert KLEE option to corresponding Eclipser option
    klee_args = klee_option.split("--")
    for klee_arg in klee_args:
        tokens = klee_arg.split()
        if len(tokens) == 0 :
            continue
        if tokens[0] == "sym-args" :
            assert(len(tokens) == 4)
            arg_no = int(tokens[2]) # Not [1]
            arg_len = int(tokens[3])
            arg_option += (" %d" % arg_len) * arg_no
        elif tokens[0] == "sym-files" :
            assert(len(tokens) == 3)
            file_len = int(tokens[2]) # Not [1]
            file_option = "--maxfilelen %d" % file_len
        elif tokens[0] == "sym-stdin" :
            assert(len(tokens) == 2)
            stdin_len = int(tokens[1])
            stdin_option = "--maxstdinlen %d" % stdin_len

    if file_option == "" and stdin_option == "":
        src_option = "--src arg"
    else:
        src_option = "--src auto"

    return "%s %s %s %s" % (src_option, arg_option, file_option, stdin_option)

