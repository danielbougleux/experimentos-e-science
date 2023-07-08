#!/bin/bash

clear_cache(){
    sync
    sudo su -c "echo 3 > /proc/sys/vm/drop_caches"
}

EXPERIMENT_DISK="sqlite"
PROGRAM_DIR="${EXPERIMENT_DISK}/pytorch-sqlite"
EXPERIMENT_PATH="${EXPERIMENT_DISK}/sqlite_exp"
execn=1
depth=(1 2)
savfreq=(1 50 500 1000)
profiler_path="~/rprof.py"

mkdir "${EXPERIMENT_PATH}"

lscpu >> "${EXPERIMENT_PATH}/lscpu.txt"
cat /proc/cpuinfo >> "${EXPERIMENT_PATH}/cpuinfo.txt"
cat /proc/meminfo >> "${EXPERIMENT_PATH}/meminfo.txt"

cp $(basename $0) "${EXPERIMENT_PATH}/" 

mkdir "${EXPERIMENT_PATH}/monitor"
mkdir "${EXPERIMENT_PATH}/monitor/init"
mkdir "${EXPERIMENT_PATH}/monitor/default"
mkdir "${EXPERIMENT_PATH}/monitor/bypass"

python3 "${profiler_path}" -o "${EXPERIMENT_PATH}/monitor/init" -dmc -i 1.5 "now run --dir ${EXPERIMENT_PATH}/monitor ${PROGRAM_DIR}/ingest_netflix"
clear_cache

python3 "${profiler_path}" -o "${EXPERIMENT_PATH}/monitor/default" -dmc -i 1.5 "now run --dir ${EXPERIMENT_PATH}/monitor ${PROGRAM_DIR}/ingest_netflix"
clear_cache

python3 "${profiler_path}" -o "${EXPERIMENT_PATH}/monitor/bypass" -dmc -i 1.5 "now run -b --dir ${EXPERIMENT_PATH}/monitor ${PROGRAM_DIR}/ingest_netflix"
clear_cache

#Standard D4ds v4 (4 vcpus, 16 GiB memory)

for dep in "${depth[@]}"; do

    dep_dir="${EXPERIMENT_PATH}/monitor/depth_${dep}"
    mkdir "${dep_dir}"

    python3 "${profiler_path}" -o "${dep_dir}" -dmc -i 1.5 "now run -d ${dep} --dir ${EXPERIMENT_PATH}/monitor ${PROGRAM_DIR}/ingest_netflix"
    clear_cache

done

for freq in "${savfreq[@]}"; do

    freq_dir="${EXPERIMENT_PATH}/monitor/save_freq_${freq}"
    mkdir "${freq_dir}"

    python3 "${profiler_path}" -o "${freq_dir}" -dmc -i 1.5 "now run -s ${freq} --dir ${EXPERIMENT_PATH}/monitor ${PROGRAM_DIR}/ingest_netflix"
    clear_cache

done

:'
for execution in $(seq "${execn}"); do

    mkdir "${EXPERIMENT_PATH}/exec_${execution}"

    /usr/bin/time -f "%e" -o "${EXPERIMENT_PATH}/exec_${execution}/time_init.txt" now run --dir "${EXPERIMENT_PATH}/exec_${execution}" ${PROGRAM_DIR}/ingest_netflix
    clear_cache

    /usr/bin/time -f "%e" -o "${EXPERIMENT_PATH}/exec_${execution}/time_wo.txt" now run --dir "${EXPERIMENT_PATH}/exec_${execution}" ${PROGRAM_DIR}/ingest_netflix
    clear_cache

    /usr/bin/time -f "%e" -o "${EXPERIMENT_PATH}/exec_${execution}/time_bypass.txt" now run -b --dir "${EXPERIMENT_PATH}/exec_${execution}" ${PROGRAM_DIR}/ingest_netflix
    clear_cache

    for dep in "${depth[@]}"; do

        dep_dir="${EXPERIMENT_PATH}/exec_${execution}/depth_${dep}"
        mkdir "${dep_dir}"

        /usr/bin/time -f "%e" -o "${dep_dir}/time.txt" now run -d ${dep} --dir "${EXPERIMENT_PATH}/exec_${execution}" ${PROGRAM_DIR}/ingest_netflix
        clear_cache

    done

    for freq in "${savfreq[@]}"; do

        freq_dir="${EXPERIMENT_PATH}/exec_${execution}/save_freq_${freq}"
        mkdir "${freq_dir}"

        /usr/bin/time -f "%e" -o "${freq_dir}/time.txt" now run -s ${freq} --dir "${EXPERIMENT_PATH}/exec_${execution}" ${PROGRAM_DIR}/ingest_netflix
        clear_cache

    done

done
'
