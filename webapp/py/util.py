"""
This is a helper file and is not intended to be used by the webserver directly
"""
import numpy as np


def main():
    create_some_test_images(some_number=10)


def create_some_test_images(some_number=10):
    import idx2numpy
    import gzip
    import numpy as np
    import PIL.Image
    import os

    test_images = "../t10k-images-idx3-ubyte.gz"
    test_labels = "../t10k-labels-idx1-ubyte.gz"
    EXPORT_FOLDER = "../test_images"

    imgs = idx2numpy.convert_from_file(gzip.open(test_images))
    lbls = idx2numpy.convert_from_file(gzip.open(test_labels))
    indices = np.arange(0, len(lbls))
    for i in range(10):

        ix = np.random.choice(indices[lbls == i], size=some_number)
        assert len(ix) == some_number

        for j, image_index in enumerate(ix):
            pil_image = PIL.Image.fromarray(np.squeeze(imgs[image_index, :, :]))
            os.makedirs(os.path.join('..', 'static','img','mnist', str(i)), exist_ok=True)
            pil_image.save(f'../static/img/mnist/{i}/{j}.png')


if __name__ == '__main__':
    main()


def rgb2gray(rgb: np.ndarray):
    """
    Converts an RGB image to greyscale
    Args:
        rgb: the rgb image

    Returns:
        A grayscaled image
    """
    w = np.array([0.2989, 0.5870, 0.1140])
    return np.dot(rgb, w)
    # r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    # gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    # return gray


