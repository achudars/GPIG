/**
 *  Function for clustering OL features (assumes they are points)
 */

function kmeansClusters(features, maxClusters) {
    if (maxClusters == undefined) {
        maxClusters = 8;
    }

    if (features.length <= maxClusters) {
        return features;
    }

    // OpenLayers setup
    var sphere = new ol.Sphere(6378137); // For distance calculations

    var groups = new Array();
    var centroids = new Array();
    var oldCentroids = new Array();
    var changed = false;

    // Temp/Calculation variables
    var i = 0, j = 0;
    var distance = -1, oldDistance = -1;

    // Choose the initial centroids as batches
    var centroidGroupSize = Math.floor(features.length / (maxClusters + 1));
    for (i = 0; i < maxClusters; i++) {
        var idx = centroidGroupSize * (i + 1);
        centroids[i] = features[idx].getGeometry().getExtent();
    }

    // Actual algorithm
    do {
        // Zero out the groups
        for (j = 0; j < maxClusters; j++) {
            groups[j] = [];
        }

        changed = false;

        for (i = 0; i < features.length; i++) {
            distance = -1;
            oldDistance = -1;

            var feature = features[i];

            var extent = feature.getGeometry().getExtent();
            var c1 = ol.extent.getCenter(extent);

            for (j = 0; j < maxClusters; j++) {
                var c2 = ol.extent.getCenter(centroids[j]);

                distance = sphere.haversineDistance(c1, c2);

                if (oldDistance == -1 || distance <= oldDistance) {
                    oldDistance = distance;
                    newGroup = j;
                }
            }

            groups[newGroup].push(features[i]);
        }

        oldCentroids = centroids;
        for (j = 0; j < maxClusters; j++) {
            var geometries = [];
            newCentroid = 0;

            for (i=0; i < groups[j].length; i++){
                geometries.push(groups[j][i].getGeometry());
            }

            var collection = new ol.geom.GeometryCollection({
                geometries: geometries
            });

            centroids[j] = collection.getExtent();
            if (centroids[j] != oldCentroids[j]) {
                changed = true;
            }
        }
    } while(changed == true);

    // Filter out the empty groups
    groups = groups.filter(function(element) {
        return element.length > 0;
    });

    // Create features out of the groups
    var results = groups.map(function(group) {
        var feature = group[0];
        var center = feature.getGeometry().getPoint();
        var crime = [feature.get('crime')];
        var size = group.length;

        for (var i = 1, l = group.length; i < l; i++) {
            var feature = group[i];

            var nextPoint = group[i].getGeometry().getPoint();
            center = center.midPoint(nextPoint);

            var type = feature.get('crime');
            if (crime.indexOf(type) == -1) {
                crime.push(type);
            }
        }

        var result = new ol.Feature({
            geometry: center
        });

        result.set('features', group);
        result.set('size', size);
        result.set('crime', crime);

        return result;
    });

    return results;
}
