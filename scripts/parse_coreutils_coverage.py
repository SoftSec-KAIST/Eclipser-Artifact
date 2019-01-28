#!/usr/bin/env python
import sys, os
sys.dont_write_bytecode = True
import utils

file_start_sig = "File '"
file_end_sig = "Creating '"
line_sig = "Lines executed:"
branch_sig = "Branches executed:"

def parse_gcov_coverage(filepath) :
  covered_line = 0
  total_line = 0
  covered_branch = 0
  total_branch = 0

  if not os.path.exists(filepath):
    print "Coverage log file %s not found" % filepath
    sys.exit(0)

  f = open(filepath)

  file_encountered = False
  for linebuf in f :

    if file_start_sig in linebuf :
      file_encountered = True
      continue

    if line_sig in linebuf and file_encountered :
      idx = linebuf.rfind(line_sig)
      assert (idx != -1)
      idx += len(line_sig)
      linebuf = linebuf[idx:]
      ratio = float(linebuf.split("%")[0]) / 100.0
      lines_in_file = int(linebuf.split()[-1])
      covered_lines_in_file = int(round(lines_in_file * ratio))
      # Accumulate
      covered_line += covered_lines_in_file
      total_line += lines_in_file

    if branch_sig in linebuf and file_encountered :
      idx = linebuf.rfind(branch_sig)
      assert (idx != -1)
      idx += len(branch_sig)
      linebuf = linebuf[idx:]
      ratio = float(linebuf.split("%")[0]) / 100.0
      branches_in_file = int(linebuf.split()[-1])
      covered_branches_in_file = int(round(branches_in_file * ratio))
      # Accumulate
      covered_branch += covered_branches_in_file
      total_branch += branches_in_file

    if file_end_sig in linebuf:
      file_encountered = False

  f.close()

  return (covered_line, total_line, covered_branch, total_branch)

def print_horizontal():
  print "=" * 70

def print_program_coverage(outdir, iter_no, program_list):
  for program in program_list:
    prog_covered_line_sum = 0
    prog_total_line_last = 0
    for i in xrange(iter_no):
      filename = "coverage-%s-%d" % (program, i)
      filepath = os.path.join(outdir, filename)
      (covered_line, total_line, _, _) = parse_gcov_coverage(filepath)
      if total_line == 0 :
        print "No coverage information in %s" % filepath
        print "This may be caused by too short experiment time provided."
        sys.exit(0)

      prog_covered_line_sum += covered_line
      # total_line should be the same
      assert(prog_total_line_last == 0 or prog_total_line_last == total_line)
      prog_total_line_last = total_line

    prog_covered_line = float(prog_covered_line_sum) / iter_no

    assert(prog_total_line_last != 0)
    # Also, record coverage information to a tuple list (to print later).
    percent = 100.0 * prog_covered_line / prog_total_line_last
    print "%30s    %7d    %7d    %7.2f" % \
            (program, prog_covered_line, prog_total_line_last, percent)

def plot_coverage(outdir, iter_no, program_list):
  TOTAL_SLOTS = 30
  DELTA_NO = 1
  for no in range(0, TOTAL_SLOTS, DELTA_NO):
    no = no + DELTA_NO
    covered_line_sum = 0.0
    total_line_sum = 0
    invalid_slot = False
    for progname in program_list:
      prog_covered_line_sum = 0
      prog_total_line_last = 0
      for i in range(iter_no) :
        filename = "coverages-%s-%d/coverage-%d" % (progname, i, no)
        filepath = os.path.join(outdir, filename)
        (covered_line, total_line, _, _) = parse_gcov_coverage(filepath)
        if total_line == 0:
          invalid_slot = True
          break

        prog_covered_line_sum += covered_line
        # total_line should be the same
        assert(prog_total_line_last == 0 or prog_total_line_last == total_line)
        prog_total_line_last = total_line

      if invalid_slot:
        break

      # Accumulate coverage information of this program.
      prog_covered_line = float(prog_covered_line_sum) / iter_no
      covered_line_sum += prog_covered_line
      assert(prog_total_line_last != 0)
      total_line_sum += prog_total_line_last

    if invalid_slot:
        continue

    # Calculate coverage of current slot (i.e. timepoint) and print it.
    ratio = float(covered_line_sum) / total_line_sum * 100.0
    print "%03d/%03d : %.3f (%d / %d)" % \
          (no, TOTAL_SLOTS, ratio, covered_line_sum, total_line_sum)

def print_iteration_coverage(outdir, iter_no, program_list):
  covered_line_sum_list = []
  total_line_sum_list = []
  for i in xrange(iter_no):
    covered_line_sum = 0
    total_line_sum = 0
    for program in program_list:
      filename = "coverage-%s-%d" % (program, i)
      filepath = os.path.join(outdir, filename)
      (covered_line, total_line, _, _) = parse_gcov_coverage(filepath)
      if total_line == 0 :
        print "No coverage information in %s" % filepath
        print "This may be caused by too short experiment time provided."
        sys.exit(0)

      covered_line_sum += covered_line
      total_line_sum += total_line

    ratio = float(covered_line_sum) / total_line_sum * 100
    print "Iteration #%d : %.3f ( %d / %d )" % \
            (i, ratio, covered_line_sum, total_line_sum)

    covered_line_sum_list.append(covered_line_sum)
    total_line_sum_list.append(total_line_sum)

  avg_covered = float(sum(covered_line_sum_list)) / iter_no
  avg_total = float(sum(total_line_sum_list)) / iter_no
  avg_ratio = float(sum(covered_line_sum_list)) / sum(total_line_sum_list) * 100
  print "Averaged coverage : %.3f (%d / %d)" % \
          (avg_ratio, avg_covered, avg_total)

def main():
  if len(sys.argv) != 3 :
    print "Usage : python %s <output directory> <iteration>" % sys.argv[0]
    sys.exit(0)

  outdir = sys.argv[1]
  iter_no = int(sys.argv[2])
  program_list = utils.get_program_list(outdir)
  print "%30s    %7s    %7s    %7s" % ("Program", "Covered", "Total", "Ratio")
  print_horizontal()
  print_program_coverage(outdir, iter_no, program_list)
  print_horizontal()
  print "(Coverage plotting over time)"
  plot_coverage(outdir, iter_no, program_list)
  print_horizontal()
  print "(Coverage of each iteration)"
  print_iteration_coverage(outdir, iter_no, program_list)
  print_horizontal()

if __name__ == "__main__" :
    main()
