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
  var input;
  var emptyTiles;

  var xmlHandlerConf = function(request) {
    if(request.status == 200) {
      document.getElementById(inputParams.divMap).innerHTML = '';
      conf = vlUtils.xmlDoc2Hash(request.responseXML);
      //TODO: change when multiple sites will appear in future 
      reqParams['site'] = conf.defaultsite;
      areaDir = reqParams['site'] + '/';
      OpenLayers.Request.GET({ 
          url: conf.dirvector
            + conf.dirplaces
            + areaDir
            + conf.filelayers,
          callback: xmlHandlerLayers
      });
    }
  }

  var xmlHandlerLayers = function(request) {
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
            + 'empty.json',
          callback: loadEmptyTilesData
      });
  }

  var loadEmptyTilesData = function(request) {
      emptyTiles = (request.status == 200) ? JSON.parse(request.responseText) : {};
      vlInitMapAfterConf();
  }
  
  var vlInitMapAfterConf = function(){

    function existsInStruct(path) {
      var pointer = emptyTiles;
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
      for(i=0; i<pointer.length; i++) {
        if(isNaN(pointer[i])) {
          if(path[lastIndex] >= pointer[i][0] && path[lastIndex] <= pointer[i][1]) { return true; }
          lastValue = pointer[i][1];
        } else {
          if(pointer[i] == path[lastIndex]) { return true; }
          lastValue = pointer[i];
        }
        // when values array is in ascending order 
        if(lastValue > path[lastIndex]) {return false;}
      }
      return false;
    }

    yearMatcher = new RegExp(conf.regexyearmatcher);

    map = new OpenLayers.Map(inputParams.divMap, {
      projection: new OpenLayers.Projection("EPSG:900913"),
      displayProjection: new OpenLayers.Projection("EPSG:4326"),
      units: "m",
      numZoomLevels: 17
    });

    function osm_getTileURL(bounds) {
        return vlUtils.getTodaysTileURL(osm, bounds);
    }

    function overlay_getTileURL(bounds) {
        var res = this.map.getResolution();
        var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
        var y = Math.round((bounds.bottom - this.tileOrigin.lat) / (res * this.tileSize.h));
        var z = this.map.getZoom();
        if (this.map.baseLayer.name == 'Virtual Earth Roads' || this.map.baseLayer.name == 'Virtual Earth Aerial' || this.map.baseLayer.name == 'Virtual Earth Hybrid') {
            z = z + 1;
        }
        if (
          (baseLayersData[map.baseLayer.layername].bounds.intersectsBounds(bounds)
            && z >= mapMinZoom && z <= mapMaxZoom)
          && !existsInStruct([
            baseLayersData[map.baseLayer.layername].year,
            ''+z, ''+x, y])
        ) {
        return conf.dirraster
                + conf.dirplaces
                + areaDir 
                + baseLayersData[map.baseLayer.layername].dir
                + conf.dirtiles
                + z + "/" + x + "/" + y + "." + this.type;
          } else {
            return osm_getTileURL(bounds);
          }
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

    var selectorLayer = new OpenLayers.Layer.Vector(' &#8984; POI', {
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
    map.addLayer(selectorLayer);

    var layersTags = layersXml.getElementsByTagName('layer');
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

    for(i = 0; i < layersTags.length; i++) {
      if(layersTags[i].getAttribute('disabled')) { continue; }
      if(layersTags[i].getAttribute('type') == 'tms') {
        if(
          visibleBaseLayers.length > 0
          && OpenLayers.Util.indexOf(visibleBaseLayers, layersTags[i].getAttribute('year')) < 0
        ) { continue; }
        layername = conf.tmslayerprefix + layersTags[i].getAttribute('year');
        layerBoundBox = layersTags[i].getAttribute('bounds').split(',');
        baseLayersData[layername] = {
          dir: layersTags[i].getAttribute('year') + '/',
          year: layersTags[i].getAttribute('year'),
          bounds: new OpenLayers.Bounds(layerBoundBox[0], layerBoundBox[1], layerBoundBox[2], layerBoundBox[3])
        };
        baseLayersData[layername].bounds = baseLayersData[layername].bounds.transform(map.displayProjection, map.projection);
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
        layername = 'roads_' + roadLayers.length;
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
            styleMap: vlUtils.mergeCustomStyleWithDefaults(vlLayerStyles['roads'])
        });
      }
    }
    roadLayers[roadLayers.length] = selectorLayer;
    map.addLayers(tmsoverlays);
    map.addLayers(roadLayers);
    
    function createVectorLayersPopup(feature) {
      if(feature.layer.getOptions().layername == 'POIs') {
        feature.popup = new OpenLayers.Popup.FramedCloud(
            "poiPopup",
            feature.geometry.getBounds().getCenterLonLat(),
            null,
            '<a href="?site=' + feature.attributes.name + '">' + feature.attributes.name + '</a>',
            null,
            true,
            function() { vectorLayersCtl.unselectAll(); }
        );
      } else {
        distanceDetails = feature.geometry.distanceTo(
          new OpenLayers.Geometry.Point(map.getCenter().lon, map.getCenter().lat), 
          {details: true}
        );
        feature.popup = new OpenLayers.Popup.FramedCloud (
            "roadPopup",
            new OpenLayers.LonLat(distanceDetails.x0, distanceDetails.y0),
            null,
            feature.attributes.name,
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

    var switcherControl = new OpenLayers.Control.LayerSwitcher();
    map.addControl(switcherControl);
    switcherControl.maximizeControl();
    switcherControl.baseLbl.innerHTML = '';
    switcherControl.dataLbl.innerHTML = '';

    map.addControl(new OpenLayers.Control.PanZoomBar());
    //map.addControl(new OpenLayers.Control.MousePosition());
    map.addControl(new OpenLayers.Control.KeyboardDefaults());
    map.addControl(new OpenLayers.Control.ScaleLine());

    permalinkReqKeys = ['zoom','lat','lon','layers'];
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
    baseurl = '';
    for(reqKey in reqParams) {
      if(reqKey == 'year') { continue; }
      if(!(reqKey in permalinkReqKeys)) {
        baseurl += (baseurl == '' ? '?' : '&') + reqKey + '=' + reqParams[reqKey];
      }
    }
    map.addControl(new OpenLayers.Control.Permalink({base: baseurl}));
    function openInfoPage() {
      var year = map.baseLayer.layername.substr(conf.tmslayerprefix.length);
      var win=window.open(
        conf.infourlprefix
        + 'site=' + reqParams['site']
        + (year.match(yearMatcher) 
          ? '&year=' + year : '')
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
    
    // Remove automatically added Zoom
    for(i in map.controls) { 
      if(map.controls[i].CLASS_NAME == 'OpenLayers.Control.Zoom') {
          map.controls[i].destroy();
          map.controls[i] = null;
      }
    }
    if(layerUrlSelect > -1) { map.setBaseLayer(tmsoverlays[layerUrlSelect]); }
  }

  var _init = function() {
    reqParams = OpenLayers.Util.getParameters();
    OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
  }

  _init();

}
