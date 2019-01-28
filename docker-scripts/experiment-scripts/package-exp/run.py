#!/usr/bin/env python
import sys, os

ECLIPSER = "eclipser"
AFLFAST = "aflfast"
LAFINTEL = "lafintel"

n_slots = 24
n_spawn = 10
n_solve = 600

OUTDIR = "/home/artifact/output/"

def export_results(program, nth):
    os.system("mv /tmp/log-run %s/log-run-%s-%d" % (OUTDIR, program, nth))
    os.system("mv /tmp/log-replay %s/log-replay-%s-%d" % (OUTDIR, program, nth))
    os.system("mv /tmp/coverage %s/coverage-%s-%d" % (OUTDIR, program, nth))
    os.system("mv /tmp/coverages %s/coverages-%s-%d" % (OUTDIR, program, nth))
    crash_dir = "/tmp/output-%s/crash.reproduced" % program
    if os.path.isdir(crash_dir) and len(os.listdir(crash_dir)) != 0:
        os.system("mv %s %s/crash-%s-%d" % (crash_dir, OUTDIR, program, nth))

def run_eclipser(program, cmdline, inputfile, timelimit):
    # Run Eclipser
    cmd = '{ ./run_eclipser.sh %s %d %d "%s" %s %d %d ; } > /tmp/log-run 2>&1' % \
            (program, timelimit, n_slots, cmdline, inputfile, n_spawn, n_solve)
    os.system(cmd)
    if not os.path.isdir('/tmp/output-%s' % program):
        exit(1)
    # Replay test cases
    cmd = './replay_eclipser.sh %s %d "%s" %s > /tmp/log-replay 2>&1' % \
            (program, n_slots, cmdline, inputfile)
    os.system(cmd)

def run_aflfast (program, cmdline, inputfile, timelimit):
    # Run AFLFast
    cmd = '{ ./run_aflfast.sh %s %d %d "%s" %s ; } > /tmp/log-run 2>&1' % \
            (program, timelimit, n_slots, cmdline, inputfile)
    os.system(cmd)
    if not os.path.isdir('/tmp/output-%s' % program):
        exit(1)
    # Replay test cases
    cmd = './replay_aflfast.sh %s %d "%s" %s > /tmp/log-replay 2>&1' % \
            (program, n_slots, cmdline, inputfile)
    os.system(cmd)
    # Export results to volume

def run_lafintel (program, cmdline, inputfile, timelimit):
    # Run LAF-intel
    cmd = '{ ./run_lafintel.sh %s %d %d "%s" %s ; } > /tmp/log-run 2>&1' % \
            (program, timelimit, n_slots, cmdline, inputfile)
    os.system(cmd)
    if not os.path.isdir('/tmp/output-%s' % program):
        exit(1)
    # Replay test cases
    cmd = './replay_lafintel.sh %s %d "%s" %s > /tmp/log-replay 2>&1' % \
            (program, n_slots, cmdline, inputfile)
    os.system(cmd)
    # Export results to volume

def main():
    if len(sys.argv) != 5:
        print "Usage : %s <tool> <target> <timelimit> <iter-nth>"
        print "invalid number of arguments"
        exit(0)

    tool = sys.argv[1]
    target = sys.argv[2]
    timelimit = int(sys.argv[3])
    iter_nth = int(sys.argv[4])

    program = target.split(",")[0]
    cmdline = target.split(",")[1]
    inputfile = target.split(",")[2]

    os.chdir(os.path.dirname(__file__))
    if tool == ECLIPSER:
        run_eclipser(program, cmdline, inputfile, timelimit)
    elif tool == AFLFAST:
        run_aflfast(program, cmdline, inputfile, timelimit)
    elif tool == LAFINTEL:
        run_lafintel(program, cmdline, inputfile, timelimit)
    else:
        print "Unsupported tool % %s" % tool

    # Export results to volume
    export_results(program, iter_nth)

if __name__ == "__main__":
    main()
