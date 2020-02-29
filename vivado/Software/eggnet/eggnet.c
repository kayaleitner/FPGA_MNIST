#include "eggnet.h"
#include <stdlib.h>
#include <pthread.h>


#define DRIVER_KEXT_NAME "dma-proxy.ko"

int init_kernel() {
    // insmod /lib/modules/4.9.0-xilinx-v2017.4/extra/dma-proxy.ko
    return system("insmod /lib/modules/4.9.0-xilinx-v2017.4/extra/dma-proxy.ko");
}

int write_to_fpga(byte_t *dst, byte_t *buffer, size_t n) {
    return -1;
}



