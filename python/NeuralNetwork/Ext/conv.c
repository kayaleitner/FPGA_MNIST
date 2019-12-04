#include "NNExtension.h"
#include "dbg.h"
#include <stdlib.h>

#if defined(_MSC_VER)
/* Microsoft C/C++-compatible compiler */
#include <intrin.h>
#elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__))
/* GCC-compatible compiler, targeting x86/x86-64 */
#include <x86intrin.h>
#elif defined(__GNUC__) && defined(__ARM_NEON__)
/* GCC-compatible compiler, targeting ARM with NEON */
#include <arm_neon.h>
#elif defined(__GNUC__) && defined(__IWMMXT__)
/* GCC-compatible compiler, targeting ARM with WMMX */
#include <mmintrin.h>
#elif (defined(__GNUC__) || defined(__xlC__)) && (defined(__VEC__) || defined(__ALTIVEC__))
/* XLC or GCC-compatible compiler, targeting PowerPC with VMX/VSX */
#include <altivec.h>
#elif defined(__GNUC__) && defined(__SPE__)
/* GCC-compatible compiler, targeting PowerPC with SPE */
#include <spe.h>
#endif


#ifndef min
#define min(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef max
#define max(a, b) ((a) < (b) ? (b) : (a))
#endif

#define CLAMP(x, a, b) (min(b, max(a, x)))

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
           int batch,
           int in_h,
           int in_w,
           int in_ch,
           const float *__restrict kernel,
           int     fh,
           int     fw,
           int     kin_ch,
           int     kout_ch,
           int     stride,
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
    const int fh2 = (int)((fh - 1) / 2);
    const int fw2 = (int)((fw - 1) / 2);
    float *   data_out = NULL;

    debug("data_in   = [%d, %d, %d, %d]", batch, in_h, in_w, in_ch);
    debug("kernel    = [%d, %d, %d, %d]", fh, fw, kin_ch, kout_ch);
    debug("data_out  = [%d, %d, %d, %d]", batch_out, out_h, out_w, out_ch);


    // Find the midpoint of the filter. This only works for odd filter sizes
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
                  "Trying to request %g GBs, exceeds max allowed %lu GBs",
                  (((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES), MAX_MEMORY_TO_ALLOCATE / GIGABYTE_BYTES)


    data_out = (float *)calloc(data_out_size, sizeof(float));
    CHECK_AND_SET(data_out != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,
                  "Error when allocating %lu bytes of memory", data_out_size * sizeof(float));


    *pdata_out = data_out;
    *pbatch_out = batch_out;
    *pout_h = out_h;
    *pout_w = out_w;
    *pout_ch = out_ch;


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

                            const float *tmp_data_in = DATA_IN_PTR(b, ix, jx, 0);
                            float        accum = 0.0;

#pragma clang loop vectorize(enable)
                            for (int q = 0; q < kin_ch; q++)
                            {
                                // log_info("[b=%d, i=%d, j=%d, k=%d, di=%d, dj=%d, ix=%d, jx=%d, q=%d]", b, i,j, k, di, dj, ix,jx, q);
                                // log_info("Data   access = [%d, %d, %d, %d]", b, ix, jx, q);
                                // log_info("kernel access = [%d, %d, %d, %d]", di, dj, q, k);
                                accum += tmp_data_in[q] * KERNEL(di, dj, q, k);
                            }
                            DATA_OUT(b, i, j, k) = accum;
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


int maxPool2D(const float *data_in,
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
                  "Trying to request %g GBs, exceeds max allowed %lu GBs",
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

                    float a_max = a0;
                    if (a1 > a_max) a_max = a1;
                    if (a2 > a_max) a_max = a2;
                    if (a3 > a_max) a_max = a3;

                    DATA_OUT(b, io, jo, k) = a_max;
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
    size_t N = DIM1 * DIM2 * DIM3 * DIM4;
#pragma clang loop vectorize(enable) interleave(enable)
    for (size_t i = 0; i < N; i++)
    {
        x[i] = F_RELU(x[i]);
    }
    return 0;
}