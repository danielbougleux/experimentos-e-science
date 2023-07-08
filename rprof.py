import psutil
import time
from datetime import datetime
import argparse
import sys

option_function = {
    'disk': 'io_counters()',
    'memory': 'memory_full_info()',
    'cpu': 'cpu_times()'
}

def config():
    """
    The desired options  
    -d for collect disk
    -m             memory
    -c             cpu
    -i for defining the monitoring interval  
    """
    parser = argparse.ArgumentParser(prog='rprof', description='resource usage profiler')

    parser.add_argument('-d', '--disk', action='store_true', help='Collect disk metrics')
    parser.add_argument('-m', '--memory', action='store_true', help='Collect memory metrics')
    parser.add_argument('-c', '--cpu', action='store_true', help='Collect cpu metrics')
    parser.add_argument('-g', '--get-children', action='store_true', help='Include the resource usage from child processes')
    parser.add_argument('-o', '--output_dir', default='.', help='The output dir for the metrics file')
    parser.add_argument('-i', '--interval', type=float, default=1.5, help='Interval in seconds between each metric collection')
    parser.add_argument('command', help='Execution command for the process to be monitored. Must be inside ""')

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    return parser.parse_args()

def write_data(value_list: list, filename: str, mode: str):

    line = ''
    for value in value_list:
        line += f'{value};'
    
    line = line.strip(';')
    line += '\n'

    with open(filename, mode) as file:
        file.write(line) 

def get_children_data(function, process):

    children = process.children(recursive=True)

    sum = eval(f'process.{function}._asdict()')

    for child in children:
        
        child_data = eval(f'child.{function}._asdict()')
        
        for key, value in sum.items():
            sum[key] = value + child_data[key]
    
    return sum

def collect_data(args, process, create=False):

    timestamp = datetime.now()

    for option in option_function.keys():
        if eval(f'args.{option}'):

            if args.get_children:
                data = get_children_data(option_function[option], process)
            else:
                data = eval(f'process.{option_function[option]}._asdict()')

            if create:
                write_data(['timestamp'] + list(data.keys()), f'{args.output_dir}/{option}.csv', 'w')
            else:
                write_data([timestamp] + list(data.values()), f'{args.output_dir}/{option}.csv', 'a')

if __name__ == '__main__':

    args = config()

    command = args.command.split(' ')

    process = psutil.Popen(command)

    collect_data(args, process, create=True)

    while process.poll() is None:

        collect_data(args, process)

        time.sleep(args.interval)