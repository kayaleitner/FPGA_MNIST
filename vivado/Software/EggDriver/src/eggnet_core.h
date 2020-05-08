/*
 * eggnet_core.h
 *
 *  Created on: 18 Feb 2020
 *      Author: lukas
 */

#ifndef SRC_EGGNET_CORE_H_
#define SRC_EGGNET_CORE_H_


#ifdef __cplusplus
#define extern                                                                                     \
    "C"                                                                                            \
    {
#endif

#include <stdlib.h>
#include <stdint.h>
#include "libuio_internal.h"
#include "libuio.h"

#define		EGG_RD_STATUS_OFS				0x00000000		// EggNet Status register address offset
#define		EGG_RD_MEM_CTRL_ADDR_MASK		0x0000FF00		// EggNet Memory controller address mask
#define		EGG_RD_MEM_CTRL_ADDR_SHIFT		8				// EggNet Memory controller address shift number
#define		EGG_RD_TYPE_MASK				0x000000E0		// EggNet Layer Type Mask (7 downto 0)
#define		EGG_RD_TYPE_SHIFT				5
#define		EGG_RD_DBG_ERROR_MASK			0x00010000		// EggNet Debug error flag mask
#define		EGG_RD_DBG_ERROR_SHIFT			16
#define		EGG_RD_DBG_ACTIVE_MASK			0x00020000		// EggNet Debug error flag mask
#define		EGG_RD_DBG_ACTIVE_SHIFT			17
#define 	EGG_RD_LAYER_PROP_OFS			0x0000000C/4	// EggNet Layer properties offset: (11 downto 0) => LAYER_WIDTH | (23 downto 12) => LAYER_HIGHT | (31 downto 24) => IN_CHANNEL_NUMBER
#define 	EGG_RD_LAYER_WIDTH_MASK			0x00000FFF		// EggNet Layer width mask
#define 	EGG_RD_LAYER_WIDTH_SHIFT		0				// EggNet Layer width shift number
#define 	EGG_RD_LAYER_HIGTH_MASK			0x00FFF000		// EggNet Layer width mask
#define 	EGG_RD_LAYER_HIGTH_SHIFT		12				// EggNet Layer width shift number
#define 	EGG_RD_LAYER_CH_NR_MASK			0xFF000000		// EggNet Layer input channel number mask
#define 	EGG_RD_LAYER_CH_NR_SHIFT		24				// EggNet Layer input channel number shift number
#define		EGG_RD_LAYER_NR_MASK			0x000000FF		// EggNet Layer number mask
#define		EGG_RD_BRAM_ADDR_OFS			0x00000004/4	// EggNet BRAM ADDR of the actual data value. Used for synchronization.
#define		EGG_RD_BRAM_DATA_OFS			0x00000008/4	// EggNet BRAM Data read offset


#define		EGG_WR_MEM_CTRL_ADDR_OFS		0x00000000		// EggNet Memory controller address offset
#define		EGG_WR_DBG_ENABLE_OFS			0x00000008		// EggNet Debug enable offset
#define		EGG_WR_BRAM_ADDR_OFS			0x00000004/4	// EggNet Memory controller address offset
#define		EGG_WR_32BIT_SEL_OFS			0x000000012/4	// EggNet
// Offsets divided by 4 because the values are added to a pointer

#define		TIMEOUT							1000			// Timeout till the communication is terminated

#define		MAX_LAYER_NUMBER				15
#define		MAX_ELEMENT_SIZE				8
#define 	DATA_WIDTH 8
#define 	OUTPUT_NUMBER 10
#define		IRQ	91

typedef uint8_t pixel_t;

typedef enum egg_error_e {
    EGG_ERROR_NONE = 0,   /// No Error
    EGG_ERROR_NULL_PTR,   /// NULL Pointer Error
    EGG_ERROR_DEVICE_COMMUNICATION_FAILED,
    EGG_ERROR_INIT_FAILDED,
    EGG_ERROR_UDEF,
    EGG_ERROR_MALLOC_FAIL
} egg_error_t;

typedef struct uio_singleton_s {
    int                number;
    struct uio_info_t* info;
    volatile uint32_t* ptr_to_mmap_addr;
} uio_singleton_t;

typedef enum layer_types {   // Only Dense and Conv3x3 are already implemented yet
    Dense = 0,
    Conv1x1,
    Conv3x3,
    Conv5x5,
    Average_pooling
} layer_type_t;   // can be extended up to 8 different layer types (Depends of status register of MemCtrl)

typedef struct layer_s {
    layer_type_t layer_type;
    uint16_t     height;   // 1 for dense layer
    uint16_t     width;
    uint8_t      in_channel_number;   // 1 for dense layer
} layer_t;

typedef struct network_s {
    uint8_t           		layer_number;
    layer_t**  				layers;
    pixel_t**         		results;
    uint32_t		 		result_number;
    const pixel_t* __restrict	img_ptr;
    uint8_t           		debug_active;
    uint8_t           		selected_layer;   // 0 = No channel selected -> overall status

} network_t;


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

/* The following function is the receive thread to allow to receive.
 * The ioctl calls are blocking such that a thread is needed.
 */
egg_error_t egg_rx_img(network_t* network);


/* The following function is the transmit thread to allow to receive.
 * The function is called when the interrupt of the uio device occurs.
 * The ioctl calls are blocking such that a thread is needed.
 */
egg_error_t egg_tx_img(network_t* network);

/**********************************************************************************************************************
 *
 *  Status Functions
 *
 *********************************************************************************************************************/

/**
 * Reads network structure from hardware
 * @param net_ptr Pointer to Network structure. Used as call by reference return value.
 */
egg_error_t get_network_structure(network_t *net_ptr);

/**
 * Free network
 * @param net Pointer to global network structure
 * @return Error code
 */
egg_error_t egg_free_network(network_t* network);


/**
 * Reads layer structure info from memory controller
 * @param nb Layer number
 * @param layer_type Type of the Layer (eg. Dense, Conv_3x3, ...)
 * @param width Width of the Layer Matrix
 * @param height Heigth of the Layer Matrix
 * @param channel_number Number of input channels of the Layer
 * @return Error code
 */
egg_error_t egg_get_layer_info(uint8_t nb, layer_type_t* type, uint16_t* width, uint16_t* height, uint8_t* channel_number, network_t* network);

/**
 * Get Type as string
 * @param type Enumerator of Layer type
 * @return Error code
 */
const char *get_type_string(layer_type_t type);


/**********************************************************************************************************************
 *
 *  UIO Functions --> egguio.c
 *
 *********************************************************************************************************************/

/**
 * Searches for Network IP name in available UIO devices and initializes the UIO device
 * @param ip_name Name of the EggNet IP in Vivado --> see device tree --> use lsuio to get available uio device names
 * @return Error code
 */
egg_error_t egg_init_uio(const char* ip_name);


/**
 * Closes uio device driver
 * @return Error code
 */
egg_error_t egg_close_uio();

/***************************
 * Interrupt functions
 ***************************/

/**
 * Enables interrupt
 * @return Error code
 */
egg_error_t initialize_interrupt();

/**
 * Waits for interrupt
 * @param intr_count Call by reference interrupt number
 * @return Error code
 */
egg_error_t wait_for_interrupt(uint32_t* intr_count);

/***************************
 * Get status uio functions
 ***************************/

/**
 * Reads layer number from hardware
 * @param layer_number Layer number
 * @return Error code
 */
egg_error_t egg_get_layer_number(uint8_t* layer_number, network_t* network);

/**
 * Writes memmory controller address to AXI lite bus register
 * @param addr Address of the memory controller ie. Layer number
 * @return Error code
 */
egg_error_t egg_update_memctrl_addr(network_t* network, uint8_t addr);


/**
 * Reads with of the Layer
 * @param width Width of the Layer Matrix
 * @return Error code
 */
egg_error_t egg_read_width(uint16_t* width);

/**
 * Reads height of the Layer
 * @param height Height of the Layer Matrix
 * @return Error code
 */
egg_error_t egg_read_height(uint16_t* height);

/**
 * Reads Channel number of the Layer
 * @param channel_nb Channel number of the Layer Matrix
 * @return Error code
 */
egg_error_t egg_read_channel_nb(uint8_t* channel_nb);

/**
 * Reads Type of the Layer
 * @param type Typer of the Layer Matrix
 * @return Error code
 */
egg_error_t egg_read_type(layer_type_t* type);


/***************************
 * Debugging functions
 ***************************/
/**
 * Activate debug mode. Computation of each layer a completed before debug mode in entered
 * @return Error code
 */
egg_error_t activate_debug_mode(network_t* network, uint8_t layer);

/**
 * Writes bram address to AXI lite bus register
 * @param addr BRAM address
 * @return Error code
 */
egg_error_t egg_update_bram_addr(uint32_t addr);

/**
 * Updates 32bit_select register
 * @param addr BRAM address
 * @return Error code
 */
egg_error_t egg_update_channel_select(uint8_t channel);

/**
 * Reads single element from BRAM
 * @return Error code
 */
egg_error_t egg_read_bram_element(uint32_t* element, uint8_t channel);

/**
 * Checks status register if debug error flag = 1
 * @return Error code
 */
egg_error_t egg_check_dbg_status();


/**
 * Reads from 4 channels with 1 BRAM access
 * @return Error code
 */
egg_error_t egg_read_32bit_vec(pixel_t** pix_la, network_t* network, uint8_t layer, uint8_t select_32bit);

#ifdef __cplusplus
}
#endif

#endif /* SRC_EGGNET_CORE_H_ */
