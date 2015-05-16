

$( document ).ready(function() {
    var uiconsole = new UIConsole();
    uiconsole.listeners();
});



var UIConsole = function() {
    //select user toolbar
    this.ui = $("#ui-toolbox");  
    
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
    
    //Add checkboxes for crime types
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
    $("#ui-toolbox input.datepickers").datepicker({ dateFormat: "dd-mm-yy" });
    
    $("#ui-toolbox input[type='checkbox'], #ui-toolbox input.datepickers").change(function(){
        applyFilters();     
    });

  
}
    


//Working on filters

function applyFilters(){
    var filterVal;
    var filterDate = dateFilter();
    var filterCrime = crimeTypeFilter();
    
    if(filterDate != ""){ //both filters set
        filterVal = filterDate + " AND " + filterCrime;
    } else {
        filterVal = filterCrime; //even if empty, don't want to show any crimes than
    }   
    
     wmsSource.updateParams({
        CQL_FILTER: (filterVal)
    });
}


function dateFilter() {
  var filterVal ="",
      fromDate = $("#ui-toolbox input.datepickers#fromDate").val(),
      toDate = $("#ui-toolbox input.datepickers#toDate").val();  
  
  if(fromDate !="" && toDate !=""){ //both dates are set
      filterVal ='(date BETWEEN ' + formatDate(fromDate)+ ' AND '+  formatDate(toDate) +')';
  } else if (fromDate !="") { // from date is set     
      filterVal ='(date > ' + formatDate(fromDate)+ ')';
  } else if (toDate !="") { //to date is set
      filterVal ='(date < ' + formatDate(toDate)+ ')';
  } 
  
  return filterVal;
}


function crimeTypeFilter(){  
    var crime_type = $("#ui-toolbox input[type='checkbox']:checked").map(function() {
                return this.value;
          }).get().join("' OR crime = '");
    
    return "(crime = '"+ crime_type+"')";
}


//modify date to be of supported format    
function formatDate(date){  
    var pieces = date.split('-');
    pieces.reverse();
    return pieces.join('-');
}