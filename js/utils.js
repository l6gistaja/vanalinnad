if (!vlUtils) {
    var vlUtils = {};
}

vlUtils.MAIN_SITE = 'http://vanalinnad.mooo.com/';

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

vlUtils.coordsPrompt = function(map, data) {
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
        var i;
        var showCoordsPrompt = true;
        var l = map.popups.length;
        for(i = l - 1; i > -1; i--) {
          if(map.popups[i].id == 'coordsPromptPopup') { map.popups[i].hide(); }
          if(map.popups[i].id == 'poiPopup' || map.popups[i].id == 'roadPopup') { showCoordsPrompt = false; }
        }
        if(!showCoordsPrompt) { return; }

        var lonlat = map.getLonLatFromPixel(e.xy);
        if('displayProjection' in map.options && map.options.projection != map.options.displayProjection) {
          lonlat = lonlat.transform(map.projection, map.displayProjection);
        }

        var coords = {};
        var p4;
        coords[data.jsonConf.urls[data.locData.baseUrlID].srs] = {x:lonlat.lon, y:lonlat.lat};
        if(data.jsonConf.urls[data.locData.baseUrlID].srs != 'EPSG:4326') {
          try {
            p4 = proj4(
              data.jsonConf.proj4[data.jsonConf.urls[data.locData.baseUrlID].srs.replace(':','_')],
              data.jsonConf.proj4['EPSG_4326'],
              [lonlat.lon, lonlat.lat]);
            coords['EPSG:4326'] = {x:p4[0], y:p4[1]};
          } catch(err) { }
        }
        
        var y = '';
	if('debug' in data && data.debug) {
	  var debugContent = {
	    GCP: ' -gcp  ' + coords['EPSG:4326'].x + ' ' + coords['EPSG:4326'].y,
	    GPX: '<wpt lon="' + coords['EPSG:4326'].x + '" lat="' + coords['EPSG:4326'].y + '"><name></name><desc></desc></wpt>',
	    KML: '<Placemark><Point><coordinates>' + coords['EPSG:4326'].x + ',' + coords['EPSG:4326'].y + '</coordinates></Point><name></name><description></description></Placemark>'
	  };
	  y = '<table class="coordsTable">';
	  for(i in debugContent) {
	      y += '<tr><th class="ctC">' + i + '</th><td class="ctC"><input type=\'text\' value=\''
		+ debugContent[i]+ '\'/></td></tr>';
	  }
	  y += '</table><br/>';
	}
        
        y += '<table class="coordsTable"><tr><th class="ctC">'
          + vlUtils.link({u:'http://en.wikipedia.org/wiki/Spatial_reference_system',l:'SRS',t:'_blank',h:'Spatial reference system'}) + '</th><th class="ctC">'
          + vlUtils.link({u:'http://en.wikipedia.org/wiki/Longitude',l:'X',t:'_blank',h:'Longitude'}) + '</th><th class="ctC">'
          + vlUtils.link({u:'http://en.wikipedia.org/wiki/Latitude',l:'Y',t:'_blank',h:'Latitude'}) +  '</th></tr>';
        var srs, decimalPlaces;
        for (srs in coords) {
          decimalPlaces = srs == 'EPSG:4326' ? 6 : 0;
          y += '<tr><th class="ctC">'
            + vlUtils.link({u:'http://spatialreference.org/ref/' + srs.toLowerCase().replace(':','/') + '/',l:srs,t:'_blank'})
            + '</th><td class="ctC">' + vlUtils.decimalRound(coords[srs].x, decimalPlaces)
            + '</td><td class="ctC">' + vlUtils.decimalRound(coords[srs].y, decimalPlaces) +  '</td></tr>';
        }
        y += '</table><br/>';
        
        var locData = vlUtils.mergeHashes({
            X: lonlat.lon,
            Y: lonlat.lat,
            Z: map.getZoom(),
            S: '',
            T: '',
            C: '',
            site: '',
            flags: 'useIcon',
            delimiter: ' '
            }, data.locData);
        y += vlUtils.getURLs(data.links, locData, data.jsonConf);
        
        if('sitesOpener' in data) {
          locData.site = '';
          locData.o = 'map.sitesPopup(); return false;';
          y +=  locData.delimiter + vlUtils.getURLs(['vanalinnad'], locData,  data.jsonConf);
        }

        var popup = new OpenLayers.Popup.FramedCloud (
            'coordsPromptPopup',
            map.getLonLatFromPixel(e.xy),
            null,
            y,
            null,
            true,
            null
        );
        popup.autoSize = true;
        map.addPopup(popup);
    }
  });
}

vlUtils.decimalRound = function(x, decimalPlaces) {
  if(decimalPlaces < 1) { return Math.round(x); }
  var factor = Math.pow(10, decimalPlaces);
  return Math.round(x * factor) / factor;
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
  * o : onclick Javascript
  *
  * @param {hash} data
  * @returns string HTML link
  */
vlUtils.link = function(data) {
  return '<a href="' + data.u + '"'
    + ('t' in data ? ' target="' + data.t + '"' : '')
    + ('h' in data ? ' title="' + data.h + '"' : '')
    + ('o' in data ? ' onclick="' + data.o + '"' : '')
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
  * delimiter : ...between links
  * o : onclick Javascript
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
    y += ((y == '') ? '' : 'delimiter' in data[i] ? data[i].delimiter : ' | ') + vlUtils.link(data[i]);
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

vlUtils.existsInStruct_v2 = function(path, struct) {
	var pointer = struct;
	var i;
	for(i=0; i<2; i++) {
		if(path[i] in pointer) {
			pointer = pointer[path[i]];
		} else {
			return false;
		}
	}
	path[2] = parseInt(path[2]);
	if(path[2] < pointer['R'][0] || path[3] < pointer['R'][2] || path[2] > pointer['R'][0] + pointer['R'][1] || path[3] > pointer['R'][2] + pointer['R'][3]) { return false; }
	var x = path[2] - pointer['R'][0];
	if(!(''+x in pointer)) { return false; }
	var y = path[3] - pointer['R'][2];
	pointer = isNaN(pointer[''+x]) ? pointer[''+x] : pointer[''+pointer[''+x]];
	var lastValue;
	for(i=0; i<pointer.length; i++) {
		if(isNaN(pointer[i])) {
			if(y >= pointer[i][0] && y <= pointer[i][1]) { return true; }
			lastValue = pointer[i][1];
		} else {
			if(pointer[i] == y) { return true; }
			lastValue = pointer[i];
		}
		if(lastValue > y) { return false; }
	}
	return false;
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
  var urlKey, locData, locUrl, p4, zooms;
  var baseUrl = jsonConf.urls[data.baseUrlID];

  for(urlKey in urlKeys) {
    if(!(urlKeys[urlKey]) in jsonConf.urls) { continue; }
    locData = vlUtils.mergeHashes({},data);
    locUrl = vlUtils.mergeHashes({},jsonConf.urls[urlKeys[urlKey]]);
    if('flags' in locData) {
      if(locData.flags.indexOf('useIcon') > -1 && 'icon' in locUrl) {
        locUrl.l = '<img src="' + locUrl.icon + '" class="popupicon"/>';
      }
    }
    
    // handle coordinate conversions
    if('srs' in baseUrl && 'srs' in locUrl && 'X'  in locData && 'Y'  in locData && baseUrl.srs != locUrl.srs) {
      try {
        p4 = proj4(jsonConf.proj4[baseUrl.srs.replace(':','_')],jsonConf.proj4[locUrl.srs.replace(':','_')],[locData.X, locData.Y]);
        locData.X = p4[0];
        locData.Y = p4[1];
      } catch(err) {
         if('coords' in locUrl && locUrl.coords == 'yes') {
           continue;
         } else { // if conversion failed and target site doesnt care about them, just ignore coordinates
           locData.X = locData.Y = '';
         }
      }
    }
    
    // handle zoom levels
    locData.Z = parseInt(locData.Z) + ('zoomdiff' in locUrl ? locUrl.zoomdiff : 0) - ('zoomdiff' in baseUrl ? baseUrl.zoomdiff : 0);
    if('maxzoom' in locUrl && locData.Z > locUrl.maxzoom) { locData.Z = locUrl.maxzoom; }
    if('minzoom' in locUrl && locData.Z < locUrl.minzoom) { locData.Z = locUrl.minzoom; }

    urlData[urlData.length] = vlUtils.mergeHashes(locUrl, locData);
  }
  return vlUtils.links(urlData);
}

vlUtils.mapDispatcher = function(initConf) {
  var reqParams = OpenLayers.Util.getParameters();
  if('wms' in reqParams && reqParams.wms.match(/^[a-z_]+$/)) {
    return new vlWms(initConf);
  } else {
    return new vlMap(initConf);
  }
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
          if(evt.keyCode == 46 || evt.keyCode == 190) { dir = -1; }
          if(evt.keyCode == 44 || evt.keyCode == 188) { dir = 1; }
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

vlUtils.mapAddCoordPopups = function(map, clickData, reqParams, jsonConf, projection) {

    if(!('draw' in reqParams)) {
	OpenLayers.Control.Click = vlUtils.coordsPrompt(map, clickData);
	var click = new OpenLayers.Control.Click();
	map.addControl(click);
	click.activate();
    } else {
      
	var lineLayer = new OpenLayers.Layer.Vector("DRAW",
	    {styleMap: vlUtils.mergeCustomStyleWithDefaults(jsonConf.olLayerStyles['roads'])});
	map.addLayer(lineLayer);
	var drawCtl = new OpenLayers.Control.DrawFeature(lineLayer, OpenLayers.Handler.Path);
	map.addControl(drawCtl);
	drawCtl.activate();

	function showPath() { 
	    var path = '';
	    var coords;
	    var pathPoint;
	    for(var i = 0; i < lineLayer.features.length; i++) {
		path += reqParams.draw == 'KML' 
		  ? '<LineString><coordinates>'
		  : '<trkseg>';
		for(var j = 0; j < lineLayer.features[i].geometry.components.length; j++) {
		    coords = [lineLayer.features[i].geometry.components[j].x,
			lineLayer.features[i].geometry.components[j].y];
		    if(projection) {
			try {
			    coords = proj4(
				jsonConf.proj4[projection.replace(':','_')],
				jsonConf.proj4['EPSG_4326'],
				coords);
			} catch(err) {
			    alert('PROJ4 failure.');
			    return;
			}
		    } else {
			pathPoint = new OpenLayers.LonLat(coords[0], coords[1]);
			pathPoint.transform(map.options.projection, map.options.displayProjection);
			coords = [pathPoint.lon, pathPoint.lat];
		    }
		    path += reqParams.draw == 'KML'
		      ? coords[0] + "," + coords[1] + " "
		      : '<trkpt lat="' + coords[1] + '" lon="' + coords[0] + '"/>';
		}
		path = path.trim() + (reqParams.draw == 'KML' 
		  ? '</coordinates></LineString>'
		  : '</trkseg>');
	    }

	    var cornerXYg = map.getLonLatFromPixel({x:55, y:20});
	    var cornerXY = new OpenLayers.LonLat(cornerXYg.lon, cornerXYg.lat);
	    cornerXYg.transform(map.options.projection, map.options.displayProjection);
	    sitesPopup = new OpenLayers.Popup.Anchored(
		"sitesPopup",
		new OpenLayers.LonLat(cornerXY.lon, cornerXY.lat),
		null,
		'Lines as ' + reqParams.draw + '.<br/><form><textarea>' + path
		  + '</textarea><br/><input type="button" value="Delete all drawed lines" onclick="return map.emptyDrawLayer();"/></form>',
		null,
		true,
		null
	    );
	    sitesPopup.setBorder('solid 2px black');
	    sitesPopup.autoSize = true;
	    map.addPopup(sitesPopup);
	}
	var drawBtn = new OpenLayers.Control.Button({
	    displayClass: 'drawBtn',
	    title: "Draw line",
	    trigger: showPath
	});
	var drawPanel = new OpenLayers.Control.Panel({defaultControl: drawBtn});
	drawPanel.addControls([drawBtn]);
	map.addControl(drawPanel);
    }
}

vlUtils.emptyDrawLayer = function(map) {
    map.getLayersByName('DRAW')[0].removeAllFeatures();
    return true;
}

vlUtils.fullOLPermalinkCoords = function(urlParamArray) {
    if(!('zoom' in urlParamArray) || isNaN(parseInt(urlParamArray['zoom']))) { return false; }
    var ll = ['lat','lon'];
    for(req in ll) { if(
	!(ll[req] in urlParamArray)
	|| isNaN(parseFloat(urlParamArray[ll[req]]))
    ) { return false; } }
    return true;
}

vlUtils.redirect2vanalinnad = function() {
    if(window.location.host == 'juks.alkohol.ee') {
        OpenLayers.Request.GET({url: vlUtils.MAIN_SITE + '1.php', callback: vlUtils.redirect2vanalinnadWork});
    }
}

vlUtils.redirect2vanalinnadWork = function(request) {
    if(request.status == 200) {
        var urlPieces = window.location.href.split('?');
        urlPieces[0] =  urlPieces[0].split('/');
        window.location.host(vlUtils.MAIN_SITE + urlPieces[0][urlPieces[0].length - 1] + (urlPieces.length > 1 ? '?' + urlPieces[1] : ''));
    }
}
