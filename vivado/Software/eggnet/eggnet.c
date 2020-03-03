#include "eggnet.h"
#include <stdio.h>
#include <unistd.h>
#include "dbg.h"


/**
 * Initializes the network. Searches for the corresponding UIO device, loads and initializes the dma proxy driver
 * @return Error code
 */
egg_error_t egg_init_network(const char *ip_name, network_t *net)
{
	egg_error_t code;
	// Initialize DMA
	debug("Initializing DMA...");
	code = egg_init_dma();
	CHECK(code == EGG_ERROR_NONE,"Error initializing DMA");
	debug("Initializing DMA done.");
	// Initialize UIO Device --> AXI-lite bus communication
	debug("Initializing UIO device of %s ...",ip_name);
	code = egg_init_uio((char *) ip_name);
	CHECK(code == EGG_ERROR_NONE,"Error initializing UIO device");
	debug("Initializing UIO device of %s done",ip_name);
	// Reading network structure from hardware using AXI lite bus and UIO device driver
	debug("Reading network structure from hardware...");
	code = get_network_structure(net);
	CHECK(code == EGG_ERROR_NONE,"Error reading network structure from hardware");
	debug("Reading network structure from hardware done");
	// Print network structure if debugging is active
	debug("Network structure:");
	#ifndef NDEBUG
		print_network();
	#endif
	return code;
	error:
		return code;
}

/**
 * Close network and free memory mapped address space
 * @return Error code
 */
egg_error_t egg_close_network()
{
	egg_error_t code;
	code = egg_close_dma();
	CHECK(code == EGG_ERROR_NONE,"Error closing DMA");

	code = egg_close_uio();
	CHECK(code == EGG_ERROR_NONE,"Error closing UIO device");

	code = egg_free_network(&network);
	CHECK(code == EGG_ERROR_NONE,"Error freeing network");

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
 * Reads network structure from hardware
 */
egg_error_t get_network_structure(network_t *net_ptr)
{
	CHECK(uio.number >= 1,"Initialize Network first!");
	if (network.layer_number > 0)
	{
		net_ptr = &network;
		return EGG_ERROR_NONE;
	}

	uint8_t layer_number = 0;
	layer_t **layers;

	CHECK(egg_get_layer_number(&layer_number)==EGG_ERROR_NONE,"Error reading layer number from hardware");
	layers = calloc (layer_number, sizeof (struct layer_t *));
	CHECK(layers != NULL,"Error allocating layers");
	for (uint8_t i=0;i<layer_number;i++)
	{
		uint16_t width, height;
		uint8_t channel_number;
		layer_type_t type;
		CHECK(egg_get_layer_info(i,&type,&width,&height,&channel_number)==EGG_ERROR_NONE,"Error reading layer number from hardware");
		layer_t *layer;
		layer = calloc (1, sizeof (layer_t));
		layer->layer_type = type;
		layer->height = height;
		layer->width = width;
		layer->in_channel_number = channel_number;
		layers[i] = layer;
	}
	network.layers = layers;
    network.layer_number = layer_number;
	*net_ptr = network;
	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;
}

/**
 * Print Network structure
 * @param net Pointer to global network structure
 * @return Error code
 */
egg_error_t print_network()
{
	CHECK(network.layer_number > 0,"Network not initialized!");
	for (int i=0;i<network.layer_number;i++)
	{
		fprintf(stdout,"LAYER %d: ",i);
		fprintf(stdout,"Type %s: ",get_type_string(network.layers[i]->layer_type));
		fprintf(stdout,"Width %d: ",network.layers[i]->width);
		fprintf(stdout,"Height %d: ",network.layers[i]->height);
		fprintf(stdout,"In channel number %d:\n",network.layers[i]->in_channel_number);
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

/* The following function is the transmit thread to allow the transmit and the
 * receive channels to be operating simultaneously. The ioctl calls are blocking
 * such that a thread is needed.
 * @param image Pointer to image 1-d array (one row after each other)
 */
void *egg_tx_img_thread(const pixel_t *image)
{
	int dummy, i;

	/* Set up the length for the DMA transfer and initialize the transmit
 	 * buffer to a known pattern.
 	 */
	tx_proxy_interface_p->length = network.layers[1]->width*network.layers[1]->height;

	for (i = 0; i < tx_proxy_interface_p->length; i++)
	{
		tx_proxy_interface_p->buffer[i] = image[i];
	}

	/* Perform the DMA transfer and check the status after it completes
	 * as the call blocks till the transfer is done.
	 */
	ioctl(tx_proxy_fd, 0, &dummy);

	if(tx_proxy_interface_p->status != PROXY_NO_ERROR)
		fprintf(stderr, "[ERROR] (%s:%d: PROXY DMA ERROR. Error sending image\n",__FILE__, __LINE__);
}

/**********************************************************************************************************************
 *
 *  Debugging Functions
 *
 *********************************************************************************************************************/

egg_error_t activate_debug_mode(uint8_t channel)
{
	//check if Hardware is already initialized
	CHECK(uio.number >= 0,"UIO not initialized");
	CHECK(network.layers[layer]->in_channel_number > channel,"Channel %d exceeds matrix dimension %d",channel,network.layers[layer]->in_channel_number);
	debug("Parameter are valid");

	//Update selected layer
	CHECK(egg_update_memctrl_addr(layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
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
 * reads a single pixel from the network
 * @param neural network structure
 * @param layer Selected Layer
 * @param row selected row of the Matrix
 * @param col selected collum of the Matrix
 * @param channel Selected channel
 * @return Error code
 */
egg_error_t read_pixel(const pixel_t *pixel,uint8_t layer, uint16_t row, uint16_t col, uint8_t channel)
{
	//Check if parameter are valid
	CHECK(network.layer_number > 0,"Network not initialized!");
	CHECK(network.layer_number >= layer,"Layer exceeds available layer size: %d",layer,network.layer_number)
	CHECK(network.layers[layer]->height > row,"Row %d exceeds matrix dimension %d",row,network.layers[layer]->height);
	CHECK(network.layers[layer]->width > col,"Col %d exceeds matrix dimension %d",col,network.layers[layer]->width);
	CHECK(network.layers[layer]->in_channel_number > channel,"Channel %d exceeds matrix dimension %d",channel,network.layers[layer]->in_channel_number);
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(layer),"Error entering debug mode in layer: %d",layer);

	uint32_t addr = (uint32_t) row * (uint32_t) network.layers[layer]->width + (uint32_t) col;
	debug("Start address %d is selected.",addr);

	CHECK(egg_update_memctrl_addr(layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	egg_update_channel_select(channel);
	CHECK(egg_update_bram_addr(addr)==EGG_ERROR_NONE,"Error updating BRAM address");
	uint32_t element;
	egg_read_bram_element(&element,channel);
	debug("Address %x: /t %d",addr+i,element);
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
egg_error_t read_row(const pixel_t **pixel, uint8_t layer, uint16_t row, uint8_t channel)
{
	//Check if parameter are valid
	CHECK(network.layer_number > 0,"Network not initialized!");
	CHECK(network.layer_number >= layer,"Layer exceeds available layer size: %d",layer,network.layer_number)
	CHECK(network.layers[layer]->height > row,"Row %d exceeds matrix dimension %d",row,network.layers[layer]->height);
	CHECK(network.layers[layer]->in_channel_number > channel,"Channel %d exceeds matrix dimension %d",channel,network.layers[layer]->in_channel_number);
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(layer),"Error entering debug mode in layer: %d",layer);

	// Update memory controller address --> selects a layer
	CHECK(egg_update_memctrl_addr(layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	// Update selected channel number
	egg_update_channel_select(channel);

	// Calculate BRAM start address from row
	uint32_t addr = (uint32_t) row * (uint32_t) network.layers[layer]->width;
	uint32_t element=0;
	pixel_t *pix_row;
	debug("Start address %d is selected.",addr);
	// Allocate row array
	pix_row = calloc (network.layers[layer]->width, sizeof (pixel_t));
	CHECK(pix_row==NULL,"Error allocating row array");
	debug("Pixel array with size %d is allocated successfully.",network.layers[layer]->width);

	// Read row from hardware
	for (uint32_t i=0; i < network.layers[layer]->width;i++)
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
egg_error_t read_channel(const pixel_t **pixel, uint8_t layer, uint8_t channel)
{
	//Check if parameter are valid
	CHECK(network.layer_number > 0,"Network not initialized!");
	CHECK(network.layer_number >= layer,"Layer exceeds available layer size: %d",layer,network.layer_number)
	CHECK(network.layers[layer]->in_channel_number > channel,"Channel %d exceeds matrix dimension %d",channel,network.layers[layer]->in_channel_number);
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(layer),"Error entering debug mode in layer: %d",layer);

	// Update memory controller address --> selects a layer
	CHECK(egg_update_memctrl_addr(layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	// Update selected channel number
	egg_update_channel_select(channel);

	// Calculate BRAM start address from row
	uint32_t addr = 0;
	uint32_t element=0;
	pixel_t *pix_ch;

	// Allocate channel array
	pix_ch = calloc (network.layers[layer]->width*network.layers[layer]->height, sizeof (pixel_t));
	CHECK(pix_ch==NULL,"Error allocating channel array");

	// Read channel from hardware
	for (uint32_t i=0; i < network.layers[layer]->width*network.layers[layer]->height;i++)
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
egg_error_t read_layer(const pixel_t ***pixel, uint8_t layer)
{
	//Check if parameter are valid
	CHECK(network.layer_number > 0,"Network not initialized!");
	CHECK(network.layer_number >= layer,"Layer exceeds available layer size: %d",layer,network.layer_number)
	debug("Parameter are valid");

	// Activate debug mode
	CHECK(activate_debug_mode(layer),"Error entering debug mode in layer: %d",layer);

	// Update memory controller address --> selects a layer
	CHECK(egg_update_memctrl_addr(layer)==EGG_ERROR_NONE,"Error writing %d to memory controller address register",layer);
	debug("Memory controller address updated successfully. Layer %d selected.",layer);

	// Update selected channel number
	egg_update_channel_select(channel);

	// Calculate BRAM start address from row
	uint32_t addr = 0;
	uint32_t element=0;
	uint32_t value = 0;
	pixel_t *pix_ch;
	pixel_t **pix_la;
	uint32_t ch_cnt = 0;
	int pixels_per_vector = 32/DATA_WIDTH; // 4 for uint8
	int channel = 0;


	// Allocate channel pointer array
	pix_la = calloc (network.layers[layer]->in_channel_number, sizeof (pixel_t *));
	CHECK(pix_la==NULL,"Error allocating channel pointer array");

	for (uint32_t j=0;j<network.layers[layer]->in_channel_number;j++)
	{
		// Allocate row array
		*pix_ch = calloc (network.layers[layer]->width*network.layers[layer]->height, sizeof (pixel_t));
		CHECK(pix_ch==NULL,"Error allocating channel array");
		pix_la[j] = pix_ch;
	}

	// Read from hardware --> different to others since the whole 32 bit vector is used
	ch_cnt = 0;
	for (uint32_t j=0;j<network.layers[layer]->in_channel_number/pixels_per_vector;j++)
	{

		// Update selected 32_bit_select value --> eg. number of 4 channels
		*(uio.ptr_to_mmap_addr+EGG_WR_32BIT_SEL_OFS) = j;	//have to be done before updating bram address, since bram address is used to check if hardware received the new values from the processor

		for (uint32_t i=0; i < network.layers[layer]->width*network.layers[layer]->height;i++)
		{
			CHECK(egg_update_bram_addr(addr+i)==EGG_ERROR_NONE,"Error updating BRAM address"); // update bram address, have to be done after channel update --> see above

			value = *(uio.ptr_to_mmap_addr + EGG_RD_BRAM_DATA_OFS); // read from hardware

			//split the 32 bit vector to single pixels for each channel
			for (int k = 0; k<pixels_per_vector;k++)
			{
				channel = j*pixels_per_vector+k;
				pix_la[channel][i]= (pixel_t) (value >> k*DATA_WIDTH);
				debug("Address %x: /t %d saved to channel %d",addr+i,pix_la[channel][i],channel);
			}
		}

	}
	*pixel = pix_la;
	return EGG_ERROR_NONE;

	error:
		return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;
}


