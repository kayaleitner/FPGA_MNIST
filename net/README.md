# Neural Network Training

The training can be done with either Pytorch or Keras, but Pytorch is recommended because of the unreliable
API of Tensorflow (the foundation of Keras)

Make sure you install all requirements:

````shell script
pip install -r requirements.txt
````

To train the network simply run in a terminal:

```shell script

python train_torch.py
python quantize.py

```

or use the Jupyter notebook to train the network.

## Quantisiation

For quantisation fixed point quantisation has been used.

| Network              | Accuracy |
|----------------------|---------:|
| Network:             | 0.9832   |
| Quantised Network:   | 0.9349   |
