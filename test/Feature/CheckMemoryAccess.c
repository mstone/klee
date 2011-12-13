// RUN: %llvmgcc -g -c %s -o %t.bc
// RUN: %klee %t.bc > %t.k
// RUN: grep -q "good" %t.k
// RUN: not grep -q "bad" %t.k

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

int main() {
  char buf[4];

  klee_check_memory_access(&buf, 1);
  printf("good\n");
  if (klee_range(0, 2, "range1")) {
    klee_check_memory_access(0, 1);
    printf("null pointer deref: bad\n");
  }

  if (klee_range(0, 2, "range2")) {
    klee_check_memory_access(buf, 5);
    printf("oversize access: bad\n");
  }

  return 0;
}
