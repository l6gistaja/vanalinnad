if (!vlUtils) {
    var vlUtils = {};
}

vlUtils.getXmlValue = function(xmlDocument, tagname) {
  index = (arguments.length > 2 ) ? arguments[2] : 0 ;
  tags = xmlDocument.getElementsByTagName(tagname);
  return index < tags.length && tags[index].childNodes.length > 0 ? tags[index].childNodes[0].nodeValue : '';
}

/**
  * Merge custom StyleMap-like hash with default styles
  *
  * Example: to make points in Layer's (default style)
  * red, add following to constructor's options hash:
  * styleMap: mergeCustomStyleWithDefaults({default: {fillColor: "red"}})
  *
  * @param {hash} customStyle
  * @returns OpenLayers.StyleMap
  */
vlUtils.mergeCustomStyleWithDefaults = function(customStyle) {
    styleMap = {};
    for(styleKey in OpenLayers.Feature.Vector.style) {
        styleMap[styleKey] = OpenLayers.Util.applyDefaults(
            styleKey in customStyle ? customStyle[styleKey] : {},
            OpenLayers.Feature.Vector.style[styleKey]
        );
    }
    return new OpenLayers.StyleMap(styleMap);
}

vlUtils.destroyPopup = function(feature) {
  feature.popup.destroy();
  feature.popup = null;
}

vlUtils.xmlDoc2Hash = function(xmlDoc) {
  y = {};
  x = xmlDoc.documentElement.childNodes;
  for (i=0;i<x.length;i++) {
    if(x[i].childNodes.length < 1) { continue; }
    y[x[i].nodeName] = x[i].childNodes[0].nodeValue;
  }
  return y;
}

vlUtils.coordsPrompt = function(map) {
  return OpenLayers.Class(OpenLayers.Control, {                
    defaultHandlerOptions: {
        'single': true,
        'double': false,
        'pixelTolerance': 0,
        'stopSingle': false,
        'stopDouble': false
    },

    initialize: function(options) {
        this.handlerOptions = OpenLayers.Util.extend(
            {}, this.defaultHandlerOptions
        );
        OpenLayers.Control.prototype.initialize.apply(
            this, arguments
        ); 
        this.handler = new OpenLayers.Handler.Click(
            this, {
                'click': this.trigger
            }, this.handlerOptions
        );
    }, 

    trigger: function(e) {
        var lonlat = map.getLonLatFromPixel(e.xy);
        lonlat = lonlat.transform(map.projection, map.displayProjection);
        prompt("EPSG:4326 E, N: \n" + lonlat.lon + " " + lonlat.lat, " -gcp  " + lonlat.lon + " " + lonlat.lat);
    }
  });
}

/**
  * Create HTML link
  *
  * Keys in data:
  *
  * u : URL
  * t : HTML target
  * h : HTML title
  * l : link text (default: u)
  *
  * @param {hash} data
  * @returns string HTML link
  */
vlUtils.link = function(data) {
  return '<a href="' + data.u + '"'
    + ('t' in data ? ' target="' + data.t + '"' : '')
    + ('h' in data ? ' title="' + data.h + '"' : '')
    + '>' + ('l' in data ? data.l : data.u)  + '</a>';
}

/**
  * Create HTML of links
  *
  * Keys in data[x] are the same as in vlUtils.link. Additionally:
  *
  * U : URL template
  * X : x, longitude
  * Y : y, latitude
  * Z : zoom level
  * C : country
  * T : town or city
  * S : street
  *
  * @param {hash[]} data
  * @returns string of HTML links
  */
vlUtils.links = function(data) {
  var y = '';
  var l = data.length;
  for(var i = 0; i < l; i++) {
    data[i].u = data[i].U;
    for(var k in data[i]) {
      if(k.charCodeAt(0) < 67) { continue; } 
      data[i].u = data[i].u.replace('@' + k + '@', data[i][k]); 
    }
    y += ((y == '') ? '' : ' | ') + vlUtils.link(data[i]);
  }
  return y;
}

vlUtils.mergeHashes = function(h0, h1) {
  for(k in h1) { h0[k] = h1[k]; }
  return h0;
}

vlUtils.addSwitcher = function(map) {
  var switcherCtl = new OpenLayers.Control.LayerSwitcher();
  map.addControl(switcherCtl);
  switcherCtl.baseLbl.innerHTML = '';
  switcherCtl.dataLbl.innerHTML = '';
  return switcherCtl;
}

vlUtils.existsInStruct = function(path, struct) {
      var pointer = struct;
      var lastIndex = 3;
      var i;
      for(i=0; i<lastIndex; i++) {
        if(path[i] in pointer) {
          pointer = pointer[path[i]];
        } else {
          return false;
        }
      }

      var lastValue;
      lastValue = isNaN(pointer[0]) ? pointer[0][0] : pointer[0];
      if(path[lastIndex] < lastValue) { return false; }
      lastValue = pointer.length - 1;
      lastValue = isNaN(pointer[lastValue]) ? pointer[lastValue][1] : pointer[lastValue];
      if(path[lastIndex] > lastValue) { return false; }

      for(i=0; i<pointer.length; i++) {
        if(isNaN(pointer[i])) {
          if(path[lastIndex] >= pointer[i][0] && path[lastIndex] <= pointer[i][1]) { return true; }
          lastValue = pointer[i][1];
        } else {
          if(pointer[i] == path[lastIndex]) { return true; }
          lastValue = pointer[i];
        }
      }

      return false;
}

vlUtils.createBaseLayerData = function(layerNode, obj, map) {
  var layerBoundBox = layerNode.getAttribute('bounds').split(',');
  obj.dir = layerNode.getAttribute('year') + '/';
  obj.year = layerNode.getAttribute('year');
  obj.bounds = new OpenLayers.Bounds(layerBoundBox[0], layerBoundBox[1], layerBoundBox[2], layerBoundBox[3]);
  obj.bounds = obj.bounds.transform(map.displayProjection, map.projection);
  return obj;
}

vlUtils.getBasemapTileUrl = function(input) {
    var res = input.layer.map.getResolution();
    var x = Math.round((input.bounds.left - input.layer.maxExtent.left) / (res * input.layer.tileSize.w));
    var y = Math.round((input.bounds.bottom - input.layer.tileOrigin.lat) / (res * input.layer.tileSize.h));
    var z = input.layer.map.getZoom();
    if (input.layer.map.baseLayer.name == 'Virtual Earth Roads'
      || input.layer.map.baseLayer.name == 'Virtual Earth Aerial'
      || input.layer.map.baseLayer.name == 'Virtual Earth Hybrid') {
        z = z + 1;
    }
    if (
      (input.layerdata.bounds.intersectsBounds(input.bounds)
        && z >= input.mapMinZoom && z <= input.mapMaxZoom)
      && !vlUtils.existsInStruct([
        input.layerdata.year,
        ''+z, ''+x, y], input.emptyTiles)
    ) {
    return input.conf.dirraster
      + input.conf.dirplaces
      + input.areaDir 
      + input.layerdata.dir
      + z + "/" + x + "/" + y + "." + input.layer.type;
    } else {
      return vlUtils.getTodaysTileURL(input.layerToday, input.bounds);
    }
}

vlUtils.getTodaysTileURL = function(layer, bounds) {
    var res = layer.map.getResolution();
    var x = Math.round((bounds.left - layer.maxExtent.left) / (res * layer.tileSize.w));
    var y = Math.round((layer.maxExtent.top - bounds.top) / (res * layer.tileSize.h));
    var z = layer.map.getZoom();
    var limit = Math.pow(2, z);
    if (y < 0 || y >= limit) {
        return 'raster/none.png';
    } else {
        x = ((x % limit) + limit) % limit;
        return layer.url + z + "/" + x + "/" + y + "." + layer.type;
    }
}