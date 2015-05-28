/**
 * Add all your dependencies here.
 *
 * @require LayersControl.js
 * @require FiltersControl.js
 * @require Stats.js
 * @require Style.js
 * @require PoliceDistribution.js
 */

// ========= config section ================================================
var url = '/geoserver/ows?';
var featurePrefix = 'crime';

// By default center around York
var center = {lat: 53.958647, long: -1.082995};
var zoom = {min: 15, default: 15, max: 19};

var neighbourhoodsStatsType = 'neighbourhood-statsistics';
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

// Styling objects for different layers
var styles = {
    neighbourhoods: new app.Style(),
    incidents: new app.Style()
};

// Mode for the application
const MODE = Object.freeze({INTERACTION: 0, SELECTION: 1});
var mode = MODE.INTERACTION;

// Selected neighbourhoods
var selectedNeighbourhoodGIDs = [];

// Police distributor
var policeDistributor = new app.PoliceDistributor();

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

        if (this.filter) {
            viewparams += ";" + this.filter;
        }

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
            var features = neighbourhoodsStatsSource.readFeatures(response);

            // Re-apply the suitable dimmed ignoring flags
            features.forEach(function(element) {
                if (selectedNeighbourhoodGIDs.indexOf(element.getId()) != -1) {
                    element.set('dimmed', false);
                }
            });

            neighbourhoodsStatsSource.addFeatures(features);
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
            'srsname='+ projection.code_ +
            '&CQL_FILTER={{CQLFILTER}}';

        var cqlFilterBBox =  "BBOX(geom, " + extent.join(',') + ",'" + projection.code_ + "')";
        var cqlFilter = cqlFilterBBox;

        if (this.cqlFilter) {
            cqlFilter += " AND " + this.cqlFilter;
        }

        url = url.replace('{{CQLFILTER}}', cqlFilter);

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
incidentsClusterSource.on('addfeature', function(evt) {
    var feature = evt.feature;

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

    recalculateClusterInfo(feature);
});

/**
 *  Map
 */

// Create the OL map
var map = new ol.Map({
    controls: ol.control.defaults().extend([
        new app.LayersControl({
            groups: {
                background: {
                    title: "Base Layer",
                    exclusive: true
                },
                overlays: {
                    title: "Overlays"
                }
            }
        }),

        new app.FiltersControl({
            sources: [neighbourhoodsStatsSource, incidentsSource]
        })
    ]),

    // Render the map in the 'map' div
    // use the Canvas renderer
    target: document.getElementById('map'),
    renderer: 'canvas',

    // Layers
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
                urls: ['http://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                        'http://b.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                        'http://c.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                        'http://d.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png'],
                tilePixelRatio: 2,
                attributions: [new ol.Attribution({ html: ['&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>'] })]
            })
        }),

        // CartoDB Dark
        new ol.layer.Tile({
            title: 'CartoDB Dark',
            group: "background",
            source: new ol.source.XYZ({
                urls: ['http://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                        'http://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                        'http://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                        'http://d.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'],
                tilePixelRatio: 2,
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
            group: 'overlays',
            style: function(feature, resolution) {
                return styles.neighbourhoods.generateNeighbourhoodStyle(feature, resolution);
            },
            visible: true
        }),

        new ol.layer.Vector({
            source: incidentsClusterSource,
            title: incidentsTitle,
            group: 'overlays',
            style: function(feature, resolution) {
                return styles.incidents.generateIncidentStyle(feature, resolution);
            },
            visible: false
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
 *  Helpers
 */

function preventDefault(event) {
    event.preventDefault();
}

function restyleLayer(layer) {
    // Loop over all visible features on the layer and re-apply their style
    var source = layer.getSource();
    var styleFunction = layer.getStyleFunction();
    var resolution = map.getView().getResolution();
    var features = source.getFeatures();

    for (var i = 0, l = features.length; i < l; i++) {
        var feature = features[i];
        feature.setStyle(styleFunction(feature, resolution));
    }
}

function restyleFeature(feature) {
    var layer = getLayerFromFeature(feature);
    var styleFunction = layer.getStyleFunction();
    var resolution = map.getView().getResolution();
    feature.setStyle(styleFunction(feature, resolution));
}

function getLayerFromFeature(feature) {
    var found = undefined;
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

function getLayerForTitle(title) {
    var found = undefined;
    map.getLayers().forEach(function(layer) {
        if (layer.get('title') == title) {
            found = layer;
            return true;
        }
    });

    return found;
}

function setMode(newMode) {
    if (mode == newMode) {
        return;
    }

    if (newMode == MODE.INTERACTION) {
        mode = newMode;

        // Alter the title of every selection button
        $(".selection-toggle").text('Select Regions');

        // Undim the neighbourhoods layer
        styles.neighbourhoods.dimmed = false;
        var layer = getLayerForTitle(neighbourhoodsStatsTitle);
        restyleLayer(layer);

    } else if (newMode == MODE.SELECTION) {
        mode = newMode;

        // Alter the title of every selection button
        $(".selection-toggle").text('Cancel Selection');

        styles.neighbourhoods.dimmed = true;
        var layer = getLayerForTitle(neighbourhoodsStatsTitle);
        restyleLayer(layer);
    }
}

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

    if (previousFeature != undefined && typeof previousFeature != undefined) {
        // unset does not work, and setting to false is not always correct
        if (previousFeature.values_[key])
            delete previousFeature.values_[key];

        if (redraw) {
            var layer = getLayerFromFeature(previousFeature);

            if (layer) {
                var styleFunction = getLayerFromFeature(previousFeature).getStyleFunction();
                previousFeature.setStyle(styleFunction(previousFeature, null));
            }
        }

        delete features[key];
    }

    if (feature != undefined &&  typeof feature != undefined) {
        feature.set(key, true);

        if (redraw) {
            var styleFunction = getLayerFromFeature(feature).getStyleFunction();
            feature.setStyle(styleFunction(feature, null));
        }

        features[key] = feature;
    }
}

/**
 *  Interactions
 */

function resetView() {
    var view = map.getView();

    map.beforeRender(new ol.animation.pan({
        duration: 750,
        source: view.getCenter()
    }), new ol.animation.zoom({
        duration: 750,
        resolution: view.getResolution()
    }));

    view.setCenter(ol.proj.transform([center.long, center.lat], 'EPSG:4326', view.getProjection()));
    view.setZoom(zoom.default);
}

function toggleMode(event) {
    if (mode == MODE.INTERACTION) {
        setMode(MODE.SELECTION);

        if (selectedNeighbourhoodGIDs.length > 0) {
            $(".selection-required").removeClass("disabled");
            $('a.selection-required').off("click", preventDefault);
        }
    } else if (mode == MODE.SELECTION) {
        setMode(MODE.INTERACTION);

        $(".selection-required").addClass("disabled");
        $('a.selection-required').on("click", preventDefault);
    }
}

function distributeForces(event) {
    if ($(event.target).hasClass("disabled"))
        return;

    var features = neighbourhoodsStatsSource.getFeatures().filter(function(element) {
        return selectedNeighbourhoodGIDs.indexOf(element.getId()) != -1;
    });
    
    policeDistributor.setNeighbourhoods(features);
    policeDistributor.startDistributionFlow();
}

// Capture hover events
map.on('pointermove', function(evt) {
    // Ignore panning events
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

// Capture single clicks (in both modes)
map.on('singleclick', function(evt) {
    var features = neighbourhoodsStatsSource.getFeaturesAtCoordinate(evt.coordinate);
    if (features.length > 0) {
        var feature = features[0];

        if (mode == MODE.INTERACTION) {

        } else if (mode == MODE.SELECTION) {
            var gid = feature.getId();

            // Toggle the dimming on the feature
            var dimmed = feature.get('dimmed');
            if (dimmed == undefined) {
                feature.set('dimmed', false);
                selectedNeighbourhoodGIDs.push(gid);
            } else {
                delete feature.values_['dimmed'];
                var idx = selectedNeighbourhoodGIDs.indexOf(gid);
                if (idx != -1) {
                    selectedNeighbourhoodGIDs.splice(idx, 1);
                }
            }

            // Update the appearance
            restyleFeature(feature);

            // Update any elements that require a selection
            if (selectedNeighbourhoodGIDs.length > 0) {
                $(".selection-required").removeClass("disabled");
                $('a.selection-required').off("click", preventDefault);
            } else {
                $(".selection-required").addClass("disabled");
                $('a.selection-required').on("click", preventDefault);
            }
        }

        //  if (typeof generatePopupContent == 'function') {
        //     $("#statsModal").modal('show');
        //     setFeature(feature);
        //
        //     generatePopupContent();
        // }

        //PLEASE DON'T REFACTOR - WORK IN PROGRESS

        /*
        if (typeof generatePopupContent == 'function') {
            var content = generatePopupContent(feature, popup);
            popup.setContent(content);
            popup.setPosition(evt.coordinate);
        }

        popup.show();
        */
    } else {
        // setSpecialFeature('highlighted', null);
        // $("#statsModal").modal('hide');
        //popup.hide();
    }
});

// By default disable all selection based items
$(".selection-required").addClass("disabled");
$('a.selection-required').on("click", preventDefault);
