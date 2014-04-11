if (!vlUtils) {
    var vlUtils = {};
}


vlUtils.getXmlValue = function(xmlDocument, tagname) {
  index = (arguments.length > 2 ) ? arguments[2] : 0 ;
  tags = xmlDocument.getElementsByTagName(tagname);
  return index < tags.length && tags[index].childNodes.length > 0 ? tags[index].childNodes[0].nodeValue : '';
}

/**
  * Merge custom StyleMap-like hash with default styles
  *
  * Example: to make points in Layer's (default style)
  * red, add following to constructor's options hash:
  * styleMap: mergeCustomStyleWithDefaults({default: {fillColor: "red"}})
  *
  * @param {hash} customStyle
  * @returns OpenLayers.StyleMap
  */
vlUtils.mergeCustomStyleWithDefaults = function(customStyle) {
    styleMap = {};
    for(styleKey in OpenLayers.Feature.Vector.style) {
        styleMap[styleKey] = OpenLayers.Util.applyDefaults(
            styleKey in customStyle ? customStyle[styleKey] : {},
            OpenLayers.Feature.Vector.style[styleKey]
        );
    }
    return new OpenLayers.StyleMap(styleMap);
}


vlUtils.getTodaysTileURL = function(layer, bounds) {
    var res = layer.map.getResolution();
    var x = Math.round((bounds.left - layer.maxExtent.left) / (res * layer.tileSize.w));
    var y = Math.round((layer.maxExtent.top - bounds.top) / (res * layer.tileSize.h));
    var z = layer.map.getZoom();
    var limit = Math.pow(2, z);
    if (y < 0 || y >= limit) {
        return 'raster/none.png';
    } else {
        x = ((x % limit) + limit) % limit;
        return layer.url + z + "/" + x + "/" + y + "." + layer.type;
    }
}

vlUtils.destroyPopup = function(feature) {
  feature.popup.destroy();
  feature.popup = null;
}

vlUtils.xmlDoc2Hash = function(xmlDoc) {
  y = {};
  x = xmlDoc.documentElement.childNodes;
  for (i=0;i<x.length;i++) {
    if(x[i].childNodes.length < 1) { continue; }
    y[x[i].nodeName] = x[i].childNodes[0].nodeValue;
  }
  return y;
}
