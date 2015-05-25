/**
 *  Stats functions to handle the contents of the popups
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

function generatePopupContent(feature, popup) {
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
                container.style.marginTop = "30px";
            }

            // Get the data from stats, sort it, and merge if needed
            if (stats.length > 1) {
                stats = stats.sort(function(a, b) {
                    return a.count - b.count;
                });
            }

            var other= 0;
            var limit = 6; // Number of different types that are allowed
            var others = stats.slice(limit).reduce(function(current, next) {
                return current + next.count;
            }, 0);

            var data = stats.slice(0, limit).map(function(element) {
                var title = element.crime.replace(/-/g, ' ');
                return [title.charAt(0).toUpperCase() + title.slice(1), element.count];
            });

            if (other > 0) {
                data.push(["Other crimes", other]);
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
