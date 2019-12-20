#ifndef NNEXTENSION_H
#define NNEXTENSION_H

#ifdef __cplusplus
extern "C" {
#endif

#include "chelper.h"
#include <stdint.h>
#include <stdlib.h>


// new_relu_proto_decleration(float);
// new_relu_proto_decleration(double);
// new_relu_proto_decleration(int8_t);
// new_relu_proto_decleration(int16_t);
// new_relu_proto_decleration(int32_t);
// new_relu_proto_decleration(int64_t);
// new_relu_proto_decleration(uint8_t);
// new_relu_proto_decleration(uint16_t);
// new_relu_proto_decleration(uint32_t);
// new_relu_proto_decleration(uint64_t);


// new_conv_protofunc_decleration(float);
// new_conv_protofunc_decleration(double);
// new_conv_protofunc_decleration(int8_t);
// new_conv_protofunc_decleration(int16_t);
// new_conv_protofunc_decleration(int32_t);
// new_conv_protofunc_decleration(int64_t);
// new_conv_protofunc_decleration(uint8_t);
// new_conv_protofunc_decleration(uint16_t);
// new_conv_protofunc_decleration(uint32_t);
// new_conv_protofunc_decleration(uint64_t);



int relu_float(float* x, int d1);
int relu_double(double* x, int d1);
int relu_int8_t(int8_t* x, int d1);
int relu_int16_t(int16_t* x, int d1);
int relu_int32_t(int32_t* x, int d1);
int relu_int64_t(int64_t* x, int d1);
int relu_uint8_t(uint8_t* x, int d1);
int relu_uint16_t(uint16_t* x, int d1);
int relu_uint32_t(uint32_t* x, int d1);
int relu_uint64_t(uint64_t* x, int d1);

int conv2d_float(const float*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const float*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, float** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_double(const double*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const double*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, double** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_int8_t(const int8_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const int8_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, int8_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_int16_t(const int16_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const int16_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, int16_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_int32_t(const int32_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const int32_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, int32_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_int64_t(const int64_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const int64_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, int64_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_uint8_t(const uint8_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const uint8_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, uint8_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_uint16_t(const uint16_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const uint16_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, uint16_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_uint32_t(const uint32_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const uint32_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, uint32_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);
int conv2d_uint64_t(const uint64_t*  data_in, const int batch, const int in_h, const int in_w, const int in_ch, const uint64_t*  kernel, const int fh, const int fw, const int kin_ch, const int kout_ch, const int stride, uint64_t** pdata_out, int* pbatch_out, int* pout_h, int* pout_w, int* pout_ch);



const char* NNE_print_error(int code);

int conv2d(const float* data_in,
           int          batch,
           int          in_h,
           int          in_w,
           int          in_ch,
           const float* kernel,
           int          fh,
           int          fw,
           int          kin_ch,
           int          kout_ch,
           int          stride,
           float**      data_out,
           int*         batch_out,
           int*         out_h,
           int*         out_w,
           int*         out_ch);

int conv2d_3x3(const float* data_in,
               int          batch,
               int          in_h,
               int          in_w,
               int          in_ch,
               const float* kernel,
               int          fh,
               int          fw,
               int          kin_ch,
               int          kout_ch,
               float**      data_out,
               int*         batch_out,
               int*         out_h,
               int*         out_w,
               int*         out_ch);

int maxPool2D(const float* data_in,
              int          batch,
              int          in_h,
              int          in_w,
              int          in_ch,
              float**      data_out,
              int*         batch_out,
              int*         out_h,
              int*         out_w,
              int*         out_ch);


int relu1D(float* x, int d1);
int relu2D(float* x, int d1, int d2);
int relu3D(float* x, int d1, int d2, int d3);
int relu4D(float* x, int d1, int d2, int d3, int d4);

#ifdef __cplusplus
}
#endif

#endif