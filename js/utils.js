function getXmlValue(xmlDocument, tagname) {
  index = (arguments.length > 2 ) ? arguments[2] : 0 ;
  return xmlDocument.getElementsByTagName(tagname)[index].childNodes[0].nodeValue;
}