function vlMap(inputParams){

  // avoid pink tiles
  OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;
  OpenLayers.Util.onImageLoadErrorColor = "transparent";

  var areaDir;
  var baseLayersData = {};
  var map;
  var mapBounds;
  var mapMinZoom;
  var mapMaxZoom;
  var conf;
  var confXml;
  var layersXml;
  var reqParams;
  var emptyTiles;
  var isAtSite;
  var baseLayersCount = 0;
  var jsonConf = {};
  var selectorLayer;
  var baseURLprefix;
  
  var xmlHandlerConf = function(request) {
    if(request.status == 200) {
      document.getElementById(inputParams.divMap).innerHTML = '';
      confXml = request.responseXML;
      conf = vlUtils.xmlDoc2Hash(confXml);
      jsonConf = JSON.parse(conf.json);
      isAtSite = 'site' in reqParams && reqParams['site'].match(/^[sA-Z][A-Za-z-]*$/);
      if(isAtSite) {
        areaDir = reqParams['site'] + '/';
        OpenLayers.Request.GET({ 
            url: conf.dirvector
              + conf.dirplaces
              + areaDir
              + conf.filelayers,
            callback: xmlHandlerLayers
        });
      } else {
        vlInitMapAfterConf();
      }
    }
  }

  var xmlHandlerLayers = function(request) {
    if(request.status == 200) {
      layersXml = request.responseXML;
      mapMinZoom = parseInt(vlUtils.getXmlValue(layersXml, 'minzoom'));
      mapMaxZoom = parseInt(vlUtils.getXmlValue(layersXml, 'maxzoom'));
      boundBox = vlUtils.getXmlValue(layersXml, 'bounds').split(',');
      mapBounds = new OpenLayers.Bounds(
        boundBox[0],
        boundBox[1],
        boundBox[2],
        boundBox[3]
      );
      OpenLayers.Request.GET({ 
          url: conf.dirvector
            + conf.dirplaces
            + areaDir
            + conf.fileemptytiles,
          callback: loadEmptyTilesData
      });
    } else {
      isAtSite = false;
      vlInitMapAfterConf();
    }
  }

  var loadEmptyTilesData = function(request) {
      emptyTiles = (request.status == 200) ? JSON.parse(request.responseText) : {};
      vlInitMapAfterConf();
  }
  
  var vlInitMapAfterConf = function(){

    yearMatcher = new RegExp(conf.regexyearmatcher);

    map = new OpenLayers.Map(inputParams.divMap, jsonConf.mapoptions);

    function osm_getTileURL(bounds) {
        return vlUtils.getTodaysTileURL(osm, bounds);
    }

    function overlay_getTileURL(bounds) {
        return vlUtils.getBasemapTileUrl({
            layer: this,   
            layerToday: osm,                       
            bounds: bounds,
            layerdata: baseLayersData[map.baseLayer.layername],
            mapMinZoom: mapMinZoom,
            mapMaxZoom: mapMaxZoom,
            emptyTiles: emptyTiles,
            areaDir: areaDir,
            conf: conf
        });
    }

    // create OSM/OAM layer
    currentTime = new Date();
    var osm = new OpenLayers.Layer.TMS( currentTime.getFullYear(),
        "http://tile.openstreetmap.org/",
        {
          layername: conf.tmslayerprefix + 'now',
          type: 'png',
          getURL: osm_getTileURL,
          displayOutsideMaxExtent: true,
          attribution: '',
          isBaseLayer: true
        } );
    map.addLayer(osm);

    selectorLayer = new OpenLayers.Layer.Vector('&#8984; POI', {
      layername: 'POIs',
      projection: map.options.displayProjection,
      minResolution: map.getResolutionForZoom(mapMinZoom - 1),
      strategies: [new OpenLayers.Strategy.Fixed()],
      protocol: new OpenLayers.Protocol.HTTP({
          url: conf.dirvector
               + conf.fileareaselector,
          format: new OpenLayers.Format.KML({
              extractAttributes: true,
              maxDepth: 0
          })
      }),
      styleMap: vlUtils.mergeCustomStyleWithDefaults(jsonConf.olLayerStyles['POIs'])
    });

    var tmsoverlays = [];
    var roadLayers = [];
    var layerUrlSelect = -1;

    visibleBaseLayers = ('years' in reqParams) ? reqParams['years'].split('.') : [];
    for(i = visibleBaseLayers.length - 1; i > -1; i--) {
      if(!visibleBaseLayers[i].match(yearMatcher)) {
        visibleBaseLayers.splice(i, 1);
      };
    }
    if('year' in reqParams) {
      layerYear = reqParams['year'];
      if(visibleBaseLayers.length > 0) {
        visibleBaseLayers[visibleBaseLayers.length] = layerYear;
      }
    } else {
      layerYear = '';
    }
    
    if(!isAtSite) {
        var bingApiKey = 'AnEDGmFjuL_87kKc8HrMK1U6Bt7Tsj2S7vF5veYm7b3MjB2hR_tjxyYfMcuupvVV';
        tmsoverlays = [
            new OpenLayers.Layer.Bing({key: bingApiKey, type: "Aerial", name: "B Sat"}),
            new OpenLayers.Layer.Bing({key: bingApiKey, type: "AerialWithLabels", name: "B Hyb"}),
            new OpenLayers.Layer.Bing({key: bingApiKey, type: "Road", name: "B Str"})/*,
            new OpenLayers.Layer.Google("G Sat",{type: G_SATELLITE_MAP, sphericalMercator: true, numZoomLevels: jsonConf.mapoptions.numZoomLevels}),
            new OpenLayers.Layer.Google("G Hyb",{type: G_HYBRID_MAP, sphericalMercator: true, numZoomLevels: jsonConf.mapoptions.numZoomLevels}),
            new OpenLayers.Layer.Google("G Str",{sphericalMercator: true, numZoomLevels: jsonConf.mapoptions.numZoomLevels}),
            new OpenLayers.Layer.Google("G Ter",{type: G_PHYSICAL_MAP, sphericalMercator: true, numZoomLevels: jsonConf.mapoptions.numZoomLevels})*/
        ];
    }
    
    var layersTags = isAtSite 
    ? layersXml.getElementsByTagName('layer')
    : confXml.getElementsByTagName('layer');
    var roadlayersBBoxes = {};
    for(i = 0; i < layersTags.length; i++) {
    if(layersTags[i].getAttribute('disabled')) { continue; }
    if(layersTags[i].getAttribute('type') == 'tms') {
        if(
        visibleBaseLayers.length > 0
        && OpenLayers.Util.indexOf(visibleBaseLayers, layersTags[i].getAttribute('year')) < 0
        ) { continue; }
        layername = conf.tmslayerprefix + layersTags[i].getAttribute('year');
        baseLayersData[layername] = vlUtils.createBaseLayerData(layersTags[i], {no: baseLayersCount}, map);
        baseLayersCount++;
        tmsoverlays[tmsoverlays.length] = new OpenLayers.Layer.TMS(
        layersTags[i].getAttribute('year'),
        "",
        {
            layername: layername,
            type: 'jpg',
            getURL: overlay_getTileURL,
            alpha: false,
            isBaseLayer: true
        }
        );
        if(layersTags[i].getAttribute('year') == layerYear) { layerUrlSelect = tmsoverlays.length - 1; }
        
    } else {
        
        layername = layersTags[i].getAttribute('type') + '_' + roadLayers.length;
        roadLayers[roadLayers.length] = new OpenLayers.Layer.Vector(layersTags[i].getAttribute('name'), {
            layername: layername,
            projection: map.options.displayProjection,
            maxResolution: map.getResolutionForZoom(parseInt(layersTags[i].getAttribute('maxres'))),
            strategies: [new OpenLayers.Strategy.Fixed()],
            protocol: new OpenLayers.Protocol.HTTP({
                url: conf.dirvector
                        + (isAtSite ? conf.dirplaces + areaDir : 'common/')
                        + layersTags[i].getAttribute('file'),
                format: (layersTags[i].getAttribute('format') === 'VLGJ') 
                    ? new vlUtils.VLGJSON()
                    : new OpenLayers.Format.KML({
                        extractAttributes: true,
                        maxDepth: 0
                    })
            }),
            styleMap: vlUtils.mergeCustomStyleWithDefaults(jsonConf.olLayerStyles[
            layersTags[i].getAttribute('style') !=null ? layersTags[i].getAttribute('style') : 'roads'
            ])
        });
        
        if(
            layersTags[i].getAttribute('hide') !=null
            && !(layersTags[i].getAttribute('year') !=null && layersTags[i].getAttribute('year') == layerYear)
        ) { roadLayers[roadLayers.length-1].setVisibility(false); }
        
        if('debug' in reqParams && layersTags[i].getAttribute('type') == 'roads') {
            roadlayersBBoxes[roadLayers[roadLayers.length-1].id] = {i: roadLayers.length-1};
            roadLayers[roadLayers.length-1].events.register('loadend', roadLayers[roadLayers.length-1], function(){
                roadlayersBBoxes[this.id].extent = this.getDataExtent();
                var rlID;
                for(rlID in roadlayersBBoxes) { if(!('extent' in roadlayersBBoxes[rlID])) { return; } }
                var bounds = {};
                var road1 = -1;
                for(rlID in roadlayersBBoxes) {
                    if(road1 < 0) { road1 = roadlayersBBoxes[rlID].i; }
                    if(!('w' in bounds) || roadlayersBBoxes[rlID].extent.left < bounds.w) { bounds.w = roadlayersBBoxes[rlID].extent.left; }
                    if(!('e' in bounds) || roadlayersBBoxes[rlID].extent.right > bounds.e) { bounds.e = roadlayersBBoxes[rlID].extent.right; }
                    if(!('s' in bounds) || roadlayersBBoxes[rlID].extent.bottom < bounds.s) { bounds.s = roadlayersBBoxes[rlID].extent.bottom; }
                    if(!('n' in bounds) || roadlayersBBoxes[rlID].extent.top > bounds.n) { bounds.n = roadlayersBBoxes[rlID].extent.top; }
                }
                roadLayers[road1].addFeatures([new OpenLayers.Feature.Vector(new OpenLayers.Geometry.LineString([
                    new OpenLayers.Geometry.Point(bounds.w,bounds.s),
                    new OpenLayers.Geometry.Point(bounds.w,bounds.n),
                    new OpenLayers.Geometry.Point(bounds.e,bounds.n),
                    new OpenLayers.Geometry.Point(bounds.e,bounds.s),
                    new OpenLayers.Geometry.Point(bounds.w,bounds.s)
                ]), {'name':'BoundingBox'}, {strokeColor:"#ff00ff", strokeWidth:2})]);
            });
        }
        
    }

      // when someone accesses page with outdated layers parameter, redirect
      var layerUrlParts;
      if(
        (layerUrlParts = window.location.href.match(/([?&]layers=)([B0]*)([TF]+)/)) != null
        && layerUrlParts.length > 2
        && layerUrlParts[2].length < baseLayersCount + 1
      ) {
        while(layerUrlParts[2].length < baseLayersCount + 1) { layerUrlParts[2] += '0'; }
        window.location.replace(window.location.href.replace(layerUrlParts[0],layerUrlParts[1]+layerUrlParts[2]+layerUrlParts[3]));
      }
    }
    roadLayers[roadLayers.length] = selectorLayer;
    map.addLayers(tmsoverlays);
    map.addLayers(roadLayers);

    function yearURL() {
      var year = map.baseLayer.layername.substr(conf.tmslayerprefix.length);
      return year.match(yearMatcher) ? '&year=' + year : ''; 
    }

    function createVectorLayersPopup(feature) {
      if(feature.layer.getOptions().layername == 'POIs') {
        feature.popup = new OpenLayers.Popup.FramedCloud(
            "poiPopup",
            feature.geometry.getBounds().getCenterLonLat(),
            null,
            htmlSites([feature]),
            null,
            true,
            function() { vectorLayersCtl.unselectAll(); }
        );
      } else {

        var clickXYg = map.getLonLatFromPixel(vectorLayersCtl.handlers.feature.evt.xy);
        var clickXY = new OpenLayers.LonLat(clickXYg.lon, clickXYg.lat);
        clickXYg.transform(map.options.projection, map.options.displayProjection);
        
        var popupContent = feature.attributes.name;
        if('description' in feature.attributes) {
            popupContent += '<br/>' + feature.attributes.description;
        }
        if(feature.layer.getOptions().layername.substr(0,6) == 'roads_') {
          var locData = {
            X: clickXYg.lon,
            Y: clickXYg.lat,
            Z: map.getZoom(),
            S: feature.attributes.name,
            T: vlUtils.getXmlValue(layersXml, 'city'),
            C: vlUtils.getXmlValue(layersXml, 'country'),
            site: reqParams['site'],
            baseUrlID: 'vanalinnad',
            flags: 'useIcon' + ('debug' in reqParams ? ',debug' : ''),
            delimiter: ' '
          };
          var urlKeys = ['googlestreetview','ajapaik','geohack','maaametaero'];
          for(w in jsonConf.urls) {
            if('type' in jsonConf.urls[w] && jsonConf.urls[w].type == 'WMS') { urlKeys[urlKeys.length] = w; }
          }
          popupContent = '<strong>' + feature.attributes.name +'</strong><br />' 
                + vlUtils.getURLs(urlKeys, locData, jsonConf);
          locData.site = '';
          locData.o = 'map.sitesPopup(); return false;';
          popupContent +=  locData.delimiter + vlUtils.getURLs(['vanalinnad'], locData, jsonConf);
        }
        
        feature.popup = new OpenLayers.Popup.FramedCloud (
            "roadPopup",
            new OpenLayers.LonLat(clickXY.lon, clickXY.lat),
            null,
            popupContent,
            null,
            true,
            function() { vectorLayersCtl.unselectAll(); }
        );
        feature.popup.setBorder('solid 2px black');
      }
      feature.popup.autoSize = true;
      map.addPopup(feature.popup);
    }

    //Add a selector control to the kmllayer with popup functions
    var vectorLayersCtl = new OpenLayers.Control.SelectFeature(roadLayers, { 
        onSelect: createVectorLayersPopup, 
        onUnselect: vlUtils.destroyPopup
    });
    map.addControl(vectorLayersCtl);
    vectorLayersCtl.activate();

    var permalinkReqKeys = ['zoom','lat','lon','layers'];
    var centerLonlat;
    var hasCoords = vlUtils.fullOLPermalinkCoords(reqParams);
    
    if(isAtSite) {
      if(hasCoords) {
          centerLonlat = new OpenLayers.LonLat(reqParams['lon'],reqParams['lat']);
          map.setCenter(centerLonlat.transform(map.displayProjection, map.projection),reqParams['zoom']);
      } else {
        if(layerUrlSelect > -1) { // if layer is selected from URL
          map.zoomToExtent(baseLayersData[conf.tmslayerprefix + map.layers[layerUrlSelect+1].name].bounds);
        } else {
          map.zoomToExtent(mapBounds.transform(map.displayProjection, map.projection));
        }
      }
    } else {

      selectorLayer.events.register('loadend', selectorLayer, function(){

        if(hasCoords) {
            centerLonlat = new OpenLayers.LonLat(reqParams['lon'],reqParams['lat']);
            map.setCenter(centerLonlat.transform(map.displayProjection, map.projection),reqParams['zoom']);
        } else {
          map.zoomToExtent(selectorLayer.getDataExtent());
        }
        _sitesPopup();
      });
    }

    baseURLprefix = '';
    for(reqKey in reqParams) {
      if(reqKey == 'year') { continue; }
      if(!(reqKey in permalinkReqKeys)) {
        baseURLprefix += (baseURLprefix == '' ? '?' : '&') + reqKey + '=' + reqParams[reqKey];
      }
    }
    map.addControl(new OpenLayers.Control.Permalink({base: baseURLprefix}));
    
    function openInfoPage() {
      var win=window.open(
        conf.infourlprefix
        + (isAtSite ? 'site=' + reqParams['site'] : '')
        + yearURL()
        + ('debug' in reqParams ? '&debug=' + reqParams['debug'] : '')
      ,'_blank'); 
      win.focus();
    }
    var infoBtn = new OpenLayers.Control.Button({
      displayClass: 'infoBtn',
      title: "Info",
      trigger: openInfoPage
    });
    var infoPanel = new OpenLayers.Control.Panel({defaultControl: infoBtn});
    infoPanel.addControls([infoBtn]);
    map.addControl(infoPanel);
    
    function toggleSearch() { vlSearch.toggleSearch(); }
    var searchBtn = new OpenLayers.Control.Button({
      displayClass: 'searchBtn',
      title: "Search",
      trigger: toggleSearch
    });
    var searchPanel = new OpenLayers.Control.Panel({defaultControl: searchBtn});
    searchPanel.addControls([searchBtn]);
    map.addControl(searchPanel);

    var automaticCtls = vlUtils.mapMapUI({map: map, add: [
      'OpenLayers.Control.PanZoomBar',
      'OpenLayers.Control.KeyboardDefaults',
      'OpenLayers.Control.ScaleLine',
      'OpenLayers.Control.LayerSwitcher'
    ], remove: 'OpenLayers.Control.Zoom'});
    if(isAtSite) { automaticCtls['OpenLayers.Control.LayerSwitcher'].maximizeControl(); }
    
    if(layerUrlSelect > -1) { map.setBaseLayer(tmsoverlays[layerUrlSelect]); }

    // coordinates popup
    var clickData = {
        jsonConf: jsonConf,
        locData: {
            site: isAtSite ? reqParams['site'] : '',
            baseUrlID: 'vanalinnad'
        },
        links: ['googlestreetview','ajapaik','geohack','maaametaero'],
        debug: 'debug' in reqParams,
        sitesOpener: true
    };
    for(w in jsonConf.urls) {
        if(!('type' in jsonConf.urls[w] && jsonConf.urls[w].type == 'WMS')) { continue; }
        clickData.links[clickData.links.length] = w;
    }
    
    vlUtils.mapAddCoordPopups(map, clickData, reqParams, jsonConf, false);

    if(isAtSite) { window.document.title += ': ' + vlUtils.getXmlValue(layersXml, 'city'); }
  }

  var htmlSites = function(s) {
    y = s.length > 1 ? vlUtils.link({'u':'?','h':'Main page','l':'Vanalinnad'})+'<br/>' : '';
    var siteParam, siteName, sitePoint;
    var wmsLinks = [];
    for(f in s) {
      siteName = 'description' in s[f].attributes ? s[f].attributes.description : s[f].attributes.name;
      siteParam = 'site=' + siteName + ('debug' in reqParams ? '&debug=' + reqParams['debug'] : '');
      y += '&nbsp;&nbsp;'
        + vlUtils.link({
            u: conf.infourlprefix + siteParam,
            h: 'Info',
            l:  '<img src="raster/icons/information.png" class="popupicon"/>'
          });
      for(w in jsonConf.urls) {
        if(!('type' in jsonConf.urls[w] && jsonConf.urls[w].type == 'WMS')) { continue; }
        sitePoint = new OpenLayers.LonLat(s[f].geometry.x, s[f].geometry.y);
        sitePoint.transform(map.options.projection, map.options.displayProjection);
        y += '&nbsp;'
          + vlUtils.getURLs([w], {
            site: siteName,
            flags: 'useIcon' + ('debug' in reqParams ? ',debug' : ''),
            X: sitePoint.lon,
            Y: sitePoint.lat,
            Z: map.getZoom(),
            baseUrlID: 'vanalinnad'
          }, jsonConf);
      }
      y += '&nbsp;&nbsp;'
        + vlUtils.link({
            u: '?' + siteParam,
            l:  s[f].attributes.name
          }) + ' <br/>';
    
    }
    return y;
  }
  
  var _sitesPopup = function() {
    for(var i = map.popups.length - 1; i > -1; i--) {
        if(map.popups[i].id == 'sitesPopup') {
            map.popups[i].hide();
        } 
    }
    var cornerXYg = map.getLonLatFromPixel({x:55, y:20});
    var cornerXY = new OpenLayers.LonLat(cornerXYg.lon, cornerXYg.lat);
    cornerXYg.transform(map.options.projection, map.options.displayProjection);
    sitesPopup = new OpenLayers.Popup.Anchored(
        "sitesPopup",
        new OpenLayers.LonLat(cornerXY.lon, cornerXY.lat),
        null,
        htmlSites(selectorLayer.features),
        null,
        true,
        function() { for(var i = map.popups.length - 1; i > -1; i--) {
          if(map.popups[i].id == 'sitesPopup') { map.removePopup(map.popups[i]); }
        } }
    );
    sitesPopup.setBorder('solid 2px black');
    sitesPopup.autoSize = true;
    map.addPopup(sitesPopup);
  }
  
  var _getLayersXml = function() { return layersXml; }
  
  var _init = function() {
    reqParams = OpenLayers.Util.getParameters();
    OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
  }

  this.sitesPopup = function() { _sitesPopup(); }
  
  this.zoomToBBox = function(x) {
      var bounds = new OpenLayers.Bounds(x);
      map.zoomToExtent(bounds.transform(map.displayProjection, map.projection));
      return false;
  }
  
  this.emptyDrawLayer = function() {
      vlUtils.emptyDrawLayer(map);
      return true;
  }
  
  this.getCityName = function() {
      lx = _getLayersXml();
      if (typeof lx == 'undefined') return "";
      return vlUtils.getXmlValue(lx, 'city');
  }
  
  _init();

}
