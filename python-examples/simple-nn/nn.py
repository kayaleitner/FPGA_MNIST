import matplotlib
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
N = 1000
x = np.linspace(0, 100, N).reshape((1, -1))

y = 2.0 * x - 1

# Dimension of x = [1 1000]
z1 = np.matmul(W1, x)+b1    # z1 = [10 1] x [1 1000] = [10 1000]
z2 = np.matmul(W2, z1)+b2   # z2 = [20 10] x [10 1000] = [20 1000]
h = np.matmul(W3, z2)+b3    # z3 = [1 20] x [20 1000] = [1 1000]


# Adding Nonlinearities

# Nonlinear Function: RELU
# f_relu(0) = max(x,0)

def relu(x): return np.maximum(x, 0)


z1 = np.matmul(W1, x)+b1
a1 = relu(z1)
z2 = np.matmul(W2, a1)+b2
a2 = relu(z2)
h = np.matmul(W3, z2)+b3    # no nonlinear function for the output


# Loss calculation
def loss_func(h, y):
    e = y-h
    _, N = e.shape  # get the number of values
    J = 1/N * np.sum(e**2)
    return J, e


J, _ = loss_func(h, y)

print("The total loss is {}".format(J))

 


# Derivative of RELU
# Relu(x) is just a ramp with slope 1 if x > 0,
# therefore the derivative is 0 if x < 0 and 1 if x > 0
def drelu(x): return (x > 0)*1.0  # multiply to convert from boolean to float

# define a learning rate
mu = 0.0001 

##### BACK PROP ######

# Repeat until converge (or at least 1000 iterations)
for i in range(1000):

    ## Step 1: Forward propagate and calculate all values
    z1 = np.matmul(W1, x)+b1
    a1 = relu(z1)
    z2 = np.matmul(W2, a1)+b2
    a2 = relu(z2)
    h = np.matmul(W3, z2)+b3   

    J, _ = loss_func(h,y) 
    print("#{:03d} Loss: {:03f}".format(i, J))


    ## Step 2: Calculate the Derivatives terms

    # Calculate delta terms (see video)
    d4 = y-h
    d3 = np.matmul(W3.transpose(), d4) * drelu(z2)
    d2 = np.matmul(W2.transpose(), d3) * drelu(z1)
    
    dW3 = 2/N  * np.matmul(d4,a2.transpose())
    dW2 = 2/N  * np.matmul(d3,a1.transpose())
    dW1 = 2/N  * np.matmul(d2,x.transpose())

    db3 = 2/N * d4
    db2 = 2/N * d3
    db1 = 2/N * d2

    W3 = W3 + mu*dW3
    W2 = W2 + mu*dW2
    W1 = W1 + mu*dW1

    b3 = b3 + mu*db3
    b2 = b2 + mu*db2
    b1 = b1 + mu*db1


print("Training is done")


plt.figure()
plt.plot(x,y)
plt.plot(x,h)
plt.show()

print("")