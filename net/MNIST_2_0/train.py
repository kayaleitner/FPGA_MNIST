#!/usr/bin/env python3


from __future__ import print_function

import os
import platform
import time
import matplotlib

matplotlib.use('TkAgg')  # to get rid of runtime error
import matplotlib.pyplot as plt
import numpy as np

# Check if the code runs on Mac (which almost all modern ones have AMD GPUs)
if platform.system() == 'Darwin':
    USE_AMD_GPU = False
else:
    USE_AMD_GPU = False

if USE_AMD_GPU:
    # Switch the backend
    # Be sure to install 'plaidml-keras'
    # and run the 'plaidml-setup'
    #
    # https://www.varokas.com/keras-with-gpu-on-plaidml/
    os.environ["KERAS_BACKEND"] = "plaidml.keras.backend"
    import keras
    from keras.models import Sequential
    from keras.layers import Dense, Conv2D, Flatten, MaxPooling2D, Reshape, Dropout, BatchNormalization, ReLU
else:
    import tensorflow.keras as keras
    from tensorflow.keras.models import Sequential
    from tensorflow.keras.layers import Dense, Conv2D, Flatten, MaxPooling2D, Reshape, Dropout, BatchNormalization, ReLU

"""
Tensorflow example for creating a MNIST image classification model with Keras

See: https://www.tensorflow.org/tutorials/images/classification
See: https://www.tensorflow.org/guide/keras/save_and_serialize

"""


IMG_HEIGHT = 28
IMG_WIDTH = 28

(x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
x_train, x_test = x_train / 255.0, x_test / 255.0

model = keras.models.Sequential([
    BatchNormalization(axis=[-1, -2], input_shape=(IMG_HEIGHT, IMG_WIDTH)),
    Reshape((IMG_HEIGHT, IMG_WIDTH, 1)),
    Conv2D(16, 5, padding='same', activation='linear', use_bias=True),  # 3x3x4 filter
    BatchNormalization(axis=-1),
    ReLU(),
    Dropout(0.2),
    MaxPooling2D(),
    Conv2D(32, 5, padding='same', activation='linear', use_bias=True),  # 3x3x8 filter
    BatchNormalization(axis=-1),
    ReLU(),
    Dropout(0.2),
    MaxPooling2D(),
    Flatten(),
    Dense(32, activation='linear'),
    BatchNormalization(axis=-1),
    Dropout(0.2),
    Dense(10, activation='softmax')
])

# loss: 0.0341 - accuracy: 0.9787
# loss: 0.0326 - accuracy: 0.9825

# You must install pydot and graphviz for `pydotprint` to work.
# keras.utils.plot_model(model, 'multi_input_and_output_model.png', show_shapes=True)

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])
model.build()
# Display the model's architecture
model.summary()
checkpoint_path = "training_1/cp.ckpt"
checkpoint_dir = os.path.dirname(checkpoint_path)

# Create a callback that saves the model's weights
cp_callback = keras.callbacks.ModelCheckpoint(filepath=checkpoint_path,
                                              save_weights_only=True,
                                              verbose=1)


class TimeHistory(keras.callbacks.Callback):
    def on_train_begin(self, logs={}):
        self.times = []

    def on_epoch_begin(self, batch, logs={}):
        self.epoch_time_start = time.time()

    def on_epoch_end(self, batch, logs={}):
        self.times.append(time.time() - self.epoch_time_start)


time_callback = TimeHistory()

# For higher GPU Utilization it is useful to increase batch_size but this can slow down training
history = model.fit(x_train, y_train, epochs=3, batch_size=50, validation_split=0.1, callbacks=[time_callback])

times = time_callback.times
print('\nEpoch Time '.join(map(str, times)))
print('Average: ', np.mean(times))

# With AMD RADEON 550 PRO GPU
# 24.548192024230957
# Epoch Time 23.452439069747925
# Epoch Time 23.493314027786255
# Epoch Time 23.409918785095215
# Epoch Time 23.45715093612671
# Epoch Time 23.192039966583252
# Epoch Time 23.245102167129517
# Epoch Time 23.274284839630127
# Epoch Time 23.248417854309082
# Epoch Time 23.290798902511597
# Average:  23.461165857315063

# Plot training & validation accuracy values
plt.figure()
plt.plot(history.history['accuracy'])
plt.plot(history.history['val_accuracy'])
plt.title('Model accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['Train', 'Test'], loc='upper left')

# Plot training & validation loss values
plt.figure()
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('Model loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Train', 'Test'], loc='upper left')
plt.show()

# Save JSON config to disk
json_config = model.to_json()
with open('training_1/model_config.json', 'w') as json_file:
    json_file.write(json_config)

# Save weights in binary to disk
model.save_weights('training_1/weights.h5')

model.evaluate(x_test, y_test, verbose=2)
