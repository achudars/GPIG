/**
 * Add all your dependencies here.
 *
 * @require Popup.js
 * @require LayersControl.js
 * @require Stats.js
 * @require Style.js
 */

// ========= config section ================================================
var url = '/geoserver/ows?';
var featurePrefix = 'crime';

// By default center around York
var center = {lat: 53.958647, long: -1.082995};
var zoom = {min: 14, default: 16, max: 19};

var neighbourhoodsStatsType = 'neighbourhoods-stats';
var neighbourhoodsStatsTitle = 'Neighbourhoods Stats';

var incidentsType = 'incidents';
var incidentsTitle = 'Incidents';

var infoFormat = 'application/json';

// =========================================================================

// Projection for the map
var proj = new ol.proj.Projection({
    code: 'http://www.opengis.net/gml/srs/epsg.xml#4326',
    axis: 'enu'
});
ol.proj.addEquivalentProjections([ol.proj.get('EPSG:4326'), proj]);

// create a new popup with a close box
// the popup will draw itself in the popup div container
// autoPan means the popup will pan the map if it's not visible (at the edges of the map).
var popup = new app.Popup({
    element: document.getElementById('popup'),
    closeBox: true,
    autoPan: true
});

/**
 *  Sources
 */

// Neighbourhoods (+ stats)
var neighbourhoodsStatsSource = new ol.source.ServerVector({
    format: new ol.format.WFS({
        featureNS: 'http://localhost',
        featureType: neighbourhoodsStatsType
    }),

    loader: function(extent, resolution, projection) {
        // Transform the extent to view params for the request
        var transformed = ol.extent.applyTransform(extent, ol.proj.getTransform(projection, 'EPSG:4326'));
        var viewparams = "AREA:" + transformed.join('\\\,') + '\\\,4326';

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
        maxZoom: zoom.max,
        minZoom: zoom.min
    }))
});

// Incidents (as a vector for clustering/styling)
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
            url: encodeURI(url)
        })
        .done(function(response) {
            incidentsSource.addFeatures(incidentsSource.readFeatures(response));
        });
    },

    strategy: ol.loadingstrategy.createTile(new ol.tilegrid.XYZ({
        maxZoom: zoom.max,
        minZoom: zoom.min
    }))
});

var incidentsClusterSource = new ol.source.Cluster({
    source: incidentsSource,
    distance: 60
});

// Listen to the events to recalculate the encapsulated crime types
function recalculateClusterInfo(feature) {
    var clustered = feature.get('features');
    var crimes = clustered.reduce(function(currentValue, element) {
        var crime = element.get('crime');
        if (crime && currentValue.indexOf(crime) == -1) {
            currentValue.push(crime);
        }

        return currentValue;
    }, []).sort();

    if (feature.get('crime') != crimes) {
        feature.set('crime', crimes);
    }

    if (feature.get('size') != clustered.length) {
        feature.set('size', clustered.length);
    }
}

incidentsClusterSource.on('addfeature', function(evt) {
    var feature = evt.feature;
    recalculateClusterInfo(feature);
});

/**
 *  Map
 */

// Create the OL map
// Add a layer switcher to the map with two groups:
// 1. background, which will use radio buttons
// 2. default (overlays), which will use checkboxes
var map = new ol.Map({
    controls: ol.control.defaults().extend([
        new app.LayersControl({
            groups: {
                background: {
                    title: "Base Layer",
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
        // Standard
        new ol.layer.Tile({
            title: 'Standard',
            group: 'background',
            source: new ol.source.XYZ({
                urls: ['http://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        'http://b.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        'http://c.tile.openstreetmap.org/{z}/{x}/{y}.png']
            }),
            visible: false
        }),

        // Mapnik
        new ol.layer.Tile({
            title: 'Mapnik',
            group: 'background',
            source: new ol.source.XYZ({
                urls: ['http://otile1.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
                        'http://otile2.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
                        'http://otile3.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
                        'http://otile4.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png']
            }),
            visible: false
        }),

        // CartoDB Light
        new ol.layer.Tile({
            title: 'CartoDB Light',
            group: "background",
            source: new ol.source.XYZ({
                url: 'http://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                attributions: [new ol.Attribution({ html: ['&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>'] })]
            })
        }),

        // CartoDB Dark
        new ol.layer.Tile({
            title: 'CartoDB Dark',
            group: "background",
            source: new ol.source.XYZ({
                url: 'http://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                attributions: [new ol.Attribution({ html: ['&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>'] })]
            }),
            visible: false
        }),

        // Humanitarian
        new ol.layer.Tile({
            title: 'Humanitarian',
            group: 'background',
            source: new ol.source.XYZ({
                urls: ['http://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                        'http://b.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                        'http://c.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png']
            }),
            visible: false
        }),

        // Custom sources
        // Neighbourhoods (Stats)
        new ol.layer.Vector({
            source: neighbourhoodsStatsSource,
            title: neighbourhoodsStatsTitle,
            style: function(feature, resolution) {
                return app.sharedStyle.generateNeighbourhoodStyle(feature, resolution);
            },
            visible: false
        }),

        new ol.layer.Vector({
            source: incidentsClusterSource,
            title: incidentsTitle,
            style: function(feature, resolution) {
                return app.sharedStyle.generateIncidentStyle(feature, resolution);
            },
            visible: true
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

/**
 *  Interactions
 */

function getLayerFromFeature(feature) {
    var found = null;
    map.getLayers().forEach(function(layer) {
        if (!(layer instanceof ol.layer.Vector)) {
             return false;
           }

           if (layer.getSource().getFeatureById(feature.getId()) != undefined) {
               found = layer;
               return true;
           }
    });

    return found;
}

// TODO: There might be a nicer way to create these functions, in essence it is about
// setting a variable, but also raising/lowering a flag and re-rendering

// Special features (hover/highlight etc.)
function setSpecialFeature(key, feature, redraw) {
    if (redraw == undefined) {
        redraw = true;
    }

    if (!window.specialFeatures) {
        window.specialFeatures = {};
    }
    var features = window.specialFeatures;

    var previousFeature = features[key];
    if (previousFeature === feature) {
        return;
    }

    if (previousFeature != undefined) {
        previousFeature.set(key, false);
        if (redraw) {
            var styleFunction = getLayerFromFeature(previousFeature).getStyleFunction();
            previousFeature.setStyle(styleFunction(previousFeature, null));
        }

        delete features[key];
    }

    if (feature != undefined) {
        feature.set(key, true);
        var styleFunction = getLayerFromFeature(feature).getStyleFunction();
        feature.setStyle(styleFunction(feature, null));
        features[key] = feature;
    }
}

// when the popup is closed, clear the highlight
$(popup).on('close', function() {
    // Clear the highlight
    setSpecialFeature('highlighted', null);
});

// Capture hover events
map.on('pointermove', function(evt) {
    if (evt.dragging) {
        return;
    }

    // Ignore events that are within overlays (to avoid weird ghosting)
    var element = document.elementFromPoint(evt.browserEvent.clientX, evt.browserEvent.clientY);

    var disable = false;
    map.getOverlays().forEach(function(overlay, idx) {
        var container = overlay.getElement();
        if (container === element || $.contains(overlay.getElement(), element)) {
            disable = true;
            return false;
        }
    });

    if (disable == false) {
        var coordinate = map.getEventCoordinate(evt.originalEvent);
        var features = neighbourhoodsStatsSource.getFeaturesAtCoordinate(coordinate);
        if (features.length > 0) {
            setSpecialFeature('hover', features[0]);
        } else {
            setSpecialFeature('hover', null);
        }
    } else {
        setSpecialFeature('hover', null);
    }
});

// Capture single clicks (for both incidents and stats)
map.on('singleclick', function(evt) {
    // Vector source has all the features available directly, perfect!
    var features = neighbourhoodsStatsSource.getFeaturesAtCoordinate(evt.coordinate);

    if (features.length > 0) {
        var feature = features[0];

        // Set the feature as highlighted and re-render
        setSpecialFeature('highlighted', feature);

        if (typeof generatePopupContent == 'function') {
            var content = generatePopupContent(feature, popup);
            popup.setContent(content);
            popup.setPosition(evt.coordinate);
        }

        popup.show();
    } else {
        setSpecialFeature('highlighted', null);
        popup.hide();
    }
});
