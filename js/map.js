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
  var layersXml;
  var reqParams;
  var emptyTiles;
  var isAtSite;
  var baseLayersCount = 0;
  var jsonConf = {};

  var xmlHandlerConf = function(request) {
    if(request.status == 200) {
      document.getElementById(inputParams.divMap).innerHTML = '';
      conf = vlUtils.xmlDoc2Hash(request.responseXML);
      jsonConf = JSON.parse(conf.json);
      isAtSite = 'site' in reqParams && reqParams['site'].match(/^[A-Z][A-Za-z-]*$/);
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

    var selectorLayer = new OpenLayers.Layer.Vector('&#8984; POI', {
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
      styleMap: vlUtils.mergeCustomStyleWithDefaults(vlLayerStyles['POIs'])
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
    
    if(isAtSite) {
      var layersTags = layersXml.getElementsByTagName('layer');
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
                          + conf.dirplaces
                          + areaDir 
                          + layersTags[i].getAttribute('file'),
                    format: new OpenLayers.Format.KML({
                        extractAttributes: true,
                        maxDepth: 0
                    })
                }),
              styleMap: vlUtils.mergeCustomStyleWithDefaults(vlLayerStyles[
                layersTags[i].getAttribute('style') !=null ? layersTags[i].getAttribute('style') : 'roads'
              ])
          });
          if(
            layersTags[i].getAttribute('hide') !=null
            && !(layersTags[i].getAttribute('year') !=null && layersTags[i].getAttribute('year') == layerYear)
          ) {
            roadLayers[roadLayers.length-1].setVisibility(false);
          }
        }
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
        var locData = {
          X: clickXYg.lon,
          Y: clickXYg.lat,
          Z: map.getZoom(),
          S: feature.attributes.name,
          T: vlUtils.getXmlValue(layersXml, 'city'),
          C: vlUtils.getXmlValue(layersXml, 'country')
        };
        if(isAtSite) { locData.site = reqParams['site']; }

        feature.popup = new OpenLayers.Popup.FramedCloud (
            "roadPopup",
            new OpenLayers.LonLat(clickXY.lon, clickXY.lat),
            null,
            feature.layer.getOptions().layername.substr(0,6) == 'roads_'
              ? '<strong>' + feature.attributes.name +'</strong><br />' 
                + vlUtils.getURLs(['googlestreetview','ajapaik'], locData, jsonConf)
              : feature.attributes.name,
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
    if(isAtSite) {
      for(reqKey in permalinkReqKeys) { 
        if(
          !(permalinkReqKeys[reqKey] in reqParams) 
          || (reqKey < 3 && isNaN(parseFloat(reqParams[permalinkReqKeys[reqKey]])))
        ) { 
          if(layerUrlSelect > -1) {
            if(reqKey == 3) {
              lonlat = new OpenLayers.LonLat(reqParams['lon'],reqParams['lat']);
              map.setCenter(lonlat.transform(map.displayProjection, map.projection),reqParams['zoom']);
            } else {
              map.zoomToExtent(baseLayersData[conf.tmslayerprefix + reqParams['year']].bounds);
            }
          } else {
            map.zoomToExtent(mapBounds.transform(map.displayProjection, map.projection));
          }
          break;
        }
      }
    } else {
      selectorLayer.events.register('loadend', selectorLayer, function(){
        map.zoomToExtent(selectorLayer.getDataExtent());
        
        var cornerXYg = map.getLonLatFromPixel({x:55, y:20});
        var cornerXY = new OpenLayers.LonLat(cornerXYg.lon, cornerXYg.lat);
        cornerXYg.transform(map.options.projection, map.options.displayProjection);
        sitesPopup = new OpenLayers.Popup.Anchored(
            "sitesPopup",
            new OpenLayers.LonLat(cornerXY.lon, cornerXY.lat), //map.getCenter(),
            null,
            htmlSites(selectorLayer.features),
            null,
            true,
            null
        );
        sitesPopup.setBorder('solid 2px black');
        sitesPopup.autoSize = true;
        map.addPopup(sitesPopup);
      });
    }

    var keyboardControl = new OpenLayers.Control();                
    var handler = new OpenLayers.Handler.Keyboard(
      new OpenLayers.Control(),
      { keydown: function(evt) {
            if(baseLayersCount < 1) { return; }
            var dir = 0;
            if(evt.keyCode > 47 && evt.keyCode < 58) { dir = -1; }
            if(evt.keyCode == 32) { dir = 1; }
            if(dir != 0) {
              var mapIndex = -1;
              if(map.baseLayer.layername in baseLayersData) {
                mapIndex = baseLayersData[map.baseLayer.layername].no + dir;
              } else {
                mapIndex = dir > 0 ? dir - 1 : baseLayersCount + dir;
              }
              if(mapIndex >= baseLayersCount) { mapIndex = -1; }
              map.setBaseLayer(mapIndex < 0 ? osm : tmsoverlays[mapIndex]);
            }
        }
      }, {}
    );
    handler.activate();
    map.addControl(keyboardControl);

    baseurl = '';
    for(reqKey in reqParams) {
      if(reqKey == 'year') { continue; }
      if(!(reqKey in permalinkReqKeys)) {
        baseurl += (baseurl == '' ? '?' : '&') + reqKey + '=' + reqParams[reqKey];
      }
    }
    map.addControl(new OpenLayers.Control.Permalink({base: baseurl}));
    function openInfoPage() {
      var win=window.open(
        conf.infourlprefix
        + (isAtSite ? 'site=' + reqParams['site'] : '')
        + yearURL()
      ,'_blank'); 
      win.focus();
    }
    var btnHiLite = new OpenLayers.Control.Button({
      displayClass: 'olControlBtnHiLite',
      title: "Info",
      id: 'btnHiLite',
      trigger: openInfoPage
    });
    var panel = new OpenLayers.Control.Panel({defaultControl: btnHiLite});
    panel.addControls([btnHiLite]);
    map.addControl(panel);

    var automaticCtls = vlUtils.mapMapUI({map: map, add: [
      'OpenLayers.Control.PanZoomBar',
      'OpenLayers.Control.KeyboardDefaults',
      'OpenLayers.Control.ScaleLine',
      'OpenLayers.Control.LayerSwitcher'
    ], remove: 'OpenLayers.Control.Zoom'});
    if(isAtSite) { automaticCtls['OpenLayers.Control.LayerSwitcher'].maximizeControl(); }
    
    if(layerUrlSelect > -1) { map.setBaseLayer(tmsoverlays[layerUrlSelect]); }
    
    if('debug' in reqParams) {
      OpenLayers.Control.Click = vlUtils.coordsPrompt(map);
      var click = new OpenLayers.Control.Click();
      map.addControl(click);
      click.activate();
    }

    if(isAtSite) { window.document.title += ': ' + vlUtils.getXmlValue(layersXml, 'city'); }
  }

  var htmlSites = function(s) {
    y = '';
    var siteParam, siteName, sitePoint;
    var wmsLinks = [];
    for(f in s) {
      siteName = 'description' in s[f].attributes ? s[f].attributes.description : s[f].attributes.name;
      siteParam = 'site=' + siteName + ('debug' in reqParams ? '&debug=' + reqParams['debug'] : '');
      y += (i > 0 ? '<br/>' : '') +  '&nbsp;&nbsp;'
        + vlUtils.link({
            u: conf.infourlprefix + siteParam,
            h: 'Info',
            l:  '<img src="raster/information.png" border="0"/>'
          });
      for(w in jsonConf.urls) {
        if(!('type' in jsonConf.urls[w])) { continue; }
        sitePoint = new OpenLayers.LonLat(s[f].geometry.x, s[f].geometry.y);
        sitePoint.transform(map.options.projection, map.options.displayProjection);
        y += '&nbsp;'
          + vlUtils.getURLs([w], {
            site: siteName,
            flags: 'useIcon',
            X: sitePoint.lon,
            Y: sitePoint.lat,
            srs0: map.options.displayProjection
          }, jsonConf);
      }
      y += '&nbsp;&nbsp;'
        + vlUtils.link({
            u: '?' + siteParam,
            l:  s[f].attributes.name
          });
    }
    return y;
  }
  
  var _init = function() {
    reqParams = OpenLayers.Util.getParameters();
    OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
  }

  _init();

}
