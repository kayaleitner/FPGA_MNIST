#include "NNExtension.h"
#include "dbg.h"
#include <stdlib.h>

#ifndef min
#    define min(a, b) (a < b ? a : b)
#endif

#ifndef max
#    define max(a, b) (a < b ? b : a)
#endif

#define CLAMP(x, a, b) (min(b, max(a, x)))

#define DATA_IN(b, i, j, ch)                                                                       \
    *(data_in + ch + (in_ch * j) + (in_ch * in_w * i) + (in_ch * in_w * in_h * b))

#define KERNEL(di, dj, q, k)                                                                       \
    *(kernel + k + (kout_ch * q) + (kout_ch * kin_ch * dj) + (kout_ch * kin_ch * fw * di))

#define DATA_OUT(b, i, j, ch)                                                                      \
    *(data_out + ch + (out_ch * j) + (out_ch * out_w * i) + (out_ch * out_w * out_h * b))


void conv2d2(const float *data_in,
             int          batch,
             int          in_h,
             int          in_w,
             int          in_ch,
             const float *kernel,
             int          fh,
             int          fw,
             int          kin_ch,
             int          kout_ch,
             int          stride,
             float        data_out[batch][in_h][in_w][kout_ch])
{

    // conv2d(data_in, batch, in_h, in_w, in_ch, kernel, fh, fw, kin_ch, kout_ch, stride,
    //        &data_out[0][0][0][0], batch, in_h, in_w, kout_ch);
}

void conv2d(const float *data_in,
            int          batch,
            int          in_h,
            int          in_w,
            int          in_ch,
            const float *kernel,
            int          fh,
            int          fw,
            int          kin_ch,
            int          kout_ch,
            int          stride,
            float **     pdata_out,
            int *        pbatch_out,
            int *        pout_h,
            int *        pout_w,
            int *        pout_ch)
{
    /*
    Perform a 2D convolution over a batch of tensors. This is equivalent to

     output[b, i, j, k] =
         sum_{di, dj, q} input[b, strides[1] * i + di, strides[2] * j + dj, q] *
                         filter[di, dj, q, k]

    :param data_in: Input data tensor with shape [batch, height, width, channels_in]
    :param kernel: Convolution kernel tensor with shape [kernel_height, kernel_width, channels_in, channels_out]
    :param stride: Integer for the step width
    :return: Tensor with shape [batch, height/stride, width/stride, channels_out]
    */


    const int batch_out = batch;
    const int out_h = in_h;
    const int out_w = in_w;
    const int out_ch = kout_ch;

    log_info("data_in   = [%d, %d, %d, %d]", batch, in_h, in_w, in_ch);
    log_info("kernel    = [%d, %d, %d, %d]", fh, fw, kin_ch, kout_ch);
    log_info("data_out  = [%d, %d, %d, %d]", batch_out, out_h, out_w, out_ch);

    CHECK(kin_ch == in_ch, "Dimension mismatch, number of input channels must be equal to number "
                           "of input filter weights");

    // Check if the filter has an uneven width
    CHECK(1 == fh % 2, "Only odd numbers for filter size are supported");
    CHECK(1 == fw % 2, "Only odd numbers for filter size are supported");


    // Allocate memory
    float *data_out = (float *) calloc(batch_out * out_h * out_w * out_ch, sizeof(float));
    CHECK(data_out != NULL, "Memory allocation failed");

    CHECK(pdata_out != NULL, "Invalid input pointer provided");
    CHECK(pbatch_out != NULL, "Invalid input pointer provided");
    CHECK(pout_h != NULL, "Invalid input pointer provided");
    CHECK(pout_w != NULL, "Invalid input pointer provided");
    CHECK(pout_ch != NULL, "Invalid input pointer provided");

    *pdata_out = data_out;
    *pbatch_out = batch_out;
    *pout_h = out_h;
    *pout_w = out_w;
    *pout_ch = out_ch;


    // Find the midpoint of the filter. This only works for odd filter sizes
    const int fh2 = (int)((fh - 1) / 2);
    const int fw2 = (int)((fw - 1) / 2);

    // output[b, i, j, k] =
    //     sum_{di, dj, q} input[b, strides[1] * i + di, strides[2] * j + dj, q] *
    //                     filter[di, dj, q, k]
    for (int b = 0; b < batch; b++)
    {
        for (int i = 0; i < in_h; i += stride)
        {
            for (int j = 0; j < in_w; j += stride)
            {
                for (int k = 0; k < kout_ch; k++)
                {
                    // patch = in_padded[b, i:i + fh, j:j + fw, :]  # 3d tensor
                    // patch_sum = np.sum(patch * kernel[:, :, :, k], axis=(0, 1, 2))  # sum along
                    // all axis out[b, i_out, j_out, k] = patch_sum

                    // Patch Convolution
                    for (int di = 0; di < fh; di++)
                    {
                        for (int dj = 0; dj < fw; dj++)
                        {
                            int ix = i + di - fh2;
                            int jx = j + dj - fw2;
                            
                            if (!( (ix >= 0 && ix < in_h) && (jx >= 0 && jx < in_h) )) {
                                // skip computation, zero padding
                                continue;
                            }
                            // int ix = CLAMP(i + di - fh2, 0, in_h-1);
                            // int jx = CLAMP(j + dj - fw2, 0, in_w-1);

                            //CHECK(ix >= 0 && ix < in_h, "Invalid ix = %d", ix);
                            //CHECK(jx >= 0 && jx < in_w, "Invalid jx = %d", jx);

                            // log_info("ix = %d", ix);
                            // log_info("jx = %d", jx);
                            for (int q = 0; q < kin_ch; q++)
                            {
                                // log_info("[b=%d, i=%d, j=%d, k=%d, di=%d, dj=%d, ix=%d, jx=%d, q=%d]", b, i,j, k, di, dj, ix,jx, q);
                                // log_info("Data   access = [%d, %d, %d, %d]", b, ix, jx, q);
                                // log_info("kernel access = [%d, %d, %d, %d]", di, dj, q, k);
                                DATA_OUT(b, i, j, k) += DATA_IN(b, ix, jx, q) * KERNEL(di, dj, q, k);
                            }
                        }
                    }
                }
            }
        }
    }

    return;

error:
    log_err("Execution failed with errors");
}