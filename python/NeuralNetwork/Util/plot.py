def trim_axs(axs, N):
    """little helper to massage the axs list to have correct length..."""
    axs = axs.flat
    for ax in axs[N:]:
        ax.remove()
    return axs[:N]


def plot_network_parameter_histogram(weights, names=None, cols=3, figsize=(10, 8)):
    """
    Plots a histogram distribution plot of the weights
    Args:
        weights:
        names:
        cols:
        figsize:

    Returns: The figure and the axes

    """
    import matplotlib.pyplot as plt

    if names is None:
        names = ["W_{}: {}".format(i, w.shape) for i, w in enumerate(weights)]
    else:
        assert len(names) == len(weights)

    rows = (len(weights) // cols) + 1

    fig1, axs = plt.subplots(rows, cols, figsize=figsize, constrained_layout=True)
    axs = trim_axs(axs, len(weights))
    i = 0
    for ax, layer_weights in zip(axs, weights):
        ax.set_title(names[i])
        ax.set_xlim([-1, 1])
        ax.hist(layer_weights.flatten())
        i += 1

    return fig1, axs
