#!/usr/bin/env python
import sys, os
sys.dont_write_bytecode = True
import utils

sig_bugid = "Successfully triggered bug "

base64_counts = []
md5sum_counts = []
uniq_counts = []
who_counts = []

if len(sys.argv) != 2 :
  print "Usage : python %s <output directory>" % sys.argv[0]
  sys.exit(0)

outdir = sys.argv[1]

utils.check_fuzzing_success(outdir)

for filename in os.listdir(outdir) :
  if "log-replay" not in filename or ".sw" in filename :
    continue

  bug_ids = []
  f = open(outdir + "/" + filename, "r")
  for line in f :
    if sig_bugid in line :
      idx = line.find(sig_bugid) + len(sig_bugid)
      bug_id = int(line[idx:].split(",")[0])
      if bug_id not in bug_ids :
        bug_ids.append(bug_id)
  f.close()
  #print "Results from %s" % filename
  #print bug_ids

  if "base64" in filename :
    base64_counts.append(len(bug_ids))
  elif "md5sum" in filename :
    md5sum_counts.append(len(bug_ids))
  elif "uniq" in filename :
    uniq_counts.append(len(bug_ids))
  elif "who" in filename :
    who_counts.append(len(bug_ids))

print "# of bugs found in base64 : %s" % base64_counts
print "Average : %d" % (sum(base64_counts) / len(base64_counts))
print "# of bugs found in md5sum : %s" % md5sum_counts
print "Average : %d" % (sum(md5sum_counts) / len(md5sum_counts))
print "# of bugs found in uniq : %s" % uniq_counts
print "Average : %d" % (sum(uniq_counts) / len(uniq_counts))
print "# of bugs found in who : %s" % who_counts
print "Average : %d" % (sum(who_counts) / len(who_counts))

