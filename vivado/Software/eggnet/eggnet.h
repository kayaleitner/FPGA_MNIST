#ifndef EGGNET_H
#define EGGNET_H

#ifdef __cplusplus
#define extern "C" {
#endif

#include <stdlib.h>
#include <stdint.h>

typedef uint8_t byte_t;


typedef enum egg_error_e {
    EGG_ERROR_NONE = 0, /// No Error
    EGG_ERROR_NULL_PTR, /// NULL Pointer Error
    EGG_ERROR_DEVICE_COMMUNICATION_FAILED,
	EGG_ERROR_INIT_FAILDED,
	EGG_ERROR_UDEF
} egg_error_t;

#define EGG_MEM_LAYER1_BRAM_ADDR 0x0
#define EGG_MEM_LAYER2_BRAM_ADDR 0x0
#define EGG_MEM_LAYER3_BRAM_ADDR 0x0
#define EGG_MEM_LAYER4_BRAM_ADDR 0x0

#define EGG_MEM_LAYER1_BRAM_END_ADDR 0x0
#define EGG_MEM_LAYER2_BRAM_END_ADDR 0x0
#define EGG_MEM_LAYER3_BRAM_END_ADDR 0x0
#define EGG_MEM_LAYER4_BRAM_END_ADDR 0x0

#define EGG_MEM_LAYER1_BRAM_SIZE 0ul
#define EGG_MEM_LAYER2_BRAM_SIZE 0ul
#define EGG_MEM_LAYER3_BRAM_SIZE 0ul
#define EGG_MEM_LAYER4_BRAM_SIZE 0ul


/**********************************************************************************************************************
 *
 *  DMA Functions
 *
 *********************************************************************************************************************/

/**
 * Initialises the kernel module for dma-proxy extension
 * @return Error code
 */
egg_error_t egg_init_dma();

/**
 * Closes dma-proxy dev driver
 * @return Error code
 */
egg_error_t egg_close_dma();

/**
 * Executes the EggNet in forward (inference) mode
 * @param image_buffer A pointer to memory image buffer
 * @param batch number of batches
 * @param height image height, 28 for MNIST
 * @param width image width, 28 for MNIST
 * @param channels image channels, which is 1 for grayscale (like MNIST) or 3 for RGB
 * @param results a buffer where to store the results, must be [batch x 10]
 * @return error code
 */
egg_error_t egg_forward(const uint8_t *image_buffer, int batch, int height, int width, int channels, int *results);

egg_error_t egg_send_single_image_sync(uint8_t *image_buffer);

egg_error_t egg_send_single_image_async(uint8_t *image_buffer, int batch_size, pthread_t tid);

void *egg_tx_thread(int batch, uint8_t *image_buffer);

void *egg_tx_callback(void *args);


/**********************************************************************************************************************
 *
 *  Debugging Functions
 *
 *********************************************************************************************************************/

/**
 * Returns an string description of the error
 */
const char *egg_print_err(egg_error_t code);

/**
 * Dumps the contents of the block rams to memory buffer for debugging
 * @param dst the bugger
 * @return an error code
 */
egg_error_t egg_debug_memdump(void *dst);

/**
 * Reads the contents of the memory and saves it to a buffer
 * @param src_start_address source start address
 * @param byte_len length that should by read in bytes
 * @param dst pointer to buffer
 * @return error code
 */
egg_error_t egg_debug_memread(const void *src_start_address, size_t byte_len, void *dst);

/**
 * Writes the contents of a buffer to the memory
 * @param src_start_address source start address
 * @param byte_len length that should by read in bytes
 * @param dst pointer to buffer
 * @return error code
 */
egg_error_t egg_debug_memwrite(const void *src_start_address, size_t byte_len, void *dst);


egg_error_t egg_debug_conv();
egg_error_t egg_debug_mul();
egg_error_t egg_debug_conv();
egg_error_t egg_conv();





#ifdef __cplusplus
}
#endif

#endif // EGGNET_H
