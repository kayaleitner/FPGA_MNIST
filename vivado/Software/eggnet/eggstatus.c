/*
 * EggNet status library
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

#include "eggnet.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pthread.h>
#include "dbg.h"

egg_error_t egg_init_uio(char *ip_name)
{
	CHECK(uio.number == 0,"UIO already initialized");
	uio.info = uio_find_by_uio_name(ip_name);

	uio.info->fd = open(uio_get_devname(uio.info), O_RDWR);
	CHECK(uio.info->fd >= 1,"Unable to open UIO device: %s\n",uio_get_devname(uio.info));
	uio.ptr_to_mmap_addr = (volatile uint32_t*) mmap(NULL, uio_get_mem_size(uio.info,0), PROT_READ|PROT_WRITE, MAP_SHARED, uio.info->fd, 0x0);
	CHECK(ptr_to_mmap_addr != NULL,"Error in memory mapping of UIO device: %s\n",uio_get_devname(uio.info));

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
	uio.ptr_to_mmap_addr = Null;
	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;
}

egg_error_t egg_get_layer_number(uint8_t *layer_number)
{
	CHECK(egg_update_memctrl_addr(0)==EGG_ERROR_NONE,"Error writing 0 to memory controller address register");
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
egg_error_t egg_update_memctrl_addr(uint8_t addr)
{
	// Check if layer is already active
	if (network.selected_layer == addr)
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
			network.selected_layer = addr;
			return EGG_ERROR_NONE;
		}
	}
	fprintf(stderr, "[ERROR] Timout occured in function egg_update_memctrl_addr()");
	return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}

/**
 * Free network
 * @return Error code
 */
egg_error_t egg_free_network()
{
	CHECK(network.layer_number > 0,"Network not initialized! Nothing to free!");
	for(int i=0; i < network.layer_number;i++)
	{
		if(network.layers[i])
		{
			free(network.layers[i]);
		}
	}
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
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

/**
 * Reads layer structure info from memory controller
 * @return Error code
 */
egg_error_t egg_get_layer_info(uint8_t nb, layer_type_t *type,uint16_t *width, uint16_t *height, uint8_t *channel_number)
{
	CHECK(egg_update_memctrl_addr(nb)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",nb);
	CHECK(egg_read_type(type)==EGG_ERROR_NONE,"Error reading type of layer %d",nb);
	CHECK(egg_read_width(width)==EGG_ERROR_NONE,"Error reading width of layer %d",nb);
	CHECK(egg_read_height(height)==EGG_ERROR_NONE,"Error reading height of layer %d",nb);
	CHECK(egg_read_channel_nb(channel_number)==EGG_ERROR_NONE,"Error reading channel number of layer %d",nb);
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
}

/**
 * Get Type as string
 * @param type Enumerator of Layer type
 * @return Error code
 */
const char *get_type_string(layer_type_t type)
{
	switch(type)
	{
	case Dense:
		return "Dense";
	case Conv1x1:
		return "Conv1x1";
	case Conv3x3:
		return "Conv3x3";
	case Conv5x5:
		return "Conv5x5";
	case Average_pooling:
		return "Average_pooling";
	default:
		return "ERROR";
	}
}
