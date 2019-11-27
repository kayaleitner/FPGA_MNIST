import NeuralNetworkExtension as nn
import numpy as np


img = np.random.rand(9,7,7,4).astype(np.float32)
K = np.random.rand(3,3,4,8).astype(np.float32)

o = nn.conv2d(img, K, 1)


print("o.shape = ", o.shape)
print(o)

#help(nn.conv2d)
