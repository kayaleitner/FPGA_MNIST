import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torch.utils.tensorboard import SummaryWriter

from NeuralNetwork.Util.torch import matplotlib_imshow, plot_classes_preds, select_n_random, MNIST_CLASSES


class SqueezeNet(nn.Module):
    def __init__(self):
        super(SqueezeNet, self).__init__()
        self.conv1_1 = nn.Conv2d(in_channels=1, out_channels=6, kernel_size=3, stride=1, padding=1)  # [B, 28, 28, 6]
        self.conv1_2 = nn.Conv2d(in_channels=1, out_channels=6, kernel_size=1, stride=1, padding=0)  # [B, 28, 28, 6]
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)  # [B, 28, 28, 6], but pool function is reused
        self.conv2_1 = nn.Conv2d(in_channels=12, out_channels=16, kernel_size=3, stride=1, padding=1)  # [B, 14, 14, 16]
        self.conv2_2 = nn.Conv2d(in_channels=12, out_channels=16, kernel_size=1, stride=1, padding=0)  # [B, 14, 14, 16]
        self.conv3 = nn.Conv2d(in_channels=32, out_channels=8, kernel_size=1, stride=1, padding=0)
        self.fc1 = nn.Linear(in_features=8 * 7 * 7, out_features=64)
        self.fc2 = nn.Linear(in_features=64, out_features=10)

    def forward(self, x: torch.Tensor):
        x1 = self.pool(F.relu(self.conv1_1(x)))
        x2 = self.pool(F.relu(self.conv1_2(x)))
        x = torch.cat((x1, x2), dim=1)  # append along last dim
        x1 = self.pool(F.relu(self.conv2_1(x)))
        x2 = self.pool(F.relu(self.conv2_2(x)))
        x = torch.cat((x1, x2), dim=1)  # append along last dim
        x = self.conv3(input=x)
        x = x.view(-1, 8 * 7 * 7)
        x = F.relu(self.fc1(x))
        x = F.softmax(self.fc2(x), dim=-1)
        return x


class LeNet(nn.Module):

    def __init__(self):
        super(LeNet, self).__init__()
        self.conv1_1 = nn.Conv2d(in_channels=1, out_channels=6, kernel_size=3, stride=1, padding=1)  # [B, 28, 28, 6]
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)  # [B, 28, 28, 6], but pool function is reused
        self.conv2_1 = nn.Conv2d(in_channels=12, out_channels=16, kernel_size=3, stride=1, padding=1)  # [B, 14, 14, 16]
        self.fc1 = nn.Linear(in_features=8 * 7 * 7, out_features=64)
        self.fc2 = nn.Linear(in_features=64, out_features=10)

    def forward(self, x: torch.Tensor):
        x = self.pool(F.relu(self.conv1_1(x)))
        x = self.pool(F.relu(self.conv2_1(x)))
        x = x.view(-1, 8 * 7 * 7)
        x = F.relu(self.fc1(x))
        x = F.softmax(self.fc2(x), dim=-1)
        return x


if __name__ == '__main__':
    # See: https://pytorch.org/tutorials/intermediate/tensorboard_tutorial.html
    transforms = transforms.Compose([
        transforms.ToTensor()
    ])

    # data sets & data loaders
    trainset = torchvision.datasets.FashionMNIST('./data', download=True, train=True, transform=transforms)
    testset = torchvision.datasets.FashionMNIST('./data', download=True, train=False, transform=transforms)
    trainloader = torch.utils.data.DataLoader(trainset, batch_size=4, shuffle=True)
    testloader = torch.utils.data.DataLoader(testset, batch_size=4, shuffle=False)

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
    writer = SummaryWriter('runs/fashion_mnist_experiment_3_LeNet')
    writer.add_image('four_fashion_mnist_images', img_grid)
    writer.add_graph(net, images)

    # select random images and their target indices
    images, labels = select_n_random(trainset.data, trainset.targets)
    # get the class labels for each image
    class_labels = [classes[lab] for lab in labels]
    # log embeddings
    features = images.view(-1, 28 * 28)
    writer.add_embedding(features,
                         metadata=class_labels,
                         label_img=images.unsqueeze(1))
    writer.close()

    running_loss = 0.0
    for epoch in range(3):  # loop over the dataset multiple times

        for i, data in enumerate(trainloader, 0):

            # get the inputs; data is a list of [inputs, labels]
            inputs, labels = data

            # zero the parameter gradients
            optimizer.zero_grad()

            # forward + backward + optimize
            outputs = net(inputs)
            pred = outputs.argmax(dim=1)  # get the index of the max log-probability
            accurracy = (pred == labels).sum() / len(labels)
            loss = criterion(outputs, labels)

            loss.backward()
            optimizer.step()

            running_loss += loss.item()
            if (i+1) % 500 == 0:  # every 1000 mini-batches...
                step = epoch * len(trainloader) + i

                print("Epoch: ", epoch, "  #MB: ", i)
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
                writer.add_figure(tag='predictions vs. actuals',
                                  figure=plot_classes_preds(net, inputs, labels),
                                  global_step=epoch * len(trainloader) + i)
                running_loss = 0.0
    print('Finished Training')
