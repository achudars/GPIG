/**
 * Add all your dependencies here.
 *
 * @require Popup.js
 * @require LayersControl.js
 */
// ========= config section ================================================
var url = '/geoserver/ows?';
var featurePrefix = 'crime';
var featureType = 'incidents';
var featureType2 = 'neighbourhoods';
var featureNS = 'http://census.gov';
var layerTitle = 'Incidents';
var layerTitle2 = 'Neighbourhoods';

// var srsName = 'EPSG:900913';
// var geometryName = 'the_geom';
// var geometryType = 'MultiPolygon';
// var fields = ['STATE_NAME', 'STATE_ABBR'];
var infoFormat = 'application/json';
var long = -1.082995;
var lat = 53.958647;
var zoom = 15;
// =========================================================================

// override the axis orientation for WMS GetFeatureInfo
var proj = new ol.proj.Projection({
  code: 'http://www.opengis.net/gml/srs/epsg.xml#4326',
  axis: 'enu'
});
ol.proj.addEquivalentProjections([ol.proj.get('EPSG:4326'), proj]);

// create a GML format to read WMS GetFeatureInfo response
var format = new ol.format.GML({featureNS: featureNS, featureType: featureType});

// create a new popup with a close box
// the popup will draw itself in the popup div container
// autoPan means the popup will pan the map if it's not visible (at the edges of the map).
var popup = new app.Popup({
  element: document.getElementById('popup'),
  closeBox: true,
  autoPan: true
});


// the tiled WMS source for our local GeoServer layer
var wmsSource = new ol.source.TileWMS({
  url: url,
  params: {'LAYERS': featurePrefix + ':' + featureType, 'TILED': true},
  serverType: 'geoserver'
});

var wmsSource2 = new ol.source.TileWMS({
  url: url,
  params: {'LAYERS': featurePrefix + ':' + featureType2, 'TILED': true, STYLE:'line'},
  serverType: 'geoserver'
});

// create the OpenLayers Map object
// we add a layer switcher to the map with two groups:
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
  target: document.getElementById('map'),
  // use the Canvas renderer
  renderer: 'canvas',
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
    }),   new ol.layer.Tile({
      title: layerTitle2,
      source: wmsSource2

    }),
       new ol.layer.Tile({
      title: layerTitle,
      source: wmsSource
    })

  ],
  // initial center and zoom of the map's view
  view: new ol.View({
    center: ol.proj.transform([long, lat], 'EPSG:4326', 'EPSG:3857'),
    zoom: zoom,
    maxZoom: 16,
    minZoom: 13
  })
});


//register a single click listener on the map and show a popup
//based on WMS GetFeatureInfo
map.on('singleclick', function(evt) {
    getNeigbourhoodCrime(evt);
});

function getNeigbourhoodCrime(event) {
 // use a CQL parser for easy filter creation
 //var format = new ol.format;

 var viewResolution = map.getView().getResolution();
 var url = wmsSource2.getGetFeatureInfoUrl(
      event.coordinate, viewResolution, map.getView().getProjection(),
      {'INFO_FORMAT': infoFormat}
 );

 $.getJSON(url,function(data){
   var neighbourhood = data.features[0].geometry.coordinates;
   var mpoly = [];
   // for each polygon
   for (var npoly = 0; npoly < neighbourhood.length; npoly++) {
      var poly = [];
      // for each polygon part
      for (var npart = 0; npart < neighbourhood[npoly].length; npart++) {
         var part = [];
         // for each vertex
         for (var vertex = 0; vertex < neighbourhood[npoly][npart].length; vertex++) {
            // swap lon lat
            neighbourhood[npoly][npart][vertex][0], neighbourhood[npoly][npart][vertex][1] = neighbourhood[npoly][npart][vertex][1], neighbourhood[npoly][npart][vertex][0];
            // add space separated
            part.push(neighbourhood[npoly][npart][vertex].join(' '));
         }
         // add this part to poly
         poly.push(part.join(','));
      }
      // add this poly to mpoly
      mpoly.push('(' + poly.join('),(') + ')');
   }
   var query = '(' + mpoly.join('),(') + ')';
   console.log(query);

   wmsSource.updateParams({
       CQL_FILTER: ('WITHIN(geom, MULTIPOLYGON('+query+'))')
   });
   });
}
