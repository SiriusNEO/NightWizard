#include "io.h"

int a[4];
int main()
{
	int i;
    for (i = 0; i < 4; i++)
	{
		a[i] = 0;
	}
    for (i = 0; i < 4; i++) {
		outl(a[i]);
    }
}
