#ifndef CHELPER_H
#define CHELPER_H
// Paper about Loop Unrolling: https://arxiv.org/pdf/1811.00624.pdf
#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include <assert.h>
#include <stdint.h>

// Uncomment Block Below to make use of SIMD Processor extensions for various architectures
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

#if _WIN32
// Do not use __restrict with windows, because of super annoying build
#define __restrict
#define restrict

#else
#ifndef __restrict
#define __restrict restrict
#endif
#endif


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

/**
 * @brief Returns the textual description for an error
 *
 * @param code
 * @return const char*
 */
const char* NNE_print_error(int code);

#define PTR_CHECK(ptr)                                                                             \
    CHECK_AND_SET(ptr != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER, "Invalid input pointer provided")


#define DATA_IN_PTR(b, i, j, ch)                                                                   \
    (data_in + ch + (in_ch * j) + (in_ch * in_w * i) + (in_ch * in_w * in_h * b))

#define DATA_IN(b, i, j, ch)                                                                       \
    *(data_in + ch + (in_ch * j) + (in_ch * in_w * i) + (in_ch * in_w * in_h * b))

#define KERNEL(di, dj, q, k)                                                                       \
    *(kernel + k + (kout_ch * q) + (kout_ch * kin_ch * dj) + (kout_ch * kin_ch * fw * di))

#define DATA_OUT(b, i, j, ch)                                                                      \
    *(data_out + ch + (out_ch * j) + (out_ch * out_w * i) + (out_ch * out_w * out_h * b))


/**
 * @brief Macro to create an array of an generic data type
 *
 * @param dtype the datatype of the array
 * @param ptr the ptr where it should be stored
 * @param dim the dimension
 */
#define CREATE_ARRAY(dtype, ptr, dim)                                                                  \
    {                                                                                                  \
        const size_t data_out_size = (dim);                                                            \
        debug("Output array elements:  %lu", data_out_size);                                           \
        debug("Output array in GB:     %g", ((double)data_out_size * sizeof(dtype)) / GIGABYTE_BYTES); \
        CHECK_AND_SET(data_out_size < MAX_MEMORY_ARRAY_SIZE, return_value, NNE_ERROR_MAX_MEMORY_LIMIT, \
                      "Trying to request %g GBs, exceeds MAX allowed %lu GBs",                         \
                      (((double)data_out_size * sizeof(float)) / GIGABYTE_BYTES),                      \
                      MAX_MEMORY_TO_ALLOCATE / GIGABYTE_BYTES)                                         \
        ptr = (dtype*)calloc(data_out_size, sizeof(dtype));                                            \
        CHECK_AND_SET(ptr != NULL, return_value, NNE_ERROR_NULL_POINTER_PARAMETER,                     \
                      "Error when allocating %lu bytes of memory", data_out_size * sizeof(dtype));     \
    }


#define CREATE_2D_ARRAY(dtype, ptr, d1, d2) CREATE_ARRAY(dtype, ptr, d1* d2)
#define CREATE_3D_ARRAY(dtype, ptr, d1, d2, d3) CREATE_ARRAY(dtype, ptr, d1* d2* d3)
#define CREATE_4D_ARRAY(dtype, ptr, d1, d2, d3, d4) CREATE_ARRAY(dtype, ptr, d1* d2* d3* d4)


// ---- Macro Definitions


#define new_relu_proto_decleration(dtype) int relu_##dtype(dtype* arr, const int DIM1)

#define new_conv_protofunc_decleration(dtype)                                                      \
    int conv2d_##dtype(const dtype* data_in, int batch, int in_h, int in_w, int in_ch,             \
                       const dtype* kernel, int fh, int fw, int kin_ch, int kout_ch, int stride,   \
                       dtype** data_out, int* batch_out, int* out_h, int* out_w, int* out_ch)


#ifdef __cplusplus
}
#endif
#endif   // CHELPER_H