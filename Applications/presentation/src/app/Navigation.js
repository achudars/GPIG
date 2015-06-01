if (!window.app) {
    window.app = {};
}
var app = window.app;

app.Navigation = function() {
    this.directionsService = new google.maps.DirectionsService();
};

app.Navigation.prototype.getRouteRecursive = function(waypts, successCallback, i) {
    if (i == waypts.length) {
        console.error("Could not fetch a suitable navigation route from Google Maps API.");
        return;
    }

    start = waypts[i];
    requestWaypoints = waypts.slice(0, i).concat(waypts.slice(i + 1, waypts.length));

    var request = {
        origin: start.location,
        // form a loop
        destination: start.location,
        waypoints: requestWaypoints,
        optimizeWaypoints: true,
        travelMode: google.maps.TravelMode.DRIVING
    };

    var self = this;
    this.directionsService.route(request, function(result, status) {
        if (status == google.maps.DirectionsStatus.OK) {
            successCallback(result.routes[0]);
        } else {
            // failed for some reason, make next request
            self.getRouteRecursive(waypts, successCallback, i + 1);
        }
    });
};

app.Navigation.prototype.displayRoute = function(route) {
    var routeLatLn = [];
    route.overview_path.forEach(function(v) {
        routeLatLn.push(ol.proj.transform([v.F, v.A], 'EPSG:4326', 'EPSG:3857'));
    });

    neighbourhoodNavigationLayer.setSource(new ol.source.Vector({
        features: [new ol.Feature({
            geometry: new ol.geom.LineString(routeLatLn, 'XY'),
            name: 'Line'
        })]
    }));
    neighbourhoodNavigationLayer.setVisible(true);
};

app.Navigation.prototype.connectCentroids = function(features) {
    var points = [];
    features.forEach(function(v) {
        var p = v.getGeometry().getCoordinates();
        p = ol.proj.transform([p[0], p[1]], 'EPSG:3857', 'EPSG:4326');
        points.push([p[1], p[0]]);
    });

    // convert all to waypoints
    var waypts = [];
    points.forEach(function(v) {
        waypts.push({
            location: v[0] + ',' + v[1],
            stopover: false
        });
    });

    this.getRouteRecursive(waypts, this.displayRoute, 0);
};

