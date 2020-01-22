from __future__ import print_function, division

import os
import numpy as np
import torch
import torch.nn as nn
import torch.optim
import torchvision
from torch.utils.data import DataLoader

MODEL_SAVE_DIR = "torch"
MODEL_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, "LeNet.pth")
MODEL_STATE_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, "LeNetStates.pth")
MODEL_CKPT_PATH = os.path.join("torch", "cp.ckpt")
MODEL_WGHTS_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, 'weights.h5')
MODEL_CONFIG_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, 'model_config.json')

IMG_HEIGHT = 28
IMG_WIDTH = 28
DEFAULT_PLOT_HISTORY = False
DEFAULT_EPOCHS = 5
BATCH_SIZE = 50
LEARNING_RATE = 0.001

LOG_MINI_BATCH_INTERVAL = 50


def get_lenet_model():
    """
    Creates a new model instance and returns it.
    Returns:

    """
    # net = LeNet()
    net = nn.Sequential(
        nn.BatchNorm2d(num_features=1),
        nn.Conv2d(in_channels=1, out_channels=16, kernel_size=3, stride=1, padding=1),  # [B, 28, 28, 6]
        nn.Dropout2d(p=0.2),
        nn.MaxPool2d(kernel_size=2, stride=2),
        nn.ReLU(),
        nn.Conv2d(in_channels=16, out_channels=32, kernel_size=3, stride=1, padding=1),  # [B, 14, 14, 16]
        nn.ReLU(),
        nn.Dropout2d(p=0.2),
        nn.MaxPool2d(kernel_size=2, stride=2),
        Flatten(),
        nn.Linear(in_features=32 * 7 * 7, out_features=32),
        nn.ReLU(),
        nn.Dropout(p=0.5),
        nn.Linear(in_features=32, out_features=10)
    )
    return net


def main():
    nepochs = DEFAULT_EPOCHS

    # See: https://pytorch.org/tutorials/intermediate/tensorboard_tutorial.html
    transforms = torchvision.transforms.Compose([
        torchvision.transforms.ToTensor()
    ])

    # data sets & data loaders
    trainset = torchvision.datasets.MNIST('./data', download=True, train=True, transform=transforms)
    testset = torchvision.datasets.MNIST('./data', download=True, train=False, transform=transforms)
    trainloader = DataLoader(trainset, batch_size=BATCH_SIZE, shuffle=True)
    testloader = DataLoader(testset, batch_size=BATCH_SIZE, shuffle=False)

    net = get_lenet_model()

    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(net.parameters(), lr=LEARNING_RATE)

    running_loss = 0.0
    for epoch in range(nepochs):  # loop over the dataset multiple times
        for i, data in enumerate(trainloader):
            inputs, labels = data  # get the inputs; data is a list of [inputs, labels]
            optimizer.zero_grad()  # zero the parameter gradients
            outputs = net(inputs)  # forward + backward + optimize
            pred = outputs.argmax(dim=1)  # get the index of the max log-probability
            accurracy = (pred == labels).sum() / float(len(labels))
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()
            if (i + 1) % LOG_MINI_BATCH_INTERVAL == 0:  # every 1000 mini-batches...
                step = epoch * len(trainloader) + i
                print("Epoch: {:3}   MB: {:5}   Acc [%]  {:3.4} %".format(epoch, i, 100 * float(accurracy)))
                # ...log the running loss
                # writer.add_scalar('Loss', running_loss / 1000, step)
                # writer.add_scalar('Accuracy', scalar_value=accurracy * 100, global_step=step)
                running_loss = 0.0

    print('Finished Training')

    # Set the model in evaluation mode -> Removes Dropout Layers
    net.eval()

    # Save the model
    torch.save(net, MODEL_SAVE_PATH)
    torch.save(net.state_dict(), MODEL_STATE_SAVE_PATH)


    test_accuracies = []
    for i, data in enumerate(testloader):
        inputs, labels = data  # get the inputs; data is a list of [inputs, labels]
        outputs = net(inputs)
        pred = outputs.argmax(dim=1)  # get the index of the max log-probability
        accurracy = (pred == labels).sum() / float(len(labels))
        test_accuracies.append(accurracy)

    test_accuracy = np.mean(test_accuracies)
    print("Test accuracy: {:3.4}%".format(100 * test_accuracy))


class Flatten(nn.Module):
    """
    Implements the flatten() function as object to be close to keras syntax
    """

    def forward(self, x):
        return x.view(x.size()[0], -1)


if __name__ == '__main__':
    main()
