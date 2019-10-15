import numpy as np
import matplotlib.pyplot as plt


# Help for matlab users:
# http://mathesaurus.sourceforge.net/matlab-numpy.html


# Forward propagation
#
# Z1 = W1 X + b1
# Z2 = W2 Z1 + b2
# y = W3 Z2 + b3
#
# Input dimension: Nx
# Output dimension: Ny
# W1 = [M Nx] (dimension of W1 is M Nx)
# W2 = [O M] (dimension of W2 is O M)
# W3 = [Ny O]

def newW(m, n):
    # Returns a [m n] matrix with random initialization
    return np.random.rand(m, n)


def newB(n):
    return np.random.rand(n, 1)


 # Example
nx = 1
ny = 1

layers = [10, 20]

W1 = newW(layers[0], nx)
b1 = newB(layers[0])

W2 = newW(layers[1], layers[0])
b2 = newB(layers[1])

W3 = newW(ny, layers[1])
b3 = newB(ny)

# Test the forward propagation
x = np.linspace(0, 100, 1000).reshape((1, -1))

y = 2.0 * x - 1

# Dimension of x = [1 1000]
z1 = np.matmul(W1, x)+b1    # z1 = [10 1] x [1 1000] = [10 1000]
z2 = np.matmul(W2, z1)+b2   # z2 = [20 10] x [10 1000] = [20 1000]
h = np.matmul(W3, z2)+b3    # z3 = [1 20] x [20 1000] = [1 1000]


# Adding Nonlinearities

# Nonlinear Function: RELU
# f_relu(0) = max(x,0)

def f_relu(x): return np.maximum(x, 0)


z1 = np.matmul(W1, x)+b1
a1 = f_relu(z1)
z2 = np.matmul(W2, a1)+b2
a2 = f_relu(z2)
h = np.matmul(W3, z2)+b3    # no nonlinear function for the output


# Loss calculation
def loss_func(h, y):
    e = h-y
    _, N = e.shape  # get the number of values
    J = 1/N * np.sum(e*e)
    return J, e


J, _ = loss_func(h, y)

print("The total loss is {}".format(J))


# Backpropagation without Actionfunctions
"""

Objective: Calculate all partial derivatives of dJ/dp where p = {W1,W2,W3,b1,b2,b3}

dJ/dp = 2/N * (h - y) * dh/dp

h  = W3 z2 + b3
z2 = W2 z1 + b2
z1 = W1  x + b1

dh/dW3 = z2                                     []
dh/dW2 = dh/dz2 * dz2/dW2 = W3*z1
dh/dW1 = dh/dz2 * dz2/dz1 * dz1/dW1 = W3*W2*x

dh/db3 = 1
dh/db2 = dh/dz2 * dz2/db2 = W3
dh/db1 = dh/dz2 * dz2/dz1 * dz1/db1 = W3*W2

update rule:
p[n+1] = p[n] + mu * dJ/dp


h  = W3 a2 + b3
a2 = f_relu(z2)
z2 = W2 a1 + b2
a1 = f_relu(z1)
z1 = W1  x + b1

dh/dW3 = z2
dh/dW2 = dh/dz2 * dz2/dW2 = W3*z1
dh/dW1 = dh/dz2 * dz2/dz1 * dz1/dW1 = W3*W2*x

dh/db3 = 1
dh/db2 = dh/dz2 * dz2/db2 = W3
dh/db1 = dh/dz2 * dz2/dz1 * dz1/db1 = W3*W2


update rule:
p[n+1] = p[n] + mu * dJ/dp
"""

# Step 1: Forward propagate and calculate all values
z1 = np.matmul(W1, x)+b1
a1 = f_relu(z1)
z2 = np.matmul(W2, a1)+b2
a2 = f_relu(z2)
h = np.matmul(W3, z2)+b3    

# Calculate the delta terms


# Derivative of RELU
# Relu(x) is just a ramp with slope 1 if x > 0,
# therefore the derivative is 0 if x < 0 and 1 if x > 0
def drelu(x): return (x > 0)*1.0  # multiply to convert from boolean to float
