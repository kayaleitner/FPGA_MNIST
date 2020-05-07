# VHDL Notation

## Folder Structure

```text

|- run.py
|- generate_mif.py
|- Dockerfile
|- requirements.txt
|- src/
|   |-Common/
|   |    -File1
|   |    -File2
|   |-Conv_Channel/
|- sim/
    |-Conv/

```

## Paramter (From MIF Files)

| Parameter                     | Description                                                                                                   |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `WEIGHT_SHIFT_VALUES`         | Weights for shifting, first bit is sign bit. Width is specified as a generic                                  |
| `WEIGHT_VALUES`               | Weights for multiplicative weights, first bit is sign bit. Width is specified as a generic                    |
| `BIAS_VALUES`                 | Weights for additive weights, first bit is sign bit. Width is specified as a generic                          |
| `ACTIVATION_OUTPUT_MAX_VALUE` | **NOT USED** (Infered by `ACTIVATION_OUTPUT_BITS`) The maximum allowed output value for the output activation |
| `ACTIVATION_OUTPUT_MIN_VALUE` | **NOT USED** (always 0) The minimum allowed output value for the output activation                            |

## Generic Parameter (most used)

| Parameter                         | Description                                                                        |
| --------------------------------- | ---------------------------------------------------------------------------------- |
| `ACTIVATION_INPUT_WIDTH_BITS`     | Bit-Width of input activations                                                     |
| `ACTIVATION_OUTPUT_WIDTH_BITS`    | Bit-Width of output activations                                                    |
| `ACTIVATION_OUTPUT_SHIFT`         | Value, for which the output after the operation should be shifted                  |
| `ACTIVATION_OUTPUT_KERNEL_SHIFT`  | Value, for which the output value after the 3x3 kernel operation should be shifted |
| `ACTIVATION_OUTPUT_CHANNEL_SHIFT` | Value, for which the output after the operation should be shifted                  |
| `WEIGHT_WIDTH_BITS`               | Bit-Width of the (multiplication) weights without signbit                          |
| `WEIGHT_SHIFT_WIDTH_BITS`         | Bit-Width of the (multiplication) shift weights                                    |
| `BIAS_WIDTH_BITS`                 | Bit-Width of the (additive) weights                                                |

## Input Parameter Layer Interface

| Parameter   | Direction | Type                                 | Description |
| ----------- | --------- | ------------------------------------ | ----------- |
| `clk_i`     | `in`      | `std_logic`                          |
| `rst_i`     | `in`      | `std_logic`                          |
| `valid_i`   | `in`      | `std_logic`                          |
| `valid_o`   | `out`     | `std_logic`                          |
| `m_ready_i` | `in`      | `std_logic`                          |
| `s_ready_o` | `out`     | `std_logic`                          |
| `x_i`       | `in`      | `channel_vector_t(N_CHANNELS)(BITS)` |
| `y_o`       | `out`     | `channel_vector_t(N_CHANNELS)(BITS)` |
