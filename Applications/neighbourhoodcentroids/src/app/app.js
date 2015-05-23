/**
 * Add all your dependencies here.
 *
 * @require Popup.js
 * @require LayersControl.js
 */

// ========= config section ================================================
var url = '/geoserver/ows?';
var featurePrefix = 'crime';

var neighbourhoodsStatsType = 'neighbourhoods-stats';
var neighbourhoodsStatsTitle = 'Neighbourhoods Crime Stats';

var centroidsType = 'neighbourhoods-centroids';
var centroidsTitle = 'Neighbourhood Centroids';

var center = {lat: 53.958647, long: -1.082995};
var zoom = {min: 13, default: 15, max: 16};

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

filterValue = "";
// Neighbourhoods (+ stats)
var neighbourhoodsStatsSource = new ol.source.ServerVector({
    format: new ol.format.WFS({
        featureNS: 'http://localhost',
        featureType: neighbourhoodsStatsType
    }),

    loader: function(extent, resolution, projection) {
        // Transform the extent to view params for the request
        var transformed = ol.extent.applyTransform(extent, ol.proj.getTransform(projection, 'EPSG:4326'));
        var viewparams = filterValue+'AREA:' + transformed.join('\\\,') + '\\\,4326';

        // TODO: Add filters to the viewparams

        // Create the URL for the reqeust
        var url = '/geoserver/wfs?' +
            'service=WFS&request=GetFeature&' +
            'version=1.1.0&typename=' + featurePrefix + ':' + neighbourhoodsStatsType + '&'+
            'srsname='+ projection.code_ + '&' +
            'viewparams=' + viewparams;

        

        $.ajax({
            url: encodeURI(url)
        })
        .done(function(response) {
            neighbourhoodsStatsSource.addFeatures(neighbourhoodsStatsSource.readFeatures(response));
        });
    },

    strategy: ol.loadingstrategy.createTile(new ol.tilegrid.XYZ({
        maxZoom: zoom.max
    }))
});

var centroidsSource = new ol.source.ServerVector({
    format: new ol.format.WFS({
        featureNS: 'http://localhost',
        featureType: centroidsType
    }),

    loader: function(extent, resolution, projection) {
        // Transform the extent to view params for the request
        var transformed = ol.extent.applyTransform(extent, ol.proj.getTransform(projection, 'EPSG:4326'));
        var viewparams = 'AREA:' + transformed.join('\\\,') + '\\\,4326';

        // TODO: Add filters to the viewparams

        // Create the URL for the reqeust
        var url = '/geoserver/wfs?' +
            'service=WFS&request=GetFeature&' +
            'version=1.1.0&typename=' + featurePrefix + ':' + centroidsType + '&'+
            'srsname='+ projection.code_ + '&' +
            'viewparams=' + viewparams;

        $.ajax({
            url: encodeURI(url)
        })
        .done(function(response) {
            centroidsSource.addFeatures(centroidsSource.readFeatures(response));
        });
    },

    strategy: ol.loadingstrategy.createTile(new ol.tilegrid.XYZ({
        maxZoom: zoom.max
    }))
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
                'default': {
                    title: "Overlays"
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
        // Neighbourhoods (Stats)
        new ol.layer.Vector({
            source: neighbourhoodsStatsSource,
            title: neighbourhoodsStatsTitle,
            style: neighbourhoodStyle
        }),

        // Neighbourhoods (Centroids)
        new ol.layer.Vector({
            source: centroidsSource,
            title: centroidsTitle,
            style: new ol.style.Style({
                image: new ol.style.Circle({
                    fill: new ol.style.Fill({
                        color: 'rgba(255,0,0,1.0)'
                    }),
                    radius: 10,
                    snapToPixel: true
                })
            })
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

// Styling function for neighbourhoods
var neighbourhoodStyleCache = {};
function neighbourhoodStyle(feature, resolution) {
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

    var styles = neighbourhoodStyleCache[key];
    if (styles) {
        styles = styles.slice(0);

        // Adjust the text (otherwise the cached value is used, which is false)
        styles.forEach(function(style) {
            var text = style.getText();
            if (text) {
                text.setText(feature.get("name"));
            }
        });

        return styles;
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

    neighbourhoodStyleCache[key] = styles;
    return styles;
}

// Capture single clicks (for both incidents and stats)
map.on('singleclick', function(evt) {
    // Vector source has all the features available directly, perfect!
    var features = neighbourhoodsStatsSource.getFeaturesAtCoordinate(evt.coordinate);

    if (features.length > 0) {
        var feature = features[0];
        var stats_feature = feature.get("stats");
        var stats = (typeof stats_feature !== 'undefined'? JSON.parse(stats_feature): false);

        // TODO: Stylise the stats JSON into a nice popup content HTML
        popup.setPosition(evt.coordinate);
        
        if (stats) {
            popup.setContent(JSON.stringify(stats));    
        } else {
            popup.setContent("No Crimes of this type.");   
        }
        
        popup.show();
    }
});
