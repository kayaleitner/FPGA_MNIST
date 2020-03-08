/**
 * @file eggnet.i
 * 
 * @author Benjamin Kulnik 
 * @brief An SWIG Interface file for the EGG API
 * @version 0.1
 * @date 2020-01-10
 * 
 * @copyright Copyright (c) The Egg Coders 2020
 * 
 */


/* Defines the name of the (python) module */
%module EggNetDriverCore


%{
    #define SWIG_FILE_WITH_INIT // This has to be declared so the %init block gets called
    #include "eggnet.h"
    #include <stdio.h>
    #include <stdlib.h>
%}

/* 
* Include to support proprietary conventions from windows
* See: http://www.swig.org/Doc1.3/Windows.html
*/
// %include "windows.i"

/* Include to use datatypes like int32_t */
%include "stdint.i"

/* Include  typemaps */
%include "typemaps.i"

/* Include exception handling */
%include "exception.i"

/* Include support for numpy */
%include "numpy.i"

/* turn on director wrapping Callback */
%feature("director") EggCallback;

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


// this transforms an the following C parameters to a single numpy array parameter in python.
%apply (uint8_t *IN_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) {
    (const uint8_t *image_buffer, int batch, int in_h, int in_w, int in_ch),
    (const uint8_t *image_buffer, int batch, int height, int width, int channels),
    (const float *kernel,  int fh, int fw, int kin_ch, int kout_ch)
};

// this transforms an the following C parameters to a single numpy array RETURN parameter in python.
// memory has to be allocated manually but will be freed from Numpy/Python automatically
%apply (uint8_t** ARGOUTVIEW_ARRAY4, int *DIM1, int *DIM2, int *DIM3, int *DIM4) {
      (uint8_t **data_out, int *batch_out, int *out_h, int *out_w, int *out_ch)    
};

%apply (int** ARGOUTVIEW_ARRAY2, int *DIM1, int *DIM2) {
    (int **results, int *batch_out, int *n)
};

%apply (uint8_t *ARGOUT_ARRAY1[ANY]) {
    (uint8_t results[batch])
};

// Inplace array typemaps
// %apply (float *INPLACE_ARRAY1, int DIM1) { 
//     (float *x, int d1) };
// %apply (float *INPLACE_ARRAY2, int DIM1, int DIM2) { 
//     (float *x, int d1, int d2) };
// %apply (float *INPLACE_ARRAY3, int DIM1, int DIM2, int DIM3) { 
//     (float *x, int d1, int d2, int d3) };
// %apply (float *INPLACE_ARRAY4, int DIM1, int DIM2, int DIM3, int DIM4) { 
//     (float *x, int d1, int d2, int d3, int d4) };


// ------------------------------------ Error Handling ----------------------------------------
// 
// Automatically throw a python exception if the return value is not zero 
// and print an error message.
// 
// See
// https://stackoverflow.com/questions/25650761/swig-how-to-typemap-the-return-value-based-on-the-original-return-value


%typemap(ret) egg_error_t %{
    // Apply a typemap to every function that has egg_error_t as a return value
    // Check if it is 0 (no error) or otherwise trigger an exception in Python
    if($1 != EGG_ERROR_NONE) {
        SWIG_exception(SWIG_RuntimeError, egg_print_err($1));
    }
    $result = Py_None;  // do not output anything
    Py_INCREF(Py_None); // Py_None is a singleton so increment its reference if used.
%}


// Remove leading egg_ prefixes
%rename("%(strip:[egg_])s") "";

// ------------------------------------ Wrapping ----------------------------------------
// Wrap everything declared in this header
// Alternativly all functions could here be specified manually
%include "eggnet.h"


