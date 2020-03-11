"""
Connect to the FPGA inside of this file
"""

import EggNet
import EggNet.Reader
import numpy as np
import os

from EggNet import FpiLeNet


def get_size(size_in_bytes, suffix="B"):
    """
    Scale bytes to its proper format
    e.g:
        1253656 => '1.20MB'
        1253656678 => '1.17GB'
    """
    factor = 1024
    for unit in ["", "K", "M", "G", "T", "P"]:
        if size_in_bytes < factor:
            return f"{size_in_bytes:.2f}{unit}{suffix}"
        size_in_bytes /= factor


def get_system_stats(verbose=False):
    """
    Collects interesting system stats

    From: https://www.thepythoncode.com/article/get-hardware-system-information-python

    :return: a string containing useful stats
    """
    import psutil
    import platform
    from datetime import datetime

    uname = platform.uname()
    boot_time_timestamp = psutil.boot_time()
    bt = datetime.fromtimestamp(boot_time_timestamp)
    svmem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    net_io = psutil.net_io_counters()
    if_addrs = psutil.net_if_addrs()

    if verbose:

        print(f"System: {uname.system}")
        print(f"Node Name: {uname.node}")
        print(f"Release: {uname.release}")
        print(f"Version: {uname.version}")
        print(f"Machine: {uname.machine}")
        print(f"Processor: {uname.processor}")

        ##### Boot Time ########
        print("=" * 40, "Boot Time", "=" * 40)

        print(f"Boot Time: {bt.year}/{bt.month}/{bt.day} {bt.hour}:{bt.minute}:{bt.second}")

        ###### CPU ########
        # let's print CPU information
        print("=" * 40, "CPU Info", "=" * 40)
        # number of cores
        print("Physical cores:", psutil.cpu_count(logical=False))
        print("Total cores:", psutil.cpu_count(logical=True))

        # CPU frequencies
        # ToDo: cpu_freq() doesnt work on the Zedboard (Linaro/Ubuntu/Lib Error?)
        # cpufreq = psutil.cpu_freq()
        # if cpufreq is not None:
        #     print(f"Max Frequency: {cpufreq.max:.2f}Mhz")
        #     print(f"Min Frequency: {cpufreq.min:.2f}Mhz")
        #     print(f"Current Frequency: {cpufreq.current:.2f}Mhz")
        # CPU usage

        print("CPU Usage Per Core:")
        for i, percentage in enumerate(psutil.cpu_percent(percpu=True)):
            print(f"Core {i}: {percentage}%")
        print(f"Total CPU Usage: {psutil.cpu_percent()}%")

        ### MEMORY
        # Memory Information
        print("=" * 40, "Memory Information", "=" * 40)
        # get the memory details

        print(f"Total: {get_size(svmem.total)}")
        print(f"Available: {get_size(svmem.available)}")
        print(f"Used: {get_size(svmem.used)}")
        print(f"Percentage: {svmem.percent}%")
        print("=" * 20, "SWAP", "=" * 20)
        # get the swap memory details (if exists)

        print(f"Total: {get_size(swap.total)}")
        print(f"Free: {get_size(swap.free)}")
        print(f"Used: {get_size(swap.used)}")
        print(f"Percentage: {swap.percent}%")

        ### Network
        # Network information
        print("=" * 40, "Network Information", "=" * 40)
        # get all network interfaces (virtual and physical)

        for interface_name, interface_addresses in if_addrs.items():
            for address in interface_addresses:
                print(f"=== Interface: {interface_name} ===")
                if str(address.family) == 'AddressFamily.AF_INET':
                    print(f"  IP Address: {address.address}")
                    print(f"  Netmask: {address.netmask}")
                    print(f"  Broadcast IP: {address.broadcast}")
                elif str(address.family) == 'AddressFamily.AF_PACKET':
                    print(f"  MAC Address: {address.address}")
                    print(f"  Netmask: {address.netmask}")
                    print(f"  Broadcast MAC: {address.broadcast}")
        # get IO statistics since boot

        print(f"Total Bytes Sent: {get_size(net_io.bytes_sent)}")
        print(f"Total Bytes Received: {get_size(net_io.bytes_recv)}")

    # Combine as a string
    os_stats = f"""
    System: {uname.system}
    Node Name: {uname.node}
    Release: {uname.release}
    Version: {uname.version}
    Machine: {uname.machine}
    Processor: {uname.processor}
    

    {'=' * 40} Boot Time {'=' * 40}
    Boot Time: {bt.year}/{bt.month}/{bt.day} {bt.hour}:{bt.minute}:{bt.second}
    
    {'=' * 40}    CPU    {'=' * 40}
    Physical cores: {psutil.cpu_count(logical=False)}
    Total cores: {psutil.cpu_count(logical=True)}
    Total CPU Usage: {psutil.cpu_percent()}

    
    {'=' * 40} Memory Information {'=' * 40}
    Total: {get_size(svmem.total)}
    Available: {get_size(svmem.available)}
    Used: {get_size(svmem.used)}
    Percentage: {svmem.percent}
    
    {'=' * 40} SWAP {'=' * 40}
    Total: {get_size(swap.total)}
    Free: {get_size(swap.free)}
    Used: {get_size(swap.used)}
    Percentage: {swap.percent}
    """

    return os_stats


def get_system_stats_dict():
    import psutil
    import platform

    uname = platform.uname()
    if_addrs = psutil.net_if_addrs()
    net_io = psutil.net_io_counters()
    swap = psutil.swap_memory()
    svmem = psutil.virtual_memory()
    bt = psutil.boot_time()

    # ToDo: This is not supported at the moment on Linaro.
    # cpufreq = psutil.cpu_freq()

    stats = {
        "System": uname.system,
        "Node Name": uname.node,
        "Release": uname.release,
        "Version": uname.version,
        "Machine": uname.machine,
        "Processor": uname.processor,
        "Boot": {
            "Boot Time": f"{bt.year}/{bt.month}/{bt.day} {bt.hour}:{bt.minute}:{bt.second}"
        },
        "CPU": {
            "Physical cores": psutil.cpu_count(logical=False),
            "Total cores": psutil.cpu_count(logical=True),
            # "Max Frequency": f"{cpufreq.max:.2f}Mhz",
            # "Min Frequency": f"{cpufreq.min:.2f}Mhz",
            # "Current Frequency": f"{cpufreq.current:.2f}Mhz",
            "Total CPU Usage": psutil.cpu_percent()
        },
        "Memory": {
            "Total": get_size(svmem.total),
            "Available": get_size(svmem.available),
            "Used": get_size(svmem.used),
            "Percentage": svmem.percent,
        },
        "Swap": {
            "Total": get_size(swap.total),
            "Free": get_size(swap.free),
            "Used": get_size(swap.used),
            "Percentage": swap.percent,
        },
        "Network": {
            "Total Bytes Sent": get_size(net_io.bytes_sent),
            "Total Bytes Received": get_size(net_io.bytes_recv)
        }
    }


def get_cpu_load():
    import psutil
    return psutil.cpu_percent(percpu=True)


def get_current_system_name():
    import socket
    return socket.gethostname()


def get_uptime():
    """
    Returns the current system uptime for linux systems
    :return: the uptime as a string and as timedelta object
    """
    from datetime import timedelta

    with open('/proc/uptime', 'r') as f:
        uptime_seconds = float(f.readline().split()[0])
        upt = timedelta(seconds=uptime_seconds)
        uptime_string = str(timedelta(seconds=uptime_seconds))

    return uptime_string, upt


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TRAIN_IMAGES = os.path.join(BASE_DIR, '../train-images-idx3-ubyte.gz')
TRAIN_LABELS = os.path.join(BASE_DIR, '../train-labels-idx1-ubyte.gz')
TEST_IMAGES = os.path.join(BASE_DIR, '../t10k-images-idx3-ubyte.gz')
TEST_LABELS = os.path.join(BASE_DIR, '../t10k-labels-idx1-ubyte.gz')


def run_benchmark(options):
    import time

    use_int_images = options['execution'].endswith('_fpi')

    if options['execution'] == 'cpu_fpi':
        net = get_fpi_network_instance()
    elif options['execution'] == 'cpu_float':
        net = get_float_network_instance()
    else:
        raise NotImplementedError()

    if options['dataset'] == 'test':
        imgs = EggNet.Reader.MNIST.idxgz2numpy(TEST_IMAGES)
        lbls = EggNet.Reader.MNIST.idxgz2numpy(TEST_LABELS)
    elif options['dataset'] == 'train':
        imgs = EggNet.Reader.MNIST.idxgz2numpy(TEST_IMAGES)
        lbls = EggNet.Reader.MNIST.idxgz2numpy(TEST_LABELS)
    else:
        raise NotImplementedError()

    start_time = time.time()
    acc = net.evaluate_network_accuracy(batch_size=50, train_images=imgs, train_labels=lbls,
                                        images_as_int=use_int_images, n_batches=options['n_batches'])
    end_time = time.time()
    delta_t = end_time - start_time

    # Return the data
    d = {
        'index': 0,
        'data_set': options['dataset'],
        'network': options['execution'],
        'accuracy': f"{acc:g}",
        'time': f"{delta_t:g}",
        'n_batches': options['n_batches']
    }

    return d


def get_fpi_network_instance():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    npz_filepath = os.path.abspath(os.path.join(BASE_DIR, '../../net/final_weights/int4_fpi/all.npz'))
    config_path = os.path.abspath(os.path.join(BASE_DIR, '../../net/final_weights/int4_fpi/config.json'))
    return EggNet.FpiLeNet.init_npz(npz_path=npz_filepath, config_path=config_path)


def get_float_network_instance():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    npz_filepath = os.path.abspath(os.path.join(BASE_DIR, '../../net/final_weights/float/all.npz'))
    return EggNet.LeNet.init_npz(npz_path=npz_filepath)


def eval_image(image):
    # Extend Image
    net = get_fpi_network_instance()

    x = np.reshape(image, (1, 28, 28)).astype(np.int32)
    y = net.forward(inputs=x)
    return int(y.argmax(-1))


if __name__ == '__main__':
    eval_image(np.zeros((28, 28)))
