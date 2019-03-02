var upstreamBase = 'http://srcomp.studentrobotics.org';

var http = require('http');
var request = require('request');

addWatcher('compbox stream', watchStream('http://localhost/stream', ['team', 'ping']));

addWatcher('compbox API', watchHTTP('http://localhost/comp-api/arenas'));

addWatcher('upstream stream', watchStream(upstreamBase + '/stream', ['team', 'ping']));

addWatcher('upstream API', watchHTTP(upstreamBase + '/comp-api/arenas'));

addWatcher('upstream sync', function(ack, err) {
    function handleStateResponse(label, next) {
        return function(e, response, body) {
            if (e) {
                err(label + " " + e.message);
            } else if (response.statusCode != 200) {
                err(label + " " + response.statusCode);
            } else {
                var state = JSON.parse(body).state;
                next(state);
            }
        }
    }

    request('http://localhost/comp-api/state', handleStateResponse(
        "downstream",
        function (dsState) {
            request(upstreamBase + '/comp-api/state', handleStateResponse(
                "upstream",
                function(usState) {
                    if (dsState === usState) {
                        ack();
                    } else {
                        err("DESYNC: upstream " + usState.substr(0, 7) + " " +
                            "downstream " + dsState.substr(0, 7));
                    }
                }
            ));
        }
    ));
});
