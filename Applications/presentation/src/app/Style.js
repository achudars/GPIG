if (!window.app) {
  window.app = {};
}

var app = window.app;

/**
 *  Object responsible for styling
 */
app.Style = function(/*options*/) {
    function hexToRGB(hex) {
        // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
        var shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
        hex = hex.replace(shorthandRegex, function(m, r, g, b) {
            return r + r + g + g + b + b;
        });

        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null;
    }

    // Populate our colour scheme for crime types
    this.conversion = {
        'drugs': hexToRGB('090446'),
        'public-order': hexToRGB('384E77'),
        'other-crime': hexToRGB('FEB95F'),
        'bicycle-theft': hexToRGB('8BBEB2'),
        'other-theft': hexToRGB('C2095A'),
        'robbery': hexToRGB('30C5FF'),
        'possession-of-weapons': hexToRGB('E9EB87'),
        'burglary': hexToRGB('7B5E7B'),
        'violent-crime': hexToRGB('DDF45B'),
        'theft-from-the-person': hexToRGB('71B48D'),
        'anti-social-behaviour': hexToRGB('404E5C'),
        'vehicle-crime': hexToRGB('5BC0BE'),
        'criminal-damage-arson': hexToRGB('4EA2BE'),
        'shoplifting': hexToRGB('5BC0BE')
    }
}

if (!app.sharedStyle) {
    app.sharedStyle = new app.Style();
}

app.Style.prototype.generateColoursImage = function(colors, radius, strokeWidth) {
    if (colors.constructor !== Array) {
        colors = [colors];
    }

    if (strokeWidth == undefined) {
        strokeWidth = 2;
    }

    if (this.colourImageCache == undefined) {
        if (String.prototype.hash == undefined) {
            String.prototype.hash = function() {
                var hash = 0, i, chr, len;
                if (this.length == 0) return hash;
                for (i = 0, len = this.length; i < len; i++) {
                    chr   = this.charCodeAt(i);
                    hash  = ((hash << 5) - hash) + chr;
                    hash |= 0; // Convert to 32bit integer
                }
                return hash;
            };
        }
        this.colourImageCache = {};
    }

    // Check the cache first (cache key is the hash of the combined colours)
    var hash = colors.reduce(function(current, element) { return current + element; }, '').hash();

    var info = this.colourImageCache[hash];
    if (info) {
        return info;
    }

    var canvas = document.createElement('canvas');
    var context = canvas.getContext('2d');

    var width = (radius * 4) + (strokeWidth * 2);
    var height = (radius * 4) + (strokeWidth * 2);

    canvas.width = width;
    canvas.height = height;

    // Adjust for HiDPI screens
    var devicePixelRatio = window.devicePixelRatio || 1;
    var backingStoreRatio = context.webkitBackingStorePixelRatio ||
                    context.mozBackingStorePixelRatio ||
                    context.msBackingStorePixelRatio ||
                    context.oBackingStorePixelRatio ||
                    context.backingStorePixelRatio || 1;

    var ratio = devicePixelRatio / backingStoreRatio;

    // Retina canvas (hence the width * ratio)
    if (devicePixelRatio != backingStoreRatio) {
        canvas.width = width * ratio;
        canvas.height = height * ratio;
        canvas.style.width = width + 'px';
        canvas.style.height = height + 'px';
        context.scale(ratio, ratio);
    }

    // Polar coordinates logic
    var slice = (2 * Math.PI) / colors.length;
    var bigRadius = radius;
    var centerX = width / 2;
    var centerY = height / 2;

    // Positions for each colour
    var positions = colors.map(function(element, idx) {
        var angle = idx * slice;
        return [centerX + bigRadius * Math.cos(angle), centerY + bigRadius * Math.sin(angle)];
    });

    // First the outline stroke
    colors.forEach(function(element, idx) {
        context.beginPath();
        context.arc(positions[idx][0], positions[idx][1], radius + strokeWidth, 0, 2 * Math.PI, false);
        context.fillStyle = '#FFF';
        context.fill();
    });

    colors.forEach(function(element, idx) {
        context.save();

        // Each should be clipped to the next
        if (idx < colors.length - 1) {
            context.beginPath();
            context.rect(0, 0, width, height);
            context.arc(positions[idx + 1][0], positions[idx + 1][1], radius - 0.25, 0, 2 * Math.PI, true);
            context.closePath();
            context.clip();
        } else if (idx == colors.length - 1) {
            context.beginPath();
            context.rect(0, 0, width, height);
            context.arc(positions[0][0], positions[0][1], radius - 0.25, 0, 2 * Math.PI, true);
            context.closePath();
            context.clip();
        }

        context.beginPath();
        context.arc(positions[idx][0], positions[idx][1], radius, 0, 2 * Math.PI, false);
        context.fillStyle = element;
        context.fill();

        context.restore();
    });

    info = {img: canvas.toDataURL(), size: [width, height], scale: ratio};
    this.colourImageCache[hash] = info;

    return info;
}

app.Style.prototype.generateColour = function(crimeType, alpha) {
    if (alpha == undefined) {
        alpha = 1.0;
    }

    var components = crimeType != undefined ? this.conversion[crimeType] : undefined;
    if (components == undefined) {
        components = this.conversion['other-crime'];
    }

    return 'rgba(' + components.r + ',' + components.g + ',' + components.b + ',' + alpha + ')'
}

app.Style.prototype.generateNeighbourhoodStyle = function(feature, resolution) {
    // Determine the key for this feature
    var count = parseInt(feature.get('crimecount'));
    var key;
    var highlighted = feature.get('highlighted') == true;
    var hovered = feature.get('hover') == true;

    if (count < 100) {
        key = 'very low';
    } else if (count < 200) {
        key = 'low';
    } else if (count < 500) {
        key = 'medium';
    } else if (count < 1000) {
        key = 'high';
    } else {
        key = 'very high';
    }

    // Shared styles
    var styles = [
        // Everybody has a stroke and a text fill style
        new ol.style.Style({
            stroke: new ol.style.Stroke({
                color: 'rgba(0,0,0,0.5)',
                width: (highlighted || hovered) ? 2 : 1
            }),

            text: new ol.style.Text({
                font: '14px Helvetica, sans-serif',
                text: feature.get("name"),
                fill: new ol.style.Fill({
                    color: "#000"
                }),
                stroke: new ol.style.Stroke({
                    color: "#FFF",
                    width: 3
                })
            })
        })
    ]

    // Dynamic styles
    var alpha = (highlighted ? '0.6' : hovered ? '0.45' : '0.35')
    var count = parseInt(feature.get("crimecount"));
    if (key == 'very low') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(115,206,255,' + alpha + ')'
            })
        }));
    } else if (key == 'low') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(187,255,255,' + alpha + ')'
            })
        }));
    } else if (key == 'medium') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(255,243,101,' + alpha + ')'
            })
        }));
    } else if (key == 'high') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(255,155,30,' + alpha + ')'
            })
        }));
    } else {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: 'rgba(255,22,4,' + alpha + ')'
            })
        }));
    }

    return styles;
}

app.Style.prototype.generateIncidentStyle = function(feature, resolution) {
    // Maintain a style cache
    // This is due to this - https://github.com/openlayers/ol3/issues/3137
    // too many styles apparently causes a flicker... *facepalm*
    if (this.incidentStyleCache == undefined) {
        this.incidentStyleCache = {};
    }

    // Check if this feature has been seen
    var key = feature.get('style-cache-key');
    if (key != undefined) {
        var styles = this.incidentStyleCache[key];
        if (styles != undefined) {
            return styles;
        }
    } else {
        key = (new Date % 9e6).toString(36);
        feature.set('style-cache-key', key);
    }

    // Generate an appropriate image for the cluster
    var clustered = feature.get('features');
    var crimes = clustered.reduce(function(currentValue, element) {
        var crime = element.get('crime');
        if (crime && currentValue.indexOf(crime) == -1) {
            currentValue.push(crime);
        }

        return currentValue;
    }, []).sort();

    var me = this;
    var colours = crimes.map(function(element, idx) {
        return me.generateColour(element);
    });

    var radius = Math.min(Math.max(clustered.length / 500 * 12, 8), 12);
    var imageInfo = this.generateColoursImage(colours, radius, 2);

    styles = [new ol.style.Style({
        image: new ol.style.Icon({
            src: imageInfo.img,
            scale: 1 / imageInfo.scale
        }),
    })];

    if (clustered.length > 1) {
        styles.push(new ol.style.Style({
            text: new ol.style.Text({
                font: '14px Helvetica, sans-serif',
                text: clustered.length.toString(),
                fill: new ol.style.Fill({
                    color: "#000"
                }),
                stroke: new ol.style.Stroke({
                    color: "#FFF",
                    width: 3
                })
            })
        }));
    }

    this.incidentStyleCache[key] = styles;
    return styles;
}
