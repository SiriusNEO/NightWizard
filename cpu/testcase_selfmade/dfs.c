#include "io.h"

int cnt = 0;

int a[10100];

void dfs(int l, int r) {
    if (l >= r) {
        outlln(l);
        return;
    }
    int mid = (l + r) / 2;
    print("l: ");
    outl(l);
    print(" r: ");
    outl(r);
    print(" mid: ");
    outl(mid);
    print(" ");
    dfs(l, mid);
    dfs(mid+1, r);
}

int main() {
    dfs(1, 2);
    return 0;
}

