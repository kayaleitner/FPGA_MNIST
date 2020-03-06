var eggnet = new Vue({

    el: '#app',

    data: {
        fields: ['Images Sent', 'Correct Guesses', 'Percent', 'Time Passed'],
        items: {},
        systemStats: String
    },

    delimiters: ['[[', ']]'],

    methods: {
        getSystemStats: function () {
            let path ='/api/v1/system/stats';
            axios.get(path)
                .then((data => {
                    console.log(data)
                    this.systemStats = data.data
                }));
        }
    },

    mounted() {
        this.getSystemStats()
        setInterval(this.getSystemStats, 5000)
    }
});


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

            for(let i = 0; i < data.length; i++ ) {
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


window.onload = function () {
    setup_chats()
};


