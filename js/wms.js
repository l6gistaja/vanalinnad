function vlWms(inputParams){

  // avoid pink tiles
  OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;
  OpenLayers.Util.onImageLoadErrorColor = "transparent";

  var map;
  var conf;
  var reqParams;
  var isAtSite;
  var jsonConf = {};
  var jsonConfWMS = {};

  var xmlHandlerConf = function(request) {
    if(request.status == 200) {
      document.getElementById(inputParams.divMap).innerHTML
        = '<center><h1>Please wait...<br/><br/><a href="?">Or click here.<br/><br/><img src="apple-touch-icon.png" border="0"/></a></h1></center>';
      conf = vlUtils.xmlDoc2Hash(request.responseXML);
      jsonConf = JSON.parse(conf.json);
      isAtSite = 'site' in reqParams && reqParams['site'].match(/^[A-Z][A-Za-z-]*$/);
      OpenLayers.Request.GET({url: conf.dirvector + 'wms/' + reqParams['wms'] + '.xml', callback: xmlHandlerLayers });
    }
  }
  
  var xmlHandlerLayers = function(request) {
    if(request.status == 200) {
      document.getElementById(inputParams.divMap).innerHTML = ''; 
      layersXml = request.responseXML;
      jsonConfWMS = JSON.parse(vlUtils.getXmlValue(layersXml, 'json'));
      if(vlUtils.getXmlValue(layersXml, 'bounds') != null) {
        jsonConfWMS.mapoptions.maxExtent = new OpenLayers.Bounds(vlUtils.getXmlValue(layersXml, 'bounds').split(','));
      }
      var currentTime = new Date();
      var layers = [];
      var layersTags = layersXml.getElementsByTagName('layer');
      for(i = 0; i < layersTags.length; i++) {
        layers[layers.length] = new OpenLayers.Layer.WMS(
          layersTags[i].getAttribute('year').replace('@NOW@',currentTime.getFullYear()),
          layersTags[i].getAttribute('wmsurl') == null
            ? vlUtils.getXmlValue(layersXml, 'defaultwmsurl')
            : layersTags[i].getAttribute('wmsurl'),
          {
              "layers": layersTags[i].getAttribute('layername'),
              "format": layersTags[i].getAttribute('format') == null
                ? vlUtils.getXmlValue(layersXml, 'defaultformat')
                : layersTags[i].getAttribute('format'),
              "transparent": layersTags[i].getAttribute('transparent')
          },
          jsonConfWMS.mapoptions
        );
      }
      
      map = new OpenLayers.Map(inputParams.divMap, jsonConfWMS.mapoptions);
      map.addLayers(layers);

      if('defaults' in jsonConfWMS) {
        var xyz = {ll: ['lon','lat'], xy: []};
        if(!( 'zoom' in reqParams && !isNaN(xyz.z = parseInt(reqParams['zoom'])) )) {
          xyz.z = jsonConfWMS.defaults.z
        }
        for(xyz.tmp in xyz.ll) {
          if(!( xyz.ll[xyz.tmp] in reqParams && !isNaN(xyz.xy[xyz.tmp] = parseFloat(reqParams[xyz.ll[xyz.tmp]])) )) {
            xyz.xy = jsonConfWMS.defaults.xy;
            xyz.msg = 'Wrong or missing lon or lat URL parameters;&nbsp;&nbsp;&nbsp;<br/>centered and zoomed to [ '
              + xyz.xy[0] + ', ' + xyz.xy[1] + ', ' + xyz.z + ' ] instead.&nbsp;&nbsp;&nbsp;';
            break;
          }
        }
        xyz.mapCenter = new OpenLayers.LonLat(xyz.xy);
        map.setCenter(xyz.mapCenter, xyz.z);
        if('msg' in xyz) {
          map.addPopup(new OpenLayers.Popup.FramedCloud('coordsPromptPopup', xyz.mapCenter, null, xyz.msg, null, true, null));
        }
      }

      if('info' in jsonConfWMS) {
        function openInfoPage() { var win=window.open(jsonConfWMS.info, '_blank'); win.focus(); }
        var infoBtn = new OpenLayers.Control.Button({
            displayClass: 'infoBtn',
            title: "Info",
            trigger: openInfoPage
        });
        var infoPanel = new OpenLayers.Control.Panel({defaultControl: infoBtn});
        infoPanel.addControls([infoBtn]);
        map.addControl(infoPanel);
      }
      function toggleSearch() { vlSearch.toggleSearch(); };
      var searchBtn = new OpenLayers.Control.Button({
        displayClass: 'searchBtn',
        title: "Search",
        trigger: toggleSearch
      });
      var searchPanel = new OpenLayers.Control.Panel({defaultControl: searchBtn});
      searchPanel.addControls([searchBtn]);
      map.addControl(searchPanel);
      
      var automaticCtls = vlUtils.mapMapUI({map: map, add: [
        'OpenLayers.Control.LayerSwitcher',
        'OpenLayers.Control.PanZoomBar',
        'OpenLayers.Control.KeyboardDefaults',
        'OpenLayers.Control.Permalink',
        'OpenLayers.Control.ScaleLine'
      ], remove: 'OpenLayers.Control.Zoom'});
      automaticCtls['OpenLayers.Control.LayerSwitcher'].maximizeControl();

      var clickData = {
        jsonConf: jsonConf,
        locData: {
          site: isAtSite ? reqParams['site'] : '',
          baseUrlID: 'maaamet'
        },
        links: ['googlestreetview','ajapaik','geohack','vanalinnad'],
        debug: 'debug' in reqParams
      };
      
      if(!('draw' in reqParams)) { vlUtils.mapAddCoordsPromptCtl(map, clickData); }
      else {

            var lineLayer = new OpenLayers.Layer.Vector("DRAW",
                {styleMap: vlUtils.mergeCustomStyleWithDefaults(jsonConf.olLayerStyles['roads'])});
            map.addLayer(lineLayer);
            var drawCtl = new OpenLayers.Control.DrawFeature(lineLayer, OpenLayers.Handler.Path);
            map.addControl(drawCtl);
            drawCtl.activate();

            function showPath() { 
                var path = '';
                var coords;
                for(var i = 0; i < lineLayer.features.length; i++) {
                    path += "<LineString><coordinates>";
                    for(var j = 0; j < lineLayer.features[i].geometry.components.length; j++) {
                        coords = [lineLayer.features[i].geometry.components[j].x,
                            lineLayer.features[i].geometry.components[j].y];
                        if(jsonConfWMS.mapoptions.projection != 'EPSG:4326') {
                            try {
                                var coords = proj4(
                                    jsonConf.proj4[jsonConfWMS.mapoptions.projection.replace(':','_')],
                                    jsonConf.proj4['EPSG_4326'],
                                    coords);
                            } catch(err) {
                                alert('PROJ4 failure.');
                                return;
                            }
                        }
                        path += coords[0] + "," + coords[1] + " ";
                    }
                    path = path.trim() + "</coordinates></LineString>";
                }
                if(prompt("Lines as KML LineStrings.\nCancel deletes all lines from map.", path) == null) {
					lineLayer.removeAllFeatures();
				}
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

    } else {
      window.location.replace('?error=nonexisting_wms');
    }
  }
  
  this.zoomToBBox = function(x) {
      if(jsonConfWMS.mapoptions.projection != 'EPSG:4326') {
        for(var i = 0; i < 4; i+=2) {
            try {
                var p4 = proj4(
                    jsonConf.proj4['EPSG_4326'],
                    jsonConf.proj4[jsonConfWMS.mapoptions.projection.replace(':','_')],
                    [x[i], x[i+1]]);
                x[i] = p4[0];
                x[i+1] = p4[1];
            } catch(err) {
                return false;
            }
        }
      }
      map.zoomToExtent(new OpenLayers.Bounds(x));
      return false;
  }

  var _init = function() {
    reqParams = OpenLayers.Util.getParameters();
    OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
  }

  _init();

}
