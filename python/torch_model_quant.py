import copy
import pathlib
import time

import matplotlib.pyplot as plt
import torch
import torch.quantization
import torchvision
import torchvision.transforms as transforms
from torch import nn
import torch.nn.functional as F

import NeuralNetwork.util
import NeuralNetwork.core
from NeuralNetwork.Torch.models import LeNet
from NeuralNetwork.util import MNIST_CLASSES


def train_model(model, criterion, optimizer, scheduler, num_epochs=25, device='cpu'):
    """
  Support function for model training.

  Args:
    model: Model to be trained
    criterion: Optimization criterion (loss)
    optimizer: Optimizer to use for training
    scheduler: Instance of ``torch.optim.lr_scheduler``
    num_epochs: Number of epochs
    device: Device to run the training on. Must be 'cpu' or 'cuda'
  """
    since = time.time()

    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0

    for epoch in range(num_epochs):
        print('Epoch {}/{}'.format(epoch, num_epochs - 1))
        print('-' * 10)

        # Each epoch has a training and validation phase
        for phase in ['train', 'val']:
            if phase == 'train':
                model.train()  # Set model to training mode
            else:
                model.eval()  # Set model to evaluate mode

            running_loss = 0.0
            running_corrects = 0

            # Iterate over data.
            for inputs, labels in dataloaders[phase]:
                inputs = inputs.to(device)
                labels = labels.to(device)

                # zero the parameter gradients
                optimizer.zero_grad()

                # forward
                # track history if only in train
                with torch.set_grad_enabled(phase == 'train'):
                    outputs = model(inputs)
                    _, preds = torch.max(outputs, 1)
                    loss = criterion(outputs, labels)

                    # backward + optimize only if in training phase
                    if phase == 'train':
                        loss.backward()
                        optimizer.step()

                # statistics
                running_loss += loss.item() * inputs.size(0)
                running_corrects += torch.sum(preds == labels.data)
            if phase == 'train':
                scheduler.step()

            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects.double() / dataset_sizes[phase]

            print('{} Loss: {:.4f} Acc: {:.4f}'.format(
                phase, epoch_loss, epoch_acc))

            # deep copy the model
            if phase == 'val' and epoch_acc > best_acc:
                best_acc = epoch_acc
                best_model_wts = copy.deepcopy(model.state_dict())

        print()

    time_elapsed = time.time() - since
    print('Training complete in {:.0f}m {:.0f}s'.format(
        time_elapsed // 60, time_elapsed % 60))
    print('Best val Acc: {:4f}'.format(best_acc))

    # load best model weights
    model.load_state_dict(best_model_wts)
    return model


def create_combined_model(model_fe):
    # Step 1. Isolate the feature extractor.
    model_fe_features = nn.Sequential(
        model_fe.quant,  # Quantize the input
        model_fe.conv1,
        model_fe.bn1,
        NeuralNetwork.NN.core.relu,
        model_fe.maxpool,
        model_fe.layer1,
        model_fe.layer2,
        model_fe.layer3,
        model_fe.layer4,
        model_fe.avgpool,
        model_fe.dequant,  # Dequantize the output
    )

    # Step 2. Create a new "head"
    new_head = nn.Sequential(
        nn.Dropout(p=0.5),
        nn.Linear(num_ftrs, 2),
    )

    # Step 3. Combine, and don't forget the quant stubs.
    new_model = nn.Sequential(
        model_fe_features,
        nn.Flatten(1),
        new_head,
    )
    return new_model


def visualize_model(model, dataloaders, class_names, rows=3, cols=3):
    was_training = model.training
    model.eval()
    current_row = current_col = 0
    fig, ax = plt.subplots(rows, cols, figsize=(cols * 2, rows * 2))

    with torch.no_grad():
        for idx, (imgs, lbls) in enumerate(dataloaders['val']):
            imgs = imgs.cpu()
            lbls = lbls.cpu()

            assert imgs.size()[0] >= rows * cols

            outputs = model(imgs)
            _, preds = torch.max(outputs, 1)

            for jdx in range(imgs.size()[0]):
                ax[current_row, current_col].imshow(imgs.data[jdx].squeeze(), cmap='gray')
                # plt.imshow(imgs.data[jdx], ax=ax[current_row, current_col])
                ax[current_row, current_col].axis('off')
                ax[current_row, current_col].set_title('predicted: {}'.format(class_names[preds[jdx]]))

                current_col += 1
                if current_col >= cols:
                    current_row += 1
                    current_col = 0
                if current_row >= rows:
                    model.train(mode=was_training)
                    return
        model.train(mode=was_training)


def train(net, *args):
    transform = transforms.Compose([
        transforms.ToTensor()
    ])

    # data sets & data loaders
    trainset = torchvision.datasets.FashionMNIST('./data', download=True, train=True, transform=transform)
    testset = torchvision.datasets.FashionMNIST('./data', download=True, train=False, transform=transform)
    trainloader = torch.utils.data.DataLoader(trainset, batch_size=9, shuffle=True)
    testloader = torch.utils.data.DataLoader(testset, batch_size=9, shuffle=False)

    # constant for classes
    classes = MNIST_CLASSES

    criterion = torch.nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(net.parameters(), lr=0.001)
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    for epoch in range(1):  # loop over the dataset multiple times
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


def model_test(model, device, test_loader):
    model.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            test_loss += F.cross_entropy(output, target, reduction='sum').item()  # sum up batch loss
            pred = output.argmax(dim=1, keepdim=True)  # get the index of the max log-probability
            correct += pred.eq(target.view_as(pred)).sum().item()

    test_loss /= len(test_loader.dataset)

    print('\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n'.format(
        test_loss, correct, len(test_loader.dataset),
        100. * correct / len(test_loader.dataset)))


if __name__ == '__main__':
    # Places to watch out for:
    #
    #
    # https://medium.com/@karanbirchahal/how-to-quantise-an-mnist-network-to-8-bits-in-pytorch-no-retraining-required-from-scratch-39f634ac8459
    # https://github.com/pytorch/glow/blob/master/docs/Quantization.md

    save_path = pathlib.Path('.') / 'models' / 'LeNet.torch'
    net = LeNet()
    state_dict = torch.load(save_path)

    no_cuda = False
    use_cuda = not no_cuda and torch.cuda.is_available()
    device = torch.device("cuda" if use_cuda else "cpu")

    transform = transforms.Compose([
        transforms.ToTensor()
    ])

    # data sets & data loaders
    trainset = torchvision.datasets.MNIST('./data', download=True, train=True, transform=transform)
    testset = torchvision.datasets.MNIST('./data', download=True, train=False, transform=transform)
    class_names = MNIST_CLASSES
    dataloaders = {
        'train': torch.utils.data.DataLoader(trainset, batch_size=9, shuffle=True),
        'val': torch.utils.data.DataLoader(testset, batch_size=9, shuffle=True)
    }

    net.load_state_dict(state_dict)

    model_test(model=net, device=device, test_loader=dataloaders['val'])

    net.eval()
    net.fuse_model()
    net.qconfig = torch.quantization.default_qconfig
    qnet = torch.quantization.convert(net)
    torch.quantization.convert(net, inplace=True)

    # qnet = convert(net, inplace=True)

    # qnet = torch.quantization.quantize(model=net, run_fn=train, run_args=())
    visualize_model(qnet, dataloaders=dataloaders, class_names=class_names)
    plt.ioff()
    plt.tight_layout()
    plt.show()
    print('Finished')
