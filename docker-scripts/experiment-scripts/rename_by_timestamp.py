#!/usr/bin/env python
import os, sys, time, shutil

if len(sys.argv) != 3 :
    print "Usage : python %s <target directory> <start time>" % sys.argv[0]
    exit(1)

target_dir = sys.argv[1]
start = int(sys.argv[2])

if not os.path.isdir(target_dir):
    print "target directry %s does not exists" % target_dir
    exit(1)

if target_dir[-1] == "/" :
    target_dir = target_dir[:-1]
output_dir = "%s.renamed" % target_dir

if os.path.isdir(output_dir):
    shutil.rmtree(output_dir)
os.mkdir(output_dir)

for filename in os.listdir(target_dir) :
    filepath = "%s/%s" % (target_dir, filename)
    
    if not os.path.isfile(filepath):
        continue

    timestamp = int(os.path.getctime(filepath))
    delta = timestamp - start
    new_filepath = "%s/%s_%08d" % (output_dir, filename, delta)
    shutil.copyfile(filepath, new_filepath)
