

$( document ).ready(function() {
    //add datepickers
    $("#ui-toolbox input.datepickers").datepicker({ dateFormat: "dd-mm-yy" });
    
    //add Listeners
    //when inputs change
    $("#ui-toolbox input[type='checkbox'], #ui-toolbox input.datepickers").change(function(){
        applyFilters();     
    });
    
    //select buttons clicked
    $("#ui-toolbox #selectAll").click(function(e){
        e.preventDefault();
         $("#ui-toolbox input[type='checkbox']").prop("checked",true);        
         applyFilters();     
    });
    
    $("#ui-toolbox #deselectAll").click(function(e){
        e.preventDefault();
         $("#ui-toolbox input[type='checkbox']").prop("checked",false);        
         applyFilters();     
    });
    
});




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