var shapefile = require("shapefile");
const fs = require('fs');

const jsonLinesArr = [];
shapefile.open("phm_us_shp/phm_us_shp.shp")
    .then(source => source.read()
        .then(function log(result) {
            if (result.done) {
                fs.writeFile('us_hardiness_zones__uoregon_2012.json', '{"type":"FeatureCollection", "features": ['+jsonLinesArr.join(',')+']}', err => {
                    if (err) {
                        console.error(err);
                    }
                    // file written successfully
                });
                return;
            }
            // console.log(result.value);
            jsonLinesArr.push(JSON.stringify(result.value));

            return source.read().then(log);
        }))
    .catch(error => console.error(error.stack));