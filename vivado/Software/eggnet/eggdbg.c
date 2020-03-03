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

#include "eggnet.h"
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
