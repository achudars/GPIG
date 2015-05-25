/**
 *  Stats functions to handle the contents of the popups
 */

/**
 *  Function that should return whatever is put into the
 *  stats popup shown for a feature
 *  (feature might be a neighbourhood or an incident)
 */
function generatePopupContent(feature) {
    // Look if feature has stats (neighbourhood)
    // TODO: Piecharts and stuff
    if (feature.get('stats')) {
        // HTML table
        var stats_feature = feature.get("stats");
        var stats = (typeof stats_feature !== 'undefined'? JSON.parse(stats_feature): false);

        if (stats) {
            // TODO: This needs tidying up...
            var container = document.createElement("div");
            container.className = 'container';
            container.style.width = '300px';
            var table = document.createElement('table');
            table.className = 'table table-striped';
            var thead = document.createElement('thead');
            var heading = document.createElement('h4');
            heading.textContent = 'Crimes in this Postcode'
            var crimecount = document.createElement('p');
            crimecount.textContent = 'Total Crimes: ' + feature.get("crimecount");
            var tr = document.createElement('tr');
            var th_Crime = document.createElement('th');
            th_Crime.textContent = 'Crime';
            var th_Count = document.createElement('th');
            th_Count.textContent = 'Count';
            var tbody = document.createElement('tbody');
            container.appendChild(table);
            table.appendChild(thead);
            thead.appendChild(heading);
            thead.appendChild(crimecount);
            thead.appendChild(tr);
            tr.appendChild(th_Crime);
            tr.appendChild(th_Count);
            table.appendChild(tbody);
            for (var i = 0; i < stats.length; i++) {
                tr_body = document.createElement('tr');
                td_crime = document.createElement('td');
                td_crime.textContent = stats[i].crime;
                td_count = document.createElement('td');
                td_count.textContent = stats[i].count;
                tbody.appendChild(tr_body);
                tr_body.appendChild(td_crime);
                tr_body.appendChild(td_count);
            }

            return container.outerHTML;
        } else {
            return "No crimes of this type";
        }
    }

    return null
}
