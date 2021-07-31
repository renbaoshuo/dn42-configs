const axios = require('axios').default;

axios.get('https://api.github.com/repos/renbaoshuo/dn42-configs/contents')
    .then(response => {
        response.data.forEach(data => {
            axios.get(`https://purge.jsdelivr.net/gh/renbaoshuo/dn42-configs/${data.path}`)
                .then(r => {
                    console.log(r.data.success ? '√' : '×', `/${data.path}`);
                })
        });
    });
