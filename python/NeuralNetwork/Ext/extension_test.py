import unittest
import NeuralNetworkExtension as nn
import numpy as np

img = np.random.rand(100, 28, 28, 4).astype(np.float32)
K = np.random.rand(3, 3, 4, 8).astype(np.float32)
o = nn.conv2d(img, K, 1)
print("o.shape = ", o.shape)
o2 = nn.maxPool2D(o)
nn.relu4D(o2)
print("o2.shape = ", o2.shape)


# Try to trigger exception by prividing bad kernel
K = np.random.rand(4, 4, 4, 8).astype(np.float32) # only odd numbers are allowed
o = nn.conv2d(img, K, 1)
