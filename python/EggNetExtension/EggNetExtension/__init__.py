"""
EggNetExtension

Import everything in this namespace
"""

try:
    if __package__ or "." in __name__:
        from .EggNetExtension import *
    else:
        from EggNetExtension import *

except:
    print("Neural Network Extension not found")
