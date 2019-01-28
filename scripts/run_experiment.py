#!/usr/bin/env python
import sys
sys.dont_write_bytecode = True
from time import sleep
from multiprocessing import Process, Queue
from Queue import Empty
from utils import *
from monitor import STATUS_FILE_TEMPLATE, FINISH_INDICATOR

MEM_PER_CONTAINER = 4096 # MBs of memory to assign for each docker container

VERSION = "v0.1"

CUR_DIR = os.path.dirname(os.path.abspath(__file__))
TESTSET_DIR = os.path.join(CUR_DIR, "testset")
DOCKER_EXP_DIR = "/home/artifact/experiment-scripts/"

COREUTILS = "coreutils"
COREUTILS_TARGET_FILE = os.path.join(TESTSET_DIR, "coreutils_targets")
COREUTILS_SCRIPT_FILE = os.path.join(DOCKER_EXP_DIR, "coreutils-exp/run.py")

LAVA = "lava"
LAVA_TARGET_FILE = os.path.join(TESTSET_DIR, "lava_targets")
LAVA_SCRIPT_FILE = os.path.join(DOCKER_EXP_DIR, "lava-exp/run.py")

PACKAGE = "package"
PACKAGE_TARGET_FILE = os.path.join(TESTSET_DIR, "package_targets")
PACKAGE_SCRIPT_FILE = os.path.join(DOCKER_EXP_DIR, "package-exp/run.py")

ECLIPSER = "eclipser"
KLEE = "klee"
AFLFAST = "aflfast"
LAFINTEL = "lafintel"

def print_usage(argv):
    usage_fmt = "Usage : %s <coreutils|lava|package> " \
                "<eclipser|klee|aflfast|lafintel> " \
                "<timelimit for each program> " \
                "<# of workers> " \
                "<# of iteration (default=1)>"
    print usage_fmt % argv[0]

def validate_option(testset, tool):
    if testset == COREUTILS:
        if tool != ECLIPSER and tool != KLEE:
            print "Coreutils can be ran only with 'eclipser' or 'klee'."
            exit(1)
    elif testset == LAVA:
        if tool != ECLIPSER and tool != AFLFAST and tool != LAFINTEL :
            print "LAVA can be ran only with 'eclipser', 'aflfast', or " \
                  "'lafintel'"
            exit(1)
    elif testset == PACKAGE:
        if tool != ECLIPSER and tool != AFLFAST and tool != LAFINTEL :
            print "Debian packages can be ran only with 'eclipser', " \
                  "'aflfast', or 'lafintel'."
            exit(1)
    else:
        print "Invalid test set : %s" % testset
        print "Allowed test sets are 'coreutils', 'lava', and 'package'"
        exit(1)

def initialize_worklist(testset, iter_no, worklist):
    if testset == COREUTILS:
        target_file = COREUTILS_TARGET_FILE
    elif testset == LAVA:
        target_file = LAVA_TARGET_FILE
    elif testset == PACKAGE:
        target_file = PACKAGE_TARGET_FILE
    else:
        assert(False) # Unreachable.
    targets = read_file(target_file)
    for i in xrange(iter_no):
        for line in targets.splitlines():
            worklist.put((i, line))

def get_script(testset):
    if testset == COREUTILS:
        script = COREUTILS_SCRIPT_FILE
    elif testset == LAVA:
        script = LAVA_SCRIPT_FILE
    elif testset == PACKAGE:
        script = PACKAGE_SCRIPT_FILE
    else:
        assert(False) # Unreachable.
    return script

def worker(worker_id, outdir, script, tool, timelimit, worklist):
    while True:
        if worklist.empty() :
            break
        else:
            try:
                # Caution : Note that get() method sometimes raises Empty
                # exception even if the queue is still not empty.
                iter_nth, target = worklist.get(block = False)
            except Empty:
                continue
        msg = "Worker %d running '%s' with %s for %d sec." % \
                (worker_id, target, tool, timelimit)
        status_file = os.path.join(outdir, STATUS_FILE_TEMPLATE % worker_id)
        write_file(status_file, msg)

        outdir_abs = os.path.abspath(outdir)
        docker_cmd = "docker run --rm -it --cap-add=SYS_PTRACE " \
                     "--cpuset-cpus %d " % worker_id + \
                     "--memory=%dm " % MEM_PER_CONTAINER + \
                     "--volume %s:/home/artifact/output " % outdir_abs + \
                     "eclipser:%s" % VERSION
        cmd = "%s %s %s '%s' %d %d" % \
                (docker_cmd, script, tool, target, timelimit, iter_nth)
        run_command(cmd)
        os.remove(status_file)
        sleep(1)

def check_core_pattern():
    core_pattern = read_file("/proc/sys/kernel/core_pattern")
    if core_pattern.strip() != "core":
        print "This experiment requires core dump pattern configuration"
        print "Run 'echo core | sudo tee /proc/sys/kernel/core_pattern'"
        exit(1)

# Import AFL's check_cpu_governor() in afl-fuzz.c to check CPU governor, so that
# we can prevent runtime error within the docker container.
def check_cpu_governor():
    GOVERNOR_PATH = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    cpu_governor = read_file(GOVERNOR_PATH);
    if cpu_governor == "":
        print "check_cpu_governor() passed (1)"
        return

    cpu_governor = cpu_governor.strip()
    if cpu_governor.startswith("perf"):
        print "check_cpu_governor() passed (2)"
        return

    try:
        MINFREQ_PATH = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"
        minfreq = read_file(MINFREQ_PATH)
        minVal = int(minfreq.strip())
    except ValueError:
        minVal = 0

    try:
        MAXFREQ_PATH = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
        maxfreq = read_file(MAXFREQ_PATH)
        maxVal = int(maxfreq.strip())
    except ValueError:
        maxVal = 0

    if minVal == maxVal:
        print "check_cpu_governor() passed (3)"
        return
    else:
        print "AFL-family fuzzers request to configure your system's CPU " + \
              "governor with the following command."
        print "'echo performance | " + \
              "sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'"
        print ""

        print "Your current governor is configured to '%s'." % cpu_governor
        print "You can later restore current state with the following command."
        print "'echo %s | " % cpu_governor + \
              "sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'"
        exit(1)

def main():
    if len(sys.argv) != 5 and len(sys.argv) != 6 :
        print_usage(sys.argv)
        exit(1)

    testset = sys.argv[1]
    tool = sys.argv[2]
    timelimit = int(sys.argv[3])
    worker_n = int(sys.argv[4])
    if len(sys.argv) == 5:
        iter_no = 1
    else:
        iter_no = int(sys.argv[5])

    validate_option(testset, tool)
    if testset == LAVA or testset == PACKAGE:
        check_core_pattern()

    if tool == AFLFAST or tool == LAFINTEL:
        check_cpu_governor()

    worklist = Queue()
    initialize_worklist(testset, iter_no, worklist)
    script = get_script(testset)
    time_prediction = float(timelimit) * worklist.qsize() / worker_n / 3600
    outdir = mkdir_with_prefix("output")

    print "Number of tasks to run : %d" % worklist.qsize()
    print "Number of worker processes to spawn : %d" % worker_n

    process_list = []
    for i in xrange(worker_n):
        args_tuple = (i, outdir, script, tool, timelimit, worklist)
        p = Process(target = worker, args = args_tuple)
        p.start()
        process_list.append(p)

    for p in process_list:
        p.join()

    write_file(os.path.join(outdir, FINISH_INDICATOR), "")

    # Restore terminal messed up by docker.
    os.system("reset")

if __name__ == "__main__":
    main()
