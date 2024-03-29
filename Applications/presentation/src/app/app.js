/**
 * Add all your dependencies here.
 *
 * @require OLAdditions.js
 * @require LayersControl.js
 * @require FiltersControl.js
 * @require Stats.js
 * @require Style.js
 * @require PoliceDistribution.js
 * @require Clustering.js
 * @require Navigation.js
 */

// ========= config section ================================================
var url = '/geoserver/ows?';
var featurePrefix = 'crime';

// By default center around York
var center = {
    lat: 53.958647,
    long: -1.082995
};
var zoom = {
    min: 15,
    default: 15,
    max: 19
};

var neighbourhoodsStatsType = 'neighbourhood-statistics';
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

var statsDrawer = $("#drawer")[0];

// Mode for the application
const MODE = Object.freeze({
    INTERACTION: 0,
    ZOOM: 1,
    SELECTION: 2
});
var mode = MODE.INTERACTION;

// Zoom restoration
// Keeping track of the feature we are zoomed into,
// as well as the state we can restore to
var zoomState = {
    feature: undefined,
    resolution: undefined,
    center: undefined
};

// Highlighted neighbourhood
var highlightedNeighbourhood = undefined;

// Selected neighbourhoods
var selectedNeighbourhoodGIDs = [];

// Police distributor
var policeDistributor = new app.PoliceDistributor();

// Statistics
var statsGenerator = new app.Statistics();

// Navigation
var navigation = new app.Navigation();

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
            'version=1.1.0&typename=' + featurePrefix + ':' + neighbourhoodsStatsType + '&' +
            'srsname=' + projection.code_ + '&' +
            'viewparams=' + viewparams;

        $.ajax({
                url: encodeURI(url)
            })
            .done(function(response) {
                var features = neighbourhoodsStatsSource.readFeatures(response);

                // Re-apply the suitable dimmed ignoring flags
                features.forEach(function(element) {
                    if (mode == MODE.SELECTION && selectedNeighbourhoodGIDs.indexOf(element.getId()) != -1) {
                        element.set('dimmed', false);
                    } else if (mode == MODE.ZOOMED && zoomState.featureGID == element.getId()) {
                        element.set('dimmed', false);
                    }
                });

                neighbourhoodsStatsSource.addFeatures(features);
            });
    },

    strategy: ol.loadingstrategy.bbox
});



// Incidents (as a vector for clustering/styling)
var incidentsSource = new ol.source.ServerVector({
    format: new ol.format.WFS({
        featureNS: 'http://localhost',
        featureType: incidentsType
    }),

    loader: function(extent, resolution, projection) {
        // Create the URL for the request
        var transformed = ol.extent.applyTransform(extent, ol.proj.getTransform(projection, 'EPSG:4326'));
        var viewparams = "AREA:" + transformed.join('\\\,') + '\\\,4326';

        if (this.filter) {
            viewparams += ";" + this.filter;
        }

        // Create the URL for the reqeust
        var url = '/geoserver/wfs?' +
            'service=WFS&request=GetFeature&' +
            'version=1.1.0&typename=' + featurePrefix + ':' + incidentsType + '&' +
            'srsname=' + projection.code_ + '&' +
            'viewparams=' + viewparams;

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


// Neighbourhood specific incidents source
var incidentsNeighbourhoodSource = new ol.source.ServerVector({
    format: new ol.format.WFS({
        featureNS: 'http://localhost',
        featureType: incidentsType
    }),

    loader: function(extent, resolution, projection) {
        // Create the URL for the request
        var viewparams = "";

        if (extent.join(',') != [-Infinity, -Infinity, Infinity, Infinity].join(',')) {
            var transformed = ol.extent.applyTransform(extent, ol.proj.getTransform(projection, 'EPSG:4326'));
            viewparams = "AREA:" + transformed.join('\\\,') + '\\\,4326' + ';';
        }

        if (this.filter) {
            viewparams += this.filter + ";";
        }

        if (this.neighbourhoodGID) {
            viewparams += "NEIGHBOURHOOD:" + this.neighbourhoodGID.split('.').pop() + ";";
        }

        // Create the URL for the reqeust
        var url = '/geoserver/wfs?' +
            'service=WFS&request=GetFeature&' +
            'version=1.1.0&typename=' + featurePrefix + ':' + incidentsType + '&' +
            'srsname=' + projection.code_ + '&' +
            'viewparams=' + viewparams;

        $.ajax({
                url: encodeURI(url)
            })
            .done(function(response) {
                var features = incidentsNeighbourhoodSource.readFeatures(response);

                // Custom clustering (not visual distance,
                // but rather physical distance based k-means approach)
                var clusters = kmeansClusters(features, 9);
                incidentsNeighbourhoodSource.addFeatures(clusters);

                // Route between clusters
                if (mode == MODE.ZOOMED) {
                    navigation.connectCentroids(clusters);
                }
            });
    },

    strategy: ol.loadingstrategy.all
});


var incidentsNeighbourhoodLayer = new ol.layer.Vector({
    source: incidentsNeighbourhoodSource,
    style: function(feature, resolution) {
        return styles.incidents.generateIncidentStyle(feature, resolution);
    },
    visible: false
});

var neighbourhoodNavigationLayer = new ol.layer.Vector({
    source: new ol.source.Vector({
        features: []
    }),
    style: [new ol.style.Style({
        stroke: new ol.style.Stroke({
            color: '#8D8E8E',
            width: 4
        })
    }), new ol.style.Style({
        stroke: new ol.style.Stroke({
            color: '#52D1DC',
            width: 2
        })
    })]
})


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
            sources: [{
                source: neighbourhoodsStatsSource
            }, {
                source: incidentsSource
            }, {
                source: incidentsNeighbourhoodSource,
                reload: false
            }]
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
                    'http://c.tile.openstreetmap.org/{z}/{x}/{y}.png'
                ]
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
                    'http://otile4.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png'
                ]
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
                    'http://d.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png'
                ],
                tilePixelRatio: 2,
                attributions: [new ol.Attribution({
                    html: ['&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>']
                })]
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
                    'http://d.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                ],
                tilePixelRatio: 2,
                attributions: [new ol.Attribution({
                    html: ['&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>']
                })]
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
                    'http://c.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'
                ]
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
        }),

        neighbourhoodNavigationLayer,
        incidentsNeighbourhoodLayer
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

function setMode(newMode, object) {
    if (mode == newMode) {
        return;
    }

    mode = newMode;

    // Handling transitions away from SELECTION and ZOOMED
    if (newMode != MODE.SELECTION) {
        // Alter the title of every selection button
        $(".selection-toggle").text('Select Regions');

        // Update the features
        var features = neighbourhoodsStatsSource.getFeaturesByIDs(selectedNeighbourhoodGIDs);
        features.forEach(function(feature) {
            feature.unset('dimmed');
        });

        // Restyle the layer
        if (newMode != MODE.ZOOMED) {
            styles.neighbourhoods.dimmed = false;
            map.getLayerForTitle(neighbourhoodsStatsTitle).restyle(map);
        }
    }

    if (newMode != MODE.ZOOMED) {
        // Restore the zoom state (if there anything to restore)
        var view = map.getView();

        if (zoomState.center && zoomState.resolution) {
            map.beforeRender(new ol.animation.pan({
                source: view.getCenter(),
                duration: 750
            }), new ol.animation.zoom({
                resolution: view.getResolution(),
                duration: 750
            }), function() {
                // Hide the drawer
                $(statsDrawer).hide("slide", {
                    direction: "left"
                }, 750);

                // Hide/Clear zoomed incidents
                incidentsNeighbourhoodLayer.setVisible(false);

                // Do the same for the navigation layer
                neighbourhoodNavigationLayer.setVisible(false);
            });

            // Wait until animations finish (postrender is too soon)
            setTimeout(function() {
                // Reset zoomed feature
                var feature = neighbourhoodsStatsSource.getFeatureById(zoomState.featureGID);
                feature.unset('dimmed');
                if (newMode != MODE.SELECTION) {
                    styles.neighbourhoods.dimmed = false;
                }

                // Restyle the layer/feature
                map.getLayerForTitle(neighbourhoodsStatsTitle).restyle(map);

                // Remove state
                delete zoomState.featureID;
                delete zoomState.center;
                delete zoomState.resolution;
            }, 750);

            view.setCenter(zoomState.center);
            view.setResolution(zoomState.resolution);
        }
    }

    // Handling transitions to SELECTION and ZOOMED
    if (newMode == MODE.SELECTION) {
        // Alter the title of every selection button
        $(".selection-toggle").text('Cancel Selection');

        // Update the features
        var features = neighbourhoodsStatsSource.getFeaturesByIDs(selectedNeighbourhoodGIDs);
        features.forEach(function(feature) {
            feature.set('dimmed', false);
        });

        // Restyle the layer
        styles.neighbourhoods.dimmed = true;
        map.getLayerForTitle(neighbourhoodsStatsTitle).restyle(map);
    }

    if (newMode == MODE.ZOOMED) {
        // Disable the highlighted feature's highlight
        if (highlightedNeighbourhood) {
            highlightedNeighbourhood.unset('hover', true, map);
            highlightedNeighbourhood = undefined;
        }

        // Zoom into a feature
        var view = map.getView();

        if (object) {
            zoomState.featureGID = object.getId();
        }

        var feature = neighbourhoodsStatsSource.getFeatureById(zoomState.featureGID);

        zoomState.center = view.getCenter();
        zoomState.resolution = view.getResolution();

        map.beforeRender(new ol.animation.pan({
            duration: 750,
            source: zoomState.center
        }), new ol.animation.zoom({
            duration: 750,
            resolution: zoomState.resolution
        }), function() {
            // Show the stats drawer
            $(statsDrawer).show("slide", {
                direction: "left"
            }, 750);

            return false;
        });

        view.fitGeometry(feature.getGeometry(), map.getSize(), {
            padding: [50, 100, 100, 450],
            maxZoom: zoom.max
        });

        // Wait until the animations finish (postrender is too soon)
        setTimeout(function() {
            // Dimming
            feature.set('dimmed', false);
            styles.neighbourhoods.dimmed = true;

            // Update the zoomed incidents layer source
            incidentsNeighbourhoodSource.neighbourhoodGID = zoomState.featureGID;
            incidentsNeighbourhoodSource.clear(true);

            // Restyle the layer/feature
            map.getLayerForTitle(neighbourhoodsStatsTitle).restyle(map);

            // Make the incidents visible
            incidentsNeighbourhoodLayer.setVisible(true);
        }, 750);
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
    if (mode == MODE.SELECTION) {
        setMode(MODE.INTERACTION);

        $(".selection-required").addClass("disabled");
        $('a.selection-required').on("click", preventDefault);
    } else {
        setMode(MODE.SELECTION);

        if (selectedNeighbourhoodGIDs.length > 0) {
            $(".selection-required").removeClass("disabled");
            $('a.selection-required').off("click", preventDefault);
        }
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

function calculateStats(event) {
    if ($(event.target).hasClass("disabled"))
        return;

    var features = neighbourhoodsStatsSource.getFeatures().filter(function(element) {
        return selectedNeighbourhoodGIDs.indexOf(element.getId()) != -1;
    });

    statsGenerator.setNeighbourhoods(features);
    statsGenerator.setPopup("#plots");
    $("#statsModal").modal().show();
    statsGenerator.generatePopupContent();

}


// Capture hover events
map.on('pointermove', function(evt) {
    // Ignore panning events
    if (evt.dragging) {
        return;
    }

    // Disable while in zoom mode
    var disable = mode == MODE.ZOOMED;

    if (!disable) {
        // or events that are within overlays (to avoid weird ghosting)
        var element = document.elementFromPoint(evt.browserEvent.clientX, evt.browserEvent.clientY);

        map.getOverlays().forEach(function(overlay, idx) {
            var container = overlay.getElement();
            if (container === element || $.contains(overlay.getElement(), element)) {
                disable = true;
                return false;
            }
        });
    }

    // Handling hover state
    if (disable == false) {
        var coordinate = map.getEventCoordinate(evt.originalEvent);
        var features = neighbourhoodsStatsSource.getFeaturesAtCoordinate(coordinate);
        if (features.length > 0) {

            if (highlightedNeighbourhood) {
                highlightedNeighbourhood.unset('hover', true, map);
            }

            highlightedNeighbourhood = features[0];
            highlightedNeighbourhood.set('hover', true);
            highlightedNeighbourhood.restyle(map);
        } else if (highlightedNeighbourhood) {
            highlightedNeighbourhood.unset('hover', true, map);
            highlightedNeighbourhood = undefined;
        }
    } else if (highlightedNeighbourhood) {
        highlightedNeighbourhood.unset('hover', true, map);
        highlightedNeighbourhood = undefined;
    }
});



// Capture single clicks (in both modes)
map.on('singleclick', function(evt) {
    var features = neighbourhoodsStatsSource.getFeaturesAtCoordinate(evt.coordinate);

    if (features.length > 0) {
        var feature = features[0];

        if (mode == MODE.INTERACTION) {
            // Populate our stats drawer
            statsGenerator.setNeighbourhoods([feature]);
            statsGenerator.setPopup("#pies");
            statsGenerator.generatePopupContent();
            setMode(MODE.ZOOMED, feature);
        } else if (mode == MODE.ZOOMED && feature.getId() != zoomState.featureGID) {
            setMode(MODE.INTERACTION);
        } else if (mode == MODE.SELECTION) {
            var gid = feature.getId();
            var oldCount = selectedNeighbourhoodGIDs.length;

            // Toggle the dimming on the feature
            var dimmed = feature.get('dimmed');
            if (dimmed == undefined) {
                feature.set('dimmed', false);
                selectedNeighbourhoodGIDs.push(gid);
            } else {
                feature.unset('dimmed');
                var idx = selectedNeighbourhoodGIDs.indexOf(gid);
                if (idx != -1) {
                    selectedNeighbourhoodGIDs.splice(idx, 1);
                }
            }

            // Update the appearance
            feature.restyle(map);

            // Update any elements that require a selection
            if (oldCount != selectedNeighbourhoodGIDs.length) {
                if (selectedNeighbourhoodGIDs.length > 0) {
                    $(".selection-required").removeClass("disabled");
                    $('a.selection-required').off("click", preventDefault);
                } else {
                    $(".selection-required").addClass("disabled");
                    $('a.selection-required').on("click", preventDefault);
                }
            }
        }
    }
});

// By default disable all selection based items
$(".selection-required").addClass("disabled");
$('a.selection-required').on("click", preventDefault);
