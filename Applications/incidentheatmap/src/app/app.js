/**
 * Add all your dependencies here.
 *
 * @require Popup.js
 * @require LayersControl.js
 */

// ========= config section ================================================
var url = '/geoserver/ows?';
var featurePrefix = 'crime';

var incidentsType = 'incidents';

var center = {lat: 53.958647, long: -1.082995};
var zoom = {min: 14, default: 15, max: 16};

var infoFormat = 'application/json';

// =========================================================================

// Override the axis orientation for WMS GetFeatureInfo
var proj = new ol.proj.Projection({
    code: 'http://www.opengis.net/gml/srs/epsg.xml#4326',
    axis: 'enu'
});
ol.proj.addEquivalentProjections([ol.proj.get('EPSG:4326'), proj]);

// Create a new popup with a close box
// The popup will draw itself in the popup div container
// autoPan means the popup will pan the map if it's not visible (at the edges of the map).
var popup = new app.Popup({
    element: document.getElementById('popup'),
    closeBox: true,
    autoPan: true
});

// Incidents (as a vector source)
var incidentsSource = new ol.source.ServerVector({
    format: new ol.format.WFS({
        featureNS: 'http://localhost',
        featureType: incidentsType
    }),

    loader: function(extent, resolution, projection) {
        // Create the URL for the request
        var url = '/geoserver/wfs?' +
            'service=WFS&request=GetFeature&' +
            'version=1.1.0&typename=' + featurePrefix + ':' + incidentsType + '&'+
            'srsname='+ projection.code_ + '&' +
            'bbox=' + extent.join(',') + ',' + projection.code_;

        $.ajax({
            url: url
        })
        .done(function(response) {
            incidentsSource.addFeatures(incidentsSource.readFeatures(response));
        });
    },

    strategy: ol.loadingstrategy.createTile(new ol.tilegrid.XYZ({
        maxZoom: zoom.max
    }))
});

var incidentsClusterSource = new ol.source.Cluster({
    source: incidentsSource,
    distance: 60
});

incidentsClusterSource.on('addfeature', function(event) {
    var weight = event.feature.get('features').reduce(function(currentWeight, nextFeature) {
        return currentWeight + parseInt(nextFeature.get('weight'));
    }, 0);

    // Normalise weight (assuming anything above 250 is "too much")
    event.feature.set('weight', weight / 250.0);
});


// Create the OL map
// Add a layer switcher to the map with two groups:
// 1. background, which will use radio buttons
// 2. default (overlays), which will use checkboxes
var map = new ol.Map({
    controls: ol.control.defaults().extend([
        new app.LayersControl({
            groups: {
                background: {
                    title: "Base Layers",
                    exclusive: true
                },
                incidents: {
                    title: "Incidents",
                    exclusive: true
                }
            }
        })
    ]),

    // add the popup as a map overlay
    overlays: [popup],

    // render the map in the 'map' div
    // use the Canvas renderer
    target: document.getElementById('map'),
    renderer: 'canvas',

    // layers
    layers: [
        // MapQuest streets
        new ol.layer.Tile({
            title: 'Street Map',
            group: "background",
            source: new ol.source.MapQuest({layer: 'osm'})
        }),
        // MapQuest imagery
        new ol.layer.Tile({
            title: 'Aerial Imagery',
            group: "background",
            visible: false,
            source: new ol.source.MapQuest({layer: 'sat'})
        }),
        // MapQuest hybrid (uses a layer group)
        new ol.layer.Group({
            title: 'Imagery with Streets',
            group: "background",
            visible: false,
            layers: [
                new ol.layer.Tile({
                    source: new ol.source.MapQuest({layer: 'sat'})
                }),
                new ol.layer.Tile({
                    source: new ol.source.MapQuest({layer: 'hyb'})
                })
            ]
        }),

        // Custom sources
        // Incidents (as points)
        new ol.layer.Vector({
            source: incidentsSource,
            title: 'Incidents',
            style: new ol.style.Style({
                image: new ol.style.Circle({
                    fill: new ol.style.Fill({
                        color: 'red'
                    }),
                    radius: 3,
                    snapToPixels: true
                })
            }),
            visible: false,
            group: "incidents"
        }),

        // Incidents (as heatmap)
        new ol.layer.Heatmap({
            source: incidentsClusterSource,
            title: 'Incidents Heatmap',
            group: "incidents",
            shadow: 120,
            radius: 30,
            blur: 60
        })
    ],

    // initial center and zoom of the map's view
    view: new ol.View({
        center: ol.proj.transform([center.long, center.lat], 'EPSG:4326', 'EPSG:3857'),
        zoom: zoom.default,
        maxZoom: zoom.max,
        minZoom: zoom.min
    })
});
