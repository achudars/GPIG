if (!window.app) {
  window.app = {};
}
var app = window.app;
var selectedNeighbourhoods = [];
var selectedNeighbourhoodsNames = [];
app.PoliceDistributor = function(map,source) {
    this.map = map;
    this.source = source;
    //this.selectedNeighbourhoods = [];
    //this.selectedNeighbourhoodsNames = [];
   
    

    var me = this;
    map.on('singleclick', function(evt) {
        //alert("works");
        if (document.getElementById("policeResourceBtn").value === "Cancel Selection") {
            document.getElementById("policeResourceBtn").value = "Finished Selection";
            document.getElementById("policeResourceBtn").innerHTML = "Finished Selection";
        }
        selectedNeighbourhoods.push(evt.coordinate);
        selectedNeighbourhoodsNames.push(me.source.getFeaturesAtCoordinate(evt.coordinate)[0].get('name'));
    });
};

app.PoliceDistributor.prototype.policeClick = function() {
    
    var me = this;
  //console.log(selectedNeighbourhoodsNames);
    console.log(document.getElementById("policeResourceBtn").value);
    if (document.getElementById("policeResourceBtn").value === "Select Region"){
        document.getElementById("policeResourceBtn").value = "Cancel Selection";
        document.getElementById("policeResourceBtn").innerHTML = "Cancel Selection";
    } else if (document.getElementById("policeResourceBtn").value === "Cancel Selection") {
         selectedNeighbourhoods = [];
         selectedNeighbourhoodsNames = [];
        document.getElementById("policeResourceBtn").value = "Select Region";
        document.getElementById("policeResourceBtn").innerHTML = "Select Region"
    } else if (document.getElementById("policeResourceBtn").value === "Finished Selection") {
        $("#policeModal").modal('show');
    }
}



app.PoliceDistributor.prototype.distribute = function  () {
  this.noOfPolice = 10;
  this.neighbourhoodCrimecounts = [];
  this.distroPercentage = [];
  this.policeDistribution = [];
  
  var me = this;
  console.log(selectedNeighbourhoods);
  console.log(selectedNeighbourhoodsNames);
  
  if (document.getElementById("calculateBtn").innerHTML == "Recalculate Distribution") {
    document.getElementById("policeResourceBtn").value = "Select Region";
    document.getElementById("policeResourceBtn").innerHTML = "Select Region";
    selectedNeighbourhoods = [];
    selectedNeighbourhoodsNames = [];
    $("#policeModal").modal('hide');
    return;
  }
  
    for (evt in selectedNeighbourhoods) {
        me.neighbourhoodCrimecounts.push(parseInt(neighbourhoodsStatsSource.getFeaturesAtCoordinate(selectedNeighbourhoods[evt])[0].get("crimecount")));
    }
    var sum = 0;

    for(x in me.neighbourhoodCrimecounts){
        sum = sum + parseInt(me.neighbourhoodCrimecounts[x]);
    }
    console.log(me.neighbourhoodCrimecounts);
    for(x in me.neighbourhoodCrimecounts){
        me.distroPercentage.push(me.neighbourhoodCrimecounts[x] / sum);
    }

    me.noOfPolice = document.getElementById("policeNo").value;

    for(x in me.distroPercentage){
        me.policeDistribution.push(Math.round(me.distroPercentage[x] * me.noOfPolice));
    }
    
    var element = '<div min-width = "588px" >\
                  <h4>Police distribution amongst area selected</h4>\
                  <table class="table table-striped">\
                  <thead>\
                  <tr>\
                  <th>Area</th>\
                  <th>Number of Police</th>\
                  </tr>\
                  </thead>\
                  <tbody>';
    for (x in me.policeDistribution){
      row = '<tr><td>'+ selectedNeighbourhoodsNames[x] + '</td><td>' +me.policeDistribution[x] +'</td></tr>';
      element += row; 
    }
    element+= '</tbody>\
                </table>\
                  </div>';
    console.log(me.policeDistribution);
    document.getElementById('modaltable').innerHTML = element;
    document.getElementById("calculateBtn").innerHTML = "Recalculate Distribution";
            

    //map.addLayer(policeDistroLayer);
    //console.log(neighbourhoodsStatsSource);
}

$(function() {
    var action;
    $(".number-spinner button").mousedown(function () {
        btn = $(this);
        input = btn.closest('.number-spinner').find('input');
        btn.closest('.number-spinner').find('button').prop("disabled", false);

    	if (btn.attr('data-dir') == 'up') {
            action = setInterval(function(){
                if ( input.attr('max') == undefined || parseInt(input.val()) < parseInt(input.attr('max')) ) {
                    input.val(parseInt(input.val())+1);
                }else{
                    btn.prop("disabled", true);
                    clearInterval(action);
                }
            }, 50);
    	} else {
            action = setInterval(function(){
                if ( input.attr('min') == undefined || parseInt(input.val()) > parseInt(input.attr('min')) ) {
                    input.val(parseInt(input.val())-1);
                }else{
                    btn.prop("disabled", true);
                    clearInterval(action);
                }
            }, 50);
    	}
    }).mouseup(function(){
        clearInterval(action);
    });
});
