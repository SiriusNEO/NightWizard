#include "io.h"

int main() {
    int a = 233, b = 666;
    outlln(a + b);
    outlln(a - b);
    outlln(a * b);
    outlln(b / a);
    outlln(b % a);
    outlln(b & a);
    outlln(b | a);
    outlln(2 << 31);
}