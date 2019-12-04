%module(package="pkg1.Ext") NeuralNetworkExtension
// Neural Network C Extension SWIG Wrapper File
//
// Written by: Benjamin Kulnik
// Date:       2019
//


%pythonbegin %{
from __future__ import absolute_import
%}

%{
// This has to be declared so the %init block gets called
#define SWIG_FILE_WITH_INIT

#include "NNExtension.h"
#include <stdio.h>
#include <stdlib.h>

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
%}




// ---------------------------- Numpy Typemaps  --------------------------------
//
// This remaps the C convention for arrays (parameter pointer + dims) to a single
// parameter in python (a numpy array)
// 
// Examples: https://docs.scipy.org/doc/numpy-1.13.0/reference/swig.interface-file.html


// Map the inputs to numpy
%apply (float *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const float *data_in, int batch, int in_h, int in_w, int in_ch),
    (const float *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};

%apply (float** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) {
      (float **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch)
};


%apply (float *INPLACE_ARRAY1, int DIM1) { 
    (float *x, int d1) };
%apply (float *INPLACE_ARRAY2, int DIM1, int DIM2) { 
    (float *x, int d1, int d2) };
%apply (float *INPLACE_ARRAY3, int DIM1, int DIM2, int DIM3) { 
    (float *x, int d1, int d2, int d3) };
%apply (float *INPLACE_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) { 
    (float *x, int d1, int d2, int d3, int d4) };


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


