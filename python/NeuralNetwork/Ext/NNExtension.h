#ifndef NNEXTENSION_H
#define NNEXTENSION_H

#ifdef __cplusplus
extern "C"
{
#endif


#ifndef __restrict
#define __restrict restrict
#endif

#include <stdlib.h>


    const char *NNE_print_error(int code);

    int conv2d(const float *data_in,
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
               float **     data_out,
               int *        batch_out,
               int *        out_h,
               int *        out_w,
               int *        out_ch);

    int maxPool2D(const float *data_in,
                  int          batch,
                  int          in_h,
                  int          in_w,
                  int          in_ch,
                  float **     data_out,
                  int *        batch_out,
                  int *        out_h,
                  int *        out_w,
                  int *        out_ch);


    int relu1D(float *x, int d1);
    int relu2D(float *x, int d1, int d2);
    int relu3D(float *x, int d1, int d2, int d3);
    int relu4D(float *x, int d1, int d2, int d3, int d4);

#ifdef __cplusplus
}
#endif

#endif