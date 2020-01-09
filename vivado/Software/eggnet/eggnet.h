#ifndef EGGNET_H
#define EGGNET_H

#ifdef __cplusplus
#define extern "C" {
#endif

#include <stdlib.h>
#include <stdint.h>

#include "dma-proxy.h"

typedef uint8_t byte_t;


int init_kernel();

int write_to_fpga(byte_t *dst, byte_t *buffer, size_t n);



int write_image(uint8_t *image_buffer, int batch, int height, int width, int channels);
int read_results(uint8_t *results, int buffer_size);



#ifdef __cplusplus
}
#endif

#endif // EGGNET_H