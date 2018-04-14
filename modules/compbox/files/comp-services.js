var upstreamBase = 'http://srcomp.sourcebots.org';

var http = require('http');
var request = require('request');

addWatcher('compbox stream', watchStream('http://localhost/stream', ['team', 'ping']));

addWatcher('compbox API', watchHTTP('http://localhost/comp-api/arenas'));

addWatcher('upstream stream', watchStream(upstreamBase + '/stream', ['team', 'ping']));

addWatcher('upstream API', watchHTTP(upstreamBase + '/comp-api/arenas'));

addWatcher('upstream sync', function(ack, err) {
    request('http://localhost/comp-api/state', function(e, response, body) {
        if (e) {
            err("downstream " + e.message);
        } else if (response.statusCode != 200) {
            err("downstream " + response.statusCode);
        } else {
            var dsState = JSON.parse(body).state;
            request(upstreamBase + '/comp-api/state', function(e, response, body) {
                if (e) {
                    err("upstream " + e.message);
                } else if (response.statusCode != 200) {
                    err("upstream " + response.statusCode);
                } else {
                    var usState = JSON.parse(body).state;
                    if (dsState === usState) {
                        ack();
                    } else {
                        err("DESYNC: upstream " + usState.substr(0, 7) + " " +
                            "downstream " + dsState.substr(0, 7));
                    }
                }
            });
        }
    });
});
