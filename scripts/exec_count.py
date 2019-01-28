#!/usr/bin/env python
import sys, os
sys.dont_write_bytecode = True
import utils

sig_exec_chatkey = "Executions : "
sig_exec_afl = "execs_done"

def count_execution(filepath):
  log_content = utils.read_file(filepath)

  if sig_exec_chatkey in log_content:
    idx_exec = log_content.rfind(sig_exec_chatkey)
    idx_exec += len(sig_exec_chatkey)
    log_content = log_content[idx_exec:]
    exec_cnt = int(log_content.split("\n")[0])
    return exec_cnt
  elif sig_exec_afl in log_content:
    idx_exec = log_content.rfind(sig_exec_afl)
    idx_exec += len(sig_exec_afl)
    log_content = log_content[idx_exec:]
    exec_cnt = int(log_content.split()[1])
  else:
    print "No execution signature found in %s" % filepath
    sys.exit(0)

  return exec_cnt

if __name__ == "__main__" :

  if len(sys.argv) != 3 :
    print "Usage : python %s <test name> <iteration>" % sys.argv[0]
    sys.exit(0)

  testname = sys.argv[1]
  iter_no = int(sys.argv[2])

  program_list = utils.get_program_list(testname)

  exec_cnt_all = 0

  for progname in program_list:
    exec_cnt_sum = 0
    for i in xrange(iter_no):
      filename = "log-run-%s-%d" % (progname, i)
      filepath = testname + "/" + filename
      exec_cnt_sum += count_execution(filepath)
    print "%s : %d execs" % (progname, exec_cnt_sum / iter_no)
    exec_cnt_all += exec_cnt_sum

  exec_cnt_avg = exec_cnt_all / iter_no
  print "Total execution count on benchmark : %d" % exec_cnt_avg
