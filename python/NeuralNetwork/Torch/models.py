import torch
import torch.nn as nn
import torch.nn.functional as F


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
    """
    Simple implementation of the classic LeNet
    """
    def __init__(self):
        super(LeNet, self).__init__()
        self.conv1_1 = nn.Conv2d(in_channels=1, out_channels=6, kernel_size=3, stride=1, padding=1)  # [B, 28, 28, 6]
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)  # [B, 28, 28, 6], but pool function is reused
        self.conv2_1 = nn.Conv2d(in_channels=6, out_channels=16, kernel_size=3, stride=1, padding=1)  # [B, 14, 14, 16]
        self.fc1 = nn.Linear(in_features=16 * 7 * 7, out_features=64)
        self.fc2 = nn.Linear(in_features=64, out_features=10)

    def forward(self, x: torch.Tensor):
        x = self.pool(F.relu(self.conv1_1(x)))
        x = self.pool(F.relu(self.conv2_1(x)))
        x = x.view(-1, 16 * 7 * 7)
        x = F.relu(self.fc1(x))
        x = F.softmax(self.fc2(x), dim=-1)
        return x
