/*
 * EggNet debug library
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

#include "eggnet_core.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pthread.h>
#include "dbg.h"
#include <math.h>

uio_singleton_t uio = { .number = 0, .info = NULL, .ptr_to_mmap_addr = NULL };

egg_error_t egg_init_uio(const char *ip_name)
{
	CHECK(uio.number == 0,"UIO already initialized");
	uio.info = uio_find_by_uio_name(ip_name);

	uio.info->fd = open(uio_get_devname(uio.info), O_RDWR);
	CHECK(uio.info->fd >= 1,"Unable to open UIO device: %s\n",uio_get_devname(uio.info));
	uio.ptr_to_mmap_addr = (volatile uint32_t*) mmap(NULL, uio_get_mem_size(uio.info,0), PROT_READ|PROT_WRITE, MAP_SHARED, uio.info->fd, 0x0);
	CHECK(uio.ptr_to_mmap_addr != NULL,"Error in memory mapping of UIO device: %s\n",uio_get_devname(uio.info));

	uio.number = 1;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_INIT_FAILDED;
}

egg_error_t egg_close_uio()
{
	CHECK(uio.number >= 0,"UIO not initialized");
	CHECK(munmap((void*)uio.ptr_to_mmap_addr, uio_get_mem_size(uio.info,0))==0,"Error unmap uio device");
	close(uio.info->fd);
	uio.number = 0;
	free(uio.info);
	uio.ptr_to_mmap_addr = NULL;
	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;
}

/***************************
 * Interrupt functions
 ***************************/

/**
 * Waits for interrupt
 * @param intr_count Call by reference interrupt number
 * @return Error code
 */
egg_error_t wait_for_interrupt(uint32_t* intr_count)
{
	int err =0;
	int icount = 0;
	debug("Waiting for interrupt..");
	err = read(uio.info->fd, &icount, 4);
	debug("Interrupt detected");
	CHECK(err == 4,"Error detecting interrupt");
	debug("Number of interrupts is %d",icount);
	*intr_count = (uint32_t) icount;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}

/***************************
 * Get status uio functions
 ***************************/

egg_error_t egg_get_layer_number(uint8_t *layer_number,network_t* network)
{
	CHECK(egg_update_memctrl_addr(network,0)==EGG_ERROR_NONE,"Error writing 0 to memory controller address register");
	uint8_t value = *(uio.ptr_to_mmap_addr+EGG_RD_LAYER_PROP_OFS);
	*layer_number = (value & EGG_RD_LAYER_NR_MASK);
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}

/**
 * Writes memmory controller address to AXI lite bus register
 * @return Error code
 */
egg_error_t egg_update_memctrl_addr(network_t* network, uint8_t addr)
{
	// Check if layer is already active
	if (network->selected_layer == addr)
	{
		return EGG_ERROR_NONE;
	}

	// Check if input is valid and device is initialized
	CHECK(uio.number >= 0,"UIO not initialized");
	*(uio.ptr_to_mmap_addr+EGG_WR_MEM_CTRL_ADDR_OFS) = (uint32_t) addr;
	int timeout = 0;
	uint32_t value = 0;
	while(timeout < TIMEOUT)
	{
		timeout++;
		value = *(uio.ptr_to_mmap_addr);
		value = (value & EGG_RD_MEM_CTRL_ADDR_MASK) >> EGG_RD_MEM_CTRL_ADDR_SHIFT;
		if (value == addr)
		{
			network->selected_layer = addr;
			return EGG_ERROR_NONE;
		}
	}
	fprintf(stderr, "[ERROR] Timout occured in function egg_update_memctrl_addr()");
	return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}


/**
 * Reads with of the Layer
 * @param width Width of the Layer Matrix
 * @return Error code
 */
egg_error_t egg_read_width(uint16_t *width)
{
	uint32_t value = 0;
	value = *(uio.ptr_to_mmap_addr + EGG_RD_LAYER_PROP_OFS);
	value = (value & EGG_RD_LAYER_WIDTH_MASK) >> EGG_RD_MEM_CTRL_ADDR_SHIFT;
	CHECK(value != 0,"Received invalid width")
	*width = value;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
}

/**
 * Reads height of the Layer
 * @param height Height of the Layer Matrix
 * @return Error code
 */
egg_error_t egg_read_height(uint16_t *height)
{
	uint32_t value = 0;
	value = *(uio.ptr_to_mmap_addr + EGG_RD_LAYER_PROP_OFS);
	value = (value & EGG_RD_LAYER_HIGTH_MASK) >> EGG_RD_LAYER_HIGTH_SHIFT;
	CHECK(value != 0,"Received invalid height")
	*height = value;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
}

/**
 * Reads Channel number of the Layer
 * @param channel_nb Channel number of the Layer Matrix
 * @return Error code
 */
egg_error_t egg_read_channel_nb(uint8_t *channel_nb)
{
	uint32_t value = 0;
	value = *(uio.ptr_to_mmap_addr + EGG_RD_LAYER_PROP_OFS);
	value = (value & EGG_RD_LAYER_CH_NR_MASK) >> EGG_RD_LAYER_CH_NR_SHIFT;
	CHECK(value != 0,"Received invalid channel number")
	*channel_nb = value;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
}

egg_error_t egg_read_type(layer_type_t *type)
{
	uint32_t value = 0;
	value = *(uio.ptr_to_mmap_addr + EGG_RD_STATUS_OFS);
	value = (value & EGG_RD_TYPE_MASK) >> EGG_RD_TYPE_SHIFT;
	CHECK(value < 8,"Received invalid type")
	*type = value;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
}

/***************************
 * Debugging functions
 ***************************/

/**
 * Activate debug mode. Computation of each layer a completed before debug mode in entered
 * @return Error code
 */
egg_error_t activate_debug_mode(network_t* network, uint8_t layer)
{
	//check if Hardware is already initialized
	CHECK(network->layer_number > layer,"Layer %d exceeds available layer number %d",layer,network->layer_number);
	debug("Parameter are valid");

	//Update selected layer
	CHECK(egg_update_memctrl_addr(network,layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	*(uio.ptr_to_mmap_addr+EGG_WR_DBG_ENABLE_OFS) = 0x00000001;
	int timeout = 0;
	uint32_t value = 0;
	debug("Wait for hardware to enter debug mode");
	// 10 * Timeout since hardware finishes current computations before entering debug mode
	while(timeout < TIMEOUT*10)
	{
		timeout++;
		value = *(uio.ptr_to_mmap_addr+EGG_RD_STATUS_OFS);
		value = (value & EGG_RD_DBG_ACTIVE_MASK) >> EGG_RD_DBG_ACTIVE_SHIFT;
		if (value == 0x00000001)
		{
			debug("Debug mode active in layer %d",layer);
			return EGG_ERROR_NONE;
		}
		#ifndef NDEBUG
		if (timeout%100)
		{
			debug("Timeout counter : %d",timeout);
		}
		#endif
	}

	fprintf(stderr, "[ERROR] Timeout occurred in function activate_debug_mode()");
	return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;

}

/**
 * Writes bram address to AXI lite bus register
 * @param addr BRAM address
 * @return Error code
 */
egg_error_t egg_update_bram_addr(uint32_t addr)
{
	CHECK(uio.number >= 0,"UIO not initialized");
	*(uio.ptr_to_mmap_addr+EGG_RD_BRAM_ADDR_OFS) = addr;
	int timeout = 0;
	uint32_t value = 0;
	while(timeout < TIMEOUT)
	{
		timeout++;
		value = *(uio.ptr_to_mmap_addr+EGG_RD_BRAM_ADDR_OFS);
		CHECK(egg_check_dbg_status()==EGG_ERROR_NONE,"No valid data is available in memory!. Ensure that a complete image is sent to the NN IP.");
		if (value == addr)
		{
			return EGG_ERROR_NONE;
		}
	}
	fprintf(stderr, "[ERROR] Timeout occurred in function egg_update_bram_addr()");
	return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}

/**
 * Updates 32bit_select register
 * @param addr BRAM address
 * @return Error code
 */
egg_error_t egg_update_channel_select(uint8_t channel)
{
	uint32_t select_32bit = ((uint32_t) channel)*DATA_WIDTH;
	select_32bit=select_32bit/32;
	*(uio.ptr_to_mmap_addr+EGG_WR_32BIT_SEL_OFS) = (uint32_t) select_32bit;
	return EGG_ERROR_NONE;
}

/**
 * Reads single element from BRAM
 * @return Error code
 */
egg_error_t egg_read_bram_element(uint32_t *element, uint8_t channel)
{
	uint32_t value = 0;
	value = *(uio.ptr_to_mmap_addr + EGG_RD_BRAM_DATA_OFS);
	int shift = channel % (32/DATA_WIDTH); // %4
	value = value >> shift*DATA_WIDTH;
	value = value & (((uint32_t) pow(2,DATA_WIDTH))-1);
	*element = value;
	return EGG_ERROR_NONE;
}

/**
 * Reads from 4 channels with 1 BRAM access
 * @return Error code
 */
egg_error_t egg_read_32bit_vec(pixel_t** pix_la, network_t* network, uint8_t layer, uint8_t select_32bit)
{
	uint8_t channel;
	uint32_t addr = 0, value=0;
	int pixels_per_vector = 32/DATA_WIDTH; // 4 for uint8
	// Update selected 32_bit_select value --> eg. number of 4 channels
	*(uio.ptr_to_mmap_addr+EGG_WR_32BIT_SEL_OFS) = select_32bit;	//have to be done before updating bram address, since bram address is used to check if hardware received the new values from the processor

	for (uint32_t i=0; i < network->layers[layer]->width*network->layers[layer]->height;i++)
	{
		CHECK(egg_update_bram_addr(addr+i)==EGG_ERROR_NONE,"Error updating BRAM address"); // update bram address, have to be done after channel update --> see above

		value = *(uio.ptr_to_mmap_addr + EGG_RD_BRAM_DATA_OFS); // read from hardware

		//split the 32 bit vector to single pixels for each channel
		for (int k = 0; k<pixels_per_vector;k++)
		{
			channel = select_32bit*pixels_per_vector+k;
			pix_la[channel][i]= (pixel_t) (value >> k*DATA_WIDTH);
			debug("Address %x: /t %d saved to channel %d",addr+i,pix_la[channel][i],channel);
		}
	}
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}

/**
 * Checks status register if debug error flag = 1
 * @return Error code
 */
egg_error_t egg_check_dbg_status()
{
	uint32_t value = 0;
	value = *(uio.ptr_to_mmap_addr + EGG_RD_STATUS_OFS);
	value = (value & EGG_RD_DBG_ERROR_MASK) >> EGG_RD_DBG_ERROR_SHIFT;
	CHECK(value == 0,"Debug error flag raised")
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}
