
// avoid pink tiles
OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;
OpenLayers.Util.onImageLoadErrorColor = "transparent";
var areaID = 'Tallinn';
var areaDir = areaID + '/';

var baseLayersData = {};
var map;
var mapBounds;
var mapMinZoom;
var mapMaxZoom;
var confXml;
var layersXml;

function getXmlValue(xmlDocument, tagname) {
  return xmlDocument.getElementsByTagName(tagname)[0].childNodes[0].nodeValue;
}

function vlInitMap(){

  function xmlHandlerConf(request) {
    if(request.status == 200) {
      document.getElementById('map').innerHTML = '';
      confXml = request.responseXML;
      OpenLayers.Request.GET({ 
          url: getXmlValue(confXml, 'dirvector')
            + getXmlValue(confXml, 'dirplaces')
            + areaDir
            + getXmlValue(confXml, 'filelayers'),
          callback: xmlHandlerLayers
      });
    }
  }
  function xmlHandlerLayers(request) {
      layersXml = request.responseXML;
      mapMinZoom = parseInt(getXmlValue(layersXml, 'minzoom'));
      mapMaxZoom = parseInt(getXmlValue(layersXml, 'maxzoom'));
      boundBox = getXmlValue(layersXml, 'bounds').split(',');
      mapBounds = new OpenLayers.Bounds(
        boundBox[0],
        boundBox[1],
        boundBox[2],
        boundBox[3]
      );
      vlInitMapAfterConf();
  }
  OpenLayers.Request.GET({ url: "conf.xml", callback: xmlHandlerConf });

}

function vlInitMapAfterConf(){

  var options = {
    //controls: [],
    projection: new OpenLayers.Projection("EPSG:900913"),
    displayProjection: new OpenLayers.Projection("EPSG:4326"),
    units: "m",
    numZoomLevels: 17
  };
  map = new OpenLayers.Map('map', options);

  function osm_getTileURL(bounds) {
      var res = osm.map.getResolution();
      var x = Math.round((bounds.left - osm.maxExtent.left) / (res * osm.tileSize.w));
      var y = Math.round((osm.maxExtent.top - bounds.top) / (res * osm.tileSize.h));
      var z = osm.map.getZoom();
      var limit = Math.pow(2, z);

      if (y < 0 || y >= limit) {
          return getXmlValue(confXml, 'dirraster') + getXmlValue(confXml, 'filetransparent');
      } else {
          x = ((x % limit) + limit) % limit;
          return osm.url + z + "/" + x + "/" + y + "." + osm.type;
      }
  }

  function overlay_getTileURL(bounds) {
      var res = this.map.getResolution();
      var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
      var y = Math.round((bounds.bottom - this.tileOrigin.lat) / (res * this.tileSize.h));
      var z = this.map.getZoom();
      if (this.map.baseLayer.name == 'Virtual Earth Roads' || this.map.baseLayer.name == 'Virtual Earth Aerial' || this.map.baseLayer.name == 'Virtual Earth Hybrid') {
          z = z + 1;
      }
      if (baseLayersData[map.baseLayer.layername].bounds.intersectsBounds(bounds) && z >= mapMinZoom && z <= mapMaxZoom ) {
      return getXmlValue(confXml, 'dirraster')
              + getXmlValue(confXml, 'dirplaces')
              + areaDir 
              + baseLayersData[map.baseLayer.layername].dir
              + getXmlValue(confXml, 'dirtiles')
              + z + "/" + x + "/" + y + "." + this.type;
        } else {
          return osm_getTileURL(bounds);
          //return getXmlValue(confXml, 'dirraster') + getXmlValue(confXml, 'filetransparent');
        }
  }

  // create OSM/OAM layer
  currentTime = new Date();
  var osm = new OpenLayers.Layer.TMS( currentTime.getFullYear(),
      "http://tile.openstreetmap.org/",
      {
        layername: 'tms_now',
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '',
        isBaseLayer: true
      } );
  map.addLayer(osm);

  var selectorLayer = new OpenLayers.Layer.Vector(' &#8984;', {
    projection: new OpenLayers.Projection("EPSG:4326"),
    minResolution: map.getResolutionForZoom(mapMinZoom - 1),
    strategies: [new OpenLayers.Strategy.Fixed()],
    protocol: new OpenLayers.Protocol.HTTP({
        url: getXmlValue(confXml, 'dirvector')
              + getXmlValue(confXml, 'fileareaselector'),
        format: new OpenLayers.Format.KML({
            extractAttributes: true,
            maxDepth: 0
        })
    })
  });
  map.addLayer(selectorLayer);

  var layersTags = layersXml.getElementsByTagName('layer');
  var tmsoverlays = [];
  var roadLayers = [];
  for(i = 0; i < layersTags.length; i++) {
    if(layersTags[i].getAttribute('disabled')) { continue; }
    if(layersTags[i].getAttribute('type') == 'tms') {
      layername = 'tms_' + layersTags[i].getAttribute('year');
      layerBoundBox = layersTags[i].getAttribute('bounds').split(',');
      baseLayersData[layername] = {
        dir: layersTags[i].getAttribute('year') + '/',
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
        });
    } else {
      roadLayers[roadLayers.length] = new OpenLayers.Layer.Vector(layersTags[i].getAttribute('name'), {
            projection: new OpenLayers.Projection("EPSG:4326"),
            maxResolution: map.getResolutionForZoom(parseInt(layersTags[i].getAttribute('maxres'))),
            strategies: [new OpenLayers.Strategy.Fixed()],
            protocol: new OpenLayers.Protocol.HTTP({
                url: getXmlValue(confXml, 'dirvector')
                      + getXmlValue(confXml, 'dirplaces')
                      + areaDir 
                      + layersTags[i].getAttribute('file'),
                format: new OpenLayers.Format.KML({
                    extractAttributes: true,
                    maxDepth: 0
                })
            }),
          styleMap: new OpenLayers.StyleMap({
            'default': new OpenLayers.Style({'strokeWidth': 3,'strokeColor': '#ff0000'}),
            'select': new OpenLayers.Style({'strokeWidth': 5,'strokeColor': '#0000ff'})
          })
      });
    }
  }
  map.addLayers(tmsoverlays);
  map.addLayers(roadLayers);

  function createPopup(feature) {
    feature.popup = new OpenLayers.Popup.Anchored("streetPopup",
        map.getCenter(),
        null,
        feature.attributes.name,
        null,
        true,
        function() { roadLayersCtl.unselectAll(); }
    );
    feature.popup.setBorder('solid 2px black');
    feature.popup.autoSize = true;
    map.addPopup(feature.popup);
  }

  function destroyPopup(feature) {
    feature.popup.destroy();
    feature.popup = null;
  }

  //Add a selector control to the kmllayer with popup functions
  var roadLayersCtl = new OpenLayers.Control.SelectFeature(roadLayers, { 
      onSelect: createPopup, 
      onUnselect: destroyPopup,
  });
  map.addControl(roadLayersCtl);
  roadLayersCtl.activate();
  
  var switcherControl = new OpenLayers.Control.LayerSwitcher();
  map.addControl(switcherControl);
  switcherControl.maximizeControl();
  map.addControl(new OpenLayers.Control.PanZoomBar());
  map.addControl(new OpenLayers.Control.MousePosition());
  map.addControl(new OpenLayers.Control.KeyboardDefaults());
  permalinkReqKeys = ['zoom=','lat=','lon=','layers='];
  for(reqKey in permalinkReqKeys) { 
    if(location.search.indexOf(permalinkReqKeys[reqKey]) < 0) {
        map.zoomToExtent(mapBounds.transform(map.displayProjection, map.projection));
        break;
    }
  }
  map.addControl(new OpenLayers.Control.Permalink({base: 'index.html?site=Tallinn&'}));
  //for(i in map.controls){ if(map.controls[i].CLASS_NAME == 'OpenLayers.Control.Zoom') { map.controls[i].deactivate(); } }

  function openInfoPage() {
    var year = map.baseLayer.layername.substr(4);
    if(year.match(/^\d+$/)) {
      var win=window.open('info.html?site='+areaID+'&year='+year, '_blank'); 
      win.focus();
    }
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
    
}
