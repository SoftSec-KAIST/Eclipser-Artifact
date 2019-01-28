/*
    Copyright 2016 KAIST SoftSec.
    ---------------------------------------------------------------------
    Forkserver written and design by Michal Zalewski <lcamtuf@google.com>
    and Jann Horn <jannhorn@googlemail.com>

    Copyright 2013, 2014, 2015, 2016 Google Inc. All rights reserved.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at:

      http://www.apache.org/licenses/LICENSE-2.0
*/


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <dlfcn.h>
#include <pty.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <stdint.h>

pid_t child_pid;

void error_exit(char* msg) {
    perror(msg);
    exit(-1);
}

static void alarm_callback(int sig) {
    //printf("Timeout!\n");
    if (child_pid)
        kill(child_pid, SIGKILL);
}

int waitchild(pid_t pid)
{
    int childstatus = 0;

    alarm(60);

    if ( waitpid(pid, &childstatus, 0) < 0)
      perror("[Warning] waitpid() : ");

    alarm(0); // Cancle pending alarm

    if ( WIFEXITED( childstatus ) ) {
      printf("Normal exit\n");
      return 0;
    }

    if ( WIFSIGNALED( childstatus ) ) {
        if ( WTERMSIG( childstatus ) == SIGSEGV ) {
          printf("Segfault!!\n");
        } else if ( WTERMSIG( childstatus ) == SIGFPE ) {
          printf("Floating point error!!\n");
        } else if ( WTERMSIG( childstatus ) == SIGILL ) {
          printf("Illegal instruction!!\n");
        } else if ( WTERMSIG( childstatus ) == SIGABRT ) {
          printf("Program aborts!!\n");
        } else if ( WTERMSIG( childstatus ) == SIGKILL ) {
          printf("Program killed by timeout!!\n");
        } else  {
          printf("Unknown signal\n");
        }
    } else {
      printf("Abnormal exit\n");
    }
    return -1;
}

int main(int argc, char **argv) {
    char **new_argv = (char **)malloc( sizeof(char*) * (argc) );
    int i, devnull_fd;
    struct sigaction sa;

    for (i = 1; i < argc; i++)
        new_argv[i - 1] = argv[i];
    new_argv[argc - 1] = 0;

    sa.sa_flags     = SA_RESTART;
    sa.sa_sigaction = NULL;
    sigemptyset(&sa.sa_mask);
    sa.sa_handler = alarm_callback;
    sigaction(SIGALRM, &sa, NULL);

    child_pid = fork();
    if (child_pid == 0) {
        devnull_fd = open( "/dev/null", O_RDWR );
        if ( devnull_fd < 0 ) error_exit( "devnull_fd open" );
        /*
        dup2(devnull_fd, 1);
        dup2(devnull_fd, 2);
        */
        close(devnull_fd);
        execv(new_argv[0], new_argv);
        error_exit("execv");
    } else if (child_pid > 0) {
        free(new_argv);
        return waitchild(child_pid);
    } else {
        error_exit("fork");
    }

    return -2;
}
