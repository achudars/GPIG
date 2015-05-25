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
var zoom = {min: 13, default: 16, max: 19};

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
            style: generateNeighbourhoodStyle
        }),

        new ol.layer.Vector({
            source: new ol.source.Cluster({
                source: incidentsSource,
                distance: 60
            }),
            title: incidentsTitle,
            style: generateIncidentStyle
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

// when the popup is closed, clear the highlight
$(popup).on('close', function() {
    // Clear the highlight

});

// Capture single clicks (for both incidents and stats)
map.on('singleclick', function(evt) {
    // Vector source has all the features available directly, perfect!
    var features = neighbourhoodsStatsSource.getFeaturesAtCoordinate(evt.coordinate);

    if (features.length > 0) {
        var feature = features[0];

        if (typeof generatePopupContent == 'function') {
            var content = generatePopupContent(feature);
            popup.setContent(content);
            popup.setPosition(evt.coordinate);
        }

        popup.show();
    } else {
        popup.hide();
    }
});
