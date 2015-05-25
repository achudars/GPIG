/**
 *  Styling functions
 */

// Styling function for neighbourhoods
function generateNeighbourhoodStyle(feature, resolution) {
    // Determine the key for this feature
    var count = parseInt(feature.get('crimecount'));
    var key;

    if (count < 100) {
        key = 'very low';
    } else if (count < 200) {
        key = 'low';
    } else if (count < 500) {
        key = 'medium';
    } else if (count < 1000) {
        key = 'high';
    } else {
        key = 'very high';
    }

    // Shared styles
    var styles = [
        // Everybody has a stroke and a text fill style
        new ol.style.Style({
            stroke: new ol.style.Stroke({
                color: 'rgba(0,0,0,0.5)',
                width: 1
            }),

            text: new ol.style.Text({
                font: '14px Helvetica, sans-serif',
                text: feature.get("name"),
                fill: new ol.style.Fill({
                    color: "#000"
                }),
                stroke: new ol.style.Stroke({
                    color: "#FFF",
                    width: 3
                })
            })
        })
    ]

    // Dynamic styles
    var count = parseInt(feature.get("crimecount"));
    if (key == 'very low') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(115,206,255,0.35)'
            })
        }));
    } else if (key == 'low') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(187,255,255,0.35)'
            })
        }));
    } else if (key == 'medium') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(255,243,101,0.35)'
            })
        }));
    } else if (key == 'high') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(255,155,30,0.35)'
            })
        }));
    } else {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(255,22,4,0.35)'
            })
        }));
    }

    return styles;
}

// Styling for incidents
function generateIncidentStyle(feature, resolution) {
    // Check if this is a cluster
    var clustered = feature.get('features');
    if (clustered != undefined && clustered.length > 1) {
        console.log("clustered");
    } else {
        // Single feature
        console.log("Single feature or no features");
    }

    return [new ol.style.Style({
        image: new ol.style.Circle({
            fill: new ol.style.Fill({
                color: 'red'
            }),
            radius: 3,
            snapToPixels: true
        })
    })];
}
