#include "io.h"

int add(int a, int b) {
    return a + b;
}

int sub(int a, int b) {
    return a - b;
}

int main() {
    outlln(add(2, 3));
    outlln(sub(1, 4));
}