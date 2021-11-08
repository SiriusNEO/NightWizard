#include "io.h"

int a[400];
int main()
{
	int i;
    for (i = 0; i < 20; i++)
	{
		a[i] = 99;
	}
	int *p = a;
    for (i = 0; i < 20; i++) {
		outl(i);print(" ");outlln(*(p+i));
    }
}
