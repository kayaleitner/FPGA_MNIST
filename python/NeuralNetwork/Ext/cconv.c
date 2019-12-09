#include <stdlib.h>
#include <assert.h>

#include "NNExtension.h"
#include "dbg.h"
#include "chelper.h"

int conv2d2(const float *__restrict data_in,
            int batch,
            int in_h,
            int in_w,
            int in_ch,
            const float *__restrict kernel,
            int   fh,
            int   fw,
            int   kin_ch,
            int   kout_ch,
            int   stride,
            float data_out[batch][in_h][in_w][kout_ch])
{

    // conv2d(data_in, batch, in_h, in_w, in_ch, kernel, fh, fw, kin_ch, kout_ch, stride,
    //        &data_out[0][0][0][0], batch, in_h, in_w, kout_ch);

    return 0;
}

int conv2d(const float *__restrict data_in,
           const int batch,
           const int in_h,
           const int in_w,
           const int in_ch,
           const float *__restrict kernel,
           const int fh,
           const int fw,
           const int kin_ch,
           const int kout_ch,
           const int stride,
           float **  pdata_out,
           int *     pbatch_out,
           int *     pout_h,
           int *     pout_w,
           int *     pout_ch)
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

    int return_value = 0;

    const int batch_out = batch;
    const int out_h = in_h;
    const int out_w = in_w;
    const int out_ch = kout_ch;
    const int fh2 = (int)((fh - 1) / 2);   // calculate the half filter heigth, odd filter size is assumed
    const int fw2 = (int)((fw - 1) / 2);   // calculate the half filter width, odd filter size is assumed
    float *data_out = NULL;

    // Define Multidimensional array pointers
    float(*array_in)[in_h][in_w][in_ch] = NULL;
    float(*kernel_in)[fw][in_ch][out_ch] = NULL;
    float(*array_out)[out_h][out_w][out_ch] = NULL;

    debug("data_in   = [%d, %d, %d, %d]", batch, in_h, in_w, in_ch);
    debug("kernel    = [%d, %d, %d, %d]", fh, fw, kin_ch, kout_ch);
    debug("data_out  = [%d, %d, %d, %d]", batch_out, out_h, out_w, out_ch);

    // ----- Input Checking & Error Handling

    CHECK(kin_ch == in_ch, "Dimension mismatch, number of input channels must be equal to number "
                           "of input filter weights");

    // Check if the filter has an uneven width
    CHECK_AND_SET(1 == fh % 2, return_value, NNE_ERROR_OTHER,
                  "Only odd numbers for filter size are supported. Input filter height is %d", fh);
    CHECK_AND_SET(1 == fw % 2, return_value, NNE_ERROR_OTHER,
                  "Only odd numbers for filter size are supported. Input filter width is %d", fw);


    // Check if input pointer are valid
    PTR_CHECK(pdata_out);
    PTR_CHECK(pbatch_out);
    PTR_CHECK(pout_h);
    PTR_CHECK(pout_w);
    PTR_CHECK(pout_ch);

    // Allocate memory
    CREATE_4D_ARRAY(float, data_out, batch_out, out_h, out_w, out_ch);

    *pdata_out = data_out;
    *pbatch_out = batch_out;
    *pout_h = out_h;
    *pout_w = out_w;
    *pout_ch = out_ch;

    // Assing Multi-Dim Array Pointers for easy access
    array_in = (float(*)[in_h][in_w][in_ch])data_in;
    kernel_in = (float(*)[fw][in_ch][out_ch])kernel;
    array_out = (float(*)[out_h][out_w][out_ch])data_out;


    // output[b, i, j, k] =
    //     sum_{di, dj, q} input[b, strides[1] * i + di, strides[2] * j + dj, q] *
    //                     filter[di, dj, q, k]
    for (int b = 0; b < batch; b++)
    {
        for (int k = 0; k < kout_ch; k++)
        {
            // Calculate the individual output kernel
            for (int i = 0; i < in_h; i += stride)
            {
                for (int j = 0; j < in_w; j += stride)
                {
                    // Sum up over the patch and convolve it
                    for (int di = 0; di < fh; di++)
                    {
                        for (int dj = 0; dj < fw; dj++)
                        {
                            int ix = i + di - fh2;
                            int jx = j + dj - fw2;

                            const int patch_h_start = MAX(0, i - fh2);         // goes from -1...26
                            const int patch_h_end = MIN(in_h, i - fh2 + fw);   // goes from  2...29
                            const int patch_w_start = MAX(0, j - fw2);         // goes from -1...26
                            const int patch_w_end = MIN(in_w, j - fw2 + fw);   // goes from  2...29


                            if (!((ix >= 0 && ix < in_h) && (jx >= 0 && jx < in_h)))
                            {
                                // skip computation, zero padding
                                continue;
                            }
                            // int ix = CLAMP(i + di - fh2, 0, in_h-1);
                            // int jx = CLAMP(j + dj - fw2, 0, in_w-1);

                            // CHECK(ix >= 0 && ix < in_h, "Invalid ix = %d", ix);
                            // CHECK(jx >= 0 && jx < in_w, "Invalid jx = %d", jx);

                            // log_info("ix = %d", ix);
                            // log_info("jx = %d", jx);

                            // ToDo: Further optimize by reducing array indexing inside loops
                            // const float *tmp_data_in = DATA_IN_PTR(b, ix, jx, 0);

                            float accum = 0.0;
                            for (int q = 0; q < kin_ch; q++)
                            {
                                accum += array_in[b][ix][jx][q] * kernel_in[di][dj][q][k];
                                // accum += DATA_IN(b, ix, jx, q) * KERNEL(di, dj, q, k);
                            }
                            // DATA_OUT(b, i, j, k) = accum;
                            array_out[b][i][j][k] = accum;
                        }
                    }
                }
            }
        }
    }

    return return_value;

    // Jump label in case of errors
error:
    return return_value;
}

/**
 * @brief Implementation of a convolution with a 3x3 kernel
 *
 * @param data_in tensor with shape [batch, in_h, in_w, in_ch]
 * @param batch
 * @param in_h
 * @param in_w
 * @param in_ch
 * @param kernel tensor with shape [fh, fw, kin_ch, kout_ch]
 * @param fh
 * @param fw
 * @param kin_ch
 * @param kout_ch
 * @param pdata_out pointer to tensor with shape [batch, in_h, in_w, in_ch]
 * @param pbatch_out
 * @param pout_h
 * @param pout_w
 * @param pout_ch
 * @return int
 */
int conv2d_3x3(const float *__restrict data_in,
               const int batch,
               const int in_h,
               const int in_w,
               const int in_ch,
               const float *__restrict kernel,
               const int fh,
               const int fw,
               const int kin_ch,
               const int kout_ch,
               float **  pdata_out,
               int *     pbatch_out,
               int *     pout_h,
               int *     pout_w,
               int *     pout_ch)
{

    int return_value = 0;

    const int batch_out = batch;
    const int out_h = in_h;
    const int out_w = in_w;
    const int out_ch = kout_ch;
    float *   data_out = NULL;

    // Define Multidimensional array pointers
    float(*array_in)[in_h][in_w][in_ch] = NULL;
    float(*kernel_in)[fw][in_ch][out_ch] = NULL;
    float(*array_out)[out_h][out_w][out_ch] = NULL;

    // Assing Multi-Dim Array Pointers for easy access
    array_in = (float(*)[in_h][in_w][in_ch])data_in;
    kernel_in = (float(*)[fw][in_ch][out_ch])kernel;
    array_out = (float(*)[out_h][out_w][out_ch])data_out;


    debug("data_in   = [%d, %d, %d, %d]", batch, in_h, in_w, in_ch);
    debug("kernel    = [%d, %d, %d, %d]", fh, fw, kin_ch, kout_ch);
    debug("data_out  = [%d, %d, %d, %d]", batch_out, out_h, out_w, out_ch);

    // ----- Input Checking & Error Handling
    assert(fh == 3);
    assert(fw == 3);
    assert(kin_ch == in_ch);

    // Check if input pointer are valid
    PTR_CHECK(pdata_out);
    PTR_CHECK(pbatch_out);
    PTR_CHECK(pout_h);
    PTR_CHECK(pout_w);
    PTR_CHECK(pout_ch);

    // Allocate memory
    CREATE_4D_ARRAY(float, data_out, batch_out, out_h, out_w, out_ch);

    // Assign values
    *pdata_out = data_out;
    *pbatch_out = batch_out;
    *pout_h = out_h;
    *pout_w = out_w;
    *pout_ch = out_ch;


    // First: Calculate the valid padding
    for (int b = 0; b < batch; b++)
    {
        for (int kout_ch = 0; kout_ch < out_ch; kout_ch++)
        {
            for (int i = 1; i < in_h - 1; i++)
            {
                for (int j = 1; j < in_w - 1; j++)
                {
                    for (int k = 0; k < in_ch; k++)
                    {
                        float a = 0.0;
                        a += kernel_in[0][0][k][kout_ch] * array_in[b][i - 1][j - 1][k];
                        a += kernel_in[0][1][k][kout_ch] * array_in[b][i - 1][j][k];
                        a += kernel_in[0][2][k][kout_ch] * array_in[b][i - 1][j + 1][k];
                        a += kernel_in[1][0][k][kout_ch] * array_in[b][i][j - 1][k];
                        a += kernel_in[1][1][k][kout_ch] * array_in[b][i][j][k];
                        a += kernel_in[1][2][k][kout_ch] * array_in[b][i][j + 1][k];
                        a += kernel_in[2][0][k][kout_ch] * array_in[b][i + 1][j - 1][k];
                        a += kernel_in[2][1][k][kout_ch] * array_in[b][i + 1][j][k];
                        a += kernel_in[2][2][k][kout_ch] * array_in[b][i + 1][j + 1][k];
                        array_out[b][i][j][kout_ch] = a;
                    }
                }
            }

            // Calculate Corners
            for (int k = 0; k < in_ch; k++)
            {
                const int H = in_h - 1, W = in_w - 1;

                // Corner Top Left
                array_out[b][0][0][kout_ch] += kernel_in[1][1][k][kout_ch] * array_in[b][0][0][k];
                array_out[b][0][0][kout_ch] += kernel_in[1][2][k][kout_ch] * array_in[b][0][1][k];
                array_out[b][0][0][kout_ch] += kernel_in[2][1][k][kout_ch] * array_in[b][1][0][k];
                array_out[b][0][0][kout_ch] += kernel_in[2][2][k][kout_ch] * array_in[b][1][1][k];

                // Corner Top Right
                array_out[b][0][W][kout_ch] += kernel_in[1][0][k][kout_ch] * array_in[b][0][W - 1][k];
                array_out[b][0][W][kout_ch] += kernel_in[1][1][k][kout_ch] * array_in[b][0][W][k];
                array_out[b][0][W][kout_ch] += kernel_in[2][0][k][kout_ch] * array_in[b][1][W - 1][k];
                array_out[b][0][W][kout_ch] += kernel_in[2][1][k][kout_ch] * array_in[b][1][W][k];

                // Corner Bottom Left
                array_out[b][H][0][kout_ch] += kernel_in[0][1][k][kout_ch] * array_in[b][H - 1][0][k];
                array_out[b][H][0][kout_ch] += kernel_in[0][2][k][kout_ch] * array_in[b][H - 1][1][k];
                array_out[b][H][0][kout_ch] += kernel_in[1][1][k][kout_ch] * array_in[b][H][0][k];
                array_out[b][H][0][kout_ch] += kernel_in[1][2][k][kout_ch] * array_in[b][H][1][k];

                // Corner Bottom Right
                array_out[b][H][W][kout_ch] += kernel_in[1][0][k][kout_ch] * array_in[b][H - 1][W - 1][k];
                array_out[b][H][W][kout_ch] += kernel_in[1][1][k][kout_ch] * array_in[b][H - 1][W][k];
                array_out[b][H][W][kout_ch] += kernel_in[2][0][k][kout_ch] * array_in[b][H][W - 1][k];
                array_out[b][H][W][kout_ch] += kernel_in[2][1][k][kout_ch] * array_in[b][H][W][k];
            }

            // Vertical Lines
            for (int i = 1; i < in_h - 1; i++)
            {
                const int H = in_h - 1, W = in_w - 1;
                for (int k = 0; k < in_ch; k++)
                {
                    float a_l = 0, a_r = 0;

                    // Left Side
                    a_l += kernel_in[0][1][k][kout_ch] * array_in[b][i - 1][0][k];
                    a_l += kernel_in[0][2][k][kout_ch] * array_in[b][i - 1][1][k];
                    a_l += kernel_in[1][1][k][kout_ch] * array_in[b][i][0][k];
                    a_l += kernel_in[1][2][k][kout_ch] * array_in[b][i][1][k];
                    a_l += kernel_in[2][1][k][kout_ch] * array_in[b][i + 1][0][k];
                    a_l += kernel_in[2][2][k][kout_ch] * array_in[b][i + 1][1][k];
                    array_out[b][i][0][kout_ch] = a_l;

                    // Right Side
                    a_r += kernel_in[0][0][k][kout_ch] * array_in[b][i - 1][W - 1][k];
                    a_r += kernel_in[0][1][k][kout_ch] * array_in[b][i - 1][W][k];
                    a_r += kernel_in[1][0][k][kout_ch] * array_in[b][i][W - 1][k];
                    a_r += kernel_in[1][1][k][kout_ch] * array_in[b][i][W][k];
                    a_r += kernel_in[2][0][k][kout_ch] * array_in[b][i + 1][W - 1][k];
                    a_r += kernel_in[2][1][k][kout_ch] * array_in[b][i + 1][W][k];
                    array_out[b][i][W][kout_ch] = a_r;
                }
            }

            // Horizontal Lines
            for (int i = 1; i < in_w - 1; i++)
            {
                const int H = in_h - 1, W = in_w - 1;
                for (int k = 0; k < in_ch; k++)
                {
                    float a_l = 0, a_r = 0;

                    // Top Side
                    a_l += kernel_in[1][0][k][kout_ch] * array_in[b][0][i - 1][k];
                    a_l += kernel_in[1][1][k][kout_ch] * array_in[b][0][i][k];
                    a_l += kernel_in[1][2][k][kout_ch] * array_in[b][0][i + 1][k];
                    a_l += kernel_in[2][0][k][kout_ch] * array_in[b][1][i - 1][k];
                    a_l += kernel_in[2][1][k][kout_ch] * array_in[b][1][i][k];
                    a_l += kernel_in[2][2][k][kout_ch] * array_in[b][1][i + 1][k];
                    array_out[b][0][i][kout_ch] = a_l;

                    // Bottom Side
                    a_r += kernel_in[0][0][k][kout_ch] * array_in[b][H - 1][i - 1][k];
                    a_r += kernel_in[0][1][k][kout_ch] * array_in[b][H - 1][i][k];
                    a_r += kernel_in[0][2][k][kout_ch] * array_in[b][H - 1][i + 1][k];
                    a_r += kernel_in[1][0][k][kout_ch] * array_in[b][H][i - 1][k];
                    a_r += kernel_in[1][1][k][kout_ch] * array_in[b][H][i][k];
                    a_r += kernel_in[1][2][k][kout_ch] * array_in[b][H][i + 1][k];
                    array_out[b][H][i][kout_ch] = a_r;
                }
            }
        }
    }

    return return_value;

error:
    // Clean up allocated data in case of error
    free(*pdata_out);
    *pdata_out = NULL;
    return return_value;
}
