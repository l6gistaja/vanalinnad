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
  var y = {};
  var k;
  for(k in h0) { y[k] = h0[k]; }
  for(k in h1) { y[k] = h1[k]; }
  return y;
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
  obj.dir = layerNode.getAttribute('year') + '/';
  obj.year = layerNode.getAttribute('year');
  if(layerNode.getAttribute('bounds') != null) {
    var layerBoundBox = layerNode.getAttribute('bounds').split(',');
    obj.bounds = new OpenLayers.Bounds(layerBoundBox[0], layerBoundBox[1], layerBoundBox[2], layerBoundBox[3]);
    obj.bounds = obj.bounds.transform(map.displayProjection, map.projection);
  }
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

vlUtils.getURLs = function(urlKeys, data, jsonConf) {
  var urlData = [];
  var urlKey, locData, locUrl, p4;
  for(urlKey in urlKeys) {
    locData = vlUtils.mergeHashes({},data);
    locUrl = vlUtils.mergeHashes({},jsonConf.urls[urlKeys[urlKey]]);
    if('flags' in locData) {
      if(locData.flags.indexOf('useIcon') > -1 && 'icon' in locUrl) {
        locUrl.l = '<img src="' + locUrl.icon + '" border="0"/>';
      }
    }
    if('srs0' in locData && 'srs' in locUrl && 'X'  in locData && 'Y'  in locData && locData.srs0 != locUrl.srs) {
      try {
        p4 = proj4(jsonConf.proj4[locData.srs0.replace(':','_')],jsonConf.proj4[locUrl.srs.replace(':','_')],[locData.X, locData.Y]);
        locData.X = p4[0];
        locData.Y = p4[1];
      } catch(err) {
         continue;
      }
    }
    switch (urlKeys[urlKey]) {
      case 'ajapaik':
        if('site' in locData && 'ajapaik' in jsonConf.urls && locData['site'] in jsonConf.ajapaikIDs) {
          locData['ajapaikID'] = jsonConf.ajapaikIDs[locData['site']];
          urlData[urlData.length] = vlUtils.mergeHashes(jsonConf.urls.ajapaik, locData);
        }
        break;
      default:
        if(urlKeys[urlKey] in jsonConf.urls) {
          urlData[urlData.length] = vlUtils.mergeHashes(locUrl, locData);
        }
        break;
    }
  }
  return vlUtils.links(urlData);
}

vlUtils.mapDispatcher = function(initConf) {
  var reqParams = OpenLayers.Util.getParameters();
  if('wms' in reqParams && reqParams.wms.match(/^[a-z]+$/)) {
    new vlWms(initConf);
  } else {
    new vlMap(initConf);
  }
  return true;
}

vlUtils.mapMapUI = function(x) {
  var y = {};
  var i, j, param, ns, nsLen, clazz;
  for(i in x.add) {
    param = null;
    if(x.add[i] == 'OpenLayers.Control.ScaleLine' && x.map.options.projection == 'EPSG:900913') {
      param = {geodesic: true};
    }
    ns = x.add[i].split(".");
    nsLen = ns.length;
    clazz = window;
    for (j = 0; j < nsLen; j++) {
        clazz = clazz[ns[j]];
    }
    y[x.add[i]] = new clazz(param);
    x.map.addControl(y[x.add[i]]);
    if(x.add[i] == 'OpenLayers.Control.LayerSwitcher') {
        y[x.add[i]].baseLbl.innerHTML = '';
        y[x.add[i]].dataLbl.innerHTML = '';
    }
  }

  y['OpenLayers.Control_baseLayerScroller'] = new OpenLayers.Control();                
  var handler = new OpenLayers.Handler.Keyboard(
    y['OpenLayers.Control_baseLayerScroller'],
    { keydown: function(evt) {
          var dir = 0;
          if(evt.keyCode > 47 && evt.keyCode < 58) { dir = -1; }
          if(evt.keyCode == 32) { dir = 1; }
          if(dir != 0) {
            var i;
            var bl = [];
            var currentBl = -1;
            for(i=0; i < x.map.layers.length; i++) {
              if(x.map.layers[i].isBaseLayer) { bl[bl.length] = i };
              if(x.map.layers[i].id == x.map.baseLayer.id) { currentBl = i };
            }
            currentBl += dir;
            if(currentBl + 1 > bl.length) { currentBl = 0; }
            if(currentBl < 0) { currentBl = bl.length - 1; }
            x.map.setBaseLayer(x.map.layers[bl[currentBl]]);
          }
      }
    }, {}
  );
  handler.activate();
  x.map.addControl(y['OpenLayers.Control_baseLayerScroller']);

  if('remove' in x) { vlUtils.mapRemoveCtl(x.map, x.remove); }
  return y;
}

vlUtils.mapRemoveCtl = function(map, ctl) {
  for(i in map.controls) { 
    if(map.controls[i].CLASS_NAME == ctl) {
        map.controls[i].destroy();
        map.controls[i] = null;
    }
  }
}
