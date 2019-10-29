import numpy as np
from matplotlib import pyplot as plt

def relu(x): return np.maximum(x, 0)
def drelu(x): return (x > 0)*1.0  # multiply to convert from boolean to float