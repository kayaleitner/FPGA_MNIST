import matplotlib
import numpy as np
import matplotlib.pyplot as plt
import tensorflow as tf

# Help for matlab users:
# http://mathesaurus.sourceforge.net/matlab-numpy.html


# define a learning rate
mu = 0.0001
nepochs = 50 * 1000
min_loss = 1e-3
# Test the forward propagation
N = 1000
minibatch_size = 100

# Example
nx = 1
ny = 1
layers = [30, 30, 30]

x = np.linspace(0, 100, N).reshape((1, -1))
y = 5 * np.sqrt(x) * np.sin((x / N) * 8 * np.pi) + (np.random.rand(1, N) - 0.5)

plt.plot(x.transpose(), y.transpose())
plt.show()


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


W1 = newW(layers[0], nx)
W2 = newW(layers[1], layers[0])
W3 = newW(layers[2], layers[1])
W4 = newW(ny, layers[2])

b1 = newB(layers[0])
b2 = newB(layers[1])
b3 = newB(layers[2])
b4 = newB(ny)


def relu(x): return np.maximum(x, 0)


# Loss calculation
def loss_func(h, y):
    e = y - h
    _, N = e.shape  # get the number of values
    J = 1 / N * np.sum(e ** 2)
    return J, e


# Derivative of RELU
# Relu(x) is just a ramp with slope 1 if x > 0,
# therefore the derivative is 0 if x < 0 and 1 if x > 0
def drelu(x): return (x > 0) * 1.0  # multiply to convert from boolean to float


##### BACK PROP ######
#
#
# Implementation of ADAM: https://arxiv.org/pdf/1412.6980.pdf

beta1 = 0.9
beta2 = 0.999
eps = 1e-8
alpha = 0.001
m0 = 0
v0 = 0
mi = 0
vi = 0

pW4 = {'vi': 0, 'mi': 0}
pW3 = {'vi': 0, 'mi': 0}
pW2 = {'vi': 0, 'mi': 0}
pW1 = {'vi': 0, 'mi': 0}

pb4 = {'vi': 0, 'mi': 0}
pb3 = {'vi': 0, 'mi': 0}
pb2 = {'vi': 0, 'mi': 0}
pb1 = {'vi': 0, 'mi': 0}


def adam_step(i, g, params, alpha=0.001, beta1=0.9, beta2=0.999, eps=1e-8):
    # Calculate the ADAM momenta
    mi = params['mi']
    vi = params['vi']

    mi = beta1 * mi + (1 - beta1) * g
    vi = beta2 * vi + (1 - beta2) * (g ** 2)
    mi_ = mi / (1 - beta1 ** (i + 1))
    vi_ = vi / (1 - beta2 ** (i + 1))

    # Update
    params['mi'] = mi
    params['vi'] = vi

    return alpha * mi_ / (np.sqrt(vi_) + eps)


Jhistory = []
# Repeat until converge (or at least 1000 iterations)
for i in range(nepochs):
    # Shuffled array

    indices = np.arange(N)
    np.random.shuffle(indices)
    Jb_history = []

    for b in range(N // minibatch_size):

        ix = indices[b:b + minibatch_size]
        xb = x[:, ix]
        yb = y[:, ix]

        ## Step 1: Forward propagate and calculate all values
        z1 = np.matmul(W1, xb) + b1
        a1 = relu(z1)
        z2 = np.matmul(W2, a1) + b2
        a2 = relu(z2)
        z3 = np.matmul(W3, a2) + b3
        a3 = relu(z3)
        h = np.matmul(W4, a3) + b4

        Jb, _ = loss_func(h, yb)
        Jb_history.append(Jb)
        print("#{:03d} Loss: {:03f}".format(i, Jb))

        if Jb < min_loss:
            print("Training finished after {} epochs. Reason: Minimum loss ({:3g}) reached".format(i, min_loss))
            break

        ## Step 2: Calculate the Derivatives terms

        # Calculate delta terms (see video)
        d4 = yb - h
        d3 = np.matmul(W4.transpose(), d4) * drelu(z3)
        d2 = np.matmul(W3.transpose(), d3) * drelu(z2)
        d1 = np.matmul(W2.transpose(), d2) * drelu(z1)

        dW4 = 2 / N * np.matmul(d4, a3.transpose())
        dW3 = 2 / N * np.matmul(d3, a2.transpose())
        dW2 = 2 / N * np.matmul(d2, a1.transpose())
        dW1 = 2 / N * np.matmul(d1, xb.transpose())

        db4 = 2 / N * np.sum(d4, axis=1, keepdims=True)
        db3 = 2 / N * np.sum(d3, axis=1, keepdims=True)
        db2 = 2 / N * np.sum(d2, axis=1, keepdims=True)
        db1 = 2 / N * np.sum(d1, axis=1, keepdims=True)

        alpha = 0.001

        W4 = W4 + adam_step(i, dW4, pW4, alpha=alpha)
        W3 = W3 + adam_step(i, dW3, pW3, alpha=alpha)
        W2 = W2 + adam_step(i, dW2, pW2, alpha=alpha)
        W1 = W1 + adam_step(i, dW1, pW1, alpha=alpha)

        b4 = b4 + adam_step(i, db4, pb4, alpha=alpha)
        b3 = b3 + adam_step(i, db3, pb3, alpha=alpha)
        b2 = b2 + adam_step(i, db2, pb2, alpha=alpha)
        b1 = b1 + adam_step(i, db1, pb1, alpha=alpha)

    Jhistory.append(np.mean(Jb_history))

    # reduce plot frequency
    if i % 500 == 0:
        plt.semilogy(Jhistory, 'r')
        plt.xlabel('Iteration')
        plt.ylabel('MSE')
        plt.title('Loss')
        plt.pause(0.01)

print("Training is done")

z1 = np.matmul(W1, x) + b1
a1 = relu(z1)
z2 = np.matmul(W2, a1) + b2
a2 = relu(z2)
z3 = np.matmul(W3, a2) + b3
a3 = relu(z3)
h = np.matmul(W4, a3) + b4

# Transpose data
ht = h.transpose()
xt = x.transpose()
yt = y.transpose()

plt.figure()
plt.plot(xt, yt, 'bo')
plt.plot(xt, ht, color='orange')
# plt.ylim(-10,100)
plt.legend(['Original', 'NN'])
plt.show()

print("")
