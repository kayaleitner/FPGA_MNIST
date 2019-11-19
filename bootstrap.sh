#!/usr/bin/env bash

#--------- Setup dependencies ---------

# Check if vfloat exists and install it if needed
if [ ! -d "lib/vfloat" ]; then
    echo "Download VFLOAT"
    mkdir lib/vfloat 
    wget -P lib/vfloat http://www.coe.neu.edu/Research/rcl/projects/floatingpoint/VFLOAT_May_2015.tar
    echo "Uncrompress VFLOAT_May_2015.tar"
    tar -x lib/vfloat/VFLOAT_May_2015.tar --directory lib/vfloat/
    rm lib/vfloat/VFLOAT_May_2015.tar # delete archive 
fi

# Check if venv exists and install it if needed
if [ ! -d "venv" ]; then
    echo "Create VENV"
    virtualenv venv 
    echo "Install Pip dependencies"
    ./venv/activate
    pip install -r requirements.txt
fi



