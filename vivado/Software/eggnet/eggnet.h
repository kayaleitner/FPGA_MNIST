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

typedef uint8_t byte_t;
#define DATA_WIDTH 8
#define OUTPUT_NUMBER 10


/**
 * Initializes the network. Searches for the corresponding UIO device, loads and initializes the dma proxy driver
 * @return Error code
 */
egg_error_t egg_init_network(const char *ip_name, network_t *net);

/**
 * Close network and free memory mapped address space
 * @return Error code
 */
egg_error_t egg_close_network();

/**
 * 
 * @param image_buffer 
 * @param batch 
 * @param height 
 * @param width 
 * @param channels 
 * @param results 
 * @return error code
 */

/**
 * @brief Executes the EggNet in forward (inference) mode
 * 
 * @param image_buffer A pointer to memory image buffer
 * @param batch number of batches
 * @param height image height, 28 for MNIST
 * @param width image width, 28 for MNIST
 * @param channels image channels, which is 1 for grayscale (like MNIST) or 3 for RGB
 * @param [out]results a pointer to buffer-ptr where to store the results, must be [batch x 10]
 * @param [out] batch_out pointer to output value
 * @param [out]n 
 * @return egg_error_t 
 */
egg_error_t egg_forward(const uint8_t *image_buffer, int batch, int height, int width, int channels, 
                        int **results, int *batch_out, int *n);


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
 * Reads network structure from hardware
 * @param net_ptr Pointer to Network structure. Used as call by reference return value.
 */
egg_error_t get_network_structure(network_t *net_ptr);

/**
 * Print Network structure
 * @return Error code
 */
egg_error_t print_network();

/**
 * Reaads overall status from hardware
 */

/**********************************************************************************************************************
 *
 *  Debugging Functions
 *
 *********************************************************************************************************************/

/**
 * Activate debug mode. Computation of each layer a completed before debug mode in entered
 * @return Error code
 */
egg_error_t activate_debug_mode();

/**
 * reads a single pixel from the network
 * @param ointer to pixel
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param col selected collum of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_pixel(const pixel_t *pixel, uint8_t layer, uint16_t row, uint16_t col, uint8_t channel);

/**
 * reads a single row from the network
 * @param ointer to pixel array
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_row(const pixel_t **pixel, uint8_t layer, uint16_t row, uint8_t channel);

/**
 * reads content of a single channel of specific layer
 * @param pointer to pixel array [with*height] --> reshape to matrix [W,H] necessary. Shape: One row after the other
 * @param layer Selected Layer
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_channel(const pixel_t **pixel, uint8_t layer, uint8_t channel);

/**
 * reads content of a layer
 * @param point to pointer to pixel array [with*height] --> reshape to matrix [W,H] necessary. Shape: One row after the other
 * @param layer Selected Layer
 * @return Error code
 */
egg_error_t read_layer(const pixel_t ***pixel, uint8_t layer);


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
