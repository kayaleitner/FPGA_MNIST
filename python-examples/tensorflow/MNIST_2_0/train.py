import os

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.layers import Dense, Conv2D, Flatten, MaxPooling2D, Reshape

"""
Tensorflow example for creating a MNIST image classification model with keras

See: https://www.tensorflow.org/tutorials/images/classification
See: https://www.tensorflow.org/guide/keras/save_and_serialize


ToDo: Extract the weights and store them in a non-binary format
ToDo: Add Dropout to the network to further improve performance

"""

mnist = tf.keras.datasets.mnist

IMG_HEIGHT = 28
IMG_WIDTH = 28

(x_train, y_train), (x_test, y_test) = mnist.load_data()
x_train, x_test = x_train / 255.0, x_test / 255.0

model = tf.keras.models.Sequential([
    Reshape((IMG_HEIGHT, IMG_WIDTH, 1), input_shape=(IMG_HEIGHT, IMG_WIDTH)),
    Conv2D(16, 3, padding='same', activation='relu'),
    MaxPooling2D(),
    Conv2D(32, 3,  padding='same', activation='relu'),
    MaxPooling2D(),
    Conv2D(64, 3,  padding='same', activation='relu'),
    MaxPooling2D(),
    Flatten(),
    Dense(128, activation='relu'),
    Dense(10, activation='softmax')
])

# You must install pydot and graphviz for `pydotprint` to work.
# keras.utils.plot_model(model, 'multi_input_and_output_model.png', show_shapes=True)

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])




# Display the model's architecture
model.summary()
checkpoint_path = "training_1/cp.ckpt"
checkpoint_dir = os.path.dirname(checkpoint_path)

# Create a callback that saves the model's weights
cp_callback = tf.keras.callbacks.ModelCheckpoint(filepath=checkpoint_path,
                                                 save_weights_only=True,
                                                 verbose=1)


if os.path.exists(checkpoint_dir):


    # Reload the model from the 2 files we saved
    with open('training_1/model_config.json') as json_file:
        json_config = json_file.read()
    new_model = keras.models.model_from_json(json_config)
    new_model.load_weights('training_1/weights.h5')




else:
    model.fit(x_train, y_train, epochs=10, callbacks=[cp_callback])

    # Save JSON config to disk
    json_config = model.to_json()
    with open('training_1/model_config.json', 'w') as json_file:
        json_file.write(json_config)
    # Save weights to disk
    model.save_weights('training_1/weights.h5')

model.evaluate(x_test, y_test, verbose=2)
