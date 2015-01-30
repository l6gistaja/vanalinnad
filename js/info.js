function vlInitInfo(inputParams){

  var map;
  var osm;
  var conf;
  var rssXml;
  var bboxLayersCtl;
  var reqParams = OpenLayers.Util.getParameters();
  if(!('site' in reqParams)) { reqParams['site'] = ''; }
  if(!('year' in reqParams)) { reqParams['year'] = ''; }
  var requestConf = {};
  var siteName = reqParams['site'];
  var level = '';
  var years = ['', ''];
  var emptyTiles = {};
  var mapMinZoom;
  var mapMaxZoom;
  var baseLayerData;
  var histBaseLayer;
  var mapTag = null;
  var areaDir;
  
  function getSiteLbl() {
    baseURL = '?site=' + reqParams['site'];
    baseYear = baseURL + '&year=';
    return ' : ' + vlUtils.link({u:baseURL, l:siteName})
      + (level != 'year' ? ''
        : ' : ' + vlUtils.link({u:baseYear + years[0], l:'&lt;&lt;', h:years[0]})
        + ' ' + vlUtils.link({u:'index.html' + baseYear + reqParams['year'], l:reqParams['year']})
        + ' ' + vlUtils.link({u:baseYear + years[1], l:'&gt;&gt;', h:years[1]}));
  }
  
  function xmlHandlerConf(request) {
    if(request.status == 200) {
      if(!('year' in reqParams)) { reqParams['year'] = ''; }
      conf = vlUtils.xmlDoc2Hash(request.responseXML);
      requestConf = {
        year: {
           url: conf.dirvector
             + conf.dirplaces
             + reqParams['site']
             + '/rss'
             + reqParams['year']
             + '.xml',
           callback: rssHandler
        },
        site: {
           url: conf.dirvector
             + conf.dirplaces
             + reqParams['site']
             + '/'
             + conf.filelayers,
           callback: layerHandler
        },
	selector: {
           url: conf.dirvector
             + conf.fileareaselector,
           callback: selectorHandler
      	},
        bbox: {
           url: conf.dirvector
             + conf.dirplaces
             + reqParams['site'] + '/bbox'
             + reqParams['year'] + '.kml'
      	},
        emptytiles: {
           url: conf.dirvector
             + conf.dirplaces
             + reqParams['site'] + '/'
             + conf.fileemptytiles,
           callback: loadEmptyTilesData
        }
      };
      if(reqParams['site'].match(/\S/)) {
	    level = reqParams['year'].match(new RegExp(conf.regexyearmatcher)) || 
              reqParams['year'].match(new RegExp('^[A-Za-z_]+$')) ? 'year' : 'site';
      } else { level = 'selector'; }
      OpenLayers.Request.GET(level == 'year' ? requestConf['site'] : requestConf[level]);
    }
  }

  function osm_getTileURL(bounds) {
      return vlUtils.getTodaysTileURL(osm, bounds);
  }
  
  function overlay_getTileURL(bounds) {
      return vlUtils.getBasemapTileUrl({
          layer: this,   
          layerToday: osm,                       
          bounds: bounds,
          layerdata: baseLayerData,
          mapMinZoom: mapMinZoom,
          mapMaxZoom: mapMaxZoom,
          emptyTiles: emptyTiles,
          areaDir: areaDir,
          conf: conf
      });
  }
  
  
  function createBBoxPopup(feature) {
    if(feature.fid.substring(0, 4) == 'bbox') {
        bounds = new OpenLayers.Bounds(feature.geometry.bounds.toArray()).transform(map.projection, map.displayProjection);
        feature.popup = new OpenLayers.Popup.Anchored(
            "bboxPopup",
            map.getCenter(),
            null,
            '<strong>BBox ' + ( feature.attributes.name == null ? '' : feature.attributes.name )  + 
              '</strong><br/>' + bounds.left + ' <br/>' + bounds.bottom + ' <br/>' + bounds.right + ' <br/>' +
              bounds.top,
            null,
            true,
            function() { bboxLayersCtl.unselectAll(); }
        );
        feature.popup.setBorder('solid 2px black');
        feature.popup.autoSize = true;
    } else {
        center = new OpenLayers.LonLat(feature.geometry.getBounds().getCenterLonLat().lon, feature.geometry.getBounds().getCenterLonLat().lat).transform(map.projection, map.displayProjection); 
        feature.popup = new OpenLayers.Popup.FramedCloud(
            "bboxPopup",
            feature.geometry.getBounds().getCenterLonLat(),
            null,
            '<strong>GCP ' + feature.attributes.name + '</strong><br/>'  + center.lon + ' <br/>' + center.lat + ' <br/>' +
              ('debug' in reqParams ?
		'<input type="text" value=" -gcp ' + feature.attributes.description + ' '  + center.lon + ' ' + center.lat + '"/>' :
                ''),
            null,
            true,
            function() { bboxLayersCtl.unselectAll(); }
        );
        feature.popup.autoSize = true;
    }
    map.addPopup(feature.popup);
  }

  function rssHandler(request) {
    if(request.status == 200) {

      rssXml = request.responseXML;
      y = '';
      items = rssXml.getElementsByTagName('item');
      itemFields = [
        {tag:'title'},
        {tag:'author'},
        {tag:'description'},
        {tag:'guid'}
      ];

      for(m=0;m<items.length;m++) {

        dateParts = vlUtils.getXmlValue(items[m], 'pubDate').split(/\s+/);
        pubYear = (dateParts.length > 3) ? dateParts[3] : '';
        mapAnchor = '';
        if(items.length > 1) {
          mapAnchor =  (vlUtils.getXmlValue(items[m], 'anchor') != '') ? vlUtils.getXmlValue(items[m], 'anchor')
            : pubYear;
          if(mapAnchor == '') { mapAnchor = String.fromCharCode(65 + m); }
          y += '<hr/><a name="map.'+mapAnchor+'">'+ vlUtils.link({u:'#map.'+mapAnchor, l:'<strong>'+mapAnchor+'</strong>'}) + '</a><br/>';
        }
        
        // legends
        if(items[m].getElementsByTagName('legends').length) {
          legends = vlUtils.getXmlValue(items[m], 'legends').split(',');
          for(i=0; i<legends.length; i++) {
            if(legends[i] == '') { continue; }
            y += ( i > -1 ? '<br/>' : '' )
              + '<img src="'
              + conf.dirlegends
              + conf.dirplaces
              + reqParams['site']
              + '/'
              + legends[i]
              + '" />';
          }
        }

        // texts
        for(i in itemFields) {
          tmp = vlUtils.getXmlValue(items[m], itemFields[i].tag, 0);
          if(itemFields[i].tag == 'author' && pubYear != '') {
            tmp += ' ' + pubYear;
          }
          if(tmp != '') { y += '<br/>' + tmp; }
        }

        // links
        y += '<ol>';
        links = items[m].getElementsByTagName('link');
        for(i=0; i<links.length; i++) {
          if(links[i].childNodes.length < 1) { continue; }
          y += '<li>' + vlUtils.link({u: links[i].childNodes[0].nodeValue}) + '</li>';
        }
        y += '</ol>';

      }
      
      y += '<a name="bbox">'+vlUtils.link({u:requestConf.bbox.url, l:'BBox &amp; GCP'})+'</a><div id="infoMap" style="height:400px;width:600px;"></div>';
      document.getElementById(inputParams.divHeader).innerHTML += getSiteLbl();
      document.getElementById(inputParams.divContent).innerHTML = y;
      document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;

      map = new OpenLayers.Map('infoMap', {
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326"),
        units: "m",
        numZoomLevels: 18
      });

      // OSM/OAM layer

      currentTime = new Date();
      osm = new OpenLayers.Layer.TMS( currentTime.getFullYear(),
        "http://tile.openstreetmap.org/",
        {
          layername: 'osm',
          type: 'png',
          getURL: osm_getTileURL,
          displayOutsideMaxExtent: true,
          attribution: '',
          isBaseLayer: true
        }
      );
      map.addLayer(osm);
      
      // BBox layer

      var bbox = new OpenLayers.Layer.Vector('BBox', {
            projection: new OpenLayers.Projection("EPSG:4326"),
            strategies: [new OpenLayers.Strategy.Fixed()],
            protocol: new OpenLayers.Protocol.HTTP({
                url: requestConf.bbox.url,
                format: new OpenLayers.Format.KML({
                    extractAttributes: true,
                    maxDepth: 0
                })
            }),
            styleMap: vlUtils.mergeCustomStyleWithDefaults(vlLayerStyles['BBox'])
      });
      bbox.events.register('loadend', bbox, function(){
        map.zoomToExtent(bbox.getDataExtent());
      });
      map.addLayer(bbox);

      bboxLayersCtl = new OpenLayers.Control.SelectFeature([bbox], { 
        onSelect: createBBoxPopup, 
        onUnselect: vlUtils.destroyPopup
      });
      map.addControl(bboxLayersCtl);
      bboxLayersCtl.activate();
      
      // historical base layer

      if(mapTag != null) {
        OpenLayers.Request.GET(requestConf['emptytiles']);
      }

    } else {
      OpenLayers.Request.GET(requestConf['site']);
    }
  }

  function loadEmptyTilesData(request) {
      emptyTiles = (request.status == 200) ? JSON.parse(request.responseText) : {};
      baseLayerData = vlUtils.createBaseLayerData(mapTag, {no: 0}, map);
      histBaseLayer = new OpenLayers.Layer.TMS(
        reqParams['year'],
        "",
        {
          layername: conf.tmslayerprefix + reqParams['year'],
          type: 'jpg',
          getURL: overlay_getTileURL,
          alpha: false,
          isBaseLayer: true
        }
      );
      map.addLayer(histBaseLayer);
      var switcherControl = vlUtils.addSwitcher(map);
      switcherControl.maximizeControl();
      map.setBaseLayer(histBaseLayer);
  }

  function layerHandler(request) {
    if(request.status == 200) {
      layerXml = request.responseXML;
      siteName = vlUtils.getXmlValue(layerXml, 'city');
      links = layerXml.getElementsByTagName('layer');
      mapMinZoom = parseInt(vlUtils.getXmlValue(layerXml, 'minzoom'));
      mapMaxZoom = parseInt(vlUtils.getXmlValue(layerXml, 'maxzoom'));
      if(level == 'year') {
        areaDir = reqParams['site'] + '/';
        l = 0;
        y = -1;
        for(i=0; i<links.length; i++) {
          if(links[i].getAttribute('disabled') || links[i].getAttribute('year') == null){ continue; }
          if(links[i].getAttribute('year') == reqParams['year']) { y = i; }
          l++;
        }
        if(y > -1 && links[y].getAttribute('type') == 'tms') { mapTag = links[y]; }
        years[0] = links[y < 1 ? l - 1 : y - 1].getAttribute('year');
        years[1] = links[y > l - 2 ? 0 : y + 1].getAttribute('year');
        OpenLayers.Request.GET(requestConf['year']);
      } else {
        y = '<br/>' 
          + vlUtils.link({u:'index.html?site=' + reqParams['site'], l:siteName}) + ' ('
          + vlUtils.link({u:'http://et.wikipedia.org/wiki/' + siteName, l:'Wikipedia'})
          + ')<ol>';
        for(i=0; i<links.length; i++) {
          if(links[i].getAttribute('disabled') || links[i].getAttribute('year') == null){ continue; }
          y += '<li>' + vlUtils.link({
            u: '?site=' + reqParams['site'] + '&year='+ links[i].getAttribute('year'),
            l: links[i].getAttribute(links[i].getAttribute('name') ? 'name' : 'year')
          })  + '</li>';
        }
        y += '</ol>';
        document.getElementById(inputParams.divContent).innerHTML = y;
        document.getElementById(inputParams.divHeader).innerHTML += getSiteLbl();
        document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;
      }
    } else {
      OpenLayers.Request.GET(requestConf['selector']);
    }
  }

  function selectorHandler(request) {
    if(request.status == 200) {
      selectorXml = request.responseXML;
      y = '<ol>';
      placemarks = selectorXml.getElementsByTagName('Placemark');
      for(i=0; i<placemarks.length; i++) {
        name = vlUtils.getXmlValue(placemarks[i], 'name');
        descr = vlUtils.getXmlValue(placemarks[i], 'description');
        y +=  '<li>' + vlUtils.link({u:'?site=' + name, l:descr != '' ? descr : name}) + '</li>';
      }
      y += '</ol>';
      document.getElementById(inputParams.divContent).innerHTML = y;
      document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;
    }
  }

  OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
}
