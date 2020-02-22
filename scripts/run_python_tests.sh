#!/usr/bin/env bash


# Run python test script
echo "Start running python unittests"
python -m unittest discover -s src/python/ -p "*_test.py"