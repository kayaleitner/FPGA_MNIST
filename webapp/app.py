from flask import Flask, render_template, jsonify, redirect, request
from bokeh.plotting import figure
from bokeh.embed import components, json_item
from bokeh.palettes import gray
from py import fpga
from py.DataHandler import DataHandler
from py.forms import DataToFPGA
import numpy as np
import base64
import cv2

app = Flask(__name__)
# Bootstrap(app)
app.config["DEBUG"] = True
app.config['SECRET_KEY'] = 'eggs-are-awesome'
DataHandler = DataHandler(app.root_path)


@app.route('/')
def index():
    form = DataToFPGA()
    im = DataHandler.testImageData[0]
    im = np.flipud(im)
    plot = figure(width=300, height=300, x_range=(0, 28), y_range=(0, 28))
    coordinates = np.where(im)
    plot.square(coordinates[1], coordinates[0], size=10)
    im_sc, im_div = components(plot)

    p = figure(plot_width=300, plot_height=300)
    ld = DataHandler.testLabelData
    x = np.arange(1, 10)
    top = [len(np.argwhere(ld == 1)),
           len(np.argwhere(ld == 2)),
           len(np.argwhere(ld == 3)),
           len(np.argwhere(ld == 4)),
           len(np.argwhere(ld == 5)),
           len(np.argwhere(ld == 6)),
           len(np.argwhere(ld == 7)),
           len(np.argwhere(ld == 8)),
           len(np.argwhere(ld == 9))]
    p.vbar(x=x, width=0.5, bottom=0,
           top=top, color="firebrick")
    hist_sc, hist_div = components(p)

    os_stats = fpga.get_system_stats()

    if form.validate_on_submit():
        pass

    return render_template('main.html', images=DataHandler.testImageData, labels=DataHandler.testLabelData,
                           form=form, im_sc=im_sc, im_div=im_div, hist_sc=hist_sc, hist_div=hist_div,
                           sys_stats=os_stats)


@app.route('/index/upload', methods=['POST'])
def upload():
    # do something
    return redirect('/')


@app.route('/index/<value>')
def image_json(value):
    form = DataToFPGA()
    if form.validate_on_submit():
        pass
    im = DataHandler.testImageData[int(value) - 1]
    plot = figure(height=300, width='scaled_width')
    return render_template('index.html', images=DataHandler.testImageData, labels=DataHandler.testLabelData,
                           form=form, info=info)


@app.route('/api/get_image_json', methods=['POST'])
def get_image_json():
    data = request.get_json()
    if 0 <= data['index'] < 10000:
        return {}
    else:
        return {'error': 'index not in range 0 to 9999'}

@app.route('/api/v1/run_benchmark', methods=['POST'])
def api_run_benchmark():
    data = request.get_json()
    id = fpga.run_benchmark(options=data)
    return jsonify(id)


@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404


@app.route('/api/v1/system/get_cpu_load', methods=['GET'])
def api_all():
    load = fpga.get_cpu_load()
    return jsonify(load)


@app.route('/api/v1/system/stats', methods=['GET'])
def api_get_system_stats():
    data = fpga.get_system_stats(verbose=False)
    return jsonify(data)


@app.after_request
def add_header(r):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    """
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r

@app.route('/api/uploadimage', methods=['GET','POST'])
def resimg():
    if request.method == 'POST':
        data = request.get_json()
        data = data['file']
        image_b64 = data.split(",")[1]
        binary = base64.b64decode(image_b64)
        image = np.asarray(bytearray(binary), dtype="uint8")
        image = cv2.imdecode(image, cv2.IMREAD_COLOR)
        image_gray = rgb2gray(image)
        image_gray = np.uint8(image_gray)

        plot = figure(
            plot_height=280,
            plot_width=280,
        )

        image_gray = np.flipud(image_gray)
        y = np.where(image_gray)[0]
        x = np.where(image_gray)[1]
        palette = gray(256)
        cols = np.take(palette, image_gray.reshape(image_gray.size))
        plot.square(x, y, color=cols, size=10)

    return json_item(plot)


def rgb2gray(rgb):
    r, g, b = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    return gray



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
