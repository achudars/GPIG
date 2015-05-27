if (!window.app) {
  window.app = {};
}
var app = window.app;

app.PoliceDistributor = function(map) {
    this.map = map;
    this.selectedNeighbourhoods = [];

    var me = this;
    map.on('singleclick', function(evt) {
        me.selectedNeighbourhoods.push(something);
    });
};

app.PoliceDistributor.distribute = function() {

}

var noOfPolice = 10;
var neighbourhoodCrimecounts = [];
var distroPercentage = [];
var policeDistribution = [];

function calculateDistribution () {
    //alert(document.getElementById("policeNo").value);
    //var policeDistro = new ol.
    //var policeCluster = new
    //map.addLayer();
    for (evt in selectedNeighbourhoods) {
        neighbourhoodCrimecounts.push(parseInt(neighbourhoodsStatsSource.getFeaturesAtCoordinate(selectedNeighbourhoods[evt])[0].get("crimecount")));
    }
    var sum = 0;

    for(x in neighbourhoodCrimecounts){
        sum = sum + parseInt(neighbourhoodCrimecounts[x]);
    }
    console.log(neighbourhoodCrimecounts);
    for(x in neighbourhoodCrimecounts){
        distroPercentage.push(neighbourhoodCrimecounts[x] / sum);
    }

    noOfPolice = document.getElementById("policeNo").value;

    for(x in distroPercentage){
        policeDistribution.push(Math.round(distroPercentage[x] * noOfPolice));
    }
    console.log(policeDistribution);

    // create a vector layer to contain the police distribution centroids
    var policeDistroLayer = new ol.layer.Vector({
        title: "Police Distribution",
        source: new ol.source.Vector(),
        style:function(feature, resolution) {
                return app.sharedStyle.generateNeighbourhoodStyle(feature, resolution);
            }
    });

    for(x in policeDistribution){
        feature = new ol.Feature({
            geometry: new ol.geom.Point(ol.proj.transform(selectedNeighbourhoods[x], 'EPSG:4326', 'EPSG:3857')),
            name: selectedNeighbourhoodsNames[x],
            noofpolice: policeDistribution[x]
            });
        policeDistroLayer.getSource().addFeature(feature);
    }
    policeDistroLayer.setVisible(true);
    console.log(policeDistroLayer.getSource());

    //map.addLayer(policeDistroLayer);
    //console.log(neighbourhoodsStatsSource);
    $("#policeModal").modal('hide');
}
