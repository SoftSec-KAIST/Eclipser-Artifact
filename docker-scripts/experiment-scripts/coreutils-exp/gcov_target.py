def get_gcov_target(target):
    if target == "[" :
        return "lbracket"
    elif target in ["b2sum", "base32", "base64", "ginstall", "md5sum", "sha1sum", "sha224sum", "sha256sum", "sha384sum", "sha512sum"] :
        return ("src_%s-*" % target)
    elif target == "dir" :
        return "ls"
    elif target == "vdir" :
        return "ls"
    else :
         return target
