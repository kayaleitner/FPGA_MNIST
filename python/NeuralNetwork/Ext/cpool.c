
#include <stdlib.h>
#include <assert.h>

#include "NNExtension.h"
#include "dbg.h"
#include "chelper.h"

/**
 * @brief Macro to perform 2x2 max pool for a specific data type
 *
 */
#define F_POOL_2x2(dtype)                                                                          \
    {                                                                                              \
        dtype a0 = DATA_IN(b, i, j, k);                                                            \
        dtype a1 = DATA_IN(b, i, j + 1, k);                                                        \
        dtype a2 = DATA_IN(b, i + 1, j, k);                                                        \
        dtype a3 = DATA_IN(b, i + 1, j + 1, k);                                                    \
                                                                                                   \
        dtype a_MAX = a0;                                                                          \
        if (a1 > a_MAX) a_MAX = a1;                                                                \
        if (a2 > a_MAX) a_MAX = a2;                                                                \
        if (a3 > a_MAX) a_MAX = a3;                                                                \
                                                                                                   \
        DATA_OUT(b, io, jo, k) = a_MAX;                                                            \
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
