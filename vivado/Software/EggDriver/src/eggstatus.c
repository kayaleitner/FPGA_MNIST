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

#include "eggnet_core.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pthread.h>
#include "dbg.h"

/**
 * Reads network structure from hardware
 */
egg_error_t get_network_structure(network_t *network)
{
	CHECK(network->layer_number == 0,"Initialize Network first!");

	uint8_t layer_number = 0;
	layer_t **layers;

	CHECK(egg_get_layer_number(&layer_number,network)==EGG_ERROR_NONE,"Error reading layer number from hardware");
	layers = calloc (layer_number, sizeof (struct layer_t *));
	CHECK(layers != NULL,"Error allocating layers");
	for (uint8_t i=0;i<layer_number;i++)
	{
		uint16_t width, height;
		uint8_t channel_number;
		layer_type_t type;
		CHECK(egg_get_layer_info(i,&type,&width,&height,&channel_number,network)==EGG_ERROR_NONE,"Error reading layer number from hardware");
		layer_t *layer;
		layer = calloc (1, sizeof (layer_t));
		layer->layer_type = type;
		layer->height = height;
		layer->width = width;
		layer->in_channel_number = channel_number;
		layers[i] = layer;
	}
	network->layers = layers;
	network->layer_number = layer_number;
	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;
}

/**
 * Free network
 * @return Error code
 */
egg_error_t egg_free_network(network_t* network)
{
	CHECK(network->layer_number > 0,"Network not initialized! Nothing to free!");
	for(int i=0; i < network->layer_number;i++)
	{
		if(network->layers[i])
		{
			free(network->layers[i]);
		}
	}
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
}


/**
 * Reads layer structure info from memory controller
 * @return Error code
 */
egg_error_t egg_get_layer_info(uint8_t nb, layer_type_t *type,uint16_t *width, uint16_t *height, uint8_t *channel_number, network_t* network)
{
	CHECK(egg_update_memctrl_addr(network,nb)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",nb);
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
