

function reportStats(stats){
    var limit = 6;
 
    // popup.setContent(JSON.stringify(stats));
     popup.setContent('<div width="400" height="400" id="myChart"></div>');
     popup.show();
    
     var data = [];
  
     if(stats.length>1){
         stats = stats.sort(compare);
     }
 
     var other= 0;
     for (var i = 0; i < stats.length; i++ ) {
        if(i < limit) { 
           data[i] = [stats[i].crime,  stats[i].count];            
        } else {
             other += stats[i].count;
        }
    }
    if(other > 0){
        data[limit] = ["other crimes", other];
           
    } 

     addChart(data);
   
}

function waitToAppear(data){
    if($("#myChart").is(":visible")) {
        addChart(data);
    } else {
        setTimeout( waitToAppear(), 30 );
    }
    
}

function addChart(crimes){
     $(function () {
    $('#myChart').highcharts({
        chart: {
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false
        },
        title: {
            text: 'Crimes in this neighbourhood:'
        },
        tooltip: {
            pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
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
            type: 'pie',
            name: 'Crime Share',
            data: crimes
        }]
    });
});
}

function compare(a,b) {
  if (a.count < b.count){
        return 1;
  }
  if (a.count > b.count) {
       return -1;
  }
  return 0;
}

