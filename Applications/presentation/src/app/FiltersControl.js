if (!window.app) {
  window.app = {};
}

var app = window.app;

/**
 * @constructor
 * @extends {ol.control.Control}
 * @param {Object=} opt_options Control options
 *                      sources - Sources to alter when the filter is changed, sets a key "filter"/"cqlFilter" on the source
 *                                  and triggers a change on the source
 */
app.FiltersControl = function(opt_options) {
    var options = opt_options || {};
    this.sources = options.sources;

    var element = document.createElement('div');
    element.className = 'filters-control ol-unselectable';

    // Main form
    var form = document.createElement('form');
    element.appendChild(form);

    // Crime types
    var crimeGroup = document.createElement('div');
    crimeGroup.className = 'form-group';
    crimeGroup.style.position = 'relative';
    form.appendChild(crimeGroup);

    // - Heading
    var heading = document.createElement('label');
    heading.innerHTML = 'Crime Types';
    heading.setAttribute('for', 'crimeType');
    crimeGroup.appendChild(heading);

    var crimeTypeSelect = document.createElement('select');
    crimeTypeSelect.className = 'multiselect';
    crimeTypeSelect.name = 'crimeType';
    crimeTypeSelect.setAttribute('multiple', 'multiple');

    function createCrimeTypeOption(value, label) {
        var result = document.createElement('option');
        result.selected = true;
        result.value = value;
        result.innerHTML = label;

        return result;
    }

    var crimeTypes = [
        {
            title: 'Theft',
            items: [
                ['bicycle-theft', 'Bicycle Theft'],
                ['shoplifting', 'Shoplifting'],
                ['theft-from-the-person', 'Theft from the Person'],
                ['burglary', 'Burglarly'],
                ['robbery', 'Robbery'],
                ['other-theft', 'Other Theft']
            ]
        },
        {
            title: 'Public Order',
            items: [
                ['anti-social-behaviour', 'Anti-Social Behaviour'],
                ['public-order', 'Public Order'],
                ['vehicle-crime', 'Vehicle Crime'],
                ['drugs', 'Drugs']
            ]
        },
        {
            title: 'Violent Crime',
            items: [
                ['possession-of-weapons', 'Possession of Weapons'],
                ['criminal-damage-arson', 'Criminal Damage & Arson'],
                ['violent-crime', 'Violent Crime'],
            ]
        },
        {
            title: 'Other Crime',
            items: [
                ['other-crime', 'Other Crime']
            ]
        }
    ]

    var crimeGroups = crimeTypes.map(function(value) {
        return {
            title: value.title,
            items: value.items.map(function(item) {
                return item[0];
            })
        };
    });

    for (var i = 0, l = crimeTypes.length; i < l; i++) {
        var group = crimeTypes[i];
        var optGroup = document.createElement('optgroup');
        optGroup.label = group.title;

        for (var j = 0, k = group.items.length; j < k; j++) {
            var item = group.items[j];
            optGroup.appendChild(createCrimeTypeOption(item[0], item[1]));
        }

        crimeTypeSelect.appendChild(optGroup);
    }

    crimeGroup.appendChild(crimeTypeSelect);

    // Start date
    var dateGroup = document.createElement('div');
    dateGroup.className = 'form-group';
    form.appendChild(dateGroup);

    // Start Date - Heading
    heading = document.createElement('label');
    heading.innerHTML = 'Starting from';
    heading.setAttribute('for', 'startDate');
    dateGroup.appendChild(heading);

    // Start Date - Input
    var startDate = document.createElement('input');
    startDate.setAttribute('type', 'text');
    startDate.id = 'fromDate';
    startDate.className = 'form-control';
    startDate.value = '01-11-2013';
    dateGroup.appendChild(startDate);

    // End Date - Heading
    heading = document.createElement('label');
    heading.innerHTML = 'until';
    heading.setAttribute('for', 'endDate');
    heading.style.marginTop = '5px';
    dateGroup.appendChild(heading);

    // End Date - Input
    var endDate = document.createElement('input');
    endDate.setAttribute('type', 'text');
    endDate.id = 'fromDate';
    endDate.className = 'form-control';
    endDate.value = '03-06-2015';
    dateGroup.appendChild(endDate);

    // Apply button
    var apply = document.createElement('a');
    apply.className = 'btn btn-primary';
    apply.innerHTML = 'Apply filters';
    form.appendChild(apply);

    // Initialise some of the fields
    $(crimeTypeSelect).multiselect({
        buttonWidth: '150px',
        enableClickableOptGroups: true,
        dropRight: true,
        includeSelectAllOption: true,
        buttonText: function(options, select) {
            if (options.length === 0) {
                return 'None';
            }

            var totalOptions = $(select).find('option').length;
            if (totalOptions == options.length) {
                return 'All ' + totalOptions + ' selected';
            }

            // Check if all options fall under the same type
            var groups = [];
            $(options).each(function(idx, element) {
                if (!element.selected) {
                    return true;
                }

                var value = element.value;
                var group = crimeGroups.find(function(element) {
                    return element.items.indexOf(value) != -1;
                });

                if (group != undefined && groups.indexOf(group) == -1) {
                    groups.push(group);
                }
            });

            if (groups.length == 1 && (groups[0].items.length == options.length || options.length > 2)) {
                // All in one group
                return groups[0].title + " (" + options.length + ")";
            } else if (options.length > 2) {
                return options.length + ' selected';
            } else {
                var labels = [];

                options.each(function() {
                    if ($(this).attr('label') !== undefined) {
                        labels.push($(this).attr('label'));
                    }
                    else {
                        labels.push($(this).html());
                    }
                });

                return labels.join(', ') + '';
            }
        }
    });

    $(startDate).datepicker({ dateFormat: "dd-mm-yy" });
    $(endDate).datepicker({ dateFormat: "dd-mm-yy" });

    // Hack around the issue with the dropdown menu for multiselect
    $(form).find('.dropdown-toggle').each(function(idx, element) {
        element.onclick = function(event) {
            var group = $(this).closest('div.btn-group');
            group.toggleClass("open");
            event.preventDefault();
            return false;
        }
    });

    // Actions
    var me = this;
    apply.onclick = function() {
        // Determine the filter string
        function filterString(cql) {
            if (cql == undefined)
                cql = false;

            function formatDate(date) {
                if(date == "") { return ""; }

                var pieces = date.split('-');
                pieces.reverse();
                return pieces.join('-');
            }

            // Filter
            var components = [];

            // Crime types
            var crimes = [];
            var selectedOptions = $(crimeTypeSelect).find('option:selected').each(function(idx, element) {
                crimes.push(element.value);
            });

            // Dates
            var start = startDate != undefined ? formatDate(startDate.value) : undefined;
            var end = endDate != undefined ? formatDate(endDate.value) : undefined;

            var components = [];
            var glue;
            if (cql) {
                glue = ' AND ';

                // Crime
                components.push("(crime IN ('" + crimes.join("', '") + "'))");

                // Dates
                if (start && end) { // Range is set
                    components.push('(date BETWEEN ' + start + ' AND '+ end +')');
                } else if (fromDate !="") { // From date is set
                    components.push('(date > ' + start + ')');
                } else if (toDate !="") { // To date is set
                    components.push('(date < ' + toDate+ ')');
                }
            } else {
                glue = ';'
                components.push("CRIME:'" + crimes.join("'\\\,'") + "'");
                components.push((((start != undefined) ? "STARTDATE:" + start + ";" : "") +
                ((end != undefined) ? "ENDDATE:" + end + ";" : "")));
            }

            return components.join(glue);
        }

        var filter = filterString();
        var cqlFilter = filterString(true);

        for (var i = 0, l = me.sources.length; i < l; i++) {
            var source = me.sources[i];

            source.filter = filter;
            source.cqlFilter = cqlFilter;

            source.clear(true);
            if (typeof source.loader_ == 'function') {
                var view = me.map.getView(),
                extent = view.calculateExtent(me.map.getSize());
                source.loader_(extent, view.getResolution(), view.getProjection());
            }
        }
    }

    ol.control.Control.call(this, {
        element: element,
        target: options.target
    });
};

ol.inherits(app.FiltersControl, ol.control.Control);

app.FiltersControl.prototype.setMap = function(map) {
    this.map = map;
    ol.control.Control.prototype.setMap.call(this, map);
};
