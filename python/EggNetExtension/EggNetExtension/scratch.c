#include <stdio.h>
#include "NNExtension.h"
#include <stdlib.h>

int interp_cgoto(unsigned char* code, int initval) {
    /* The indices of labels in the dispatch_table are the relevant opcodes
    */
    static void* dispatch_table[] = {
            &&do_halt, &&do_inc, &&do_dec, &&do_mul2,
            &&do_div2, &&do_add7, &&do_neg};
#define DISPATCH() goto *dispatch_table[code[pc++]]

    int pc = 0;
    int val = initval;

    

    DISPATCH();
    while (1) {
        do_halt:
        return val;
        do_inc:
        val++;
        DISPATCH();
        do_dec:
        val--;
        DISPATCH();
        do_mul2:
        val *= 2;
        DISPATCH();
        do_div2:
        val /= 2;
        DISPATCH();
        do_add7:
        val += 7;
        DISPATCH();
        do_neg:
        val = -val;
        DISPATCH();
    }
}

#define RAND_X(r)                                                                                  \
    ({                                                                                             \
        int y = rand() % 10;                                                                       \
        int z;                                                                                     \
        if (y > r)                                                                                 \
            z = y;                                                                                 \
        else                                                                                       \
            z = -y;                                                                                \
        z;                                                                                         \
    })

int main()
{
    int t = RAND_X(4);
    printf("t = %d", t);


    // int r = conv2d_int32_t(NULL, 0, 0, 0, 0, NULL, 0, 0, 0, 0, 1, NULL, NULL, NULL, NULL, NULL);
    return 0;
}