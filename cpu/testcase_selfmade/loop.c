#include "io.h"

int main() {
    int sum = 0;
    for (int i = 1; i <= 10; i++) 
    for (int j = 1; j <= 10; j++)
    for (int k = 1; k <= 10; k++)
    for (int l = 1; l <= 10; l++)
    {
        if (i == j) sum = sum + 1;
    }
    outlln(sum);
}