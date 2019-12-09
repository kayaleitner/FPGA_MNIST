#include <stdlib.h>
#include <assert.h>

#include "NNExtension.h"
#include "dbg.h"
#include "chelper.h"

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

#define BITS_OF_BYTE(n_byte) (n_byte * 8)

/**
 * @brief Allows bit manipulation of floating point types
 * This is a workaround because C does not allow bit manipulation on non-integer types.
 */
union bitfloat {
    uint32_t bits;  // the bit representation of the float value
    float    value; // the float representation of the value
};


inline float f_fast_relu(float x)
{
    union bitfloat co;
    co.value = x;
    co.bits = co.bits & (co.bits >> 31);
    return co.value;
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

        // Assign float value
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
