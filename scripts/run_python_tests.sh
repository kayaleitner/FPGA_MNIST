#!/usr/bin/env bash

# ToDo: this is not up2date
# Run python test script
echo "Start running python unittests"
python -m unittest discover -s src/python/ -p "*_test.py"