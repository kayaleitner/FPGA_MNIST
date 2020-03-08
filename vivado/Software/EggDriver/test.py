"""
Test the new created wrapper
But first test if installation works:

```
python setup.py build_ext
python setup.py build
pip install .
```
"""

import numpy as np

# try
from .lib import EggNetDriverCore
# or
# import EggNetDriverCore

imgs = np.random.rand(shape=(10, 28, 28, 1))
results = EggNetDriverCore.inference(imgs)