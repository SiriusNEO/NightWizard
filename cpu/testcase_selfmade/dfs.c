#include "io.h"

void dfs(int l, int r) {
    if (l >= r) {
        outlln(l);
        return;
    }
    int mid = (l + r) / 2;
    outl(mid);
    dfs(l, mid);
    dfs(mid+1, r);
}

int main() {
    dfs(1, 3);
    return 0;
}

