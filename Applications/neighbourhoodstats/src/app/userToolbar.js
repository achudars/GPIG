

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
    var fromDate = formatDate($("#ui-toolbox input.datepickers#fromDate").val()),
      toDate = formatDate($("#ui-toolbox input.datepickers#toDate").val());

    if (typeof incidentsSource !== 'undefined') {
        var filterVal;
        var filterDate = dateFilterCQL(fromDate,toDate);
        var filterCrime = crimeTypeFilter();

        if(filterDate != ""){ //both filters set
            filterVal = filterDate + " AND " + filterCrime;
        } else {
            filterVal = filterCrime; //even if empty, don't want to show any crimes than
        }
        incidentsSource.updateParams({
            CQL_FILTER: (filterVal)
        }); 
    }
    
    if (typeof neighbourhoodsStatsSource !== 'undefined') {
        filterValue = dateFilterSQL(fromDate,toDate);
        filterValue += crimeTypeFilterSQL();
        neighbourhoodsStatsSource.clear(true);
    }
    
    
}

function dateFilterSQL(fromDate, toDate){
    var filterVal = (fromDate !="" ? "STARTDATE:"+fromDate+";" : "");
    filterVal += (toDate !="" ? "ENDDATE:"+toDate+";" : "");
    return filterVal;
    
}

function dateFilterCQL(fromDate, toDate) {
  var filterVal ="";

  if(fromDate !="" && toDate !=""){ //both dates are set
      filterVal ='(date BETWEEN ' + fromDate+ ' AND '+  toDate +')';
  } else if (fromDate !="") { // from date is set
      filterVal ='(date > ' + fromDate+ ')';
  } else if (toDate !="") { //to date is set
      filterVal ='(date < ' + toDate+ ')';
  }

  return filterVal;
}

function crimeTypeFilterSQL(){
    var crime_type = $("#ui-toolbox input[type='checkbox']:checked").map(function() {
                return this.value;
          }).get().join("','");

    return "CRIME:'"+ crime_type+"';";
}

function crimeTypeFilter(){
    var crime_type = $("#ui-toolbox input[type='checkbox']:checked").map(function() {
                return this.value;
          }).get().join("' OR crime = '");

    return "(crime = '"+ crime_type+"')";
}


//modify date to be of supported format
function formatDate(date){
    if(date == "") { return ""; }
    
    var pieces = date.split('-');
    pieces.reverse();
    return pieces.join('-');
}
