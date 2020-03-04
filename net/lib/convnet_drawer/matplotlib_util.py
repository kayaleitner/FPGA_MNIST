from .convnet_drawer import *
import matplotlib.pyplot as plt


def save_model_to_file(model, filename, dpi=300):
    model.build()
    fig1 = plt.figure(figsize=(8, 6))
    ax1 = fig1.add_subplot(111, aspect='equal')
    ax1.axis('off')
    plt.xlim(model.x, model.x + model.width)
    plt.ylim(model.y + model.height, model.y)

    for feature_map in model.feature_maps + model.layers:

        if isinstance(feature_map, FeatureMap1D) and feature_map.c == 1568:
            # Trim the fully connected layer
            for object in feature_map.objects:
                if isinstance(object, Line):
                    object.y1 = object.y1 / 2
                    object.y2 = object.y2 / 2
                elif isinstance(object, Text):
                    object.y = object.y / 2


        if isinstance(feature_map, Flatten):
            print("Stop!")
            for obj in feature_map.objects:
                if isinstance(obj, Text):
                    obj.y = obj.y/2


        for obj in feature_map.objects:
            if isinstance(obj, Line):
                if obj.dasharray == 1:
                    linestyle = ":"
                elif obj.dasharray == 2:
                    linestyle = "--"
                else:
                    linestyle = "-"
                plt.plot([obj.x1, obj.x2], [obj.y1, obj.y2], color=[c / 255 for c in obj.color], lw=obj.width,
                         linestyle=linestyle)
            elif isinstance(obj, Text):
                ax1.text(obj.x, obj.y, obj.body, horizontalalignment="center", verticalalignment="bottom",
                         size=2 * obj.size / 3, color=[c / 255 for c in obj.color])

    plt.savefig(filename, dpi=dpi)
