#!/usr/bin/env python
import sys, os
from options import *
from gcov_target import *

ECLIPSER = "eclipser"
KLEE = "klee"
n_slots = 30
n_spawn = 10
n_solve = 600

OUTDIR = "/home/artifact/output/"

def export_results(program, nth):
    os.system("mv /tmp/log-run %s/log-run-%s-%d" % (OUTDIR, program, nth))
    os.system("mv /tmp/coverage %s/coverage-%s-%d" % (OUTDIR, program, nth))
    os.system("mv /tmp/coverages %s/coverages-%s-%d" % (OUTDIR, program, nth))
    crash_dir = "/tmp/output-%s/crash.renamed" % program
    if os.path.isdir(crash_dir) and len(os.listdir(crash_dir)) != 0:
        os.system("mv %s %s/crash-%s-%d" % (crash_dir, OUTDIR, program, nth))

def run_eclipser(program, timelimit):
    gcov_target = get_gcov_target(program)
    eclipser_option = get_eclipser_option(program)
    # Run Eclipser
    cmd = '{ ./run_eclipser.sh "%s" %d %d "%s" %d %d ; } > /tmp/log-run 2>&1' % \
            (program, timelimit, n_slots, eclipser_option, n_spawn, n_solve)
    os.system(cmd)
    if not os.path.isdir('/tmp/output-%s' % program):
        exit(1)
    # Replay test cases
    cmd = 'sudo ./replay_eclipser.sh "%s" %d "%s" > /tmp/log-replay 2>&1' % \
            (program, n_slots, gcov_target)
    os.system(cmd)
    # Export results to volume

def run_klee(program, timelimit):
    gcov_target = get_gcov_target(program)
    klee_option = get_klee_option(program)
    # Run KLEE
    cmd = '{ ./run_klee.sh "%s" %d %d "%s" ; } > /tmp/log-run 2>&1' % \
            (program, timelimit, n_slots, klee_option)
    os.system(cmd)
    if not os.path.isdir('/tmp/output-%s' % program):
        exit(1)
    # Special handling for "yes" program that emits a too long runtime log
    if program == "yes" :
        os.system('tail -n 100 /tmp/log-run > /tmp/log-run.tail')
        os.system('mv /tmp/log-run.tail /tmp/log-run')
    # Replay test cases
    cmd = 'sudo ./replay_klee.sh "%s" %d "%s" > /tmp/log-replay 2>&1' % \
            (program, n_slots, gcov_target)
    os.system(cmd)

def main():
    if len(sys.argv) != 5:
        print "Usage : %s <tool> <target> <timelimit> <iter-nth>"
        print "invalid number of arguments"
        exit(0)

    tool = sys.argv[1]
    program = sys.argv[2]
    timelimit = int(sys.argv[3])
    iter_nth = int(sys.argv[4])

    os.chdir(os.path.dirname(__file__))
    if tool == ECLIPSER:
        run_eclipser(program, timelimit)
    elif tool == KLEE:
        run_klee(program, timelimit)
    else:
        print "Unsupported tool % %s" % tool

    # Export results to volume
    export_results(program, iter_nth)

if __name__ == "__main__":
    main()
