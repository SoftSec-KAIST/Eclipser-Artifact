#!/usr/bin/env python

import sys
sys.dont_write_bytecode = True
import os, subprocess, shlex

def read_file(filepath):
  if not os.path.exists(filepath):
    return ""

  f = open(filepath)
  content = f.read()
  f.close()
  return content

def write_file(filepath, content):
    f = open(filepath, "w")
    f.write(content)
    f.close()
    return

def run_command(command):
    process = subprocess.Popen(shlex.split(command), \
              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout = ''
    while True:
        outbuf = process.stdout.readline()
        if outbuf == '' and process.poll() is not None:
            break
        if outbuf:
            stdout = stdout + outbuf.strip()+ '\n'
    stderr = process.communicate()[1]
    return stdout, stderr, process.returncode

def mkdir_with_prefix(prefix):
    i = 0
    while True:
        dirname = "%s-%d" % (prefix, i)
        if not os.path.exists(dirname):
            os.mkdir(dirname, 0755)
            return dirname
        i += 1

def get_program_list(directory):
    sig = "log-run-"
    prog_list = []
    for filename in os.listdir(directory):
        if sig not in filename or ".sw" in filename:
            continue

        idx1 = filename.find(sig)
        assert(idx1 != -1)
        idx1 += len(sig)

        # Now should trim trailing '-n'.
        idx2 = filename.rfind("-")
        assert(idx2 != -1)

        progname = filename[idx1:idx2]
        if progname not in prog_list:
            prog_list.append(progname)

    prog_list.sort()
    return prog_list

def check_fuzzing_success(directory):
    sig = "log-run-"
    for filename in os.listdir(directory):
        if sig not in filename or ".sw" in filename:
            continue

        content = read_file(os.path.join(directory, filename))
        if "execs_done" not in content and "Executions : " not in content:
            print "Log file '%s' indicates an error while fuzzing." % filename
            sys.exit(0)
