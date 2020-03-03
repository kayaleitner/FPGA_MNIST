#include "eggnet.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pthread.h>
#include "dma-proxy.h"
#include "dbg.h"


#define DRIVER_KEXT_NAME "dma-proxy.ko"

#define HEIGTH 28
#define WIDTH 28
#define CHANNELS 1
#define IMG_GET(b,h,w,c) image_buffer + c + w*CHANNELS + h*CHANNELS*WIDTH + b *CHANNELS*WIDTH*HEIGTH


static struct dma_proxy_channel_interface *tx_proxy_interface_p;
static int tx_proxy_fd;
static struct dma_proxy_channel_interface *rx_proxy_interface_p;
static int rx_proxy_fd, i;
const int TRANSFER_SIZE = HEIGTH*WIDTH*CHANNELS;
static pthread_mutex_t buffer_write_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t buffer_read_lock = PTHREAD_MUTEX_INITIALIZER;

#define LINUX_KERNEL_MODULE_PATH "/lib/modules/4.9.0-xilinx-v2017.4/extra/dma-proxy.ko"
#define LINUX_ADD_KERNEL_MODULE_COMMAND "insmod " LINUX_KERNEL_MODULE_PATH
#define LINUX_DEV_PATH "/dev/dma_proxy_rx"


egg_error_t egg_init_dma()
{
	if( access( LINUX_DEV_PATH, F_OK ) == -1 ) {
		CHECK(system(LINUX_ADD_KERNEL_MODULE_COMMAND) == 0,"Error loading dma-proxy kernel module");
	}
	tx_proxy_fd = open("/dev/dma_proxy_tx", O_RDWR);
	CHECK(tx_proxy_fd >= 1,"Unable to open dma_proxy_tx device file");

	rx_proxy_fd = open("/dev/dma_proxy_rx", O_RDWR);
	CHECK(rx_proxy_fd >= 1,"Unable to open dma_proxy_rx device file");

	tx_proxy_interface_p = (struct dma_proxy_channel_interface *)mmap(NULL, sizeof(struct dma_proxy_channel_interface),
											PROT_READ | PROT_WRITE, MAP_SHARED, tx_proxy_fd, 0);
	rx_proxy_interface_p = (struct dma_proxy_channel_interface *)mmap(NULL, sizeof(struct dma_proxy_channel_interface),
									PROT_READ | PROT_WRITE, MAP_SHARED, rx_proxy_fd, 0);

	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_INIT_FAILDED;

}

egg_error_t egg_close_dma()
{
	CHECK(munmap(tx_proxy_interface_p, sizeof(struct dma_proxy_channel_interface))==0,"Error unmap tx proxy interface");
	CHECK(munmap(rx_proxy_interface_p, sizeof(struct dma_proxy_channel_interface))==0,"Error unmap rx proxy interface");

	close(tx_proxy_fd);
	close(rx_proxy_fd);
	return EGG_ERROR_NONE;
	error:
		return EGG_ERROR_UDEF;

}



int write_image(uint8_t *image_buffer, int batch, int height, int width, int channels)
{
	// image_buffer[b][h][w][c]
	*IMG_GET(1,1,1,1)++;



}


egg_error_t egg_send_single_image_sync(uint8_t *image_buffer) {

	int dummy;
	tx_proxy_interface_p->length = TRANSFER_SIZE;
	int i = 0;
	for (int i = 0; i < TRANSFER_SIZE; i++) {
		tx_proxy_interface_p->buffer[i] =  image_buffer[i];
	}

	/* Perform the DMA transfer and the check the status after it completes
	 * as the call blocks til the transfer is done.
	 */
	ioctl(tx_proxy_fd, 0, &dummy);

	CHECK(tx_proxy_interface_p->status == PROXY_NO_ERROR,"Proxy tx transfer error\n");

	error:
	// do something smart here
	return EGG_ERROR_DEVICE_COMMUNICATION_FAILED;

}

struct egg_send_image_thread_args {
	int batch_size;
	uint8_t *image_buffer;
	egg_error_t error_status;
};

void *egg_tx_thread(void *args)
{
	int batch_size = ((struct egg_send_image_thread_args *) args)->batch_size;
	uint8_t *image_buffer = ((struct egg_send_image_thread_args *) args)->image_buffer;

	/* Set up the length for the DMA transfer and initialize the transmit
 	 * buffer to a known pattern.
 	 */

	pthread_mutex_lock(&buffer_write_lock); // ensures that interface to dma-proxy is used by only one thread
	for (int b=0;b<batch_size;b++)
	{
		CHECK(send_single_image_sync(IMG_GET(b,0,0,0)) == EGG_ERROR_NONE,"Proxy tx transfer error\n");
	}

	pthread_mutex_unlock(&buffer_write_lock); // unlock interface
	free(args);


	error:
		pthread_mutex_unlock(&buffer_write_lock); // unlock interface
		free(args);
}

void *egg_tx_callback(void *args)
{

}

egg_error_t egg_send_single_image_async(uint8_t *image_buffer, int batch_size, pthread_t tid)
{
	struct egg_send_image_thread_args *args = malloc(sizeof(struct egg_send_image_thread_args));
	args->batch_size = batch_size;
	args->image_buffer = image_buffer;

	pthread_create(&tid, NULL, egg_tx_thread, (void *) args);
}

void *tx_image_batch(int dma_count, uint8_t *image_buffer,  int batch, int height, int width, int channels)
{
	int dummy;

	/* Set up the length for the DMA transfer and initialize the transmit
 	 * buffer to a known pattern.
 	 */
	pthread_mutex_lock(&buffer_write_lock); // ensures that interface to dma-proxy is used by only one thread
	tx_proxy_interface_p->length = batch * width * height * channels;
		int i = 0;
		for (int b = 0; b < batch; b++) {
		    for (int h = 0; h < height; h++) {
		        for (int w = 0; w < width; w++) {
		            for (int c = 0; c < channels; c++) {
		            	tx_proxy_interface_p->buffer[i] =  *IMG_GET(b,h,w,c);
		            	i++;
		            }
		        }
		    }
		}

	pthread_mutex_unlock(&buffer_write_lock); // unlock interface

		for (i = 0; i < TRANSFER_SIZE; i++)
       			tx_proxy_interface_p->buffer[i] = *IMG_GET(1,1,1,1)++;;

		/* Perform the DMA transfer and the check the status after it completes
	 	 * as the call blocks til the transfer is done.
 		 */
		ioctl(tx_proxy_fd, 0, &dummy);

		if (tx_proxy_interface_p->status != PROXY_NO_ERROR)
			printf("Proxy tx transfer error\n");

}

