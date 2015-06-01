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


if (!window.app) {
    window.app = {};
}
var app = window.app;


//should have a parent object with police. TODO if there's time. 
app.Statistics = function() {
    this.neighbourhoods = [];
    var that = this;
    this.plotLimit = 3;
    this.pieLimit = 6;
    this.popup ;
     this.filtering = false;
    
    //Listeners
    $( document ).ready(function() {
        $(".chartTabs").click(function() {
            $(".chartTabs").removeClass("selectedTab");
            $(this).addClass("selectedTab");
            that.generatePopupContent();
        });
    });
}

app.Statistics.prototype.setPopup = function(popup){
    this.popup = popup;
}

//should have a parent object with police. TODO if there's time. 
app.Statistics.prototype.setNeighbourhoods = function(newNeighbourhoods) {
    if (newNeighbourhoods.constructor === Array)
        this.neighbourhoods = newNeighbourhoods;
    else
        this.neighbourhoods = [];
}

app.Statistics.prototype.generatePopupContent = function() {
    var selectedTab = $(".chartTabs.selectedTab").prop("id");
    var popup = this.popup;
   
    if(popup == "#plots") {
        switch(selectedTab) {
            case "pie":
                this.generatePopupPie(popup);
                break;
            case "overTime":
                this.generatePopupCharts(popup);
                break;
            case "totalTime":    
                this.generatePopupChartsTotals(popup);
                break;
            default:
            // default code block
        }
    }else {
        this.generatePopupPie(popup);
        this.generatePopupCharts(popup+"2");
        
    }
    
}



app.Statistics.prototype.generatePopupCharts = function(popup) {
    var that = this, 
    limit = this.plotLimit,
    features = this.neighbourhoods,
    title="", crimeCounts = 0;
        
    var plotTitle = 'Highest Crimes over time in ' + this.getPostCodes(features);    
    
    //get array of names of highest crimes
    var someCrimes = that.getBiggestCrimeNames(features, limit);
    
    //get array of dates
    var crimeCategories= that.getCrimeCategories(features, someCrimes);
   
   var style = new app.Style();
   
    //construct array that's supported by charts
    var crimeData = someCrimes.map(function(element) {
        var crimeColor = style.generateColour(element);
        title = element.replace(/-/g, ' ');
        title = title.charAt(0).toUpperCase() + title.slice(1);
        crimeCounts = that.getCrimeCounts(features, element,crimeCategories );
        return {
            name: title, 
            data: crimeCounts,
            color: crimeColor
        };
    });
    
    this.showCharts(popup,plotTitle,crimeCategories, crimeData);
 
}

app.Statistics.prototype.showCharts = function(popup,plotTitle,crimeCategories, crimeData) {
    var pieSizes = this.getSizes();
 
    $(popup).highcharts({
        title: {
            text: plotTitle,
            x: 0 //center
        },
        chart: {
            width: pieSizes.width,
            height: pieSizes.height
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

app.Statistics.prototype.generatePopupChartsTotals = function(popup) {
    var that = this,
    features = this.neighbourhoods, crimeCounts = 0;
        
    var plotTitle = 'All Crimes over time' ;    
    
    //get array of names of highest crimes
    var someCrimes = that.getBiggestCrimeNames(features, 200);
    
    //get array of dates
    var crimeCategories= that.getCrimeCategories(features, someCrimes);
   
    var totalCrimes = Array.apply(null, new Array(crimeCategories.length)).map(Number.prototype.valueOf,0);
    //construct array that's supported by charts
    
    for(var i = 0; i < someCrimes.length; i++) {
        crimeCounts = that.getCrimeCounts(features, someCrimes[i],crimeCategories );
        totalCrimes =  crimeCounts.map(function(count, idx) {
                return count + totalCrimes[idx];
        });
    }
 
    var crimeData = [{data: totalCrimes, name: "All crimes in " + this.getPostCodes(features)}];
 
    
 
   this.showCharts(popup,plotTitle,crimeCategories, crimeData);
 
}


app.Statistics.prototype.generatePopupPie = function(popup) {
    var features = this.neighbourhoods, 
    limit = this.pieLimit; // Number of different types that are allowed 

    var pieTitle = 'Highest Crimes in ' + this.getPostCodes(features);
  
    var stats = this.getBiggestCrimes(features);
    if (stats != false) {

        var other = stats.slice(limit).reduce(function(current, next) {
            return current + next.count;
        }, 0);

        var style = new app.Style();
        var data = stats.slice(0, limit).map(function(element) {
            var title = element.crime.replace(/-/g, ' ');
            return {
                name: title.charAt(0).toUpperCase() + title.slice(1), 
                y: element.count, 
                color: style.generateColour(element.crime)
                };
        });

        if (other > 0) {
            data.push({
                name: "Other crimes", 
                y: other, 
                color: style.generateColour('other-crime')
                });
        }

        var pieSizes = this.getSizes();

        $(popup).highcharts({
            chart: {
                type: 'pie',
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                width: pieSizes.width,
                height: pieSizes.height
                
            },
            title: {
                text: pieTitle
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
                            color: (Highcharts.theme && Highcharts.theme.contrastTextColor),
                             fontSize: pieSizes.font
                        }
                    }
                }
            },
            series: [{
                data: data
            }]
        });

                
     
        
    }

 
}

app.Statistics.prototype.getPostCodes = function(features){
    return features.map(function(element) {
       return element.get("name");
    }).join(", ");
}

app.Statistics.prototype.getSizes = function(){
    var chartSizes;
    if(this.popup == "#plots"){
        chartSizes = {"width": 600, "height":300, "font" : "12px"};
    }else {
        chartSizes = {"width": 380, "height":300, "font": "9px"};
    }
    return chartSizes;
}


app.Statistics.prototype.getCrimeCounts=function(features, crimeName , crimeCategories){
    var crimeCounts = Array.apply(null, new Array(crimeCategories.length)).map(Number.prototype.valueOf,0);
    
    for(var i =0; i<features.length; i++) {
        var feature = this.extractFeature(features[i], "periodicstats");
        var crimeArray = $.grep(feature, function(e){
            return e.crime == crimeName;
        });
        if (crimeArray.length > 0) {
            crimeArray = crimeArray.sort(function(a,b){
                return new Date(a.date) - new Date(b.date);
            });

            crimeCounts = crimeCategories.map(function(date, idx) {
                var counts=  $.grep(crimeArray, function(e){
                    return e.date == date;
                });
                return (counts.length == 0 ? 0 : counts[0].count) + crimeCounts[idx];
            });
        } 
    }
    return crimeCounts;
}

app.Statistics.prototype.getCrimeCategories = function(features, crimeName){
    var dates = [], crimeCategories=[];
    for(var j = 0; j< features.length;j++) {
        var periodicstats =this.extractFeature(features[j], "periodicstats");
        if(periodicstats !== false){
            for(var i = 0; i<crimeName.length; i++) {
                dates = $.grep(periodicstats, function(e){ 
                    return (e.crime == crimeName[i]) && (jQuery.inArray( e.date , crimeCategories )<0); 
                });
                crimeCategories = crimeCategories.concat(dates.map(function(d) {    
                    return d.date;
                }));
            }
        }
    }
    crimeCategories =crimeCategories.sort(function(a,b){
        return new Date(a) - new Date(b);
    });

    return crimeCategories;
}


app.Statistics.prototype.getBiggestCrimes = function(features){
    var statCounts = this.extractFeature(features[0], "stats");
    
    for(var i = 1; i < features.length; i++){
        var stats = this.extractFeature(features[i], "stats");
        
        //add counts from all neighbourhoods
        statCounts = stats.map(function(element){ 
            var rObj = {};
            rObj.crime = element.crime;            
            var counts = $.grep(statCounts, function(e){
                return e.crime == element.crime;
            });
            rObj.count = (counts.length>0 ? element.count + counts[0].count : element.count) ;
            return rObj;
        });
    }
    
    // Get the data from stats, sort it (DESCENDING), and merge if needed
    if (statCounts.length > 1) {
        statCounts = statCounts.sort(function(a, b) {
            return b.count - a.count;
        });
    }
    return statCounts;
}


app.Statistics.prototype.getBiggestCrimeNames = function(features, limit) {
    var stats = this.getBiggestCrimes(features);
    var data = stats.slice(0, limit).map(function(element) {
        return element.crime;
    });
    return data;
}


app.Statistics.prototype.extractFeature = function(feature,name){
    var periodicstats = feature.get(name);
    periodicstats = (typeof periodicstats !== 'undefined'? JSON.parse(periodicstats): false);
    return periodicstats;
}

app.Statistics.prototype.setFiltering = function(value){
    this.filtering = value;
}

app.Statistics.prototype.refreshStats = function(){
    if(!this.filtering) { return;}
    this.setFiltering(false);
    if($('#drawer:visible').length ==0) {return;}
    var features = this.neighbourhoods;
    if(features.length !== 1) {return;}
    var gid = features[0].getId();
    var feature = neighbourhoodsStatsSource.getFeatureById(gid);
    this.setNeighbourhoods([feature]);
   
    this.generatePopupContent(); 
    
}