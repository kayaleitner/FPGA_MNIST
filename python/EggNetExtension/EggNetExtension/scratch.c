#include <stdio.h>
#include "NNExtension.h"

int main() {

    int r = conv2d_int32_t(NULL, 0,0,0,0, NULL, 0,0,0,0, 1, NULL, NULL,NULL,NULL,NULL);
    
    return r == 0;
}