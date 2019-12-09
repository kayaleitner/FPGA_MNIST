#include <stdlib.h>
#include <assert.h>

#include "NNExtension.h"
#include "dbg.h"

// Paper about Loop Unrolling: https://arxiv.org/pdf/1811.00624.pdf


// Uncomment Block Below to make use of SIMD Processor extensions for various architectures
// #if defined(_MSC_VER)
// /* Microsoft C/C++-compatible compiler */
// #include <intrin.h>
// #elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__))
// /* GCC-compatible compiler, targeting x86/x86-64 */
// #include <x86intrin.h>
// #elif defined(__GNUC__) && defined(__ARM_NEON__)
// /* GCC-compatible compiler, targeting ARM with NEON */
// #include <arm_neon.h>
// #elif defined(__GNUC__) && defined(__IWMMXT__)
// /* GCC-compatible compiler, targeting ARM with WMMX */
// #include <mmintrin.h>
// #elif (defined(__GNUC__) || defined(__xlC__)) && (defined(__VEC__) || defined(__ALTIVEC__))
// /* XLC or GCC-compatible compiler, targeting PowerPC with VMX/VSX */
// #include <altivec.h>
// #elif defined(__GNUC__) && defined(__SPE__)
// /* GCC-compatible compiler, targeting PowerPC with SPE */
// #include <spe.h>
// #endif




#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef MAX
#define MAX(a, b) ((a) < (b) ? (b) : (a))
#endif

#define CLAMP(x, a, b) (MIN(b, MAX(a, x)))

#define GIGABYTE_BYTES (1024ul * 1024ul * 1024ul)
#define MAX_MEMORY_TO_ALLOCATE (2ul * 1024ul * 1024ul * 1024ul)   // = 2GB
#define MAX_MEMORY_ARRAY_SIZE (MAX_MEMORY_TO_ALLOCATE / sizeof(float))

#define NNE_ERROR_MEMORY_ALLOC_FAIL (-1)
#define NNE_ERROR_DIMENSION_MISMATCH (-2)
#define NNE_ERROR_NULL_POINTER_PARAMETER (-3)
#define NNE_ERROR_MAX_MEMORY_LIMIT (-4)
#define NNE_ERROR_OTHER (-5)


const char *NNE_print_error(int code)
{
    switch (code)
    {
    case NNE_ERROR_MEMORY_ALLOC_FAIL: return "No memory could be allocated"; break;
    case NNE_ERROR_DIMENSION_MISMATCH: return "Input dimensions does not match"; break;
    case NNE_ERROR_NULL_POINTER_PARAMETER: return "Input parameter pointer is NULL"; break;
    default: return "An unkwon error has occured"; break;
    }
}


#define ARRAY_4D_GET(arr, dim1, dim2, dim3, dim4, i, j, k, l) \\
    (arr + l + dim4*k + dim3*dim4*

#define DATA_IN_PTR(b, i, j, ch)                                                                   \
    (data_in + ch + (in_ch * j) + (in_ch * in_w * i) + (in_ch * in_w * in_h * b))

#define DATA_IN(b, i, j, ch)                                                                       \
    *(data_in + ch + (in_ch * j) + (in_ch * in_w * i) + (in_ch * in_w * in_h * b))

#define KERNEL(di, dj, q, k)                                                                       \
    *(kernel + k + (kout_ch * q) + (kout_ch * kin_ch * dj) + (kout_ch * kin_ch * fw * di))

#define DATA_OUT(b, i, j, ch)                                                                      \
    *(data_out + ch + (out_ch * j) + (out_ch * out_w * i) + (out_ch * out_w * out_h * b))


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
           const int     fh,
           const int     fw,
           const int     kin_ch,
           const int     kout_ch,
           const int     stride,
           float **pdata_out,
           int *   pbatch_out,
           int *   pout_h,
           int *   pout_w,
           int *   pout_ch)
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
    CHECK_AND_SET(pdata_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pbatch_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,
                  "Invalid input pointer provided");
    CHECK_AND_SET(pout_h != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pout_w != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pout_ch != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");

    // Allocate memory and check if the array size is reasonable
    const unsigned long data_out_size = batch_out * out_h * out_w * out_ch;
    debug("Output array elements:  %lu", data_out_size);
    debug("Output array in GB:     %g", ((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES);
    CHECK_AND_SET(data_out_size < MAX_MEMORY_ARRAY_SIZE, return_value, NNE_ERROR_MAX_MEMORY_LIMIT,
                  "Trying to request %g GBs, exceeds MAX allowed %lu GBs",
                  (((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES), MAX_MEMORY_TO_ALLOCATE / GIGABYTE_BYTES)

    data_out = (float *)calloc(data_out_size, sizeof(float));
    CHECK_AND_SET(data_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,
                  "Error when allocating %lu bytes of memory", data_out_size * sizeof(float));

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
    CHECK_AND_SET(pdata_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pbatch_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,
                  "Invalid input pointer provided");
    CHECK_AND_SET(pout_h != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pout_w != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pout_ch != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");

    // Allocate memory and check if the array size is reasonable
    const unsigned long data_out_size = batch_out * out_h * out_w * out_ch;
    debug("Output array elements:  %lu", data_out_size);
    debug("Output array in GB:     %g", ((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES);
    CHECK_AND_SET(data_out_size < MAX_MEMORY_ARRAY_SIZE, return_value, NNE_ERROR_MAX_MEMORY_LIMIT,
                  "Trying to request %g GBs, exceeds MAX allowed %lu GBs",
                  (((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES), MAX_MEMORY_TO_ALLOCATE / GIGABYTE_BYTES)

    data_out = (float *)calloc(data_out_size, sizeof(float));
    CHECK_AND_SET(data_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,
                  "Error when allocating %lu bytes of memory", data_out_size * sizeof(float));

    *pdata_out = data_out;
    *pbatch_out = batch_out;
    *pout_h = out_h;
    *pout_w = out_w;
    *pout_ch = out_ch;

    // Assing Multi-Dim Array Pointers for easy access
    array_in = (float(*)[in_h][in_w][in_ch])data_in;
    kernel_in = (float(*)[fw][in_ch][out_ch])kernel;
    array_out = (float(*)[out_h][out_w][out_ch])data_out;


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
                
                #pragma clang loop vectorize(enable) interleave(enable)
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


static void matmul_(float * __restrict pA, float * __restrict pB, float * __restrict pC, const int M, const int N, const int K) {

    // float(*array_in)[in_h][in_w][in_ch] = NULL;
    // float(*kernel_in)[fw][in_ch][out_ch] = NULL;
    // float(*array_out)[out_h][out_w][out_ch] = NULL;

    // array_in = (float(*)[in_h][in_w][in_ch])data_in;
    // kernel_in = (float(*)[fw][in_ch][out_ch])kernel;
    // array_out = (float(*)[out_h][out_w][out_ch])data_out;


    float (*A)[M][K] = (float (*)[M][K]) pA;
    float (*B)[K][N] = (float (*)[K][N]) pB;
    float (*C)[M][N] = (float (*)[M][N]) pC;

    #pragma clang loop id(i)
    for (int i = 0; i < M; i+=1) 
        #pragma clang loop id(j)
        for (int j = 0; j < N; j+=1)
            #pragma clang loop id(k)
            for (int k = 0; k < K; k+=1) 
                C[i][j] += A[i][k] * B[k][j];

    
}

int MAXPool2D(const float *data_in,
              int          batch,
              int          in_h,
              int          in_w,
              int          in_ch,
              float **     pdata_out,
              int *        pbatch_out,
              int *        pout_h,
              int *        pout_w,
              int *        pout_ch)
{
    int return_value = 0;

    float *   data_out = NULL;
    const int batch_out = batch;
    const int out_h = in_h / 2;
    const int out_w = in_w / 2;
    const int out_ch = in_ch;

    debug("data_in   = [%d, %d, %d, %d]", batch, in_h, in_w, in_ch);
    debug("data_out  = [%d, %d, %d, %d]", batch_out, out_h, out_w, out_ch);

    // Check input pointers
    CHECK_AND_SET(pdata_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pbatch_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,
                  "Invalid input pointer provided");
    CHECK_AND_SET(pout_h != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pout_w != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");
    CHECK_AND_SET(pout_ch != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided");

    // Allocate memory
    const unsigned long data_out_size = batch_out * out_h * out_w * out_ch;
    debug("Output array elements:  %lu", data_out_size);
    debug("Output array in GB:     %g", ((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES);
    CHECK_AND_SET(data_out_size < MAX_MEMORY_ARRAY_SIZE, return_value, NNE_ERROR_MAX_MEMORY_LIMIT,
                  "Trying to request %g GBs, exceeds MAX allowed %lu GBs",
                  (((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES), MAX_MEMORY_TO_ALLOCATE / GIGABYTE_BYTES)

    data_out = (float *)calloc(data_out_size, sizeof(float));
    CHECK_AND_SET(data_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,
                  "Error when allocating %lu bytes of memory", data_out_size * sizeof(float));


    *pdata_out = data_out;
    *pbatch_out = batch_out;
    *pout_h = out_h;
    *pout_w = out_w;
    *pout_ch = out_ch;

    for (int b = 0; b < batch; b++)
    {
        int io = 0;
        int jo = 0;
        for (int i = 0; i < in_h; i += 2)
        {
            for (int j = 0; j < in_w; j += 2)
            {
#pragma clang loop unroll(enable)
                for (int k = 0; k < in_ch; k++)
                {
                    float a0 = DATA_IN(b, i, j, k);
                    float a1 = DATA_IN(b, i, j + 1, k);
                    float a2 = DATA_IN(b, i + 1, j, k);
                    float a3 = DATA_IN(b, i + 1, j + 1, k);

                    float a_MAX = a0;
                    if (a1 > a_MAX) a_MAX = a1;
                    if (a2 > a_MAX) a_MAX = a2;
                    if (a3 > a_MAX) a_MAX = a3;

                    DATA_OUT(b, io, jo, k) = a_MAX;
                }
                jo++;
            }
            io++;
            jo = 0;
        }
    }
    return return_value;

    // Jump label to skip calculation in case of errors
error:
    return return_value;
}

// y = x >>> 31
// abs(x) = (x XOR y) - y

// Define Branchless RELU
// y = x >>> 31
// y = 0xFFFF if x is positive
// y = 0x0000 if x is negative
// See: https://stackoverflow.com/questions/2639173/x86-assembly-abs-implementation
#define relu_float_fast(x) ((x) & ((x) >> 31))


#define F_RELU(x) (x > 0.0 ? x : 0)
inline float f_relu(float x) { return x > 0.0 ? x : 0.0; }

inline float f_fast_relu(float x)
{

    union conv {
        uint32_t n;
        float    f;
    };

    union conv co;

    co.f = x;
    co.n = co.n & (co.n >> 31);
    return co.f;
}

int relu1D(float *x, const int DIM1)
{
    union bitfloat {
        uint32_t bits;
        float    value;
    };

#pragma clang loop vectorize(enable) interleave(enable)
    for (int i = 0; i < DIM1; i++)
    {
        union bitfloat bf;
        bf.value = x[i];   // copy value

        // twiggle bits
        bf.bits = bf.bits & (bf.bits >> 31);

        //
        x[i] = bf.value;
    }
    return 0;
}

int relu2D(float *x, const int DIM1, const int DIM2)
{
#pragma clang loop vectorize(enable)
    for (int i = 0; i < DIM1 * DIM2; i++)
    {
        x[i] = F_RELU(x[i]);
    }
    return 0;
}

int relu3D(float *x, const int DIM1, const int DIM2, const int DIM3)
{
#pragma clang loop vectorize(enable) interleave(enable)
    for (int i = 0; i < DIM1 * DIM2 * DIM3; i++)
    {
        x[i] = F_RELU(x[i]);
    }
    return 0;
}
int relu4D(float *x, const int DIM1, const int DIM2, const int DIM3, const int DIM4)
{
    const size_t N = DIM1 * DIM2 * DIM3 * DIM4;
#pragma clang loop vectorize(enable) interleave(enable)
    for (size_t i = 0; i < N; i++)
    {
        x[i] = F_RELU(x[i]);
    }
    return 0;
}
