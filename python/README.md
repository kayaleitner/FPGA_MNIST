# Neural Network Calculation with Python and C

## Requirements

- Python3
- SWIG

## Build

Check if the build runs by opening the folder in terminal and try

```bash
python setup.py build_ext -f --build-lib .
python setup.py bdist sdist
```

or to install it into your Environment: 

```bash
# cd to the folder
pip install .
# or use
pip install path/to/folder
```

## Performance of C-Extensions

| Function      | Speed Up |
|---------------|----------|
| `conv2d`      |    236   |
| `relu`        |     2    |
| `max_pool_2d` |    165   

## Test
