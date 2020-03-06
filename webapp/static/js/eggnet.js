var eggnet = new Vue({

    el: '#app',

    data: {
        fields: ['Images Sent', 'Correct Guesses', 'Percent', 'Time Passed'],
        items: {},
        systemStats: String
    },

    delimiters: ['[[',']]'],

    methods: {
        getSystemStats: function() {
            let path = document.location + 'api/v1/system/stats'
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

/*
<script async defer>
    window.onload = function () {
        var ctx = document.getElementById('myChart').getContext('2d');

        var api_cpu_url = "/api/v1/system/get_cpu_load";
        setInterval(function () {
            $.ajax({
                type: 'GET',
                url: '/api/v1/system/get_cpu_load',
            }).then(function (data) {
                var labels = data.flatMap(function (elem) {
                    return "CPU" + elem.toString()
                });
                var l = [];
                for (let i = 0; i < data.length; i++) {
                    l.push("CPU" + i);
                }
                console.log(data);
                myChart.data.labels = l;
                myChart.data.datasets[0].data = data;
                myChart.update();
            });
        }, 5000); //10000 milliseconds = 10 seconds

        var myChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
                datasets: [{
                    label: '# of Votes',
                    data: [12, 19, 3, 5, 2, 3],
                    backgroundColor: [
                        'rgba(255, 99, 132, 0.2)',
                        'rgba(54, 162, 235, 0.2)',
                        'rgba(255, 206, 86, 0.2)',
                        'rgba(75, 192, 192, 0.2)',
                        'rgba(153, 102, 255, 0.2)',
                        'rgba(255, 159, 64, 0.2)'
                    ],
                    borderColor: [
                        'rgba(255, 99, 132, 1)',
                        'rgba(54, 162, 235, 1)',
                        'rgba(255, 206, 86, 1)',
                        'rgba(75, 192, 192, 1)',
                        'rgba(153, 102, 255, 1)',
                        'rgba(255, 159, 64, 1)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero: true,
                            min: 0,
                            max: 100,
                        }
                    }]
                }
            }
        });
    };
</script>
*/
