function getXmlValue(xmlDocument, tagname) {
  index = (arguments.length > 2 ) ? arguments[2] : 0 ;
  tags = xmlDocument.getElementsByTagName(tagname);
  return index < tags.length && tags[index].childNodes.length > 0 ? tags[index].childNodes[0].nodeValue : '';
}