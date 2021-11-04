#include "io.h"

int a[10];

int main() {
    a[0] = 1;
    a[1] = 1;
    for (int i = 2; i < 10; ++i)
        a[i] = a[i-1] + a[i-2];
    outlln(a[9]);
}