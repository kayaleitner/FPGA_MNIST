#!/usr/bin/env bash

# TODO this is not up2date
# Run python test script
echo "Start running python unittests"
python -m unittest discover -s src/python/ -p "*_test.py"