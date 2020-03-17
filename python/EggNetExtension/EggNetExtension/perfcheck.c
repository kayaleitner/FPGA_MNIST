//
// Created by Benjamin Kulnik on 16.03.20.
//

#include <stdlib.h>

#include "dbg.h"
#include "chelper.h"
#include "NNExtension.h"






typedef struct {
    uint8_t *__buffer;
    int ndims;
    int *dims;
} tensor_t;

int add_int(int a, int b) { return a+b; }
float add_float(float a, float b) { return a+b; }


#define add_gen(a,b) _Generic((a,b), float: add_float, default: add_int)

static
void fill_random(int *buffer, size_t N, int range, int offset) {
    for (int i = 0; i < N; ++i) {
        buffer[i] = (arc4random() % range) + offset;
    }
}

int
main(int argc, const char *argv[]) {

    add_gen(1,2);
    add_gen(0.1,0.2);

    __m128 a = {0};
    __m128 b = {0};

    a[0] = 0;
    a[1] = 1;
    a[2] = 2;
    a[3] = 3;

    b[0] = 0;
    b[1] = 1;
    b[2] = 2;
    b[3] = 3;

    
    __m128 c = _mm_add_ps(a,b);

    const int stride = 1;

    int return_value = 0;
    int32_t *image = NULL;
    int32_t *kernel = NULL;
    const size_t IMAGE_HEIGHT = 28;
    const size_t IMAGE_WIDTH = 28;
    const size_t CN1 = 16, CN2 = 32;
    const size_t BATCH = 10;
    const size_t KERNEL_HEIGHT = 3, KERNEL_WIDTH = 3;

    int32_t *layer_1_out = NULL;
    int out_1_b = 0, out_1_h = 0, out_1_w = 0, out_1_c = 0;

    int32_t *layer_2_out = NULL;
    int out_2_b = 0, out_2_h = 0, out_2_w = 0, out_2_c = 0;

    CREATE_4D_ARRAY(int32_t, image, BATCH, IMAGE_HEIGHT, IMAGE_WIDTH, CN1);
    CREATE_4D_ARRAY(int32_t, kernel, KERNEL_HEIGHT, KERNEL_WIDTH, CN1, CN2);

    fill_random(image, BATCH*IMAGE_HEIGHT*IMAGE_WIDTH*CN1, 256, -128);
    fill_random(kernel, KERNEL_HEIGHT*KERNEL_WIDTH*CN1*CN2, 256, -128);


    conv2d_int32_t(image, BATCH, IMAGE_HEIGHT, IMAGE_WIDTH, CN1,
                    kernel, KERNEL_HEIGHT, KERNEL_WIDTH, CN1, CN2, stride,
                    &layer_1_out, &out_1_b, &out_1_h, &out_1_w, &out_1_c);
    max_pool_2x2(layer_1_out, out_1_b, out_1_h, out_1_w, out_1_c, &layer_2_out, &out_2_b, &out_2_h, &out_2_w, &out_2_c);


error:
    return return_value;


}