"""Purpose is to create a cross platform bootstrap file based on python

Parts of the code from: https://bootstrap.pypa.io/ez_setup.py
"""


import sys
import os
from os.path import join
import platform
import tarfile
import shutil
import subprocess


if sys.version_info[0] < 3:
    raise Exception("Python 3 or a more recent version is required.")

try:
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen


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


def download_file_powershell(url, target):
    """
    Download the file at url to target using Powershell.

    Powershell will validate trust.
    Raise an exception if the command cannot complete.
    """
    target = os.path.abspath(target)
    ps_cmd = (
        "[System.Net.WebRequest]::DefaultWebProxy.Credentials = "
        "[System.Net.CredentialCache]::DefaultCredentials; "
        '(new-object System.Net.WebClient).DownloadFile("%(url)s", "%(target)s")'
        % locals()
    )
    cmd = [
        'powershell',
        '-Command',
        ps_cmd,
    ]
    _clean_check(cmd, target)


def has_powershell():
    """Determine if Powershell is available."""
    if platform.system() != 'Windows':
        return False
    cmd = ['powershell', '-Command', 'echo test']
    with open(os.path.devnull, 'wb') as devnull:
        try:
            subprocess.check_call(cmd, stdout=devnull, stderr=devnull)
        except Exception:
            return False
    return True


download_file_powershell.viable = has_powershell


def download_file_curl(url, target):
    cmd = ['curl', url, '--location', '--silent', '--output', target]
    _clean_check(cmd, target)


def has_curl():
    cmd = ['curl', '--version']
    with open(os.path.devnull, 'wb') as devnull:
        try:
            subprocess.check_call(cmd, stdout=devnull, stderr=devnull)
        except Exception:
            return False
    return True


download_file_curl.viable = has_curl


def download_file_wget(url, target):
    cmd = ['wget', url, '--quiet', '--output-document', target]
    _clean_check(cmd, target)


def has_wget():
    cmd = ['wget', '--version']
    with open(os.path.devnull, 'wb') as devnull:
        try:
            subprocess.check_call(cmd, stdout=devnull, stderr=devnull)
        except Exception:
            return False
    return True


download_file_wget.viable = has_wget


def download_file_insecure(url, target):
    """Use Python to download the file, without connection authentication."""
    src = urlopen(url)
    try:
        # Read all the data in one block.
        data = src.read()
    finally:
        src.close()

    # Write all the data in one block to avoid creating a partial file.
    with open(target, "wb") as dst:
        dst.write(data)


download_file_insecure.viable = lambda: True


def get_best_downloader():
    downloaders = (
        download_file_powershell,
        download_file_curl,
        download_file_wget,
        download_file_insecure,
    )
    viable_downloaders = (dl for dl in downloaders if dl.viable())
    return next(viable_downloaders, None)


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
            # \\venv\\Scripts\\activate.bat;
            pip_command = """
             \\venv\\Scripts\\activate.ps;
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
