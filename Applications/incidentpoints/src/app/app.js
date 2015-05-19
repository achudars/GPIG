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
var featureType3 = 'incident_types';
var featureNS = 'http://census.gov';
var layerTitle = 'Incidents';
var layerTitle2 = 'Neighbourhoods';
var layerTitle3 = 'Incident Types';

// var srsName = 'EPSG:900913';
// var geometryName = 'the_geom';
// var geometryType = 'MultiPolygon';
// var fields = ['STATE_NAME', 'STATE_ABBR'];
var infoFormat = 'application/json'; // can also be 'text/html'
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

var wmsSource3 = new ol.source.TileWMS({
  url: url,
  params: {'LAYERS': featurePrefix + ':' + featureType3, 'TILED': true, STYLE:'point_types'},
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
    }),
       new ol.layer.Tile({
      title: layerTitle3,
      source: wmsSource3
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
 
   var viewResolution = map.getView().getResolution();
   var url = wmsSource2.getGetFeatureInfoUrl(
       evt.coordinate, viewResolution, map.getView().getProjection(),
       {'INFO_FORMAT': infoFormat});
   //if (url) {
   //  if (infoFormat == 'application/json') {
   //    popup.setPosition(evt.coordinate);
   //    popup.setContent('<iframe seamless frameborder="0" src="' + url + '"></iframe>');
   //    popup.show();
   //  } else {      
   //    $.ajax({
   //      url: url,
   //      success: function(data) {
   //        var features = format.readFeatures(data);
   //        highlight.getSource().clear();
   //        if (features && features.length >= 1 && features[0]) {
   //          var feature = features[0];
   //          var html = '<table class="table table-striped table-bordered table-condensed">';
   //          var values = feature.getProperties();
   //          var hasContent = false;
   //          for (var key in values) {
   //            if (key !== 'the_geom' && key !== 'boundedBy') {
   //              html += '<tr><td>' + key + '</td><td>' + values[key] + '</td></tr>';
   //              hasContent = true;
   //            }
   //          }
   //          if (hasContent === true) {
   //            popup.setPosition(evt.coordinate);
   //            popup.setContent(html);
   //            popup.show();
   //          }
   //          feature.getGeometry().transform('EPSG:4326', 'EPSG:3857');
   //          highlight.getSource().addFeature(feature);
   //        } else {
   //          popup.hide();
   //        }
   //      }
   //    });
   //  }
   //} else {
   //  popup.hide();
   //}
 });
 
 function getNeigbourhoodCrime(event) {
  // use a CQL parser for easy filter creation
    //var format = new ol.format;
   
  var viewResolution = map.getView().getResolution();
  var url = wmsSource2.getGetFeatureInfoUrl(
       event.coordinate, viewResolution, map.getView().getProjection(),
       {'INFO_FORMAT': infoFormat});
  
  $.getJSON(url,function(data){
    var neighbourhood = data.features[0].geometry.coordinates;
    console.log(neighbourhood);
    var query = [];
    
    for (var i = 0; i < neighbourhood.length; i++) {
      neighbourhood[0][0][i][0], neighbourhood[0][0][i][1] = neighbourhood[0][0][i][1], neighbourhood[0][0][i][0];
      query.push(neighbourhood[0][0][i].join(' '));
    }
    wmsSource.updateParams({
        CQL_FILTER: ('WITHIN(geom, POLYGON(('+query.join()+')))')
    });
    // wmsSource.updateParams({
    //    CQL_FILTER: ('WITHIN(geom, POLYGON(('+neighbourhood[0][0]+')))')
    //});
    //console.log(query.join());
    });
  
  
  //window.alert(neighbourhood);
  
  
  
    popup.setPosition(event.coordinate);
               popup.setContent('<iframe seamless frameborder="0" src="' + url + '"></iframe>');
               popup.show();
  //var html ;
  //return html;
 }
 
 
 function ol3_legend(e) {
    var options = e || {};
    var wmsVersion = options.wmsVersion || '1.1.1';
    var format = options.format || 'image/png';
    var legendP = document.createElement('p');
    legendP.innerHTML = 'Legend:';
    var legendDiv = document.createElement('div');
    legendDiv.className = options.class + ' ol-unselectable';
    legendDiv.appendChild(legendP);
    var layers = options.map.getLayers().getArray();
    for (var i = 0; i < layers.length; i++) {
        if (layers[i].values_.title  === 'Incident Types' ){
          var legendImg = document.createElement('img');
          legendImg.src = 'geoserver/wms?REQUEST=GetLegendGraphic&sld_version=1.0.0&layer=' + layers[i].getSource().params_.LAYERS + '&format=' + format;
          legendDiv.appendChild(legendImg);
        }
        if (layers[i].values_.title  === 'Incidents' ){
          var legendImg = document.createElement('img');
          legendImg.src = 'geoserver/wms?REQUEST=GetLegendGraphic&sld_version=1.0.0&layer=' + layers[i].getSource().params_.LAYERS + '&format=' + format;
          legendDiv.appendChild(legendImg);
        }
        if (layers[i].values_.title  === 'Neighbourhoods' ){
          var legendImg = document.createElement('img');
          legendImg.src = 'geoserver/wms?REQUEST=GetLegendGraphic&sld_version=1.0.0&layer=' + layers[i].getSource().params_.LAYERS + '&format=' + format;
          legendDiv.appendChild(legendImg);
        }
    }
     ol.control.Control.call(this, {
        element: legendDiv
    });
   
}


    
ol.inherits(ol3_legend, ol.control.Control);

map.addControl(new ol3_legend({
    map: map,
    class: 'ol_legend' }));
