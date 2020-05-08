#include "eggnet.h"
#include <stdio.h>
#include <unistd.h>
#include "dbg.h"
#include <pthread.h>


/**
 * Initializes the network. Searches for the corresponding UIO device, loads and initializes the dma proxy driver
 * @param ip_name String including the Name of the IP implemented in vivado
 * @param network Pointer to network structure
 * @return Error code
 */
egg_error_t egg_init_network(const char *ip_name, network_t* network)
{
	egg_error_t code;
	network = calloc(1,sizeof(network_t));
	CHECK(network != NULL,"Error allocating network sturcture")
	// Initialize DMA
	debug("Initializing DMA...");
	code = egg_init_dma();
	CHECK(code == EGG_ERROR_NONE,"Error initializing DMA");
	debug("Initializing DMA done.");
	// Initialize UIO Device --> AXI-lite bus communication
	debug("Initializing UIO device of %s ...",ip_name);
	code = egg_init_uio(ip_name);
	CHECK(code == EGG_ERROR_NONE,"Error initializing UIO device");
	debug("Initializing UIO device of %s done",ip_name);
	// Reading network structure from hardware using AXI lite bus and UIO device driver
	debug("Reading network structure from hardware...");
	code = get_network_structure(network);
	CHECK(code == EGG_ERROR_NONE,"Error reading network structure from hardware");
	debug("Reading network structure from hardware done");
	// Print network structure if debugging is active
	debug("Network structure:");
	#ifndef NDEBUG
		print_network(network);
	#endif
	return code;
	error:
		return code;
}

/**
 * Close network and free memory mapped address space
 * @param network Pointer to network structure
 * @return Error code
 */
egg_error_t egg_close_network(network_t* network)
{
	egg_error_t code;
	code = egg_close_dma();
	CHECK(code == EGG_ERROR_NONE,"Error closing DMA");

	code = egg_close_uio();
	CHECK(code == EGG_ERROR_NONE,"Error closing UIO device");

	code = egg_free_network(network);
	CHECK(code == EGG_ERROR_NONE,"Error freeing network");

	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;
}


/**
 * Gets results
 * @param results Pointer to result matrix --> Used as return value
 * @param result_number Pointer to number of results --> Used as return value
 * @param network Pointer to network structure
 * @return Error code
 */
egg_error_t get_results(pixel_t*** results, uint32_t* result_number, network_t* network)
{
	CHECK(network->result_number > 0,"No results available");
	*results = network->results;
	*result_number = network->result_number;
	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;
}


static inline void encode_base64(char dest[static 4], const uint8_t src[static 3])
{
    const uint8_t input[] = { (src[0] >> 2u) & 63, ((src[0] << 4u) | (src[1] >> 4)) & 63, ((src[1] << 2) | (src[2] >> 6)) & 63, src[2] & 63 };

    for (unsigned int i = 0; i < 4; ++i)
        dest[i] = input[i] + 'A'
                  + (((25 - input[i]) >> 8) & 6)
                  - (((51 - input[i]) >> 8) & 75)
                  - (((61 - input[i]) >> 8) & 15)
                  + (((62 - input[i]) >> 8) & 3);

}

/**
 * Free results
 * @param network Pointer to network structure
 * @return Error code
 */
egg_error_t free_results(network_t* network)
{
	CHECK(network->result_number > 0,"No results available");
	for (int i=0;i<network->result_number;i++)
	{
		free(network->results[i]);
	}
	free(network->results);
	network->result_number = 0;
	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;
}

egg_error_t egg_forward(const uint8_t *image_buffer, int batch, int height, int width, int channels, 
                        int **results, int *batch_out, int *n) {

	egg_error_t return_value = EGG_ERROR_NONE;
	
	CHECK_AND_SET(results != NULL && batch_out != NULL && n != NULL && image_buffer != NULL,
		return_value, EGG_ERROR_NULL_PTR, "Invalid input arg");

	// allocate 
	int *_results = calloc(10 * batch, sizeof(int));




	*results = _results;
	*n = 10;
	*batch_out = batch;

error:
	return return_value;			
}


/**********************************************************************************************************************
 *
 *  Status Functions
 *
 *********************************************************************************************************************/

/**
 * Returns an string description of the error
 */
const char *egg_print_err(egg_error_t code)
{
	switch(code)
	{
	case EGG_ERROR_NONE:
		return "No error.";

	case EGG_ERROR_NULL_PTR:
		return "Null pointer error.";

	case EGG_ERROR_DEVICE_COMMUNICATION_FAILED:
		return "Communication with the device failed.";

	case EGG_ERROR_INIT_FAILDED:
		return "Device initialization failed.";

	case EGG_ERROR_UDEF:
		return "Undefined error occurred.";
	default:
		return "Undefined error occurred.";
	}
}

/**
 * Print Network structure
 * @param net Pointer to global network structure
 * @return Error code
 */
egg_error_t print_network(network_t *network)
{
	CHECK(network->layer_number > 0,"Network not initialized!");
	layer_t* layer;

	for (int i=0;i<network->layer_number;i++)
	{
		layer = network->layers[i];
		fprintf(stdout,"LAYER %d: ",i);
		fprintf(stdout,"Type %s: ",get_type_string(layer->layer_type));
		fprintf(stdout,"Width %d: ",layer->width);
		fprintf(stdout,"Height %d: ",layer->height);
		fprintf(stdout,"In channel number %d:\n",layer->in_channel_number);
	}
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_UDEF;
}


/**********************************************************************************************************************
 *
 *  DMA Functions
 *
 *********************************************************************************************************************/

/* The following function is the transmit thread to allow to receive.
 * Calls egg_tx_img() --> In separate file to encapsulate global dma interface variable
 * The ioctl calls are blocking such that a thread is needed.
 * @param image Pointer to image array
 * @param network Pointer to network structure
 * @return Pointer to error code
 */
void *egg_tx_img_thread(void* network)
{
	network_t* net = network;
	if (egg_tx_img_thread(net)==EGG_ERROR_NONE)
	{
		pthread_exit((void*) EGG_ERROR_DEVICE_COMMUNICATION_FAILED);
	}
	else
	{
		pthread_exit((void*) EGG_ERROR_NONE);
	}
}

/* The following function is the transmit thread to allow to receive.
 * Calls egg_rx_img() --> In separate file to encapsulate global dma interface variable
 * The function is called when the interrupt of the uio device occurs.
 * The ioctl calls are blocking such that a thread is needed.
 * @param network Pointer to network structure
 * @return Pointer to error code
 */
void *egg_rx_img_thread(void* network)
{
	network_t* net = network;
	if (egg_rx_img_thread(net)==EGG_ERROR_NONE)
	{
		pthread_exit((void*) EGG_ERROR_DEVICE_COMMUNICATION_FAILED);
	}
	else
	{
		pthread_exit((void*) EGG_ERROR_NONE);
	}
}

/**********************************************************************************************************************
 *
 *  Debugging Functions
 *
 *********************************************************************************************************************/


/**
 * reads a single pixel from the network
 * @param neural network structure
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param col selected collum of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_pixel(pixel_t *pixel, network_t* network, uint8_t layer, uint16_t row, uint16_t col, uint8_t channel)
{
	//Check if parameter are valid
	CHECK(network->layer_number > 0,"Network not initialized!");
	CHECK(network->layer_number >= layer,"Layer %d exceeds available layer number: %d",layer,network->layer_number);
	CHECK(network->layers[layer]->height > row,"Row %d exceeds matrix dimension %d",row,network->layers[layer]->height);
	CHECK(network->layers[layer]->width > col,"Col %d exceeds matrix dimension %d",col,network->layers[layer]->width);
	CHECK(network->layers[layer]->in_channel_number > channel,"Channel %d exceeds matrix dimension %d",channel,network->layers[layer]->in_channel_number);
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(network,layer),"Error entering debug mode in layer: %d",layer);

	uint32_t addr = (uint32_t) row * (uint32_t) network->layers[layer]->width + (uint32_t) col;
	debug("Start address %d is selected.",addr);

	CHECK(egg_update_memctrl_addr(network,layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	egg_update_channel_select(channel);
	CHECK(egg_update_bram_addr(addr)==EGG_ERROR_NONE,"Error updating BRAM address");
	uint32_t element;
	egg_read_bram_element(&element,channel);
	debug("Address %x: /t %d",addr,element);
	if (pixel == NULL)
	{
		debug("Allocate pixel element");
		pixel = calloc (1, sizeof (pixel_t));
		*pixel = (pixel_t) element;
	}
	else
	{
		*pixel = (pixel_t) element;
	}
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}

/**
 * reads a single row from the network
 * @param neural network structure
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_row(pixel_t **pixel, network_t* network, uint8_t layer, uint16_t row, uint8_t channel)
{
	//Check if parameter are valid
	CHECK(network->layer_number > 0,"Network not initialized!");
	CHECK(network->layer_number >= layer,"Layer %d exceeds available layer size: %d",layer,network->layer_number)
	CHECK(network->layers[layer]->height > row,"Row %d exceeds matrix dimension %d",row,network->layers[layer]->height);
	CHECK(network->layers[layer]->in_channel_number > channel,"Channel %d exceeds matrix dimension %d",channel,network->layers[layer]->in_channel_number);
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(network,layer),"Error entering debug mode in layer: %d",layer);

	// Update memory controller address --> selects a layer
	CHECK(egg_update_memctrl_addr(network,layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	// Update selected channel number
	egg_update_channel_select(channel);

	// Calculate BRAM start address from row
	uint32_t addr = (uint32_t) row * (uint32_t) network->layers[layer]->width;
	uint32_t element=0;
	pixel_t *pix_row;
	debug("Start address %d is selected.",addr);
	// Allocate row array
	pix_row = calloc (network->layers[layer]->width, sizeof (pixel_t));
	CHECK(pix_row==NULL,"Error allocating row array");
	debug("Pixel array with size %d is allocated successfully.",network->layers[layer]->width);

	// Read row from hardware
	for (uint32_t i=0; i < network->layers[layer]->width;i++)
	{
		CHECK(egg_update_bram_addr(addr+i)==EGG_ERROR_NONE,"Error updating BRAM address");
		// channel is used to select correct pixel of 32 bit vector
		egg_read_bram_element(&element,channel);
		debug("Address %x: /t %d",addr+i,element);
		pix_row[i] = (pixel_t) element;
	}
	*pixel = pix_row;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}
/**
 * reads content of a single channel of specific layer
 * @param pointer to pixel array
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_channel(pixel_t **pixel, network_t* network, uint8_t layer, uint8_t channel)
{
	//Check if parameter are valid
	CHECK(network->layer_number > 0,"Network not initialized!");
	CHECK(network->layer_number >= layer,"Layer %d exceeds available layer size: %d",layer,network->layer_number);
	CHECK(network->layers[layer]->in_channel_number > channel,"Channel %d exceeds matrix dimension %d",channel,network->layers[layer]->in_channel_number);
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(network,layer),"Error entering debug mode in layer: %d",layer);

	// Update memory controller address --> selects a layer
	CHECK(egg_update_memctrl_addr(network,layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	// Update selected channel number
	egg_update_channel_select(channel);

	// Calculate BRAM start address from row
	uint32_t addr = 0;
	uint32_t element=0;
	pixel_t *pix_ch;

	// Allocate channel array
	pix_ch = calloc (network->layers[layer]->width*network->layers[layer]->height, sizeof (pixel_t));
	CHECK(pix_ch==NULL,"Error allocating channel array");

	// Read channel from hardware
	for (uint32_t i=0; i < network->layers[layer]->width*network->layers[layer]->height;i++)
	{
		CHECK(egg_update_bram_addr(addr+i)==EGG_ERROR_NONE,"Error updating BRAM address");
		// channel is used to select correct pixel of 32 bit vector
		egg_read_bram_element(&element,channel);
		debug("Address %x: /t %d",addr+i,element);
		pix_ch[i] = (pixel_t) element;
	}
	*pixel = pix_ch;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}

/**
 * reads content of a layer
 * @param point to pointer to pixel array [with*height] --> reshape to matrix [W,H] necessary. Shape: One row after the other
 * @param layer Selected Layer
 * @return Error code
 */
egg_error_t read_layer(pixel_t ***pixel, network_t* network, uint8_t layer)
{
	//Check if parameter are valid
	CHECK(network->layer_number > 0,"Network not initialized!");
	CHECK(network->layer_number >= layer,"Layer %d exceeds available layer size: %d",layer,network->layer_number);
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(network,layer),"Error entering debug mode in layer: %d",layer);

	// Update memory controller address --> selects a layer
	CHECK(egg_update_memctrl_addr(network,layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	// Calculate BRAM start address from row
	pixel_t *pix_ch;
	pixel_t **pix_la;
	int pixels_per_vector = 32/DATA_WIDTH; // 4 for uint8


	// Allocate channel pointer array
	pix_la = calloc (network->layers[layer]->in_channel_number, sizeof (pixel_t *));
	CHECK(pix_la==NULL,"Error allocating channel pointer array");

	for (uint8_t j=0;j<network->layers[layer]->in_channel_number;j++)
	{
		// Allocate row array
		pix_ch = calloc (network->layers[layer]->width*network->layers[layer]->height, sizeof (pixel_t));
		CHECK(pix_ch==NULL,"Error allocating channel array");
		pix_la[j] = pix_ch;
	}

	// Read from hardware --> different to others since the whole 32 bit vector is used
	for (uint8_t j=0;j<network->layers[layer]->in_channel_number/pixels_per_vector;j++)
	{

		CHECK(egg_read_32bit_vec(pix_la, network, layer, j)==EGG_ERROR_NONE,"Error reading data from bram in layer %d and in channel %d to %d",layer,j,j*pixels_per_vector);
	}
	*pixel = pix_la;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}


