%module NeuralNetworkExtension

%{
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

/* Include support for numpy */
%include "numpy.i"

%init %{

/**
 * Import Numpy Arrays
 */
import_array();

%}





/**
 * Numpy Typemaps 
 * 
 * See: https://docs.scipy.org/doc/numpy-1.13.0/reference/swig.interface-file.html
 * 
 */



// Map the inputs to numpy
%apply (float *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const float *data_in, int batch, int in_h, int in_w, int in_ch),
    (const float *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};


%apply (float** ARGOUTVIEWM_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) {
      (float **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch)
};



%include "NNExtension.h"






