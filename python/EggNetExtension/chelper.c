#include "chelper.h"

const char* NNE_print_error(int code)
{
    switch (code) {
    case NNE_ERROR_MEMORY_ALLOC_FAIL: return "No memory could be allocated"; break;
    case NNE_ERROR_DIMENSION_MISMATCH: return "Input dimensions does not match"; break;
    case NNE_ERROR_NULL_POINTER_PARAMETER: return "Input parameter pointer is NULL"; break;
    default: return "An unkwon error has occured"; break;
    }
}
