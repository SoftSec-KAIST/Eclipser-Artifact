#!/usr/bin/env python
import os, sys, time, shutil

if len(sys.argv) != 5 :
    print "Usage : python %s <target directory> <start time> <interval> <max>" % sys.argv[0]
    exit(1)

target_dir = sys.argv[1]
start = int(sys.argv[2])
interval = int(sys.argv[3])
max_idx = int(sys.argv[4])

if interval == 0:
    interval = 1

if not os.path.isdir(target_dir):
    print "target directry %s does not exists" % target_dir
    exit(1)

if target_dir[-1] == "/" :
    target_dir = target_dir[:-1]
output_dir = "%s.sorted" % target_dir

if os.path.isdir(output_dir):
    shutil.rmtree(output_dir)
os.mkdir(output_dir)

for filename in os.listdir(target_dir) :
    filepath = "%s/%s" % (target_dir, filename)
    
    if not os.path.isfile(filepath):
        continue

    timestamp = int(os.path.getctime(filepath))
    delta = timestamp - start
    idx = (delta / interval) + 1
    if idx > max_idx :
        idx = max_idx
    if idx < 1 :
        print "Warning : clock skew : start_time = %d vs timestamp = %d" % (start, timestamp)
        idx = 1
    slot_dir = "%s/%d" % (output_dir, idx)
    if not os.path.isdir(slot_dir):
        os.mkdir(slot_dir)

    dst_path = "%s/%s" % (slot_dir, filename)
    shutil.copyfile(filepath, dst_path)
