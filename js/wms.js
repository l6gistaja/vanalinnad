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
      document.getElementById(inputParams.divMap).innerHTML = '';
      conf = vlUtils.xmlDoc2Hash(request.responseXML);
      jsonConf = JSON.parse(conf.json);
      isAtSite = 'site' in reqParams && reqParams['site'].match(/^[A-Z][A-Za-z-]*$/);
      OpenLayers.Request.GET({url: conf.dirvector + 'wms/' + reqParams['wms'] + '.xml', callback: xmlHandlerLayers });
    }
  }
  
  var xmlHandlerLayers = function(request) {

    if(request.status == 200) {
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

      if(!vlUtils.fullOLPermalinkCoords(reqParams) && 'defaults' in jsonConfWMS) {
          map.setCenter(new OpenLayers.LonLat(jsonConfWMS.defaults.xy),jsonConfWMS.defaults.z);
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
      document.getElementById(inputParams.divMap).innerHTML = '<h1><a href="?">Vanalinnad</a></h1>';
      document.location = '?';
    }
  }

  var _init = function() {
    reqParams = OpenLayers.Util.getParameters();
    OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
  }

  _init();

}
