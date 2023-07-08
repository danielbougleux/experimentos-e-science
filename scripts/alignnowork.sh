#!/bin/bash

clear_cache(){
    sync
    sudo su -c "echo 3 > /proc/sys/vm/drop_caches"
}

EXPERIMENT_NAME="/datadir/exp_without_nowork_60k"
execn=12
seq1="ref-wuhan-60k.fa"
seq2="ref-MT012098.1-60k.fa"
profiler_path="rprof.py"

mkdir "${EXPERIMENT_NAME}"

lscpu >> "${EXPERIMENT_NAME}/lscpu.txt"
cat /proc/cpuinfo >> "${EXPERIMENT_NAME}/cpuinfo.txt"
cat /proc/meminfo >> "${EXPERIMENT_NAME}/meminfo.txt"

cp $(basename $0) "${EXPERIMENT_NAME}/" 

mkdir "${EXPERIMENT_NAME}/monitor"

python3 "${profiler_path}" -o "${EXPERIMENT_NAME}/monitor/" -dmc -i 1.5 "python3 align.py ${seq1} ${seq2}"
clear_cache

for execution in $(seq "${execn}"); do

    mkdir "${EXPERIMENT_NAME}/exec_${execution}"

    /usr/bin/time -f "%e" -o "${EXPERIMENT_NAME}/exec_${execution}/time_init.txt" python3 align.py ${seq1} ${seq2}
    clear_cache

done