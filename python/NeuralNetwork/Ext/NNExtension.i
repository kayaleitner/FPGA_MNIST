%module NeuralNetworkExtension
// Neural Network C Extension SWIG Wrapper File
//
// Written by: Benjamin Kulnik
// Date:       2019
//
//
// Good reference: https://www.numpy.org.cn/en/reference/swig/interface-file.html#other-situations

%pythonbegin %{
from __future__ import absolute_import
%}

%{
// This has to be declared so the %init block gets called
#define SWIG_FILE_WITH_INIT

#include "NNExtension.h"
#include "chelper.h"
#include "dbg.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

%}

/* 
* Include to support proprietary conventions from windows
* See: http://www.swig.org/Doc1.3/Windows.html
*/
%include "windows.i"

/* Include to use datatypes like int32_t */
%include "stdint.i"

/* Include  typemaps */
%include "typemaps.i"

%include "exception.i"

/* Include support for numpy */
%include "numpy.i"

%init %{
// Import Numpy Arrays
import_array();
// import_umath();
%}




// ---------------------------- Numpy Typemaps  --------------------------------
//
// This remaps the C convention for arrays (parameter pointer + dims) to a single
// parameter in python (a numpy array)
// 
// Examples: https://docs.scipy.org/doc/numpy-1.13.0/reference/swig.interface-file.html

// Support all default numeric types
// float
// double
// int8_t
// int16_t
// int32_t
// int64_t
// uint8_t
// uint16_t
// uint32_t
// uint64_t

// Map the inputs to numpy
%apply (float *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const float *data_in, int batch, int in_h, int in_w, int in_ch),
    (const float *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (double *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const double *data_in, int batch, int in_h, int in_w, int in_ch),
    (const double *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (int8_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const int8_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const int8_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (uint8_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const uint8_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const uint8_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (int16_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const int16_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const int16_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (uint16_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const uint16_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const uint16_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (int32_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const int32_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const int32_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (uint32_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const uint32_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const uint32_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (int64_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const int64_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const int64_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};
%apply (uint64_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const uint64_t *data_in, int batch, int in_h, int in_w, int in_ch),
    (const uint64_t *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};

// Typemaps for Output Arrays of Conv2D and MaxPool2D
%apply (float** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (float **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (double** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (double **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (int8_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (int8_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (int16_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (int16_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (int32_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (int32_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (int64_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (int64_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (uint8_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (uint8_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (uint16_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (uint16_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (uint32_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (uint32_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };
%apply (uint64_t** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) { (uint64_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch) };

// Typemaps for RELU_1D
%apply (float *INPLACE_ARRAY1, int DIM1) {  (float *x, int d1) };
%apply (double *INPLACE_ARRAY1, int DIM1) {  (double *x, int d1) };
%apply (int8_t *INPLACE_ARRAY1, int DIM1) {  (int8_t *x, int d1) };
%apply (int16_t *INPLACE_ARRAY1, int DIM1) {  (int16_t *x, int d1) };
%apply (int32_t *INPLACE_ARRAY1, int DIM1) {  (int32_t *x, int d1) };
%apply (int64_t *INPLACE_ARRAY1, int DIM1) {  (int64_t *x, int d1) };
%apply (uint8_t *INPLACE_ARRAY1, int DIM1) {  (uint8_t *x, int d1) };
%apply (uint16_t *INPLACE_ARRAY1, int DIM1) {  (uint16_t *x, int d1) };
%apply (uint32_t *INPLACE_ARRAY1, int DIM1) {  (uint32_t *x, int d1) };
%apply (uint64_t *INPLACE_ARRAY1, int DIM1) {  (uint64_t *x, int d1) };

// Typemaps for RELU_2D
%apply (float *INPLACE_ARRAY2, int DIM1, int DIM2) {  (float *x, int d1, int d2) };
%apply (double *INPLACE_ARRAY2, int DIM1, int DIM2) {  (double *x, int d1, int d2) };
%apply (int8_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (int8_t *x, int d1, int d2) };
%apply (int16_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (int16_t *x, int d1, int d2) };
%apply (int32_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (int32_t *x, int d1, int d2) };
%apply (int64_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (int64_t *x, int d1, int d2) };
%apply (uint8_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (uint8_t *x, int d1, int d2) };
%apply (uint16_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (uint16_t *x, int d1, int d2) };
%apply (uint32_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (uint32_t *x, int d1, int d2) };
%apply (uint64_t *INPLACE_ARRAY2, int DIM1, int DIM2) {  (uint64_t *x, int d1, int d2) };


%apply (float *INPLACE_ARRAY3, int DIM1, int DIM2, int DIM3) {  (float *x, int d1, int d2, int d3) };
%apply (float *INPLACE_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) { (float *x, int d1, int d2, int d3, int d4) };


// ------------------------------------ Error Handling ----------------------------------------
// 
// Automatically throw a python exception if the return value is not zero 
// and print an error message.
// 
// See
// https://stackoverflow.com/questions/25650761/swig-how-to-typemap-the-return-value-based-on-the-original-return-value


%typemap(out) int %{
    if($1 != 0)
        SWIG_exception(SWIG_RuntimeError,NNE_print_error($1));
    $result = Py_None;  // do not output anything
    Py_INCREF(Py_None); // Py_None is a singleton so increment its reference if used.
%}



// ------------------------------------ Wrapping ----------------------------------------
// Wrap everything declared in this header
%include "NNExtension.h"


