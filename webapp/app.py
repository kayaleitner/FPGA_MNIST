from flask import Flask, render_template, jsonify

import fpga
import api
from DataHandler import DataHandler

app = Flask(__name__)
#app.config["DEBUG"] = True
DataHandler = DataHandler(app.root_path)

@app.route('/')
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