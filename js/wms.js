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
        = '<center><a href="?"><h1>Error occured.<br/>Click here.</h1><img src="apple-touch-icon.png" border="0"/></a></center>';
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
          layersTags[i].getAttribute('year') == '@NOW@'
            ? currentTime.getFullYear()
            : layersTags[i].getAttribute('year'),
          layersTags[i].getAttribute('wmsurl') == null
            ? vlUtils.getXmlValue(layersXml, 'defaultwmsurl')
            : layersTags[i].getAttribute('wmsurl'),
          {
              "layers": layersTags[i].getAttribute('layername'),
              "format": vlUtils.getXmlValue(layersXml, 'defaultformat')
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
        var btnHiLite = new OpenLayers.Control.Button({
          displayClass: 'olControlBtnHiLite',
          title: "Info",
          id: 'btnHiLite',
          trigger: openInfoPage
        });
        var panel = new OpenLayers.Control.Panel({defaultControl: btnHiLite});
        panel.addControls([btnHiLite]);
        map.addControl(panel);
      }

      var automaticCtls = vlUtils.mapMapUI({map: map, add: [
        'OpenLayers.Control.LayerSwitcher',
        'OpenLayers.Control.PanZoomBar',
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
        links: ['googlestreetview','ajapaik','vanalinnad'],
        debug: 'debug' in reqParams
      };
      vlUtils.mapAddCoordsPromptCtl(map, clickData);
      
    } else {
      window.location.replace('?');
    }
  }

  var _init = function() {
    reqParams = OpenLayers.Util.getParameters();
    OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
  }

  _init();

}
