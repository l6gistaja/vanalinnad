function vlInitInfo(){

  var map;
  var osm;
  var confXml;
  var rssXml;
  var bboxLayersCtl;
  var reqParams = OpenLayers.Util.getParameters();
  if(!('site' in reqParams)) { reqParams['site'] = ''; }
  if(!('year' in reqParams)) { reqParams['year'] = ''; }
  var siteLbl = ' &gt; <a href="?site=' + reqParams['site'] + '">' + reqParams['site'] + '</a>';
  var requestConf = {};

  function xmlHandlerConf(request) {
    if(request.status == 200) {
      if(!('year' in reqParams)) { reqParams['year'] = ''; }
      confXml = request.responseXML;
      requestConf = {
        year: {
           url: vlUtils.getXmlValue(confXml, 'dirvector')
             + vlUtils.getXmlValue(confXml, 'dirplaces')
             + reqParams['site']
             + '/rss'
             + reqParams['year']
             + '.xml',
           callback: rssHandler
        },
        site: {
           url: vlUtils.getXmlValue(confXml, 'dirvector')
             + vlUtils.getXmlValue(confXml, 'dirplaces')
             + reqParams['site']
             + '/'
             + vlUtils.getXmlValue(confXml, 'filelayers'),
           callback: layerHandler
        },
	    selector: {
           url: vlUtils.getXmlValue(confXml, 'dirvector')
             + vlUtils.getXmlValue(confXml, 'fileareaselector'),
           callback: selectorHandler
      	},
        bbox: {
           url: vlUtils.getXmlValue(confXml, 'dirvector')
                + vlUtils.getXmlValue(confXml, 'dirplaces')
                + reqParams['site'] + '/bbox'
                + reqParams['year'] + '.kml',
           callback: bboxHandler
      	}
      };
      if(reqParams['site'].match(/\S/)) {
	    key = reqParams['year'].match(new RegExp(vlUtils.getXmlValue(confXml, 'regexyearmatcher'))) ? 'year' : 'site';
      } else { key = 'selector'; }
      OpenLayers.Request.GET(requestConf[key]);
    }
  }

  function osm_getTileURL(bounds) {
      return vlUtils.getTodaysTileURL(osm, bounds);
  }
  
  function createBBoxPopup(feature) {
    if(feature.fid == 'bbox') {
        bounds = new OpenLayers.Bounds(feature.geometry.bounds.toArray()).transform(map.projection, map.displayProjection);
        feature.popup = new OpenLayers.Popup.Anchored(
            "bboxPopup",
            map.getCenter(),
            null,
            '<strong>BBox</strong><br/>' + bounds.left + ' <br/>' + bounds.bottom + ' <br/>' + bounds.right + ' <br/>' + bounds.top,
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
            '<strong>GCP ' + feature.attributes.name + '</strong><br/>'  + center.lon + ' <br/>' + center.lat + ' <br/><input type="text" value=" -gcp ' + feature.attributes.description + ' '  + center.lon + ' ' + center.lat + '"/>',
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
      if(rssXml.getElementsByTagName('legends').length) {
        legends = vlUtils.getXmlValue(rssXml, 'legends').split(',');
        for(i=0; i<legends.length; i++) {
          if(legends[i] == '') { continue; }
          y += ( i > -1 ? '<br/>' : '' )
             + '<img src="'
             + vlUtils.getXmlValue(confXml, 'dirraster')
             + vlUtils.getXmlValue(confXml, 'dirplaces')
             + reqParams['site']
             + '/'
             + reqParams['year']
             + '/'
             + legends[i]
             + '"/>';
        }
      }
      itemFields = [
	{tag:'title', no:1},
	{tag:'author'},
	{tag:'description'},
	{tag:'guid'}
      ]; 
      for(i in itemFields) {
        tmp = vlUtils.getXmlValue(rssXml, itemFields[i].tag, 'no' in itemFields[i] ? itemFields[i].no : 0);
	    if(itemFields[i].tag == 'author') {
          dateParts = vlUtils.getXmlValue(rssXml, 'pubDate').split(/\s+/);
          if(dateParts.length > 3) { tmp += ' ' + dateParts[3]; }
        }
	if(tmp != '') { y += '<br/>' + tmp; }
      }
      y += '<ol>';
      links = rssXml.getElementsByTagName('link');
      for(i=0; i<links.length; i++) {
         y += '<li><a href="' 
           + links[i].childNodes[0].nodeValue + '">'
           + links[i].childNodes[0].nodeValue + '</a></li>';
      }
      y += '</ol><a name="bbox"><a href="'+requestConf.bbox.url+'">BBox &amp; GCP</a></a><div id="map" style="height:400px;width:600px;"></div>';
      document.getElementById('header').innerHTML += siteLbl + ' &gt; ' 
        + '<a href="index.html?site=' + reqParams['site'] 
        + '&year=' + reqParams['year'] + '">' + reqParams['year'] + '</a>';
      document.getElementById('content').innerHTML = y;
      document.getElementById('footer').innerHTML = document.getElementById('header').innerHTML;

      map = new OpenLayers.Map('map', {
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326"),
        units: "m",
        numZoomLevels: 18
      });
      
      osm = new OpenLayers.Layer.TMS('OSM',
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
      
      bbox = new OpenLayers.Layer.Vector('BBox', {
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
      map.addLayer(bbox);
      
      bboxLayersCtl = new OpenLayers.Control.SelectFeature([bbox], { 
        onSelect: createBBoxPopup, 
        onUnselect: vlUtils.destroyPopup,
      });
      map.addControl(bboxLayersCtl);
      bboxLayersCtl.activate();
      
      //map.zoomToExtent(bbox.getDataExtent());
      OpenLayers.Request.GET(requestConf['bbox']);
    } else {
      OpenLayers.Request.GET(requestConf['site']);
    }
  }

  function bboxHandler(request) {
    if(request.status == 200) {
      bboxXml = request.responseXML;
      coords = vlUtils.getXmlValue(bboxXml, 'coordinates').split(/[, ]+/);
      bbx = [181,91,-181,-91];
      for(i=0; i<coords.length; i+=2) {
        if(coords[i] < bbx[0]) { bbx[0] = coords[i]; } //W
        if(coords[i] > bbx[2]) { bbx[2] = coords[i]; } //E
        if(coords[i+1] < bbx[1]) { bbx[1] = coords[i+1]; } //S
        if(coords[i+1] > bbx[3]) { bbx[3] = coords[i+1]; } //N
      }
      mapBounds = new OpenLayers.Bounds(bbx);
      map.zoomToExtent(mapBounds.transform(map.displayProjection, map.projection));
    }
  }

  function layerHandler(request) {
    if(request.status == 200) {
      layerXml = request.responseXML;
      y = '<ol>';
      links = layerXml.getElementsByTagName('layer');
      for(i=0; i<links.length; i++) {
         if(links[i].getAttribute('disabled') || links[i].getAttribute('type') != 'tms'){ continue; }
         y += '<li><a href="?site=' 
           + reqParams['site'] + '&year='
           + links[i].getAttribute('year') + '">'
           + links[i].getAttribute('year') + '</a></li>';
      }
      y += '</ol>';
      document.getElementById('content').innerHTML = y;
      document.getElementById('header').innerHTML += siteLbl;
      document.getElementById('footer').innerHTML = document.getElementById('header').innerHTML;
    } else {
      OpenLayers.Request.GET(requestConf['selector']);
    }
  }

  function selectorHandler(request) {
    if(request.status == 200) {
      selectorXml = request.responseXML;
      y = '<ol>';
      links = selectorXml.getElementsByTagName('name');
      for(i=0; i<links.length; i++) {
         y += '<li><a href="?site=' + links[i].childNodes[0].nodeValue 
           + '">' + links[i].childNodes[0].nodeValue + '</a></li>';
      }
      y += '</ol>';
      document.getElementById('content').innerHTML = y;
      document.getElementById('footer').innerHTML = document.getElementById('header').innerHTML;
    }
  }

  OpenLayers.Request.GET({ url: "conf.xml", callback: xmlHandlerConf });
}
