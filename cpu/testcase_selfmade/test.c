#include "io.h"
int a[4][11];
int i;
int j;

void printNum(int num) {
    outlln(num);
}
int main() {
    for (i = 0; i < 4; i ++) {
        for (j = 0; j < 10; j ++)
            a[i][j] = 888;
    }

    printNum(a[3][9]);
}