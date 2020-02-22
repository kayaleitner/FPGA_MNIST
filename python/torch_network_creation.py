import pathlib

import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torch.utils.tensorboard import SummaryWriter

from NeuralNetwork.Torch.models import LeNet
# from NeuralNetwork.Torch.models import QuantLeNet
from NeuralNetwork.nn.util import MNIST_CLASSES, matplotlib_imshow, plot_classes_preds, select_n_random

if __name__ == '__main__':
    # See: https://pytorch.org/tutorials/intermediate/tensorboard_tutorial.html
    transforms = transforms.Compose([
        transforms.ToTensor()
    ])
    BATCH_SIZE = 32
    # data sets & data loaders
    trainset = torchvision.datasets.MNIST('./data', download=True, train=True, transform=transforms)
    testset = torchvision.datasets.MNIST('./data', download=True, train=False, transform=transforms)
    trainloader = torch.utils.data.DataLoader(trainset, batch_size=BATCH_SIZE, shuffle=True)
    testloader = torch.utils.data.DataLoader(testset, batch_size=BATCH_SIZE, shuffle=False)

    # constant for classes
    classes = MNIST_CLASSES

    net = LeNet()
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(net.parameters(), lr=0.001)

    # get some random training images
    dataiter = iter(trainloader)
    images, labels = dataiter.next()

    # create grid of images
    img_grid = torchvision.utils.make_grid(images)
    matplotlib_imshow(img_grid, one_channel=True)  # show images

    # write to tensorboard
    # default `log_dir` is "runs" - we'll be more specific here
    writer = SummaryWriter('runs/mnist_experiment_4_QLeNet')
    writer.add_image('four_mnist_images', img_grid)
    # writer.add_graph(net, images)

    # select random images and their target indices
    images, labels = select_n_random(trainset.data, trainset.targets)
    # get the class labels for each image
    class_labels = [classes[lab] for lab in labels]
    # log embeddings
    # features = images.view(-1, 28 * 28)
    # writer.add_embedding(features,
    #                      metadata=class_labels,
    #                      label_img=images.unsqueeze(1))
    # writer.close()


    running_loss = 0.0
    for epoch in range(5):  # loop over the dataset multiple times

        for i, data in enumerate(trainloader, 0):

            # get the inputs; data is a list of [inputs, labels]
            inputs, labels = data

            # zero the parameter gradients
            optimizer.zero_grad()

            # forward + backward + optimize
            outputs = net(inputs)
            pred = outputs.argmax(dim=1)  # get the index of the max log-probability
            accurracy = (pred == labels).sum() / float(len(labels))
            loss = criterion(outputs, labels)

            loss.backward()
            optimizer.step()

            running_loss += loss.item()
            if (i + 1) % 500 == 0:  # every 1000 mini-batches...
                step = epoch * len(trainloader) + i

                print("Epoch: ", epoch, "  #MB: ", i, "     Acc [%]  ", float(accurracy) * 100, "%")
                # ...log the running loss
                writer.add_scalar('Loss', running_loss / 1000, step)
                writer.add_scalar('Accuracy', scalar_value=accurracy * 100, global_step=step)

                params = [p for p in net.parameters()]
                for p in params:
                    if p.ndim == 1:
                        pass
                    # writer.add_histogram(tag="L1 Channels", )

                # ...log a Matplotlib Figure showing the model's predictions on a
                # random mini-batch
                # writer.add_figure(tag='predictions vs. actuals',
                #                   figure=plot_classes_preds(net, inputs, labels, MNIST_CLASSES),
                #                   global_step=epoch * len(trainloader) + i)
                running_loss = 0.0
    print('Finished Training')
    save_path = pathlib.Path('.') / 'models'
    save_path.mkdir(parents=True, exist_ok=True)
    torch.save(net.state_dict(), save_path / 'LeNet.torch')
