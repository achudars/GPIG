if (!window.app) {
  window.app = {};
}

var app = window.app;

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

/**
 *  Object responsible for styling
 */
app.Style = function(/*options*/) {
    // Populate our colour scheme for crime types
    this.conversion = {
        'drugs': hexToRGB('231f20'),
        'public-order': hexToRGB('1c3f95'),
        'other-crime': hexToRGB('5a5758'),
        'bicycle-theft': hexToRGB('737171'),
        'other-theft': hexToRGB('959ca1'),
        'robbery': hexToRGB('d9d8d8'),
        'possession-of-weapons': hexToRGB('ee2e24'),
        'burglary': hexToRGB('f386a1'),
        'violent-crime': hexToRGB('ffd204'),
        'theft-from-the-person': hexToRGB('00853e'),
        'anti-social-behaviour': hexToRGB('85cebc'),
        'vehicle-crime': hexToRGB('009ddc'),
        'criminal-damage-arson': hexToRGB('98005d'),
        'shoplifting': hexToRGB('b06110')
    }

    // Not dimmed by default
    this.dimmed = false;
}

app.Style.prototype.setDimmed = function(dimmed) {
    this.dimmed = dimmed;
    // Potentially could clear caches
    console.log("Dimmed changed", dimmed);
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
        } else if (idx == colors.length - 1 && idx > 0) {
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

app.Style.prototype.convertColourToString = function(color, alpha, dimmed) {
    if (alpha == undefined) {
        alpha = 1.0;
    }

    if (dimmed == undefined) {
        dimmed = false;
    }

    if (typeof color == 'string' || color instanceof String) {
        color = hexToRGB(color);
    }

    // Check if we need to dim the colours
    if (dimmed) {
        var y = ((66 * color.r + 129 * color.g +  25 * color.b + 128) >> 8) +  16;
        var u = ((-38 * color.r - 74 * color.g + 112 * color.b + 128) >> 8) + 128;
        var v = ((112 * color.r - 94 * color.g - 18 * color.b + 128) >> 8) + 128;

        return 'rgba(' + y + ',' + y + ',' + y + ',' + alpha + ')';
    }

    return 'rgba(' + color.r + ',' + color.g + ',' + color.b + ',' + alpha + ')'
}

app.Style.prototype.generateColour = function(crimeType, alpha, dimmed) {
    var components = crimeType != undefined ? this.conversion[crimeType] : undefined;
    if (components == undefined) {
        components = this.conversion['other-crime'];
    }

    return this.convertColourToString(components, alpha, dimmed);
}

app.Style.prototype.generateNeighbourhoodStyle = function(feature, resolution) {
    var count = parseInt(feature.get('crimecount'));
    var highlighted = feature.get('highlighted');
    var hovered = feature.get('hover');
    var dimmed = feature.get('dimmed');

    if (highlighted == undefined)
        highlighted = false;

    if (hovered == undefined)
        hovered = false;

    if (dimmed == undefined)
        dimmed = this.dimmed;

    // Determine the key for this feature
    var key;
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
                color: 'rgba(0,0,0,' + (dimmed ? 0.25 : 0.5) + ')',
                width: (highlighted || hovered) ? 2 : 1
            }),

            text: new ol.style.Text({
                font: '14px Helvetica, sans-serif',
                text: feature.get("name"),
                fill: new ol.style.Fill({
                    color: 'rgba(0,0,0,' + (dimmed ? 0.4 : 1.0) + ')',
                }),
                stroke: new ol.style.Stroke({
                    color: "#FFF",
                    width: 3
                })
            })
        })
    ]

    // Dynamic styles
    var alpha = (highlighted ? '0.5' : hovered ? '0.35' : dimmed ? '0.1' : '0.25');
    var count = parseInt(feature.get("crimecount"));
    if (key == 'very low') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: this.convertColourToString({r: 115, g: 206, b: 255}, alpha, dimmed)
            })
        }));
    } else if (key == 'low') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: this.convertColourToString({r: 187, g: 255, b: 255}, alpha, dimmed)
            })
        }));
    } else if (key == 'medium') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: this.convertColourToString({r: 255, g: 243, b: 101}, alpha, dimmed)
            })
        }));
    } else if (key == 'high') {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: this.convertColourToString({r: 255, g: 155, b: 30}, alpha, dimmed)
            })
        }));
    } else {
        styles.push(new ol.style.Style({
            fill: new ol.style.Fill({
                color: this.convertColourToString({r: 255, g: 22, b: 4}, alpha, dimmed)
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

    var crimes = feature.get('crime');
    var size = feature.get('size');
    var dimmed = feature.get('dimmed');

    if (dimmed == undefined) {
        dimmed = this.dimmed;
    }

    // Check if such a feature has been seen (crimes + size)
    if (crimes == undefined || size == undefined) {
        console.log("values not defined");
        return [];
    }

    var key = 'crimes:' + crimes + ';size:' + size + ';dimmed:' + dimmed;

    var styles = this.incidentStyleCache[key];
    if (styles != undefined) {
        return styles;
    }

    // Generate an appropriate image for the cluster
    var me = this;
    var colours = crimes.map(function(element, idx) {
        return me.generateColour(element, 1.0, dimmed);
    });

    var radius = Math.min(Math.max(size / 500 * 12, 8), 12);
    var imageInfo = this.generateColoursImage(colours, radius, 2);

    styles = [new ol.style.Style({
        image: new ol.style.Icon({
            src: imageInfo.img,
            scale: 1 / imageInfo.scale
        }),
    })];

    if (size > 1) {
        styles.push(new ol.style.Style({
            text: new ol.style.Text({
                font: '14px Helvetica, sans-serif',
                text: size.toString(),
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

app.Style.prototype.generatePoliceDistroStyle = function(feature, resolution) {

    var numberOfPolice = feature.get('noofpolice');

    // Check if such a feature has been seen (Number of Police)
    if (numberOfPolice == undefined) {
        console.log("values not defined");
        return [];
    }

    return [new ol.style.Style({
        image: new ol.style.Circle({
          radius: 8,
          fill: new ol.style.Fill({
            color: 'rgba(20,150,200,0.3)'
          }),
          stroke: new ol.style.Stroke({
            color: 'rgba(20,130,150,0.8)',
            width: 1
          })
        }),
        text: new ol.style.Text({
          font: '14px Helvetica, sans-serif',
          text: numberOfPolice.toString(),
          fill: new ol.style.Fill({
            color: "#000"
          }),
          stroke: new ol.style.Stroke({
            color: "#FFF",
            width: 3
          })
        })
    })];
}
