# Configuration Panel for FPGA

## Dependencies

Python with Version 3.6 is used for development. Also the requirements can be installed via: 

```shell script
pip install -r requirements.txt
```

Also install the EggNet Package from the same repository!

## Run

For development this can be used.
```shell script
python -m flask run
```

To make it available in the local network, this can be used
```shell script
python -m flask run -h 0.0.0.0
```

## ToDo: 

- [x] Add MNIST Test Data
- [x] Add More Charts
- [x] Image Upload
- [x] Benchmark Formsheet  

## References

Build with Flask and based on the <a href="https://github.com/ColorlibHQ/AdminLTE">Admin LTE Package</a>