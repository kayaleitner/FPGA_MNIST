const axios = require('axios').default;
const image_number = 0;


function(payload) {
    data = {"index": image_number}
    axios.post('/get_fig_json', data)
        .then( (response) => {
            response.data
        });
}

!function(mpld3) {
       mpld3.draw_figure("img-fig", {{ figure_json }});
 } (mpld3);
