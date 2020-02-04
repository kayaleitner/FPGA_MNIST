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


class ConvBNReLU(nn.Sequential):
    """
    A combined Conv2D + BatchNorm + ReLU Layer
    """

    def __init__(self, in_planes, out_planes, kernel_size=3, stride=1, groups=1):
        padding = (kernel_size - 1) // 2
        super(ConvBNReLU, self).__init__(
            nn.Conv2d(in_planes, out_planes, kernel_size, stride, padding, groups=groups, bias=False),
            nn.BatchNorm2d(out_planes, momentum=0.1),
            # Replace with ReLU
            nn.ReLU(inplace=False)
        )


class ConvBN(nn.Sequential):
    """
    A combined Conv2D + BatchNorm Layer
    """

    def __init__(self, in_planes, out_planes, kernel_size=3, stride=1, groups=1):
        padding = (kernel_size - 1) // 2
        super(ConvBN, self).__init__(
            nn.Conv2d(in_planes, out_planes, kernel_size, stride, padding, groups=groups, bias=False),
            nn.BatchNorm2d(out_planes, momentum=0.1),
        )


class LinearRelu(nn.Sequential):

    def __init__(self, in_features, out_features):
        super(LinearRelu, self).__init__(
            nn.Linear(in_features=in_features, out_features=out_features),
            nn.ReLU(inplace=False)
        )


class LeNetV2(nn.Sequential):
    """
    Improved Version with BatchNorm and Dropout
    """

    def __init__(self):
        super(LeNetV2, self).__init__(
            ConvBN(in_planes=1, out_planes=16, kernel_size=3, stride=1),
            nn.Dropout(p=0.25),
            nn.MaxPool2d(kernel_size=2, stride=2),
            ConvBN(in_planes=16, out_planes=32, kernel_size=3, stride=1),
            nn.Dropout(p=0.25),
            nn.MaxPool2d(kernel_size=2, stride=2),
            LinearRelu(in_features=32*7*7, out_features=32),
            nn.Dropout(p=0.25),
            LinearRelu(in_features=32, out_features=10),
        )


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

    def quantize(self):
        net = LeNet()
        net.conv1_1.weight = self.conv1_1.weight
        net.conv2_1.weight = self.conv2_1.weight
        net.fc1.weight = self.fc1.weight
        net.fc2.weight = self.fc2.weight

    def fuse_model(self):
        """
        Fuse Conv+BN and Conv+BN+Relu modules prior to quantization
        This operation does not change the numerics
        Returns:

        """
        import torch.quantization

        for m in self.modules():
            if type(m) == ConvBN:
                torch.quantization.fuse_modules(m, ['0', '1'], inplace=True)
            if type(m) == ConvBNReLU:
                torch.quantization.fuse_modules(m, ['0', '1', '2'], inplace=True)
            if type(m) == InvertedResidual:
                for idx in range(len(m.conv)):
                    if type(m.conv[idx]) == nn.Conv2d:
                        torch.quantization.fuse_modules(m.conv, [str(idx), str(idx + 1)], inplace=True)


class QuantLeNet(nn.Module):
    """
    From: https://github.com/Xilinx/brevitas
    """

    def __init__(self, bit_width=8, weight_bit_width=8):
        import brevitas.nn as qnn
        from brevitas.core.quant import QuantType
        super(QuantLeNet, self).__init__()
        self.conv1 = qnn.QuantConv2d(1, 6, 5,
                                     weight_quant_type=QuantType.INT,
                                     weight_bit_width=weight_bit_width, padding=2)
        self.relu1 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=bit_width, max_val=6)
        self.conv2 = qnn.QuantConv2d(6, 16, 5,
                                     weight_quant_type=QuantType.INT,
                                     weight_bit_width=weight_bit_width, padding=2)
        self.relu2 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=bit_width, max_val=6)
        self.fc1 = qnn.QuantLinear(16 * 7 * 7, 120, bias=True,
                                   weight_quant_type=QuantType.INT,
                                   weight_bit_width=weight_bit_width)
        self.relu3 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=bit_width, max_val=6)
        self.fc2 = qnn.QuantLinear(120, 84, bias=True,
                                   weight_quant_type=QuantType.INT,
                                   weight_bit_width=weight_bit_width)
        self.relu4 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=bit_width, max_val=6)
        self.fc3 = qnn.QuantLinear(84, 10, bias=False,
                                   weight_quant_type=QuantType.INT,
                                   weight_bit_width=weight_bit_width)

    def forward(self, x):
        out = F.dropout(self.relu1(self.conv1(x)), p=0.2)
        out = F.max_pool2d(out, 2)
        out = F.dropout(self.relu2(self.conv2(out)), p=0.2)
        out = F.max_pool2d(out, 2)
        out = out.view(out.size(0), -1)
        out = F.dropout(self.relu3(self.fc1(out)), p=0.2)
        out = F.dropout(self.relu4(self.fc2(out)), p=0.2)
        out = self.fc3(out)
        return out
