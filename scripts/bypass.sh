#!/bin/bash

clear_cache(){
    sync
    sudo su -c "echo 3 > /proc/sys/vm/drop_caches"
}

EXPERIMENT_NAME="exp"
execn=12
depth=(1 2)
savfreq=(1 50 500 1000)
seq1="ref-wuhan-60k.fa"
seq2="ref-MT012098.1-60k.fa"
profiler_path="rprof.py"

mkdir "${EXPERIMENT_NAME}"

lscpu >> "${EXPERIMENT_NAME}/lscpu.txt"
cat /proc/cpuinfo >> "${EXPERIMENT_NAME}/cpuinfo.txt"
cat /proc/meminfo >> "${EXPERIMENT_NAME}/meminfo.txt"

cp $(basename $0) "${EXPERIMENT_NAME}/" 

mkdir "${EXPERIMENT_NAME}/monitor"
mkdir "${EXPERIMENT_NAME}/monitor/init"
mkdir "${EXPERIMENT_NAME}/monitor/default"
mkdir "${EXPERIMENT_NAME}/monitor/bypass"

python3 "${profiler_path}" -o "${EXPERIMENT_NAME}/monitor/init" -dmc -i 1.5 "now run --dir ${EXPERIMENT_NAME}/monitor align.py ${seq1} ${seq2}"
clear_cache

python3 "${profiler_path}" -o "${EXPERIMENT_NAME}/monitor/default" -dmc -i 1.5 "now run --dir ${EXPERIMENT_NAME}/monitor align.py ${seq1} ${seq2}"
clear_cache

python3 "${profiler_path}" -o "${EXPERIMENT_NAME}/monitor/bypass" -dmc -i 1.5 "now run -b --dir ${EXPERIMENT_NAME}/monitor align.py ${seq1} ${seq2}"
clear_cache

#Standard D4ds v4 (4 vcpus, 16 GiB memory)

for dep in "${depth[@]}"; do

    dep_dir="${EXPERIMENT_NAME}/monitor/depth_${dep}"
    mkdir "${dep_dir}"

    python3 "${profiler_path}" -o "${dep_dir}" -dmc -i 1.5 "now run -d ${dep} --dir ${EXPERIMENT_NAME}/monitor align.py ${seq1} ${seq2}"
    clear_cache

done

for freq in "${savfreq[@]}"; do

    freq_dir="${EXPERIMENT_NAME}/monitor/save_freq_${freq}"
    mkdir "${freq_dir}"

    python3 "${profiler_path}" -o "${freq_dir}" -dmc -i 1.5 "now run -s ${freq} --dir ${EXPERIMENT_NAME}/monitor align.py ${seq1} ${seq2}"
    clear_cache

done

for execution in $(seq "${execn}"); do

    mkdir "${EXPERIMENT_NAME}/exec_${execution}"

    /usr/bin/time -f "%e" -o "${EXPERIMENT_NAME}/exec_${execution}/time_init.txt" now run --dir "${EXPERIMENT_NAME}/exec_${execution}" align.py ${seq1} ${seq2}
    clear_cache

    /usr/bin/time -f "%e" -o "${EXPERIMENT_NAME}/exec_${execution}/time_wo.txt" now run --dir "${EXPERIMENT_NAME}/exec_${execution}" align.py ${seq1} ${seq2}
    clear_cache

    /usr/bin/time -f "%e" -o "${EXPERIMENT_NAME}/exec_${execution}/time_bypass.txt" now run -b --dir "${EXPERIMENT_NAME}/exec_${execution}" align.py ${seq1} ${seq2}
    clear_cache

    for dep in "${depth[@]}"; do

        dep_dir="${EXPERIMENT_NAME}/exec_${execution}/depth_${dep}"
        mkdir "${dep_dir}"

        /usr/bin/time -f "%e" -o "${dep_dir}/time.txt" now run -d ${dep} --dir "${EXPERIMENT_NAME}/exec_${execution}" align.py ${seq1} ${seq2}
        clear_cache

    done

    for freq in "${savfreq[@]}"; do

        freq_dir="${EXPERIMENT_NAME}/exec_${execution}/save_freq_${freq}"
        mkdir "${freq_dir}"

        /usr/bin/time -f "%e" -o "${freq_dir}/time.txt" now run -s ${freq} --dir "${EXPERIMENT_NAME}/exec_${execution}" align.py ${seq1} ${seq2}
        clear_cache

    done

done