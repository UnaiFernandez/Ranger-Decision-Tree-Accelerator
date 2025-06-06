#include <stdio.h>

#define RADDR_MASK	0b11111111111111110000000000000000
#define FEATURE_MASK	0b00000000000000001111111111111110
#define LEAF_MASK	0b00000000000000000000000000000001

int main(int argc, char **argv) {
    char buf [1025];

    int r_addr, feature, l;
     
    while (!feof(stdin)) {
        buf[0] = 0;
        fscanf(stdin, "%s", buf);
        if (buf[0]) {
            int hx;
            sscanf(buf, "%x", &hx);
            r_addr = (hx & RADDR_MASK) >> 16;
            feature = (hx & FEATURE_MASK) >> 15;
            l = (hx & LEAF_MASK);
            printf("r:%d, f:%d, leaf:%d\n", r_addr, feature, l);
            fflush(stdout);
        }
    }
    return 0;
}
