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
var incidentsTitle = 'Incidents';

var neighbourhoodsStatsType = 'neighbourhoods-stats';
var neighbourhoodsStatsTitle = 'Neighbourhoods Crime Stats';

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

// Sources for the different layers
var incidentsSource = new ol.source.TileWMS({
    url: url,
    serverType: 'geoserver',
    params: {'LAYERS': featurePrefix + ':' + incidentsType, 'TILED': true}
});

var neighbourhoodsStatsSource = new ol.source.ImageWMS({
    url: url,
    serverType: 'geoserver',
    params: {'LAYERS': featurePrefix + ':' + neighbourhoodsStatsType}
})

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
        new ol.layer.Tile({
            title: incidentsTitle,
            source: incidentsSource
        }),

        new ol.layer.Image({
            source: neighbourhoodsStatsSource,
            title: neighbourhoodsStatsTitle,
            opacity: 0.6
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


// Track boundng box changes, in order to correctly update view params on stats layer
map.on("moveend", function(evt) {
    function wrapLon(value) {
        var worlds = Math.floor((value + 180) / 360);
        return value - (worlds * 360);
    }

    var map = evt.map;
    var extent = map.getView().calculateExtent(map.getSize());
    var bottomLeft = ol.proj.transform(ol.extent.getBottomLeft(extent), 'EPSG:3857', 'EPSG:4326');
    var topRight = ol.proj.transform(ol.extent.getTopRight(extent), 'EPSG:3857', 'EPSG:4326');

    // Update the view params of the stats layer
    neighbourhoodsStatsSource.updateParams({
        'VIEWPARAMS': 'left:' + wrapLon(bottomLeft[0]) + ';right:' + wrapLon(topRight[0]) + ';top:' + topRight[1] + ';bottom:' + bottomLeft[1] + ';'
    });
});

// Capture single clicks (for both incidents and stats)
map.on('singleclick', function(evt) {
    var infoURL = neighbourhoodsStatsSource.getGetFeatureInfoUrl(evt.coordinate, map.getView().getResolution(), map.getView().getProjection(), {'INFO_FORMAT': infoFormat});

    if (infoURL) {
        $.getJSON(infoURL, function(data){
            if (data.features && data.features.length > 0) {
                var feature = data.features[0];
                var stats = JSON.parse(feature.properties.stats);

                // TODO: Stylise the stats JSON into a nice popup content HTML
                if (stats) {
                    popup.setPosition(evt.coordinate);
                    popup.setContent(JSON.stringify(stats));
                    popup.show();
                }
            }
        });
    }
});
