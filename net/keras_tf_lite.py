"""
Example from https://www.tensorflow.org/lite/performance/post_training_integer_quant
"""
import logging
import pathlib

import tensorflow as tf

logging.getLogger("tensorflow").setLevel(logging.DEBUG)
# tf.enable_v2_behavior()

from tensorflow import keras

KERAS_CONFIG_FILE = "keras/model_config.json"
KERAS_WEIGHTS_FILE = "keras/weights.h5"


def main():
    # Reload the model from the 2 files we saved
    with open(KERAS_CONFIG_FILE) as json_file:
        json_config = json_file.read()

    model = keras.models.model_from_json(json_config)
    model.load_weights(KERAS_WEIGHTS_FILE)

    mnist_train, _ = tf.keras.datasets.mnist.load_data()
    images = tf.cast(mnist_train[0], tf.float32) / 255.0
    mnist_ds = tf.data.Dataset.from_tensor_slices(images).batch(1)


    def representative_data_gen():
        for input_value in mnist_ds.take(100):
            yield [input_value]


    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    tflite_model = converter.convert()

    converter.representative_dataset = representative_data_gen
    converter.optimizations = [tf.lite.Optimize.OPTIMIZE_FOR_SIZE]
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.uint8
    converter.inference_output_type = tf.uint8

    tflite_quant_model = converter.convert()

    # https://www.tensorflow.org/lite/performance/quantization_spec

    tflite_models_dir = pathlib.Path("tflite/")
    tflite_model_file = tflite_models_dir / "mnist_model.tflite"
    tflite_model_quant_file = tflite_models_dir / "mnist_model_quant_io.tflite"

    tflite_models_dir.mkdir(exist_ok=True, parents=True)
    tflite_model_file.write_bytes(tflite_model)
    tflite_model_quant_file.write_bytes(tflite_quant_model)


    # Test the quantised model
    interpreter = tf.lite.Interpreter(model_path=str(tflite_model_file))
    interpreter.allocate_tensors()
    interpreter_quant = tf.lite.Interpreter(model_path=str(tflite_model_quant_file))
    interpreter_quant.allocate_tensors()
    input_index_quant = interpreter_quant.get_input_details()[0]["index"]
    output_index_quant = interpreter_quant.get_output_details()[0]["index"]


if __name__ == '__main__':
    main()