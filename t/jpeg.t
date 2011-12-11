#!/bin/bash
./build/bin/klee --only-output-states-covering-new t/jpeg.bc
