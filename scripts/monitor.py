#!/usr/bin/env python

import sys
sys.dont_write_bytecode = True
import os
from time import sleep
from utils import *

STATUS_FILE_TEMPLATE = "worker-%d.status"
FINISH_INDICATOR = "DONE"

def count_done_tasks(outdir):
    count = 0
    for filename in os.listdir(outdir):
        if "log-run-" in filename:
            count += 1
    return count

def monitor(outdir, worker_n):
    msg_list = []
    for i in xrange(worker_n):
        status_file = os.path.join(outdir, STATUS_FILE_TEMPLATE % i)
        status_msg = read_file(status_file)
        if status_msg != "":
            msg_list.append(status_msg)

    os.system("clear")
    for msg in msg_list:
        print msg

    print ""
    print "(%d tasks are finished currently)" % count_done_tasks(outdir)

def main():
    if len(sys.argv) != 3 :
        print "Usage : %s <outdir> <worker N>" % sys.argv[0]
        exit(1)

    outdir = sys.argv[1]
    worker_n = int(sys.argv[2])
    done_file = os.path.join(outdir, FINISH_INDICATOR)
    while not os.path.exists(done_file):
        monitor(outdir, worker_n)
        sleep(5)
    print "All tastks finished!"

if __name__ == "__main__":
    main()
