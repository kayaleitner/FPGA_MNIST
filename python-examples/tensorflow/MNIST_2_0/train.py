import os

USE_AMD_GPU = True

if USE_AMD_GPU:
    # Switch the backend
    # Be sure to install 'plaidml-keras'
    # and run the 'plaidml-setup'
    #
    # https://www.varokas.com/keras-with-gpu-on-plaidml/
    os.environ["KERAS_BACKEND"] = "plaidml.keras.backend"


import keras
import keras.datasets
import keras.layers
from keras.layers import Dense, Conv2D, Flatten, MaxPooling2D, Reshape, Dropout


"""
Tensorflow example for creating a MNIST image classification model with Keras

See: https://www.tensorflow.org/tutorials/images/classification
See: https://www.tensorflow.org/guide/keras/save_and_serialize

ToDo: Extract the weights and store them in a non-binary format
"""

mnist = keras.datasets.mnist

IMG_HEIGHT = 28
IMG_WIDTH = 28

(x_train, y_train), (x_test, y_test) = mnist.load_data()
x_train, x_test = x_train / 255.0, x_test / 255.0

model = keras.models.Sequential([
    Reshape((IMG_HEIGHT, IMG_WIDTH, 1), input_shape=(IMG_HEIGHT, IMG_WIDTH)),
    Conv2D(16, 5, padding='same', activation='relu', use_bias=True),  # 3x3x4 filter
    Dropout(0.2),
    MaxPooling2D(),
    Conv2D(32, 5, padding='same', activation='relu', use_bias=True),  # 3x3x8 filter
    Dropout(0.2),
    MaxPooling2D(),
    Conv2D(64, 5, padding='valid', activation='relu', use_bias=True),  # 3x3x8 filter
    Dropout(0.2),
    Flatten(),
    Dense(32, activation='relu'),
    Dropout(0.2),
    Dense(10, activation='softmax')
])

# loss: 0.0341 - accuracy: 0.9787
# loss: 0.0326 - accuracy: 0.9825

# You must install pydot and graphviz for `pydotprint` to work.
keras.utils.plot_model(model, 'multi_input_and_output_model.png', show_shapes=True)

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

# Display the model's architecture
model.summary()
checkpoint_path = "training_1/cp.ckpt"
checkpoint_dir = os.path.dirname(checkpoint_path)

# Create a callback that saves the model's weights
cp_callback = keras.callbacks.ModelCheckpoint(filepath=checkpoint_path,
                                              save_weights_only=True,
                                              verbose=1)

# For higher GPU Utilization it is useful to increase batch_size but this can slow down training
model.fit(x_train, y_train, epochs=10, batch_size=200, validation_split=0.1, callbacks=[cp_callback])


# Save JSON config to disk
json_config = model.to_json()
with open('training_1/model_config.json', 'w') as json_file:
    json_file.write(json_config)

# Save weights in binary to disk
model.save_weights('training_1/weights.h5')

model.evaluate(x_test, y_test, verbose=2)
