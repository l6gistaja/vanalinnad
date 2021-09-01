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
  var jsonConf = {};
  var componentsRegexp = {};
  
  function getSiteLbl() {
    baseURL = '?site=' + reqParams['site'] + ('debug' in reqParams ? '&debug=' + reqParams['debug'] : '');
    baseYear = baseURL + '&year=';
    debugLinks = '';
    if('debug' in reqParams) {
        debugLinks = '<div style="background-color:#ccffcc;padding:1em">Manually refresh: <ol>';
        debugURLs = [
            'conf.xml',
            'js/',
            conf.dirlegends + conf.dirplaces + reqParams['site'],
            conf.dirvector + conf.dirplaces + reqParams['site'],
            conf.dirvector + conf.dirplaces + reqParams['site'] + '/' + conf.fileemptytiles,
            conf.dirvector + conf.dirplaces + reqParams['site'] + '/' + conf.filelayers
        ];
        //debugLinks
        for(i in debugURLs) {
            debugLinks += '<li>'+vlUtils.link({t:'_blank',u:debugURLs[i]})+'</li>'
        }
        debugLinks += '</ol></div>';
    }
    return ' : ' + vlUtils.link({u:baseURL, l:siteName})
      + (level != 'year' ? ''
        : ' : ' + vlUtils.link({u:baseYear + years[0], l:'&lt;&lt;', h:years[0]})
        + ' ' + vlUtils.link({u:'index.html' + baseYear + reqParams['year'], l:reqParams['year'], h:'See map itself'})
        + ' ' + vlUtils.link({u:baseYear + years[1], l:'&gt;&gt;', h:years[1]}))
      + debugLinks;
  }
  
  function xmlHandlerConf(request) {
    if(request.status == 200) {
        
      if('debug' in reqParams) {
        items = document.getElementsByTagName('a');
        for(m=0;m<items.length;m++) { items[m].setAttribute("href", items[m].getAttribute("href") + '?debug=' + reqParams['debug']); }
      }
      
      if(!('year' in reqParams)) { reqParams['year'] = ''; }
      conf = vlUtils.xmlDoc2Hash(request.responseXML);
      jsonConf = JSON.parse(conf.json);
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
  
  function bBoxPopupTrunc(x) { return Math.trunc(1000000*x)/1000000; }
  
  function bBoxPopupAnchor(x) {
      a = x;
      for(anchor in componentsRegexp) {
          cre = new RegExp(componentsRegexp[anchor]);
          if(cre.test(x)) {
              a = anchor;
              break;
          }
      }
      return ' <a href="#map.' + a + '">' + x + '</a>';
  }
  
  function createBBoxPopup(feature) {
    if(feature.fid.substring(0, 4) == 'bbox') {
        bounds = new OpenLayers.Bounds(feature.geometry.bounds.toArray()).transform(map.projection, map.displayProjection);
        feature.popup = new OpenLayers.Popup.Anchored(
            "bboxPopup",
            map.getCenter(),
            null,
            '<strong>BBox' 
                + ( feature.attributes.name == null ? '' : bBoxPopupAnchor(feature.attributes.name) )
                + '</strong><br/>W '
                + bBoxPopupTrunc(bounds.left) + ' <br/>S '
                + bBoxPopupTrunc(bounds.bottom) + ' <br/>E '
                + bBoxPopupTrunc(bounds.right) + ' <br/>N '
                + bBoxPopupTrunc(bounds.top),
            null,
            true,
            function() { bboxLayersCtl.unselectAll(); }
        );
        feature.popup.setBorder('solid 2px black');
        feature.popup.autoSize = true;
    } else {
        center = new OpenLayers.LonLat(feature.geometry.getBounds().getCenterLonLat().lon, feature.geometry.getBounds().getCenterLonLat().lat).transform(map.projection, map.displayProjection);
        nameParts = feature.attributes.name.split(' ');
        feature.popup = new OpenLayers.Popup.FramedCloud(
            "bboxPopup",
            feature.geometry.getBounds().getCenterLonLat(),
            null,
            '<strong>GCP'
                + (nameParts.length == 2 
                    ? bBoxPopupAnchor(nameParts[0]) + ' ' + nameParts[1]
                    : ' ' + feature.attributes.name)
                +'</strong><br/>'
                + bBoxPopupTrunc(center.lon) + '&nbsp;&nbsp;'
                + bBoxPopupTrunc(center.lat)
                + ('debug' in reqParams
                    ? ' <br/><input type="text" value=" -gcp ' 
                        + feature.attributes.description + ' '
                        + bBoxPopupTrunc(center.lon) + ' '
                        + bBoxPopupTrunc(center.lat) 
                        + '"/>'
                    : ''),
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
      window.document.title += ' ' + reqParams['year'];
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

        if(vlUtils.getXmlValue(items[m], 'deleted') == '1') { continue; }
            
        dateParts = vlUtils.getXmlValue(items[m], 'pubDate').split(/\s+/);
        pubYear = (dateParts.length > 3) ? dateParts[3] : '';
        mapAnchor =  (vlUtils.getXmlValue(items[m], 'anchor') != '') ? vlUtils.getXmlValue(items[m], 'anchor') : pubYear;
        if(mapAnchor == '') { mapAnchor = String.fromCharCode(65 + m); }
        y += items.length > 1
            ? '<hr/><a name="map.'+mapAnchor+'">'+ vlUtils.link({u:'#map.'+mapAnchor, l:'<strong>'+mapAnchor+'</strong>'}) + '</a><br/>'
            : '<a name="map.'+mapAnchor+'"> </a>';

        componentRegexp = vlUtils.getXmlValue(items[m], 'componentsregexp');
        if(componentRegexp != '') { componentsRegexp[mapAnchor] = componentRegexp; }
        var mapTitle = siteName + ' ' + mapAnchor;
        
        // legends
        if(items[m].getElementsByTagName('legends').length) {
          legends = vlUtils.getXmlValue(items[m], 'legends').split(',');
          for(i=0; i<legends.length; i++) {
            if(legends[i] == '') { continue; }
            y += ( i > -1 ? '<br/>' : '' )
              + '<a href="#L.'+legends[i]+'">'
              + '<img src="'
              + (legends[i].indexOf('/') == -1
                ? conf.dirlegends + conf.dirplaces + reqParams['site'] + '/' + legends[i]
                : legends[i] )
              + '" title="Legend '
              + mapTitle
              + ' #'+(i+1)
              +'" id="L.'+legends[i]+'"/></a>';
          }
        }

        // texts
        for(i in itemFields) {
          tmp = vlUtils.getXmlValue(items[m], itemFields[i].tag, 0);
          if(itemFields[i].tag == 'title') {
            tmp = '<a href="#D.' + mapAnchor + '" id="D.' + mapAnchor + '" class="hashLnk" title="Description ' + mapTitle + '">' + tmp + '</a>';
          }
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
          y += '<li>' + vlUtils.link({u: links[i].childNodes[0].nodeValue, l: decodeURIComponent(links[i].childNodes[0].nodeValue)}) + '</li>';
        }
        y += '</ol>';

      }
      
      y += '<a href="#infoMap" class="hashLnk">↓</a> ' + vlUtils.link({u:requestConf.bbox.url, l:'BBox &amp; GCP'})
        + ' ; ↑ ' + vlUtils.link({u:requestConf.year.url, l:'RSS'})
        + '<div id="infoMap"></div>';
      document.getElementById(inputParams.divHeader).innerHTML += getSiteLbl();
      document.getElementById(inputParams.divContent).innerHTML = y;
      document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;
      
      // anchors wont work otherwise, as content is dynamically generated
      if (location.hash) {
        var requested_hash = location.hash.slice(1);
        location.hash = '';
        location.hash = requested_hash;
      }

      map = new OpenLayers.Map('infoMap', jsonConf.mapoptions);

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
            styleMap: vlUtils.mergeCustomStyleWithDefaults(jsonConf.olLayerStyles['BBox'])
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
      var automaticCtls = vlUtils.mapMapUI({map: map, add: ['OpenLayers.Control.LayerSwitcher']});
      automaticCtls['OpenLayers.Control.LayerSwitcher'].maximizeControl();
      map.setBaseLayer(histBaseLayer);
  }

  function layerHandler(request) {
    if(request.status == 200) {
      layerXml = request.responseXML;
      siteName = vlUtils.getXmlValue(layerXml, 'city');
      window.document.title += ': ' + siteName;
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
        var bbx = vlUtils.getXmlValue(layerXml, 'bounds').split(',');
        var locData = {
          X: (parseFloat(bbx[0]) + parseFloat(bbx[2])) / 2,
          Y: (parseFloat(bbx[1]) + parseFloat(bbx[3])) / 2,
          Z: vlUtils.getXmlValue(layerXml, 'minzoom'),
          T: vlUtils.getXmlValue(layerXml, 'city'),
          C: vlUtils.getXmlValue(layerXml, 'country'),
          site: reqParams['site'],
          baseUrlID: 'vanalinnad',
          delimiter: '</li><li>'
        };        
        
        var w;
        var urlKeys = ['wikipedia','ajapaik','geohack'];
        for(w in jsonConf.urls) {
          if('type' in jsonConf.urls[w] && jsonConf.urls[w].type == 'WMS') { urlKeys[urlKeys.length] = w; }
        }
        var siteConf = vlUtils.getXmlValue(layerXml, 'json');
        if(siteConf != '') {
          siteConf = JSON.parse(siteConf);
          if('urls' in siteConf) {
            for(w in siteConf.urls) {
              jsonConf.urls[w] = siteConf.urls[w];
              urlKeys[urlKeys.length] = w;
            }
          }
        }

        y = '<br/><strong>' + vlUtils.link({u:'index.html?site=' + reqParams['site'] + ('debug' in reqParams ? '&debug=' + reqParams['debug'] : ''), l:siteName})
          + '</strong><div class="Table"><div class="Row"><div class="Cell"><ol>';
        for(i=0; i<links.length; i++) {
          if(links[i].getAttribute('disabled') || links[i].getAttribute('year') == null){ continue; }
          y += '<li>' + vlUtils.link({
            u: '?site=' + reqParams['site'] + '&year='+ links[i].getAttribute('year') + ('debug' in reqParams ? '&debug=' + reqParams['debug'] : ''),
            l: links[i].getAttribute(links[i].getAttribute('name') ? 'name' : 'year')
          })  + '</li>';
        }
        y += '</ol></div><div class="Cell"><ol type="A"><li>' + vlUtils.getURLs(urlKeys, locData, jsonConf)
          + '</li></ol></div></div></div>';
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
        y +=  '<li>' + vlUtils.link({u:'?site=' + (descr != '' ? descr : name) + ('debug' in reqParams ? '&debug=' + reqParams['debug'] : ''), l:name}) + '</li>';
      }
      y += '</ol>';
      document.getElementById(inputParams.divContent).innerHTML = y;
      document.getElementById(inputParams.divFooter).innerHTML = document.getElementById(inputParams.divHeader).innerHTML;
    }
  }

  OpenLayers.Request.GET({ url: inputParams.conf, callback: xmlHandlerConf });
}
