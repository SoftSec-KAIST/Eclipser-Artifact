#!/usr/bin/env python
import sys, os
sys.dont_write_bytecode = True
import utils

node_sig = "Visited nodes : "
edge_sig = "Visited edges : "

def parse_basic_block_coverage(filepath) :

  content = utils.read_file(filepath)
  if content == "":
    print "Failed to read coverage information from %s" % filepath
    sys.exit(0)

  idx_node = content.rfind(node_sig)
  if idx_node == -1 :
    print "No node signature found in %s" % filepath
    sys.exit(0)
  idx_node += len(node_sig)
  node = int(content[idx_node:].split()[0])

  idx_edge = content.rfind(edge_sig)
  if idx_edge == -1 :
    print "No edge signature found in %s" % filepath
    sys.exit(0)
  idx_edge += len(edge_sig)
  edge = int(content[idx_edge:].split()[0])

  return (node, edge)

def print_horizontal():
  print "=" * 70

def print_program_coverage(outdir, iter_no, program_list):
  for program in program_list:
    prog_node_count_sum = 0
    prog_edge_count_sum = 0
    for i in xrange(iter_no):
      filename = "coverage-%s-%d" % (program, i)
      filepath = os.path.join(outdir, filename)
      node_count, edge_count = parse_basic_block_coverage(filepath)
      prog_node_count_sum += node_count
      prog_edge_count_sum += edge_count

    prog_node_count = float(prog_node_count_sum) / iter_no
    prog_edge_count = float(prog_edge_count_sum) / iter_no
    print "%048s    %7d    %7d" % (program, prog_node_count, prog_edge_count)

def print_iteration_coverage(outdir, iter_no, program_list):
  covered_node_sum_list = []
  covered_edge_sum_list = []
  for i in xrange(iter_no):
    covered_node_sum = 0
    covered_edge_sum = 0
    for program in program_list:
      filename = "coverage-%s-%d" % (program, i)
      filepath = os.path.join(outdir, filename)
      node_count, edge_count = parse_basic_block_coverage(filepath)
      covered_node_sum += node_count
      covered_edge_sum += edge_count

    print "Iteration #%d : Node = %d, Edge = %d" % \
            (i, covered_node_sum, covered_edge_sum)

    covered_node_sum_list.append(covered_node_sum)
    covered_edge_sum_list.append(covered_edge_sum)

  avg_node = float(sum(covered_node_sum_list)) / iter_no
  avg_edge = float(sum(covered_edge_sum_list)) / iter_no
  print "Averaged coverage : Node = %d, Edge = %d" % (avg_node, avg_edge)

def main():
  if len(sys.argv) != 3 :
    print "Usage : python %s <output directory> <iteration>" % sys.argv[0]
    sys.exit(0)

  outdir = sys.argv[1]
  iter_no = int(sys.argv[2])
  program_list = utils.get_program_list(outdir)
  utils.check_fuzzing_success(outdir)
  print "%48s    %7s    %7s" % ("Program", "Node", "Branch")
  print_horizontal()
  print_program_coverage(outdir, iter_no, program_list)
  print_horizontal()
  print "(Coverage of each iteration)"
  print_iteration_coverage(outdir, iter_no, program_list)
  print_horizontal()

if __name__ == "__main__" :
  main()
