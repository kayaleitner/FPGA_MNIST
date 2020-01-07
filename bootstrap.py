"""Purpose is to create a cross platform bootstrap file based on python
"""


import sys
import os
from os.path import join
import platform
import tarfile
import urllib.request
import shutil

if sys.version_info[0] < 3:
    raise Exception("Python 3 or a more recent version is required.")


def system(command: str, convert_slashes=False):
    if convert_slashes and platform.system() == "Windows":
        command = command.replace('/', os.path.sep)

    code = os.system(command=command)
    if code != 0:
        raise Exception(
            "'{}' returned with exit code {}".format(command, code))


def path_convert(path: str):
    # this makes sure the path is always in the correct format
    return path.replace('/', os.path.sep)


def check_if_package_manager_is_available():

    if platform.system() == "Windows":
        try:
            system('choco --version')
        except:
            raise Exception("Please install the 'Choco' package manager")
    elif platform.system() == "Darwin":
        try:
            system('brew --version')
        except:
            raise Exception("Please install the 'Choco' package manager")


class PackageManager:
    def __init__(self):
        super().__init__()
        if platform.system() == "Windows":
            self.package_command = 'choco'
        elif platform.system() == "Darwin":
            self.package_command = 'brew'
        else:
            self.package_command = 'sudo apt-get'

    def install(self, *packages):
        command = self.package_command + ' ' + ' '.join(packages)
        system(command=command)


if __name__ == "__main__":

    # Check package manager
    check_if_package_manager_is_available()

    # Make sure everything is done in the right directory
    PROJECT_DIRECTORY = os.path.dirname(os.path.abspath(__file__))
    os.chdir(PROJECT_DIRECTORY)

    # Setup consts
    LIB_VFLOAT_PATH = join(PROJECT_DIRECTORY, 'lib', 'vfloat')
    LIB_VFLOAT_URL = 'http://www.coe.neu.edu/Research/rcl/projects/floatingpoint/VFLOAT_May_2015.tar'
    VENV_PIP_PATH = path_convert('./venv/bin/pip')
    # Setup Virtualenv
    # https://stackoverflow.com/questions/1871549/determine-if-python-is-running-inside-virtualenv?noredirect=1
    if not hasattr(sys, 'real_prefix') and not os.path.exists(join(PROJECT_DIRECTORY, 'venv')):

        # update pip, install virtualenv and create a new one
        system('python -m pip install --upgrade pip')
        system('pip install virtualenv')
        system('virtualenv venv')

        # # Not sure if this works
        if platform.system() == 'Windows':
             pip_command = """
             \\venv\\Scripts\\activate.bat;
             pip install -r python\\requirements.txt
             """
        else:
             pip_command = """
             source ./venv/bin/activate;
             pip install -r python/requirements.txt
             """
        system(pip_command)

    if not os.path.exists(LIB_VFLOAT_PATH):
        os.makedirs(LIB_VFLOAT_PATH, exist_ok=True)
        (file_path, http_response) = urllib.request.urlretrieve(LIB_VFLOAT_URL,
                                                                join(LIB_VFLOAT_PATH, 'VFLOAT_May_2015.tar'))
        shutil.unpack_archive(filename=file_path, extract_dir=LIB_VFLOAT_PATH)
        # Alternative would be WGET but it is not default on most systems
        # system('wget -P lib/vfloat http://www.coe.neu.edu/Research/rcl/projects/floatingpoint/VFLOAT_May_2015.tar')

    # Install packages
    manager = PackageManager()
    manager.install('swig')


    print('Finished workspace setup. You can now simply activate your ')
