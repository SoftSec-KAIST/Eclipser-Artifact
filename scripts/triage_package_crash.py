#!/usr/bin/env python
import sys, os
sys.dont_write_bytecode = True
import utils

crash_start_sig = "===== Now reproducing crash ======"
asan_start_sig = "===== Now analyzing with sanitizer ======"

sanitize_delim_sig = "+++++++++++++++++++++++"
reproduce_sig = ".reproduced/"
sanitize_msg_sig = "==ERROR:"
sanitize_pc_sig = "#0 0x"
fpe_error_sig = "FPE"
alloc_error_sig = "failed to allocate"

replay_delim_sig = "======================="
rename_sig = ".renamed/"
segv_sig = "SIGSEGV"
ill_sig = "SIGILL"
abort_sig = "SIGABRT"
bus_sig = "SIGBUS"
replay_pc_sig = "=>"

def extract_stack_trace(msg):
  # First find the start of stack trace.
  trace_start_idx = msg.find(sanitize_pc_sig)
  if trace_start_idx == -1:
    return ""
  msg = msg[trace_start_idx:]

  # Append to stack trace as long as the line starts with '#' signature.
  stack_trace = ""
  for line in msg.split("\n"):
    line = line.strip()
    if len(line) > 0 and line[0] == "#":
      stack_trace = stack_trace + line + "\n"
    else:
      break
  return stack_trace

def triage_crash(filepath, log, error_pc_list, crash_pc_list):
  buf = utils.read_file(filepath)

  idx_start = buf.find(crash_start_sig)
  if idx_start == -1 :
    print "No replay signature found in %s" % filepath
    sys.exit(0)
  idx_start += len(crash_start_sig)

  idx_end = buf.rfind(asan_start_sig)
  if idx_end == -1 :
    print "No ASAN signature found in %s" % filepath
    sys.exit(0)

  replay_buf = buf[idx_start:idx_end]
  sanitize_buf = buf[idx_end:]

  # List of testcases that sanitizer failed to identify error.
  unreproduced_crashes = []
  i = 0

  while sanitize_delim_sig in sanitize_buf:

    # Print progress
    i += 1
    if i % 1000 == 0 :
      print "%d more bytes to parse" % len(sanitize_buf)

    # Find the delimiter and extract the sanitizer message
    idx_delim = sanitize_buf.find(sanitize_delim_sig)
    if idx_delim == -1 :
      assert(False)
    idx_delim += len(sanitize_delim_sig)
    sanitize_msg = sanitize_buf[:idx_delim]
    sanitize_buf = sanitize_buf[idx_delim:]

    # Find the crash name
    idx_reproduce = sanitize_msg.find(reproduce_sig)
    if idx_reproduce == -1 :
      assert(False)
    idx_reproduce += len(reproduce_sig)
    sanitize_msg = sanitize_msg[idx_reproduce:]
    crash_name = sanitize_msg.split("\n")[0]

    # Find the error cause from sanitizer message
    if sanitize_msg_sig not in sanitize_msg:
      unreproduced_crashes.append(crash_name)
    else:
      idx_sanitize_msg = sanitize_msg.find(sanitize_msg_sig)
      idx_sanitize_msg += len(sanitize_msg_sig)
      error_msg = sanitize_msg[idx_sanitize_msg:].split("\n")[0]

      # Identify program counter of error
      if sanitize_pc_sig in sanitize_msg:
        pc_idx = sanitize_msg.find(sanitize_pc_sig) + len(sanitize_pc_sig)
        error_pc = sanitize_msg[pc_idx:].split(" ")[0]
        stack_trace = extract_stack_trace(sanitize_msg)
      else:
        error_pc = None
        stack_trace = ""

      # Add to the log if it's an interesting error, and it pc is new
      if fpe_error_sig not in error_msg and \
         alloc_error_sig not in error_msg and \
         (error_pc is None or error_pc not in error_pc_list):
        error_pc_list.append(error_pc)
        error_content = error_msg + "\n" + stack_trace
        log.append((filepath, crash_name, error_pc, error_content))

  # If sanitize failed to report the error, extract replay log and record it.
  for unreproduced_crash in unreproduced_crashes:
    idx_crash = replay_buf.find(unreproduced_crash)
    if idx_crash == -1 :
      print replay_buf
      assert(False)
    idx_crash += len(unreproduced_crash)
    replay_buf = replay_buf[idx_crash:]

    # Find the delimeter and split
    idx_delim = replay_buf.find(replay_delim_sig)
    if idx_delim == -1 :
      assert(False)
    idx_delim += len(replay_delim_sig)
    replay_msg = replay_buf[:idx_delim]
    replay_buf = replay_buf[idx_delim:]

    # Check if this is valid crash
    if segv_sig in replay_msg or ill_sig in replay_msg or \
       abort_sig in replay_msg or bus_sig in replay_msg :
      pc_idx = replay_msg.find(replay_pc_sig) + len(replay_pc_sig)
      crash_pc = replay_msg[pc_idx:].split("\n")[0]
      if crash_pc not in crash_pc_list:
        crash_pc_list.append(crash_pc)
        log.append((filepath, unreproduced_crash, crash_pc, replay_msg))

def main():
  if len(sys.argv) != 3 :
    print "Usage : python %s <test name> <iteration>" % sys.argv[0]
    exit(0)

  outdir = sys.argv[1]
  iter_no = int(sys.argv[2])
  program_list = utils.get_program_list(outdir)

  for progname in program_list:
    print "program : %s" % progname
    log = []
    error_pc_list = []
    crash_pc_list = []
    for i in xrange(iter_no):
      filename = "log-replay-%s-%d" % (progname, i)
      filepath = os.path.join(outdir, filename)
      triage_crash(filepath, log, error_pc_list, crash_pc_list)

    for crash in log:
      filename, crash_name, pc, msg = crash
      print "%s : %s @ %s\n  %s\n" % (filename, crash_name, pc, msg)
    print "-----------------------------"

if __name__ == "__main__" :
    main()
