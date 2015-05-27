/**
 *  Stats functions to handle the contents of the popups
 *
 *  @require Style.js
 */

if (!window.app) {
  window.app = {};
}

var app = window.app;

/**
 *  Function that should return whatever is put into the
 *  stats popup shown for a feature
 *  (feature might be a neighbourhood or an incident)
 *
 *  @param feature  - Feature for which the popup will be shown
 *  @param popup    - Popup into which the content will be placed (function
 *                      should avoid calling functions on the popup)
 */

function generatePopupContent(feature, popup){

    var contents = generatePopupPie(feature, popup);



   // generatePopupCharts(feature, popup);


    return contents;
}

function generatePopupCharts(feature, popup){

    var stats2 = feature.get('stats2'), limit = 5;

     stats2 = (typeof stats2 !== 'undefined'? JSON.parse(stats2): false);

    if(!stats2) return "";
 
    
   
    var someCrimes = getBiggestCrimeNames(feature, limit);
    
    addPlot(someCrimes, stats2, popup);

    //var drugs = $.grep(stats2, function(e){ return e.crime == 'drugs2'; });

    //console.log(drugs.length == 0);


}

function getBiggestCrimeNames(feature, limit){
    var stats = feature.get('stats');
    
     stats = (typeof stats !== 'undefined'? JSON.parse(stats): false);
    
     // Get the data from stats, sort it, and merge if needed
     //GET BIGGER STATS, DO NOT REVERSE THIS!!!!!!
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

function addPlot(crimeName, stats2,popup){
    var crimeArray = $.grep(stats2, function(e){ return e.crime == crimeName; });

    if(crimeArray.length < 2) return "";

    if($(popup.getElement()).find("#"+crimeName+"div")[0]== undefined){
        var crimeDiv = $("<div>", {id :crimeName+"div"});
        $(popup.getElement()).append(crimeDiv);
    }
    
    
    crimeArray = crimeArray.sort(function(a,b){
        return new Date(a.date) - new Date(b.date);
    });

    var crimeCategories = crimeArray.map(function(crime) {
        return crime.date;
    });
    
    var crimeCounts = crimeArray.map(function(crime) {
        return crime.count;
    });
    
    $(popup).on('didShow', function(event) {

        $(crimeDiv).highcharts({
            title: {
                text: crimeName,
                x: -20 //center
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
            series: [{showInLegend: false,      
                data: crimeCounts
            }]
        });


    });


}

function generatePopupPie(feature, popup) {
    // Look if feature has stats (neighbourhood)

    if (feature.get('stats')) {
        var stats = feature.get('stats');
        stats = (typeof stats !== 'undefined'? JSON.parse(stats): false);

        if (stats != false) {
            // Create a chart element
            var container = $(popup.getElement()).find('#chart')[0];
            if (container == undefined) {
                container = document.createElement('div');
                container.id = 'chart';
                container.width = 450;
                container.height = 450;
                container.style.marginTop = "10px";
            }

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

            // For some reason can't reuse the chart, as data wouldn't
            // update. FIXME, this is a hack, better approach would be to reuse
            // the chart (otherwise get the same annoying animation every time
            // even if the chart was already open)
            var chart = $(container).highcharts();
            if (chart != undefined) {
                chart.destroy();
            }

            $(popup).on('didShow', function(event) {
                var container = $(popup.getElement()).find('#chart').first();
                $(container).highcharts({
                    chart: {
                        type: 'pie',
                        plotBackgroundColor: null,
                        plotBorderWidth: null,
                        plotShadow: false,
                        width: 350,
                        height: 250
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

                $(popup).off(event);
            });

            $(popup).on('didHide', function(event) {
                $(container).highcharts().destroy();
                $(container).remove();
                $(popup).off(event);
            });

            return container.outerHTML;
        }
    }

    return "";
}
