if (!window.app) {
  window.app = {};
}
var app = window.app;

/**
 * @class
 * Object that can carry out the police force distribution algorithm
 * given a set of neighbourhoods and a number of available forces.
 *
 * The flow for displaying the force input and results is handled by the
 * distributor, but the neighbourhoods should be provided from the outside
 *
 * @constructor
 */

app.PoliceDistributor = function() {
    this.neighbourhoods = [];
}

app.PoliceDistributor.prototype.setNeighbourhoods = function(newNeighbourhoods) {
    if (newNeighbourhoods.constructor === Array)
        this.neighbourhoods = newNeighbourhoods;
    else
        this.neighbourhoods = [];
}

app.PoliceDistributor.prototype.createDistributionModal_ = function(calculationCallback) {
    var modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.setAttribute('tabindex', -1);
    modal.setAttribute('role', 'dialog');

    // Container
    var dialog = document.createElement('div');
    dialog.className = 'modal-dialog';
    modal.appendChild(dialog);

    // Content
    var content = document.createElement('div');
    content.className = 'modal-content container-fluid';
    dialog.appendChild(content);

    // Header
    var header = document.createElement('div');
    header.className = 'modal-header';
    content.appendChild(header);

    var closeButton = document.createElement('button');
    closeButton.className = 'close';
    closeButton.setAttribute('data-dismiss', 'modal');
    closeButton.setAttribute('aria-hidden', true);
    closeButton.setAttribute('type', 'button');
    closeButton.innerHTML = "&times;";
    header.appendChild(closeButton);

    var title = document.createElement('h4');
    title.innerHTML = 'Police Resource Distribution';
    title.className = 'modal-title';
    header.appendChild(title);

    // Body
    var body = document.createElement('div');
    body.className = 'modal-body';
    body.style["overflow-y"] = "auto";
    body.style["max-height"] = "300px";
    $(body).append('<div class="row"><div><p><b>Specify available forces for the selected area<b></p><div></div>');
    $(body).append('<div class="row"><div class="col-md-5"><div class="input-group number-spinner"><span class="input-group-btn data-dwn"><button class="btn btn-default btn-info" data-dir="dwn"><span class="glyphicon glyphicon-minus"></span></button></span><input id="policeNo" type="text" class="form-control text-center" value="10" min="10" max="400" width="585px"><span class="input-group-btn data-up"><button class="btn btn-default btn-info" data-dir="up"><span class="glyphicon glyphicon-plus"></span></button></span></div></div></div>');

    // Results table
    $(body).append('<div id="modaltable" class="row" style="margin-top: 20px"></div>');

    // Enable the +/- buttons
    var action;
    $(body).find(".number-spinner button").mousedown(function () {
        btn = $(this);
        input = btn.closest('.number-spinner').find('input');
        btn.closest('.number-spinner').find('button').prop("disabled", false);

    	if (btn.attr('data-dir') == 'up') {
            action = setInterval(function(){
                if (input.attr('max') == undefined || parseInt(input.val()) < parseInt(input.attr('max'))) {
                    input.val(parseInt(input.val())+1);
                }else{
                    btn.prop("disabled", true);
                    clearInterval(action);
                }
            }, 50);
    	} else {
            action = setInterval(function(){
                if (input.attr('min') == undefined || parseInt(input.val()) > parseInt(input.attr('min'))) {
                    input.val(parseInt(input.val())-1);
                } else {
                    btn.prop("disabled", true);
                    clearInterval(action);
                }
            }, 50);
    	}
    }).mouseup(function(){
        clearInterval(action);
    });

    content.appendChild(body);

    // Footer
    var footer = document.createElement('div');
    footer.className = 'modal-footer';

    // Dismiss
    var dismissButton = document.createElement('button');
    dismissButton.className = 'btn btn-default';
    dismissButton.setAttribute('type', 'button');
    dismissButton.setAttribute('data-dismiss', 'modal');
    dismissButton.innerHTML = 'Close';
    footer.appendChild(dismissButton);

    // Calculate
    var calculateButton = document.createElement('button');
    calculateButton.setAttribute('type', 'button');
    calculateButton.className = 'btn btn-primary';
    calculateButton.innerHTML = 'Calculate Distribution';
    calculateButton.onclick = function(event) {
        var count = document.getElementById("policeNo").value;
        calculationCallback(count, $("#modaltable")[0], calculateButton);
    };
    footer.appendChild(calculateButton);

    content.appendChild(footer);

    return modal;
}

app.PoliceDistributor.prototype.startDistributionFlow = function() {
    var me = this;

    // Create the modal to show
    // (which takes input and will eventually show the results)
    var modal = this.createDistributionModal_(function(forceSize, resultsTable, calculateButton) {
        // Carry out the calculations
        var crimeCounts = [];
        var distributionRatios = [];
        var distributions = [];
        var sum = 0;
        var i = 0;

        for (i = 0, l = me.neighbourhoods.length; i < l; i++) {
            var neighbourhood = me.neighbourhoods[i];

            var crimeCount = parseInt(neighbourhood.get('crimecount'));
            crimeCounts.push(crimeCount);

            sum += crimeCount;
        }

       
        var leftoverForce = forceSize - crimeCounts.length;
        var used = 0, toAdd;

        for (i = 0, l = crimeCounts.length; i < l; i++) {
            var ratio = crimeCounts[i] / sum;
            toAdd= Math.round(ratio * leftoverForce);

            distributionRatios.push(ratio); 
            distributions.push(toAdd + 1);
            used += (toAdd + 1);
            
        }
        
        //sometimes rounding "loses" some police. Hack to fix
        if(used < forceSize) {
            var ratioArray = distributionRatios.map(function(element) {
                return (element + 0.5) % 1; // get leftover ratio
            });
            while(used < forceSize) {
                var ind = ratioArray.indexOf(Math.max.apply(Math, ratioArray));
                distributions[ind] =  distributions[ind] + 1;
                ratioArray[ind] = 0;
                used += 1;
            }
        }
        
        // Build the final results table
        var element = '<div><p><b>Police distribution amongst area selected</b></p></div>\
                       <div><table class="table table-striped" style="margin-bottom: 0px">\
                            <thead>\
                                <tr>\
                                    <th>Area</th>\
                                    <th>Number of Police</th>\
                                </tr>\
                            </thead>\
                            <tbody>';

        for (i = 0, l = me.neighbourhoods.length; i < l; i++) {
            var neighbourhood = me.neighbourhoods[i];
            row = '<tr><td>'+ neighbourhood.get('name') + '</td><td>' + distributions[i] +'</td></tr>';
            element += row;
        }

        element+= '</tbody></table></div>';

        resultsTable.innerHTML = element;
        calculateButton.innerHTML = "Recalculate Distribution";
    });

    $(modal).modal().show();

    $(modal).on('hidden.bs.modal', function () {
        $(modal).data('bs.modal', null);
        $(modal).remove();
    });
}
