/**
 *  Stats functions to handle the contents of the popups
 *
 *  @require Style.js
 */

/**
 *  Function that should return whatever is put into the
 *  stats popup shown for a feature
 *  (feature might be a neighbourhood or an incident)
 *
 *  @param feature  - Feature for which the popup will be shown
 *  @param popup    - Popup into which the content will be placed (function
 *                      should avoid calling functions on the popup)
 */

$( document ).ready(function() {
    $(".chartTabs").click(function() {
 
        $(".chartTabs").removeClass("selectedTab");
        $(this).addClass("selectedTab");
        generatePopupContent();
        
    });
});

var popupFeature;

function setFeature(feature){
    popupFeature= feature;
}

//PLEASE DON'T REFACTOR - WORK IN PROGRESS
function generatePopupContent() {
    // Currently creates a pie chart, can use the other functions
    // to create other types of charts
    var popup = "#statsModal";
    var feature = popupFeature;
    var selectedTab = $(".chartTabs.selectedTab").prop("id");
    
    
    // $("#plots").highcharts().destroy();
   
    
    switch(selectedTab) {
        case "pie":
             generatePopupPie(feature, popup);
            break;
        case "overTime":
            generatePopupCharts(feature, popup);
            break;
        default:
           // default code block
        }
    
   
    
}

//PLEASE DON'T REFACTOR - WORK IN PROGRESS
function generatePopupCharts(feature, popup) {
    var periodicstats = feature.get('stats2'), limit = 5, title="", crimeCounts = 0;
    periodicstats = (typeof periodicstats !== 'undefined'? JSON.parse(periodicstats): false);

    //get array of names of highest crimes
    var someCrimes = getBiggestCrimeNames(feature, limit);
    //get dates TODO FIX THIS IS BAD
    var crimeCategories= getCrimeCategories(periodicstats, someCrimes);
   
   //construct array that's supported by charts
    var crimeData = someCrimes.map(function(element) {
                title = element.replace(/-/g, ' ');
                title = title.charAt(0).toUpperCase() + title.slice(1);
                crimeCounts = getCrimeCounts(periodicstats, element,crimeCategories );
                return {name: title, data: crimeCounts};
    });
    
  
 
        $("#plots").highcharts({
            title: {
                text: "Crime rate over time",
                x: 0 //center
            },
            xAxis: {
                categories: crimeCategories,
                title: {
                    text: 'Date'
                }
            },
            yAxis: {
                title: {
                    text: 'Crime count'
                },
                plotLines: [{
                    value: 0,
                    width: 1,
                    color: '#808080'
                }]
            },
            tooltip:{
                hideDelay: 5,
                        backgroundColor: 'white',
                        headerFormat: '<span style="font-size: 13px; font-weight: 700;">{point.key}</span><br/>',
                        borderColor: 'black',
                        borderWidth: 1
            },
            series: crimeData
        });
 
    
}

//PLEASE DON'T REFACTOR - WORK IN PROGRESS
function generatePopupPie(feature, popup) {
    // Look if feature has stats (neighbourhood)
    if (feature.get('stats')) {
        var stats = feature.get('stats');
        stats = (typeof stats !== 'undefined'? JSON.parse(stats): false);

        if (stats != false) {
            // Create a chart element
          

            // Get the data from stats, sort it, and merge if needed
            //GET BIGGER STATS, DO NOT REVERSE THIS!!!!!!
            if (stats.length > 1) {
                stats = stats.sort(function(a, b) {
                    return b.count - a.count;
                });
            }

            var other= 0;
            var limit = 6; // Number of different types that are allowed
            var others = stats.slice(limit).reduce(function(current, next) {
                return current + next.count;
            }, 0);

            var data = stats.slice(0, limit).map(function(element) {
                var title = element.crime.replace(/-/g, ' ');
                return {name: title.charAt(0).toUpperCase() + title.slice(1), y: element.count, color: app.sharedStyle.generateColour(element.crime)};
            });

            if (other > 0) {
                data.push({name: "Other crimes", y: other, color: app.sharedStyle.generateColour('other-crime')});
            }

                $('#plots').highcharts({
                    chart: {
                        type: 'pie',
                        plotBackgroundColor: null,
                        plotBorderWidth: null,
                        plotShadow: false,
                        width: 600,
                        height: 300
                    },
                    title: {
                        text: 'Crimes in ' + feature.get('name')
                    },
                    tooltip: {
                        pointFormat: 'Share: <b>{point.percentage:.1f}%</b>',
                        hideDelay: 5,
                        backgroundColor: 'white',
                        headerFormat: '<span style="font-size: 13px; font-weight: 700;">{point.key}</span><br/>',
                        borderColor: 'black',
                        borderWidth: 1
                    },
                    plotOptions: {
                        pie: {
                            allowPointSelect: false,
                            cursor: 'pointer',
                            dataLabels: {
                                enabled: true,
                                format: '{point.name}: {point.y} ',
                                style: {
                                    color: (Highcharts.theme && Highcharts.theme.contrastTextColor)
                                }
                            }
                        }
                    },
                    series: [{
                        data: data
                    }]
                });

                
           

            $(popup).on('didHide', function(event) {
               // $(container).highcharts().destroy();
               // $(container).remove();
               // $(popup).off(event);
            });

           
        }
    }

 
}


//PLEASE DON'T REFACTOR - WORK IN PROGRESS
function getCrimeCounts(periodicstats, crimeName , crimeCategories){
    var crimeArray = $.grep(periodicstats, function(e){ return e.crime == crimeName; });
    if (crimeArray.length < 1) return 0;

    crimeArray = crimeArray.sort(function(a,b){
        return new Date(a.date) - new Date(b.date);
    });
    
    var crimeCounts = crimeCategories.map(function(date) {
        var counts=  $.grep(crimeArray, function(e){ return e.date == date; });
        return (counts.length == 0 ? 0 : counts[0].count);
    });
    
   
    return crimeCounts;
}

//PLEASE DON'T REFACTOR - WORK IN PROGRESS
function getCrimeCategories(periodicstats, crimeName){
    var dates = [], crimeCategories=[];
    
    for(var i = 0; i<crimeName.length; i++) {
        dates = $.grep(periodicstats, function(e){ 
            return (e.crime == crimeName[i]) && (jQuery.inArray( e.date , crimeCategories )<0); 
        });
        crimeCategories = crimeCategories.concat(dates.map(function(d) {    
            return d.date;
        }));
    }
    
    crimeCategories =crimeCategories.sort(function(a,b){
        return new Date(a) - new Date(b);
    });

    return crimeCategories;
    
    
}

function getBiggestCrimeNames(feature, limit) {
    var stats = feature.get('stats');
    stats = (typeof stats !== 'undefined'? JSON.parse(stats): false);

    // Get the data from stats, sort it (DESCENDING), and merge if needed
    if (stats.length > 1) {
        stats = stats.sort(function(a, b) {
            return b.count - a.count;
        });
    }

    var data = stats.slice(0, limit).map(function(element) {
        return element.crime;
    });

    return data;

}
