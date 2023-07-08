from Bio import Align
import time
import sys

def read_fast_sequence(filename):

    sequence = ''
    with open(filename, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if line[0] == '>':
                continue
            sequence += line.strip('\n')
    return sequence

def write_alignment(alignment):

    with open('alignment.txt', 'w') as file:
        file.write(alignment)

target = read_fast_sequence(sys.argv[1])
query = read_fast_sequence(sys.argv[2])

aligner = Align.PairwiseAligner()
aligner.mode = 'local'

alignments = aligner.align(target, query)

write_alignment(str(alignments[0]))