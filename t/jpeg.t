#!/bin/bash
./build/bin/klee --klee-lib-dir=$(pwd)/build/lib --only-output-states-covering-new t/jpeg.bc
