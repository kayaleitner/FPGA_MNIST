#ifndef _DEFINITIONS_H
#define _DEFINITIONS_H

/*
 * Global Includes
 */

#include "net_def.h"
#include <stdint.h>

/*
 * Global Definitions
 */

#define INPUT_SIZE_X    28
#define INPUT_SIZE_Y    28

/*
 * Convolutional Neural Networks Definitions
 */

enum CNN_LAYER_TYPE {
    UNDEFINED,
    CONVOLUTIONAL,
    POOLING,
    RELU
};

#define CNN_KERNEL_SIZE 9

struct CNN_LAYER {
    uint8_t type;
    uint8_t num_kernels;
};

static const struct CNN_LAYER CNN_LAYERS[] = {
    {UNDEFINED, 0}
};

/*
 * Fully Connected NN Definitions
 */

#define INPUT_SIZE      (INPUT_SIZE_X * INPUT_SIZE_Y)
#define OUTPUT_SIZE     10

static const uint16_t NN_LAYER_NODE_SIZE[] = {
    INPUT_SIZE,
    200,
    100,
    50,
    OUTPUT_SIZE
};

#define NN_LAYERS (sizeof(NN_LAYER_NODE_SIZE) / sizeof(uint16_t))
#define SIZE_LAYER(i) (NN_LAYER_NODE_SIZE[i-1] * NN_LAYER_NODE_SIZE[i] + NN_LAYER_NODE_SIZE[i])

#endif
