#include <stdlib.h>
#include <assert.h>

#include "NNExtension.h"
#include "dbg.h"
#include "chelper.h"

void vector_add(const float * restrict A, const float * restrict B, float * restrict C, const int DIM) {

    
    for (size_t i = 0; i < DIM; i++)
    {
        C[i] = A[i] + B[i];
    }
}

void
matmul_(const float * restrict pA, const float *restrict pB, float *restrict pC, const int M, const int N, const int K)
{
    const float(*A)[K] = NULL;
    const float(*B)[N] = NULL;
    float(*C)[N] = NULL;
    A = (const float(*)[K])pA;
    B = (const float(*)[N])pB;
    C = (float(*)[N])pC;


    // TODO: Vectorize this
    for (int i = 0; i < M; i += 1)
    {
        for (int j = 0; j < N; j += 1)
        {
            for (int k = 0; k < K; k += 1)
            {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}

static void matmul_plus_bias(const float *__restrict pA,
                             const float *__restrict pB,
                             const float *__restrict pBias,
                             float *__restrict pC,
                             const int BATCH,
                             const int N,
                             const int K)
{
    const float(*A)[K] = NULL;
    const float(*B)[N] = NULL;
    const float(*bias) = NULL;
    float(*C)[N] = NULL;
    A = (const float(*)[K])pA;
    B = (const float(*)[N])pB;
    bias = (const float *)pBias;
    C = (float(*)[N])pC;


    // TODO: Vectorize this
    for (int i = 0; i < BATCH; i += 1)
    {
        for (int j = 0; j < N; j += 1)
        {
            for (int k = 0; k < K; k += 1)
            {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }

    for (int i = 0; i < BATCH; i++)
    {
        for (int j = 0; j < N; j++)
        {
            C[i][j] += bias[j];
        }
    }
}


int dense_layer(const float *__restrict weights,
                const int w_in,
                const int w_out,
                const float *__restrict X,
                const int batch,
                const int x_in,
                float **  y,
                int *     pbatch_out,
                int *     psize_out)
{


    return 0;
}


