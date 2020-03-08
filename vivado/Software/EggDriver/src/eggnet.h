/*
 * EggNet TOP library --> Functions mapped to Python
 *
 * Copyright (C) 2020 Lukas Baischer
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA
 */

#ifndef EGGNET_H
#define EGGNET_H

#ifdef __cplusplus
#define extern "C" {
#endif

#include <stdlib.h>
#include <stdint.h>
#include "eggnet_core.h"


#ifndef __restrict
#define __restrict restrict
#endif

typedef uint8_t byte_t;


/**
 * Initializes the network. Searches for the corresponding UIO device, loads and initializes the dma proxy driver
 * @return Error code
 */
egg_error_t egg_init_network(const char *ip_name, network_t* network);

/**
 * Closes network and frees memory mapped address space
 * @param network Pointer to network sturcture
 * @return Error code
 */
egg_error_t egg_close_network(network_t* network);

/* The following function is the transmit thread to allow to receive.
 * Calls egg_tx_img() --> In separate file to encapsulate global dma interface variable
 * The ioctl calls are blocking such that a thread is needed.
 * @param image Pointer to image array
 * @param network Pointer to network structure
 * @return Pointer to error code
 */
void *egg_tx_img_thread(void* network);

/* The following function is the transmit thread to allow to receive.
 * Calls egg_rx_img() --> In separate file to encapsulate global dma interface variable
 * The function is called when the interrupt of the uio device occurs.
 * The ioctl calls are blocking such that a thread is needed.
 */
void *egg_rx_img_thread(void* network);


/**
 * Gets results
 * @param results Pointer to result matrix
 * @param network Pointer to network structure
 * @return Error code
 */
egg_error_t get_results(pixel_t*** results, uint32_t* result_number, network_t* network);

/**
 * Runs an inference on the FPGA
 *
 *
 *
 * @param image_data
 * @param batch_size
 * @param height
 * @param width
 * @param channels
 * @param results
 * @return
 */
egg_error_t egg_inference(const uint8_t *__restrict image_buffer,
                          int batch, int height, int width, int channels,
                          uint8_t results[batch]);


/**********************************************************************************************************************
 *
 *  Status Functions
 *
 *********************************************************************************************************************/
/**
 * Returns an string description of the error
 */
const char *egg_print_err(egg_error_t code);

/**
 * Print Network structure
 * @return Error code
 */
egg_error_t print_network(network_t* network);

/**
 * Reaads overall status from hardware
 */

/**********************************************************************************************************************
 *
 *  Debugging Functions
 *
 *********************************************************************************************************************/

/**
 * reads a single pixel from the network
 * @param ointer to pixel
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param col selected collum of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_pixel(pixel_t *pixel, network_t* network, uint8_t layer, uint16_t row, uint16_t col, uint8_t channel);

/**
 * reads a single row from the network
 * @param ointer to pixel array
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_row(pixel_t **pixel, network_t* network, uint8_t layer, uint16_t row, uint8_t channel);

/**
 * reads content of a single channel of specific layer
 * @param pointer to pixel array [with*height] --> reshape to matrix [W,H] necessary. Shape: One row after the other
 * @param layer Selected Layer
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_channel(pixel_t **pixel, network_t* network, uint8_t layer, uint8_t channel);

/**
 * reads content of a layer
 * @param point to pointer to pixel array [with*height] --> reshape to matrix [W,H] necessary. Shape: One row after the other
 * @param layer Selected Layer
 * @return Error code
 */
egg_error_t read_layer(pixel_t ***pixel, network_t* network, uint8_t layer);


//Not implemented in hardware yet --> Not really useful
//egg_error_t egg_debug_memwrite(const void *src_start_address, size_t byte_len, void *dst);

/* Add later if there is time
egg_error_t egg_debug_conv();
egg_error_t egg_debug_mul();
egg_error_t egg_debug_conv();
egg_error_t egg_conv();
*/

#ifdef __cplusplus
}
#endif

#endif // EGGNET_H
