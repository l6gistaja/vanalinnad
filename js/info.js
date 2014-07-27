function vlInitInfo(inputParams){

  var map;
  var osm;
  var conf;
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
      	}
      };
      if(reqParams['site'].match(/\S/)) {
	    key = reqParams['year'].match(new RegExp(conf.regexyearmatcher)) || 
              reqParams['year'].match(new RegExp('^[A-Za-z_]+$')) ? 'year' : 'site';
      } else { key = 'selector'; }
      OpenLayers.Request.GET(requestConf[key]);
    }
  }

  function osm_getTileURL(bounds) {
      return vlUtils.getTodaysTileURL(osm, bounds);
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
          y += '<hr/><a name="map.'+mapAnchor+'"><a href="#map.'+mapAnchor+
            '"><strong>'+mapAnchor+'</strong></a></a><br/>';
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
              + '"/>';
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
          y += '<li><a href="' 
            + links[i].childNodes[0].nodeValue + '">'
            + links[i].childNodes[0].nodeValue + '</a></li>';
        }
        y += '</ol>';

      }
      
      y += '<a name="bbox"><a href="'+requestConf.bbox.url+'">BBox &amp; GCP</a></a><div id="map" style="height:400px;width:600px;"></div>';
      document.getElementById(inputParams.divHeader).innerHTML += siteLbl + ' &gt; ' 
        + '<a href="index.html?site=' + reqParams['site'] 
        + '&year=' + reqParams['year'] + '">' + reqParams['year'] + '</a>';
      document.getElementById(inputParams.divContent).innerHTML = y;
      document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;

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
      bbox.events.register('loadend', bbox, function(){map.zoomToExtent(bbox.getDataExtent());});
      map.addLayer(bbox);

      bboxLayersCtl = new OpenLayers.Control.SelectFeature([bbox], { 
        onSelect: createBBoxPopup, 
        onUnselect: vlUtils.destroyPopup
      });
      map.addControl(bboxLayersCtl);
      bboxLayersCtl.activate();

    } else {
      OpenLayers.Request.GET(requestConf['site']);
    }
  }

  function layerHandler(request) {
    if(request.status == 200) {
      layerXml = request.responseXML;
      y = '<br/><a href="index.html?site=' + reqParams['site'] + '">' + reqParams['site'] + '</a><ol>';
      links = layerXml.getElementsByTagName('layer');
      for(i=0; i<links.length; i++) {
         if(links[i].getAttribute('disabled') || !links[i].hasAttribute('year')){ continue; }
         y += '<li><a href="?site=' 
           + reqParams['site'] + '&year='
           + links[i].getAttribute('year') + '">'
           + links[i].getAttribute(links[i].getAttribute('name') ? 'name' : 'year') + '</a></li>';
      }
      y += '</ol>';
      document.getElementById(inputParams.divContent).innerHTML = y;
      document.getElementById(inputParams.divHeader).innerHTML += siteLbl;
      document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;
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
      document.getElementById(inputParams.divContent).innerHTML = y;
      document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;
    }
  }

  OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
}
