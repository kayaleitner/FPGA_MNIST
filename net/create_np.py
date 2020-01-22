import numpy as np




def main():
    pass


def load_keras():
    if not os.path.exists(save_dir):
        raise RuntimeError("There is no trained model data!")

    # Reload the model from the 2 files we saved
    with open(os.path.join(save_dir, 'model_config.json')) as json_file:
        json_config = json_file.read()

    model = keras.models.model_from_json(json_config)
    model.load_weights(os.path.join(save_dir, 'weights.h5'))


if __name__ == '__main__':
    main()
