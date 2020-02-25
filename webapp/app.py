from flask import Flask, render_template, jsonify, redirect, request
from flask_bootstrap import Bootstrap
from matplotlib import pyplot as plt
import mpld3


#import fpga
import api
from DataHandler import DataHandler
from forms import DataToFPGA


app = Flask(__name__)
Bootstrap(app)
app.config["DEBUG"] = True
app.config['SECRET_KEY'] = 'eggs-are-awesome'
DataHandler = DataHandler(app.root_path)


@app.route('/')
@app.route('/index')
def index():
    form = DataToFPGA()
    if form.validate_on_submit():
        pass
    return render_template('index.html', images=DataHandler.testImageData, labels=DataHandler.testLabelData,
                            form=form)


@app.route('/index/upload', methods=['POST'])
def upload():
    #do something
    return redirect('/')

@app.route('/index/<value>')
def image_json(value):
    form = DataToFPGA()
    if form.validate_on_submit():
        pass
    info = mpld3.fig_to_html(plt.imshow(DataHandler.testImageData[int(value) - 1]).figure)
    return render_template('index.html', images=DataHandler.testImageData, labels=DataHandler.testLabelData,
                           form=form, info=info)


@app.route('/api/get_image_json', methods=['POST'])
def get_image_json():
    data = request.get_json()
    if 0 <= data['index'] < 10000:
        return mpld3.fig_to_json(plt.imshow(DataHandler.testImageData[data['index']]).figure)
    else:
        return {'error': 'index not in range 0 to 9999'}


@app.route('/admin')
def admin():
    os_stats = fpga.get_system_stats()
    return render_template('admin.html', sys_stats=os_stats)


@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404


@app.route('/api/v1/system/get_cpu_load', methods=['GET'])
def api_all():
    load = fpga.get_cpu_load()
    return jsonify(load)


@app.route('/api/v1/system/stats', methods=['GET'])
def api_get_system_stats():
    data = fpga.get_system_stats_dict()
    return jsonify(data)


if __name__ == '__main__':
    app.debug()
    # app.run()