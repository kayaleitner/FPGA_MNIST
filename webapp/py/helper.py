"""
This is a helper file and is not intended to be used by the webserver directly
"""


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
            os.makedirs(os.path.join('..', 'test_images', str(i)), exist_ok=True)
            pil_image.save(f'../test_images/{i}/{j}.png')


if __name__ == '__main__':
    main()
