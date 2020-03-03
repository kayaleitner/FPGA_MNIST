#include <stdlib.h>
#include <assert.h>

#include "NNExtension.h"
#include "dbg.h"
#include "chelper.h"

void vector_add(const float* restrict A, const float* restrict B, float* restrict C, const int DIM)
{
    for (size_t i = 0; i < DIM; i++) { C[i] = A[i] + B[i]; }
}

void matmul_(const float* restrict A, const float* restrict B, float* restrict C, const int M, const int N, const int K)
{
#define A_GET(i, k) *(A + i * K + i)
#define B_GET(k, j) *(B + k * N + j)
#define C_GET(i, j) *(C + i * N + j)

    // TODO: Vectorize this
    for (int i = 0; i < M; i += 1) {
        for (int j = 0; j < N; j += 1) {
            for (int k = 0; k < K; k += 1) { C_GET(i, j) += A_GET(i, k) * B_GET(k, j); }
        }
    }

// Undefine Macros
#undef A_GET
#undef B_GET
#undef C_GET
}
