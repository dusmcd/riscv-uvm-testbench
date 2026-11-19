#! /usr/bin/bash

if [ -z "$1"]; then
  echo "Please specify your test name as the first argument"
else
  vsim -c -sv_seed random work.simtop +UVM_TESTNAME=$1 -do "run -all; quit -f"
fi
