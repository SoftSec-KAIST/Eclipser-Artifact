Eclipser Artifact
========

[Eclipser](https://github.com/SoftSec-KAIST/Eclipser) is a binary-based fuzz
testing tool, which will be presented in ICSE 2019 conference. This repository
maintains a Docker image to run the experiments in our paper. The Docker image
and running scripts were tested on Ubuntu 18.04 host machine.

# Installation

1. Install Docker

To install Docker CE, please follow the instructions in this
[link](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

2. Prepare to run Docker without root privilege (i.e. sudo)

Since we wanted our scripts not to ask you for sudo password, we assumed that
you run Docker commands as a non-root user. Please follow the instructions in
this [link](https://docs.docker.com/install/linux/linux-postinstall/) for the
configuration.

3. Prepare Docker image for experiment

You may choose either (1) to build a Docker image from the scratch by running
[build.sh](build.sh), or (2) to download an already-built image from Docker
Hub by running [pull.sh](pull.sh). Since building an image from the scratch
takes a long time, we recommend the latter choice if you want to save your time.

If you want to investigate the image setup process in detail, please refer to
[Dockerfile](Dockerfile) and [setup scripts](docker-scripts/setup-scripts).

Note: If you chose to run `build.sh` script, you would want to fix the first
command in [Dockerfile](Dockerfile) and replace the apt-get repository to the
fastest one from your region.

Note: When you run `pull.sh`, it will first pull the image from Docker Hub, and
then build an image on top of that, by running a command to adjust UID within
the container. This is to avoid creating files on your system with root
privilege.

4. Testing the image

Once the Docker image is prepared, you can run [launch.sh](launch.sh) to run a
Docker container. Also, you can use the following commands to run Eclipser on
some simple example programs. Each testing script in `Eclipser/examples`
directory contains a comment about the test cases expected to be found by
Eclipser.

```
$ ./launch.sh
artifact@fb7350adf920:~$ cd Eclipser/examples/
artifact@fb7350adf920:~/Eclipser/examples$ ./test_cmp_gcc.sh
Fuzz target: /home/artifact/Eclipser/examples/cmp.bin
...
```

Note: In `launch.sh`, resource limitations of Docker container is specified with
`--cpuset-cpus` and `--memory` options. Memory resource limitation may print the
following warning message, depending on the kernel environment. We believe this
warning can be ignored.

```
WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.
```

# Running experiments

## Pre-requisites

Although we provide a Docker image to minimize the effect on your system,
running AFLFast and LAF-intel requires to change some of your system
configuration.

- Configuring core dump file pattern

AFL-based fuzzers request to disable the use of external crash report utilities
like 'apport', by running the following command.
```
echo core | sudo tee /proc/sys/kernel/core_pattern'"
```

- Configuring CPU governor

AFL-based fuzzers request to configure your CPU scaling algorithm, by running
the following command.
```
[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ] && \
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

## Top-level script

We provide a single top-level script
[scripts/run_experiment.py](scripts/run_experiment.py) to run our experiments.
You can specify which experiment to run, by providing proper arguments to this
script. Its basic usage is as follow, and more detailed usage for each
experiment is described below.

```
run_experiment.py <testset> <tool> <timelimit> <# proc> <# iteration (optional)>
```

Note: You can adjust the memory resource limitation for each Docker container,
by fixing `MEM_PER_CONTAINER` variable at the top of `run_experiment.py` file.

## Running coreutils experiment

To run coreutils experiment with Eclipser and KLEE, you can use the following
commands respectively.

```
$ ./scripts/run_experiment.py coreutils eclipser 3600 4
$ ./scripts/run_experiment.py coreutils klee 3600 4
```

This command will run each program in coreutils for one hour, as in our
experiment setting in the paper. The last argument specifies to run four worker
processes in parallel. You should modify these parameters considering your
machine spec and available resource. When deciding the number of worker
processes, please take a look at [threats](#threats-to-reproducing-experiments)
section, too.

Also, you can run each program in the test set iteratively. For this, you simply
have to append an optional argument (N) at the end of the command. If no
optional argument is provided, each program in the test set will be ran only
once.

When `run_experiment.py` script finishes, the testing outputs will be stored in
`output-*` directory. The directory name is automatically suffixed with a unique
number, starting from zero. You can parse the coverage result of the experiment
with [scripts/parse_coreutils_coverage.py](scripts/parse_coreutils_coverage.py)
as below. The last argument specifies how many time each program was ran
iteratively.

```
$./scripts/parse_coreutils_coverage.py ./output-0 1
```

Note : FYI, coreutils test set is composed of 95 programs.

## Running LAVA experiment

To run LAVA experiment with Eclipser, AFLFast, and LAF-intel, you can use the
following commands respectively. Each program in LAVA test set will be ran for 5
hours, as in our experiment setting in the paper. You should modify these
parameters considering your machine spec and available resource.


```
$ ./scripts/run_experiment.py lava eclipser 18000 4
$ ./scripts/run_experiment.py lava aflfast 18000 4
$ ./scripts/run_experiment.py lava lafintel 18000 4
```

We recommend you to carefully choose the number of worker process to spawn,
because if you run too many Docker containers simultaneously, AFLFast may fail
to initialize its 'fork server' for fuzzing, and exit immediately.

You can count the number of bugs found from the experiment with
[scripts/count_lava_crash.py](scripts/count_lava_crash.py) as below.

```
$./scripts/count_lava_crash.py ./output-0
```

Note : FYI, LAVA test set is composed of 4 programs.

## Running Debian package experiment

To run Debian package experiment with Eclipser, AFLFast, and LAF-intel, you can
use the following commands respectively. Each program in Debian package test set
will be ran for 24 hours, as in our experiment setting in the paper. You should
modify these parameters considering your machine spec and available resource.

```
$ ./scripts/run_experiment.py package eclipser 86400 4
$ ./scripts/run_experiment.py package aflfast 86400 4
$ ./scripts/run_experiment.py package lafintel 86400 4
```

You can parse the coverage result of the experiment with
[scripts/parse_package_coverage.py](scripts/parse_package_coverage.py), and
triage found crashes with
[scripts/triage_package_crash.py](scripts/triage_package_crash.py) as below.
However, note that `triage_package_crash.py` conservatively de-duplicates
crashes, so its result should be further investigated manually, in order to
correctly identify unique bugs.

```
$./scripts/parse_package_coverage.py ./output-0 1
$./scripts/triage_package_crash.py ./output-0 1
```

Note : FYI, Debian package test set is composed of 20 programs.

# Threats to reproducing experiments

There are several obstacles to precisely reproduce the experiment results of the
paper. First, the difference between Docker and KVM (which was used in our paper
experiment) seems to substantially affect the experiment result.

Especially, running AFLFast and LAF-intel within Docker seems not to scale up
well as we increase the number of worker processes (i.e. Docker container) that
runs in parallel. Therefore, we recommend to avoid choosing a large number as
the number of worker process to spawn, when running `run_experiment.py` script.

Also, even if we give each experiment the same amount of time as in the paper,
experiment results can vary according to machine specs.

Despite such threats, in our several testing environments we could consistently
confirm the overall tendency that Eclipser outperforms other tools as in the
paper.
