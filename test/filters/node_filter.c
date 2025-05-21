#include <stdio.h>

#define LINK_BASE_MASK	0b111111111111111100000000000000000
#define FEATURE_MASK	0b000000000000000011111111111111100
#define LEAF_MASK	0b000000000000000000000000000000010
#define VALUE_MASK	0b111111111111111111111111111110000
#define CMD_MASK	0b000000000000000000000000000001110
#define DEBUG_MASK	0b000000000000000000000000000000001
		        //010000000010000000000000000001010000

int main(int argc, char **argv) {
    char buf [1025];

    unsigned int link_base, feature, leaf, value, cmd, debug;
     
    while (!feof(stdin)) {
        buf[0] = 0;
        fscanf(stdin, "%s", buf);
        if (buf[0]) {
            unsigned int hx;
            sscanf(buf, "%x", &hx);
	    debug = (hx & DEBUG_MASK);
	    if(debug == 1){
		link_base = (hx & LINK_BASE_MASK) >> 18;
		feature = (hx & FEATURE_MASK) >> 2;
		leaf = (hx & LEAF_MASK) >> 1;
		printf("l:%d, f:%d, leaf:%d\n", link_base, feature, leaf);
	    }else{
		value = (hx & VALUE_MASK)>>4;
		value = value << 3;
		cmd = (hx & CMD_MASK) >> 1;
		printf("v:%x, c:%d\n", value, cmd);
	    }
            fflush(stdout);
        }
    }
    return 0;
}
