#!/usr/bin/env python3
from __future__ import print_function, division

import os

import keras
import keras.layers as layers
from keras.layers import BatchNormalization, Reshape, Conv2D, ReLU, Dropout, MaxPooling2D, Flatten, Dense

# CONSTANTS
MODEL_SAVE_PATH = "keras"
MODEL_CKPT_PATH = os.path.join("keras", "cp.ckpt")
MODEL_WGHTS_SAVE_PATH = os.path.join(MODEL_SAVE_PATH, 'weights.h5')
MODEL_CONFIG_SAVE_PATH = os.path.join(MODEL_SAVE_PATH, 'model_config.json')

IMG_HEIGHT = 28
IMG_WIDTH = 28
DEFAULT_PLOT_HISTORY = False
DEFAULT_EPOCHS = 2


def train(nepochs=DEFAULT_EPOCHS, plot_history=DEFAULT_PLOT_HISTORY):

    (x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
    x_train, x_test = x_train / 255.0, x_test / 255.0

    # Define Constriants (useful for quantization)
    kernel_constraint = keras.constraints.max_norm(max_value=1)

    """
    Define the model here
    
    Changes:
    - Added initial BatchNorm: Makes sense to distribute the input image data evenly around zero
    - Increased value of dropout layer to .5 in first fully connected layer 
    - Removed bias from conv layers
    """
    model = keras.models.Sequential(name="KerasEggNet", layers=[
        # Hack: Reshape the image to 1D to make the Keras BatchNorm layer work
        Reshape(target_shape=(IMG_HEIGHT * IMG_WIDTH, 1), input_shape=(IMG_HEIGHT, IMG_WIDTH)),
        BatchNormalization(),
        Reshape((IMG_HEIGHT, IMG_WIDTH, 1)),  # Reshape to 3D input for the Conv layer
        Conv2D(16, 3, padding='same', activation='linear', use_bias=False, kernel_constraint=kernel_constraint),
        BatchNormalization(axis=-1),  # Normalize along the channels (meaning last axis)
        ReLU(),
        Dropout(0.2),
        MaxPooling2D(),
        Conv2D(32, 3, padding='same', activation='linear', use_bias=False, kernel_constraint=kernel_constraint),
        BatchNormalization(axis=-1),  # Normalize along the channels (meaning last axis)
        ReLU(),
        Dropout(0.2),
        MaxPooling2D(),
        Flatten(),
        Dense(32, activation='linear', kernel_constraint=kernel_constraint),
        ReLU(),
        Dropout(0.5),
        Dense(10, activation='softmax', kernel_constraint=kernel_constraint)
    ])

    # You must install pydot and graphviz for `pydotprint` to work.
    # keras.utils.plot_model(model, 'multi_input_and_output_model.png', show_shapes=True)
    model.compile(optimizer='adam',
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])
    model.build()
    model.summary()
    checkpoint_dir = os.path.dirname(MODEL_CKPT_PATH)

    # Create a callback that saves the model's weights
    cp_callback = keras.callbacks.ModelCheckpoint(filepath=MODEL_CKPT_PATH,
                                                  save_weights_only=True,
                                                  verbose=1)

    # For higher GPU Utilization it is useful to increase batch_size but this can slow down training
    history = model.fit(x_train, y_train,
                        epochs=nepochs,
                        batch_size=50,
                        validation_split=0.1,
                        callbacks=[cp_callback])

    # Save JSON config to disk
    json_config = model.to_json()
    with open(MODEL_CONFIG_SAVE_PATH, 'w') as json_file:
        json_file.write(json_config)

    # Save weights in binary to disk
    model.save_weights(MODEL_WGHTS_SAVE_PATH)
    model.evaluate(x_test, y_test, verbose=2)

    if plot_history:
        _plot_history(history=history)


def _plot_history(history):
    # If you have problems with matplotlib try this
    # import matplotlib
    # matplotlib.use('TkAgg')  # to get rid of runtime error
    import matplotlib.pyplot as plt
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


if __name__ == '__main__':
    # Add argument parsing to start it from the command line
    # parser = argparse.ArgumentParser()
    # parser.add_argument("plot_history", help="Print the training history using matplotlib",
    #                     default=PRINT_HISTORY_DEFAULT)
    # parser.add_argument()
    # args = parser.parse_args(args=sys.argv)
    # plot_history = args.plot_history

    train()
