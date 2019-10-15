import tensorflow as tf
from tensorflow.examples.tutorials.mnist import input_data

import os
import math
import time

# get data
mnist = input_data.read_data_sets('MNIST_data', one_hot=True)
# mnist is a CLASS and provides useful functions


# PLACEHOLDERS

# Input image size is 28x28 pixels.
X = tf.placeholder(tf.float32, shape=[None, 28*28], name='X')

# Every image has on of ten class. For better results (cross-entropy) it is a
Y_ = tf.placeholder(tf.float32, shape=[None, 10], name='Y_')

# Probability that a unit gets disabled (dropout). Prevents overfitting
keep_prob = tf.placeholder(tf.float32, name='keep_prob')

# learning rate
lr = tf.placeholder(tf.float32, name='learning_rate')

# Add to important variables to collections
# This makes it easier to find the correct nodes when loading the model form a file.
tf.add_to_collection('inputs', X)
tf.add_to_collection('inputs', Y_)
tf.add_to_collection('inputs', keep_prob)
tf.add_to_collection('inputs', lr)


def weight_variable(shape):
    initial = tf.truncated_normal(shape, stddev=0.1)
    return tf.Variable(initial)


def bias_variable(shape):
    initial = tf.constant(0.1, shape=shape)
    return tf.Variable(initial)

# "scanns" center pixel and surrounding pixels


def conv2d(x, W):
    return tf.nn.conv2d(x, W, strides=[1, 1, 1, 1], padding='SAME')


def max_pool_2x2(x):
    return tf.nn.max_pool(x, ksize=[1, 2, 2, 1], strides=[1, 2, 2, 1], padding='SAME')


# reshape the image from 1D to 2D
# shape: [BATCHSIZE x IMG_HEIGHT x IMG_WIDTH x IMG_DEPTH]
x_image = tf.reshape(X, [-1, 28, 28, 1])

# FIRST LAYER: Conv
# 5-by-5 patch size, 1 input channel, 32 output channels
W_conv1 = weight_variable([5, 5, 1, 32])
b_conv1 = bias_variable([32])

# Convolution with ReLU activation function
# shape: [BATCH x 28 x 28 x 32]
h_conv1 = tf.nn.relu(conv2d(x_image, W_conv1))

# 2x2 pooling: 2x2 "pixels" become 1 "pixel"
# shape: [BATCH x 14 x 14 x 32]
h_pool1 = max_pool_2x2(h_conv1)


# SECOND LAYER: Conv
# 5-by-5 patch size, 32 input channel, 64 output channels
W_conv2 = weight_variable([5, 5, 32, 64])
b_conv2 = bias_variable([64])

h_conv2 = tf.nn.relu(conv2d(h_pool1, W_conv2) + b_conv2)
h_pool2 = max_pool_2x2(h_conv2)


# THIRD LAYER: Fully connected layer
# input shape: [BATCH x 7 x 7 x 64]
# output shape: [BATCH x 1024]
W_fc1 = weight_variable([7*7*64, 1024])
b_fc1 = bias_variable([1024])

h_pool2_flat = tf.reshape(h_pool2, [-1, 7*7*64])
h_fc1 = tf.nn.relu(tf.matmul(h_pool2_flat, W_fc1)+b_fc1)


h_fc1_dropout = tf.nn.dropout(h_fc1, keep_prob)

# Output layer
W_fc2 = weight_variable([1024, 10])
b_fc2 = bias_variable([10])

Y = tf.matmul(h_fc1_dropout, W_fc2) + b_fc2
tf.identity(Y, name='Y')

# Defines the loss function
loss = tf.reduce_mean(
    tf.nn.softmax_cross_entropy_with_logits(logits=Y, labels=Y_))

# Define the optimizer with a learning and rate and set the objective to minimize the loss
train_step = tf.compat.v1.train.AdamOptimizer(learning_rate=lr).minimize(loss)

tf.identity(loss, name='loss')
tf.add_to_collection('outputs', Y)
tf.add_to_collection('outputs', loss)

#### SUMMARYS ####

correct_prediction = tf.equal(tf.argmax(Y, 1), tf.argmax(Y_, 1))
accuracy = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))


sum_loss = tf.summary.scalar('batch_loss', tf.reduce_mean(loss))
sum_accuray = tf.summary.scalar('batch_accuracy', accuracy)


summaries = tf.summary.merge([sum_accuray, sum_loss])

timestamp = str(math.trunc(time.time()))
# returns the current path of the script
script_path = os.path.realpath(__file__)
script_folder_path = os.path.dirname(script_path)
logdir = os.path.join(script_folder_path, 'log', 'conv_' + timestamp)
if not os.path.exists(logdir):
    os.mkdir(logdir)
summary_writer = tf.summary.FileWriter(
    logdir=logdir + '_train', graph=tf.get_default_graph())
validation_writer = tf.summary.FileWriter(
    logdir=logdir + '_val', graph=tf.get_default_graph())

tf.add_to_collection('outputs', accuracy)

#### SAVER ####
save_path = os.path.join(script_folder_path, 'models', 'conv')
if not os.path.exists(save_path):
    os.mkdir(save_path)
saver = tf.train.Saver()


#### RUN ####

sess = tf.Session()
sess.run(tf.global_variables_initializer())

for i in range(1000):
    x, y_ = mnist.train.next_batch(100)

    feed_dict_train = {X: x, Y_: y_, keep_prob: 0.5, lr: 0.001}

    _, sm_train = sess.run([train_step, summaries], feed_dict=feed_dict_train)

    if i % 100 == 0:
        train_accuracy = sess.run(accuracy, feed_dict=feed_dict_train)

        feed_dict_val = {X: mnist.validation.images,
                         Y_: mnist.validation.labels, keep_prob: 1.0}

        val_accuracy, sm_val = sess.run(
            [accuracy, summaries], feed_dict=feed_dict_val)

        print("step %d \t training accuracy %g \t validation accuracy %g" %
              (i, train_accuracy, val_accuracy))
        validation_writer.add_summary(sm_val, global_step=i)

    summary_writer.add_summary(sm_train, global_step=i)


saver.save(sess=sess, save_path=save_path + 'mnist')
print("test accuracy %g" % accuracy.eval(
    feed_dict={X: mnist.test.images, Y_: mnist.test.labels, keep_prob: 1.0}))
