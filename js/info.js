function vlInitInfo(){

  var map;
  var osm;
  var confXml;
  var rssXml;
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
           url: getXmlValue(confXml, 'dirvector')
             + getXmlValue(confXml, 'dirplaces')
             + reqParams['site']
             + '/rss'
             + reqParams['year']
             + '.xml',
           callback: rssHandler
        },
        site: {
           url: getXmlValue(confXml, 'dirvector')
             + getXmlValue(confXml, 'dirplaces')
             + reqParams['site']
             + '/'
             + getXmlValue(confXml, 'filelayers'),
           callback: layerHandler
        },
	selector: {
           url: getXmlValue(confXml, 'dirvector')
             + getXmlValue(confXml, 'fileareaselector'),
           callback: selectorHandler
      	}
      };
      if(reqParams['site'].match(/\S/)) {
	key = reqParams['year'].match(new RegExp(getXmlValue(confXml, 'regexyearmatcher'))) ? 'year' : 'site';
      } else { key = 'selector'; }
      OpenLayers.Request.GET(requestConf[key]);
    }
  }

  function osm_getTileURL(bounds) {
      return getTileURL(osm, bounds);
  }

  function rssHandler(request) {
    if(request.status == 200) {
      rssXml = request.responseXML;
      y = '';
      if(rssXml.getElementsByTagName('legends').length) {
        legends = getXmlValue(rssXml, 'legends').split(',');
        for(i=0; i<legends.length; i++) {
          y += '<br/><img src="'
             + getXmlValue(confXml, 'dirraster')
             + getXmlValue(confXml, 'dirplaces')
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
        tmp = getXmlValue(rssXml, itemFields[i].tag, 'no' in itemFields[i] ? itemFields[i].no : 0);
	if(itemFields[i].tag == 'author') {
          dateParts = getXmlValue(rssXml, 'pubDate').split(/\s+/);
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
      y += '</ol><div id="map" style="height:400px;width:600px;"></div>';
      document.getElementById('header').innerHTML += siteLbl + ' &gt; ' 
        + '<a href="index.html?site=' + reqParams['site'] 
        + '&year=' + reqParams['year'] + '">' + reqParams['year'] + '</a>';
      document.getElementById('content').innerHTML = y + document.getElementById('header').innerHTML;

      map = new OpenLayers.Map('map', {
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326"),
        units: "m"
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
                url: getXmlValue(confXml, 'dirvector')
                      + getXmlValue(confXml, 'dirplaces')
                      + reqParams['site'] + '/bbox'
                      + reqParams['year'] + '.kml',
                format: new OpenLayers.Format.KML({
                    extractAttributes: true,
                    maxDepth: 0
                })
            })
      });
      map.addLayer(bbox);
      //map.zoomToExtent(bbox.getDataExtent().transform(map.displayProjection, map.projection));
    } else {
      OpenLayers.Request.GET(requestConf['site']);
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
      y += '</ol><a href="index.html">Maps</a> | <a target="_blank" href="readme.html">Readme</a> | <a href="https://github.com/l6gistaja/vanalinnad">GitHub</a>';
      document.getElementById('content').innerHTML = y;
    }
  }

  OpenLayers.Request.GET({ url: "conf.xml", callback: xmlHandlerConf });
}
