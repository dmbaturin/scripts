#!/usr/bin/env python3
#
# Retrieves (or at least attempts to retrieve) the total number of real CPU cores
# installed in a Linux system.
#
# The issue of core count is complicated by existence of SMT, e.g. Intel's Hyper Threading.
# GNU nproc returns the number of LOGICAL cores,
# which is 2x of the real cores if SMT is enabled.
#
# The idea is to find all physical CPUs and add up their core counts.
# It has special cases for x86_64 and MAY work correctly on other architectures,
# but nothing is certain.
#
# Copyright (c) 2022 Daniil Baturin <daniil at baturin dot org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


import re


def read_cpuinfo():
    with open('/proc/cpuinfo', 'r') as f:
        return f.readlines()

def split_line(l):
    l = l.strip()
    parts = re.split(r'\s*:\s*', l)
    return (parts[0], ":".join(parts[1:]))

def find_cpus(cpuinfo_lines):
    cpus = {}

    cpu_number = 0

    for l in cpuinfo_lines:
        key, value = split_line(l)
        if key == 'processor':
            cpu_number = value
            cpus[cpu_number] = {}
        else:
            cpus[cpu_number][key] = value

    return cpus

def find_physical_cpus(cpus):
    phys_cpus = {}

    for num in cpus:
        if 'physical id' in cpus[num]:
            # On at least some architectures, CPUs in different sockets
            # have different 'physical id' field, e.g. on x86_64.
            phys_id = cpus[num]['physical id']
            if phys_id not in phys_cpus:
                phys_cpus[phys_id] = cpus[num]
        else:
            # On other architectures, e.g. on ARM, there's no such field.
            # We just assume they are different CPUs,
            # whether single core ones or cores of physical CPUs.
            phys_cpus[num] = cpu[num]

    return phys_cpus


if __name__ == '__main__':
    physical_cpus = find_physical_cpus(find_cpus(read_cpuinfo()))

    core_count = 0

    for num in physical_cpus:
        # Some architectures, e.g. x86_64, include a field for core count.
        # Since we found unique physical CPU entries, we can sum their core counts.
        if 'cpu cores' in physical_cpus[num]:
            core_count += int(physical_cpus[num]['cpu cores'])
        else:
            core_count += 1

    print(core_count)
