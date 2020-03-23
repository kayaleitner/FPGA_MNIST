from __future__ import print_function, division

import os
import time

import numpy as np
import torch
import torch.nn as nn
import torch.optim
import torch.quantization
import torchvision
from torch.utils.data import DataLoader

EXPORT_DIR = 'np'
SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))

try:
    import EggNet.NeuralNetwork.Ext as nnext
except ImportError as error:
    print("Unable to import NeuralNetwork.Ext. Is it installed?")
    print(error)

# Set this to true to skip training
SKIP_TRAIN = False

MODEL_SAVE_DIR = "torch"
MODEL_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, "LeNet.pth")
MODEL_STATE_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, "LeNetStates.pth")
QMODEL_STATE_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, "QLeNetStates.pth")
MODEL_CKPT_PATH = os.path.join("torch", "cp.ckpt")
MODEL_WGHTS_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, 'weights.h5')
MODEL_CONFIG_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, 'model_config.json')

TORCH_SAVE_DIR = os.path.join(SCRIPT_PATH, 'torch')
TORCH_SAVE_FILE = os.path.join(TORCH_SAVE_DIR, 'LeNet.pth')
TORCH_STATES_SAVE_FILE = os.path.join(TORCH_SAVE_DIR, 'LeNetStates.pth')

IMG_HEIGHT = 28
IMG_WIDTH = 28
DEFAULT_PLOT_HISTORY = False
DEFAULT_EPOCHS = 10
BATCH_SIZE = 128
EVAL_BATCH_SIZE = 128
LEARNING_RATE = 0.001
NUM_CALIBRATION_BATCHES = 128
NUM_EVAL_BATCHES = 50
LOG_MINI_BATCH_INTERVAL = 50


def main(nepochs=DEFAULT_EPOCHS, plot_history=False):
    """
    data sets & data loaders
    """

    testloader, trainloader = prepare_datasets()

    """
    Setup Network
    """
    net = LeNetV2()
    net.to('cpu')
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(net.parameters(), lr=LEARNING_RATE)
    history_accuracy, history_loss = train_network(net, nepochs, criterion, optimizer, trainloader)

    print('Finished Training')

    # Save history
    history_accuracy = np.array(history_accuracy)
    history_loss = np.array(history_loss)
    np.save(file='runs/history_accuracy', arr=history_accuracy)
    np.save(file='runs/history_loss', arr=history_loss)
    np.savetxt(fname='runs/history_accuracy.txt', X=history_accuracy, header='Run Accuracy')
    np.savetxt(fname='runs/history_loss.txt', X=history_loss, header='Run Loss')

    """
    Fuse Network
    """
    # Set the model in evaluation mode -> Removes Dropout Layers
    net.eval()
    # Fuse model -> Removes batch norm layers
    net.fuse_model()

    """
    Quant Network using Torch Quantization
    See: https://pytorch.org/tutorials/advanced/static_quantization_tutorial.html#post-training-static-quantization

    Not working!
    """
    # qnet = quantize_network(criterion, net, testloader, trainloader)
    # torch.save(qnet.state_dict(), QMODEL_STATE_SAVE_PATH)

    """
    Save Network
    """
    torch.save(net, MODEL_SAVE_PATH)
    torch.save(net.state_dict(), MODEL_STATE_SAVE_PATH)

    save_weights_as_numpy(net)

    test_accuracies = []
    for i, data in enumerate(testloader):
        inputs, labels = data  # get the inputs; data is a list of [inputs, labels]
        outputs = net(inputs)
        pred = outputs.argmax(dim=1)  # get the index of the max log-probability
        accurracy = (pred == labels).sum() / float(len(labels))
        test_accuracies.append(accurracy)

    test_accuracy = np.mean(test_accuracies)
    print("Test accuracy: {:3.4}%".format(100 * test_accuracy))

    if plot_history:
        import matplotlib.pyplot as plt
        # Plot training & validation accuracy values
        plt.figure()
        plt.plot(history_accuracy)
        plt.title('Model accuracy')
        plt.ylabel('Accuracy')
        plt.xlabel('Epoch')
        plt.show()


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
        nn.Linear(in_features=32, out_features=10),
        nn.Softmax(dim=1)
    )
    return net


class AverageMeter(object):
    """Computes and stores the average and current value"""

    def __init__(self, name, fmt=':f'):
        self.name = name
        self.fmt = fmt
        self.reset()

    def reset(self):
        self.val = 0
        self.avg = 0
        self.sum = 0
        self.count = 0

    def update(self, val, n=1):
        self.val = val
        self.sum += val * n
        self.count += n
        self.avg = self.sum / self.count

    def __str__(self):
        fmtstr = '{name} {val' + self.fmt + '} ({avg' + self.fmt + '})'
        return fmtstr.format(**self.__dict__)


def accuracy(output, target, topk=(1,)):
    """Computes the accuracy over the k top predictions for the specified values of k"""

    maxk = max(topk)
    batch_size = target.size(0)

    _, pred = output.topk(maxk, 1, True, True)
    pred = pred.t()
    correct = pred.eq(target.view(1, -1).expand_as(pred))

    res = []
    for k in topk:
        correct_k = correct[:k].view(-1).float().sum(0, keepdim=True)
        res.append(correct_k.mul_(100.0 / batch_size))
    return res


def _evaluate_full_output(model, criterion, data_loader, neval_batches=None):
    model.eval()
    top1 = AverageMeter('Acc@1', ':6.2f')
    top5 = AverageMeter('Acc@5', ':6.2f')
    cnt = 0
    outputs = []
    losses = []
    with torch.no_grad():
        for image, target in data_loader:
            output = model(image)
            outputs.append(output)
            loss = criterion(output, target)
            losses.append(loss)
            cnt += 1
            acc1, acc5 = accuracy(output, target, topk=(1, 5))
            print('.', end='')
            top1.update(acc1[0], image.size(0))
            top5.update(acc5[0], image.size(0))
            if neval_batches is not None and cnt >= neval_batches:
                return top1, top5

    return top1, top5, outputs, losses


def evaluate_labels(model, criterion, data_loader, neval_batches=None):
    _, _, outputs, _ = _evaluate_full_output(model=model, criterion=criterion, data_loader=data_loader,
                                             neval_batches=neval_batches)
    return outputs


def evaluate(model, criterion, data_loader, neval_batches=None):
    top1, top5, _, _ = _evaluate_full_output(model=model, criterion=criterion, data_loader=data_loader,
                                             neval_batches=neval_batches)
    return top1, top5


def print_size_of_model(model):
    torch.save(model.state_dict(), "temp.p")
    print('Size (MB):', os.path.getsize("temp.p") / 1e6)
    os.remove('temp.p')


class ConvBN(nn.Sequential):
    """
    A combined Conv2D + BatchNorm Layer
    """

    def __init__(self, in_planes, out_planes, kernel_size=3, stride=1, groups=1):
        padding = (kernel_size - 1) // 2
        super(ConvBN, self).__init__(
            nn.Conv2d(in_channels=in_planes, out_channels=out_planes, kernel_size=kernel_size, stride=stride,
                      padding=padding, groups=groups, bias=True),
            nn.BatchNorm2d(out_planes),
        )


class ConvBNReLU(nn.Sequential):
    """
    A combined Conv2D + BatchNorm + ReLU Layer
    """

    def __init__(self, in_planes, out_planes, kernel_size=3, stride=1, groups=1):
        padding = (kernel_size - 1) // 2
        super(ConvBNReLU, self).__init__(
            nn.Conv2d(in_planes, out_planes, kernel_size, stride, padding, groups=groups, bias=True),
            nn.BatchNorm2d(out_planes, momentum=0.1),
            # Replace with ReLU
            nn.ReLU(inplace=False)
        )


class LinearRelu(nn.Sequential):

    def __init__(self, in_features, out_features):
        super(LinearRelu, self).__init__(
            nn.Linear(in_features=in_features, out_features=out_features, bias=True),
            nn.ReLU6(inplace=False))

    @staticmethod
    def init_with_weights(w, b):
        module = LinearRelu(in_features=w.shape[1], out_features=w.shape[0])

        new_state_dict = {
            'weight': torch.from_numpy(w),
            'bias': torch.from_numpy(b),
        }

        for child in module.children():
            if isinstance(child, nn.Linear):
                child.load_state_dict(new_state_dict)

        return module


class LeNetV2(nn.Sequential):
    """
    Improved Version with BatchNorm and Dropout
    """

    def __init__(self):
        super(LeNetV2, self).__init__(
            # Ignore initial Bachnorm
            # nn.BatchNorm2d(num_features=1),
            ConvBN(in_planes=1, out_planes=16, kernel_size=3, stride=1),
            nn.Dropout(p=0.5),
            nn.ReLU6(),
            nn.MaxPool2d(kernel_size=2, stride=2),
            ConvBN(in_planes=16, out_planes=32, kernel_size=3, stride=1),
            nn.Dropout(p=0.5),
            nn.ReLU6(),
            nn.MaxPool2d(kernel_size=2, stride=2),
            Flatten(),
            LinearRelu(in_features=32 * 7 * 7, out_features=32),
            nn.Dropout(p=0.5),
            nn.Linear(in_features=32, out_features=10),
            # No Softmax needed, combined in cross entropy loss function
            # nn.Softmax(dim=1)
        )

    # COMPLEX_MODULES = (nn.Sequential,)  # Add any "recursable" modules in here

    def fuse_model(self):
        """
        Fuse Conv+BN and Conv+BN+Relu modules prior to quantization
        This operation does not change the numerics
        Returns:

        """
        import torch.quantization
        self.eval()
        for m in self.modules():
            if type(m) == ConvBN:
                torch.quantization.fuse_modules(m, ['0', '1'], inplace=True)
            if type(m) == ConvBNReLU:
                torch.quantization.fuse_modules(m, ['0', '1', '2'], inplace=True)


def train_one_epoch(model, criterion, optimizer, data_loader, device, ntrain_batches):
    model.train()
    top1 = AverageMeter('Acc@1', ':6.2f')
    top5 = AverageMeter('Acc@5', ':6.2f')
    avgloss = AverageMeter('Loss', '1.5f')

    cnt = 0
    for image, target in data_loader:
        start_time = time.time()
        print('.', end='')
        cnt += 1
        image, target = image.to(device), target.to(device)
        output = model(image)
        loss = criterion(output, target)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        acc1, acc5 = accuracy(output, target, topk=(1, 5))
        top1.update(acc1[0], image.size(0))
        top5.update(acc5[0], image.size(0))
        avgloss.update(loss, image.size(0))
        if cnt >= ntrain_batches:
            print('Loss', avgloss.avg)

            print('Training: * Acc@1 {top1.avg:.3f} Acc@5 {top5.avg:.3f}'
                  .format(top1=top1, top5=top5))
            return

    print('Full imagenet train set:  * Acc@1 {top1.global_avg:.3f} Acc@5 {top5.global_avg:.3f}'
          .format(top1=top1, top5=top5))
    return


def save_weights_as_numpy(net):
    save_torch_model_weights(net)


def prepare_datasets():
    # See: https://pytorch.org/tutorials/intermediate/tensorboard_tutorial.html
    transforms = torchvision.transforms.Compose([
        torchvision.transforms.ToTensor()
    ])
    trainset = torchvision.datasets.MNIST('./data', download=True, train=True, transform=transforms)
    testset = torchvision.datasets.MNIST('./data', download=True, train=False, transform=transforms)
    trainloader = DataLoader(trainset, batch_size=BATCH_SIZE, shuffle=True)
    testloader = DataLoader(testset, batch_size=BATCH_SIZE, shuffle=False)
    return testloader, trainloader


def quantize_network(criterion, net, testloader, trainloader):
    # Specify quantization configuration
    # Start with simple min/max range estimation and per-tensor quantization of weights
    net.qconfig = torch.quantization.default_qconfig
    print(net.qconfig)
    torch.quantization.prepare(net, inplace=True)
    # Calibrate first
    print('Post Training Quantization Prepare: Inserting Observers')
    # print('\n Inverted Residual Block:After observer insertion \n\n', net.features[1].conv)
    # Calibrate with the training set
    evaluate(net, criterion, trainloader, neval_batches=NUM_CALIBRATION_BATCHES)
    print('Post Training Quantization: Calibration done')
    # Convert to quantized model
    qnet = torch.quantization.convert(net, inplace=False)
    print('Post Training Quantization: Convert done')
    # print('\n Inverted Residual Block: After fusion and quantization, note fused modules: \n\n',
    #      net.features[1].conv)
    print("Size of model before quantization")
    print_size_of_model(net)
    print("Size of model after quantization")
    print_size_of_model(qnet)
    # top1, top5 = evaluate(net, criterion, testloader, neval_batches=NUM_EVAL_BATCHES)
    # print('Evaluation accuracy on %d images, %2.2f' % (NUM_EVAL_BATCHES * EVAL_BATCH_SIZE, top1.avg))
    top1, top5 = evaluate(net, criterion, testloader, neval_batches=NUM_EVAL_BATCHES)
    print('Evaluation accuracy on %d images, %2.2f' % (NUM_EVAL_BATCHES * EVAL_BATCH_SIZE, top1.avg))
    return qnet


def train_network(net, nepochs, criterion, optimizer, trainloader):
    history_loss = []
    history_accuracy = []
    running_loss = 0.0

    for epoch in range(nepochs):  # loop over the dataset multiple times
        for i, data in enumerate(trainloader):

            global_step = epoch * len(trainloader.dataset) + i * trainloader.batch_size

            inputs, labels = data  # get the inputs; data is a list of [inputs, labels]
            optimizer.zero_grad()  # zero the parameter gradients
            outputs = net(inputs)  # forward + backward + optimize
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            history_loss.append((global_step, float(loss)))

            pred = outputs.argmax(dim=1)  # get the index of the max log-probability
            running_loss += loss.item()
            accuracy = (pred == labels).sum() / float(len(labels))

            history_accuracy.append((global_step, float(accuracy)))

            if (i + 1) % trainloader.batch_size == 0:  # every 1000 mini-batches...
                # step = epoch * len(trainloader) + i
                print("Epoch: {:3}   MB: {:5}   Acc [%]  {:3.4} %".format(epoch, i, 100 * float(accuracy)))
                # ...log the running loss
                # writer.add_scalar('Loss', running_loss / LOG_MINI_BATCH_INTERVAL, global_step)
                # writer.add_scalar('Accuracy', scalar_value=accuracy * 100, global_step=global_step)

                # writer.add_figure('predictions vs. actuals',
                #                  plot_classes_preds(net, inputs, labels),
                #                  global_step=global_step)

                running_loss = 0.0

                if SKIP_TRAIN:
                    break

    return history_accuracy, history_loss


class Flatten(nn.Module):
    """
    Implements the flatten() function as object to be close to keras syntax
    """

    def forward(self, x):
        return x.view(x.size()[0], -1)


def save_torch_model_weights(tmodel):
    tmodel.eval()  # Put in eval mode
    for key, weights in tmodel.state_dict().items():
        weights = weights.numpy()
        # Save Binary
        np.save(file=os.path.join(EXPORT_DIR, 't_{}'.format(key)), arr=weights)
        # Save as TXT
        vals = weights.flatten(order='C')
        np.savetxt(os.path.join(EXPORT_DIR, 't_{}.txt'.format(key)), vals,
                   header=str(weights.shape))


def load_torch(filepath=TORCH_SAVE_FILE):
    # Create a model instance, make sure that save data and source code is in sync
    # model = get_lenet_model()
    # model.load_state_dict(torch.load(TORCH_STATES_SAVE_FILE))

    model = torch.load(filepath)

    return model


if __name__ == '__main__':
    torch.manual_seed(123456789)
    np.random.seed(123456789)
    main()
