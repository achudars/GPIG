/**
 *  Feature additions
 */

ol.Feature.prototype.getLayer = function(map) {
    var found = undefined;
    var id = this.getId();

    map.getLayers().forEach(function(layer) {
        if (!(layer instanceof ol.layer.Vector)) {
             return false;
           }

           if (layer.getSource().getFeatureById(id) != undefined) {
               found = layer;
               return true;
           }
    });

    return found;
};

ol.Feature.prototype.restyle = function(map) {
    var layer = this.getLayer(map);
    var styleFunction = layer.getStyleFunction();
    var resolution = map.getView().getResolution();
    this.setStyle(styleFunction(this, resolution));
};

ol.Feature.prototype.unset = function(key, restyle, map) {
    if (restyle == undefined || map == undefined)
        restyle = false;

    if (this.values_[key] != undefined) {
        delete this.values_[key];

        if (restyle)
            this.restyle(map);
    }
}

/**
 *  Layer
 */

ol.layer.Layer.prototype.restyle = function(map) {
    if (map == undefined) {
        // No way to get the resolution, but could
        // still look for a local style function
        return;
    }

    // Loop over all visible features on the layer and re-apply their style
    var source = this.getSource();
    var styleFunction = this.getStyleFunction();
    var resolution = map.getView().getResolution();
    var features = source.getFeatures();

    for (var i = 0, l = features.length; i < l; i++) {
        var feature = features[i];
        feature.setStyle(styleFunction(feature, resolution));
    }
};

/**
 *  Source
 */
ol.source.Vector.prototype.getFeaturesByIDs = function(IDs) {
    return this.getFeatures().filter(function(element) {
        var id = element.getId();
        return IDs.indexOf(id) != -1;
    });
}

/**
 *  Map
 */

ol.Map.prototype.getLayerForTitle = function(title) {
    var found = undefined;
    this.getLayers().forEach(function(layer) {
        if (layer.get('title') == title) {
            found = layer;
            return true;
        }
    });

    return found;
};
