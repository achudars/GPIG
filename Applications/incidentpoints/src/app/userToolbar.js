$( document ).ready(function() {
    //$('#map').prepend("<div>Test</div>");
    var uiconsole = new UIConsole();
    uiconsole.listeners();
});

var UIConsole = function() {
    this.ui = $("<div></div>", {'id': "ui-toolbox"});  
    
    var checkboxes = {
        "Antisocial Behaviour  ":"anti-social-behaviour",
        "Violent Crimes " : "violent-crime",
        "Drugs " : "drugs",
        "Public Order " : "public-order",
        "Other Crime ": "other-crime",
        "Bicycle-Theft " : "bicycle-theft",
        "Other theft " : "other-theft",
        "Robbery " : "robbery",
        "Possesion of Weapons " : "possesion-of-weapons",
        "Burlgrary " : "burlgrary",
        "Theft From The Person " : "theft-from-the-person",
        "Vehicle Crime ": "vehicle-crime",
        "Criminal Damage - Arson " : "criminal-damage-arson",
        "Shoplifting" : "shoplifting" 
    };
    
    
    $('#map').prepend(this.ui);
    $(this.ui).append("<div>To be styled, etc</div>");
    
    var chbx;
    for(var propertyName in checkboxes) {
        chbx = getCheckbox(checkboxes[propertyName]);
        $(this.ui).append(chbx);
        $(this.ui).append(propertyName);
   
   
    }
    

}

function getCheckbox(val){
    return $("<input>", {'type': "checkbox", "name" : "crimeType", "value": val});
}
 
    
UIConsole.prototype.listeners = function() {
    $("#ui-toolbox input[type='checkbox']").change(function(){
        crimeTypeFilter();      
    });
}
    
    

//Working on filters

function crimeTypeFilter(){
    
    var crime_type = $("#ui-toolbox input[type='checkbox']:checked").map(function() {
                return this.value;
          }).get().join("' OR crime = '");
    
    
    
    filterVal = "crime = '"+ crime_type+"'";
    
    console.log(filterVal);
    
    wmsSource.updateParams({
        CQL_FILTER: (filterVal)
    });
    
   
}

//anti-social-behaviour




/*
var date = "2014-01-01";

function dateFilter(date) {
  var dateFilter ='stdate BETWEEN ' + date.fromDate + ' AND ' + date.toDate;
  return '(' + dateFilter + ')';
}
*/



