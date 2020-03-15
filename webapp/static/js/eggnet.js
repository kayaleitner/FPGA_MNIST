// import Vue from 'vue';
// import axios from 'axios';
// import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'


let eggnet = new Vue({

    el: '#app',

    // Add the fontawesome component. Taken from here: https://github.com/FortAwesome/vue-fontawesome
    // components: {},

    data: {
        fields: ['Images Sent', 'Correct Guesses', 'Percent', 'Time Passed'],
        items: {},

        mnist_results: [
            {index: 0, data_set: 'Train Set', n_batches: 1, network: 'CPU', accuracy: '0.999', time: '0.01'},
        ],

        mnist_fields: [
            {
                key: 'index',
                sortable: true
            },
            {
                key: 'data_set',
                label: 'Data Set',
                sortable: false
            },
            {
                key: 'n_batches',
                label: '# Batches',
                sortable: true
            },
            {
                key: 'network',
                sortable: true
            },
            {
                key: 'accuracy',
                sortable: true
            },
            {
                key: 'time',
                sortable: true
            }
        ],

        quant_4_data: [],
        quant_4_fields: [
            {
                key: 'id',
                label: 'Type',
                sortable: false
            },
            {
                key: 'bits',
                label: '$\log_2(Q)$ (Total Bits)',
                sortable: true
            },
            {
                key: 'frac',
                label: '$m$ (Fraction)',
                sortable: true
            },
        ],

        systemStats: String,
        calcnumber: '',
        image: Object,
        hasImage: false,


        benchmark_form: {
            dataset: null,
            execution: null,
            n_batches: null
        }
    },
    delimiters: ['[[', ']]'],

    methods: {
        getSystemStats: function () {
            let path = '/api/v1/system/stats';
            axios.get(path)
                .then((data => {
                    console.log(data);
                    this.systemStats = data.data;
                }));
        },


        onRunBenchmark: function (evt) {
            // console.log(JSON.stringify(this.form));
            const path = '/api/v1/run_benchmark';
            axios.post(path, this.benchmark_form)
                .then((res) => {
                    return res.data;
                })
                .then((data => {
                    console.log(data);
                    this.mnist_results.push(data)
                }));
        },

        fetch_quantization: function () {
            let path = '/api/v1/system/quant';
            axios.get(path)
                .then((data => {
                    console.log(data);
                    this.quant_4_data = data.data;
                }));
        },

        setImage(file) {
            document.getElementById('bok-prev').innerHTML = '';

            this.image = file;
            this.hasImage = true;
            data = {file};
            let path = document.location.origin + '/api/uploadimage';
            axios.post(path, data)
                .then((res) => {
                    return res.data;
                })
                .then((item) => {
                    Bokeh.embed.embed_item(item.plot, "bok-prev");
                    this.calcnumber = item.calcnumber;
                    console.log(this.calcnumber);
                })
                .catch((error) => {
                    // eslint-disable-next-line
                    console.error(error);
                });
        }
    },

    mounted() {
        this.getSystemStats();
        add_random_mnist_images();
        setup_chats();
        setInterval(this.getSystemStats, 5000);
        this.fetch_quantization();
    }
});

/**
 * Sets up the charts
 */
function setup_chats() {
    //10000 milliseconds = 10 seconds

    let cpu_usage_ctx = document.getElementById("cpu-usage-chart").getContext("2d");
    let cpu_hist_ctx = document.getElementById("cpu-history-chart").getContext("2d");

    let cpu_usage_chart = new Chart(cpu_usage_ctx, {
        type: "bar",
        data: {
            datasets: [
                {
                    label: "CPU Usage",
                    data: [],
                    backgroundColor: "rgba(30,192,20,0.2)",
                    borderColor: "rgb(15,71,38)",
                    borderWidth: 1
                }
            ]
        },
        options: {
            scales: {
                yAxes: [
                    {
                        ticks: {
                            beginAtZero: true,
                            min: 0,
                            max: 100
                        }
                    }
                ]
            }
        }
    });
    let cpu_history_chart = new Chart(cpu_hist_ctx, {
        type: "line",
        data: {
            datasets: [
                {
                    label: "CPU History",
                    data: [],
                    backgroundColor: "rgba(30,192,20,0.2)",
                    borderColor: "rgb(15,71,38)",
                    borderWidth: 1
                }
            ]
        },
        options: {
            animation: {
                duration: 0 // general animation time
            },
            lineTension: 0,
            scales: {
                yAxes: [
                    {
                        ticks: {
                            beginAtZero: true,
                            min: 0,
                            max: 100
                        }
                    }
                ],
                xAxes: [
                    {
                        ticks: {
                            beginAtZero: true,
                            min: 0,
                            max: 100
                        }
                    }
                ]
            }
        }
    });

    const max_cpu_history_values = 20;
    let cpu_history = new Array(max_cpu_history_values).fill(0);
    let cpu_history_x = new Array(max_cpu_history_values);
    for (let i = 0; i < max_cpu_history_values; i++) {
        cpu_history_x[i] = i;
    }
    const chart_refresh_interval = 2000; // 5ms
    let api_cpu_url = "/api/v1/system/get_cpu_load";
    setInterval(function () {
        $.ajax({
            type: "GET",
            url: "/api/v1/system/get_cpu_load"
        }).then(function (data) {
            let labels = data.flatMap(function (elem) {
                return "CPU" + elem.toString();
            });
            let l = [];
            for (let i = 0; i < data.length; i++) {
                l.push("CPU" + i);
            }
            console.log(data);

            // Update CPU usage
            cpu_usage_chart.data.labels = l;
            cpu_usage_chart.data.datasets[0].data = data;
            cpu_usage_chart.update();

            // Update CPU history
            let sum = 0;

            for (let i = 0; i < data.length; i++) {
                sum += parseFloat(data[i], 10); //don't forget to add the base
            }
            const avg = sum / data.length;

            cpu_history.shift();
            cpu_history.push(avg);

            let line_chart_data = [];
            for (let i = 0; i < max_cpu_history_values; i++) {
                line_chart_data[i] = {
                    x: cpu_history_x[i],
                    y: cpu_history[i],
                }
            }

            cpu_history_chart.data.labels = cpu_history_x;
            cpu_history_chart.data.datasets[0].data = line_chart_data;
            cpu_history_chart.update();
        });
    }, chart_refresh_interval);
}

/**
 * Adds random MNIST images
 */
function add_random_mnist_images() {
    let keys = [];
    for (let i = 0; i < 10; i++) {
        keys[i] = i;
    }

    const container = document.getElementById("mnist-image-container");
    const n_images_per_class = 10;
    for (let i = 0; i < n_images_per_class; i++) {
        for (let j = 0; j < 10; j++) {

            const shuffled_keys = shuffle(keys);

            let new_div = document.createElement('div');
            new_div.setAttribute('class', 'card');

            const new_img = document.createElement('img');
            new_img.src = '/static/img/mnist/' + shuffled_keys[i] + '/' + shuffled_keys[j] + '.png';
            new_img.setAttribute('class', 'mnist-image');


            new_div.appendChild(new_img);
            container.appendChild(new_div);
        }
    }

    setInterval(function () {
        container.scrollBy(1, 0);
    }, 40);
}

function pageScroll() {
    container.scrollBy(1, 0);
    scrollDelay = setTimeout(pageScroll, 10);
    scrolldelay = setTimeout(pageScroll, 10);
}

/**
 * Shuffles array in place.
 * @param {Array} a items An array containing the items.
 */
function shuffle(a) {
    let j, x, i;
    for (i = a.length - 1; i > 0; i--) {
        j = Math.floor(Math.random() * (i + 1));
        x = a[i];
        a[i] = a[j];
        a[j] = x;
    }
    return a;
}
