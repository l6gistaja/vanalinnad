<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:osm="http://www.openstreetmap.org/gml/"
  xmlns:gml="http://www.opengis.net/gml">

<xsl:output method="xml"/>
<xsl:output indent="no"/>
<xsl:output encoding="UTF-8"/>

<xsl:template match="/">
<kml xmlns="http://earth.google.com/kml/2.2">
<Document>

<Placemark>
<name>&lt;a href="http://et.wikipedia.org/wiki/Narva_veehoidla" target="_blank"&gt;Narva veehoidla&lt;/a&gt; / &lt;br /&gt;&lt;a href="https://ru.wikipedia.org/wiki/%D0%9D%D0%B0%D1%80%D0%B2%D1%81%D0%BA%D0%BE%D0%B5_%D0%B2%D0%BE%D0%B4%D0%BE%D1%85%D1%80%D0%B0%D0%BD%D0%B8%D0%BB%D0%B8%D1%89%D0%B5" target="_blank"&gt;Нарвское водохранилище&lt;/a&gt;</name>
<color>#0044FF</color>
<MultiGeometry>
<xsl:for-each select="osm:FeatureCollection/gml:featureMember">
<xsl:if test="osm:way/osm:geometryProperty/gml:LineString and not(osm:way/osm:highway) and not(osm:way/osm:waterway) and not(osm:way/osm:wood) and not(osm:way/osm:cables) and not(osm:way/osm:admin_level) and not(osm:way/osm:place) and not(osm:way/osm:wetland) and not(osm:way/osm:building) and not(osm:way/osm:power) and not(osm:way/osm:leisure) and not(osm:way/osm:barrier) and not(osm:way/osm:source_zoomlevel) and not(osm:way/osm:railway) and not(osm:way/osm:landuse) and not(osm:way/osm:natural and contains('wood,scrub,wetland', osm:way/osm:natural)) and not(osm:way/osm:source and contains(osm:way/osm:source,'Corine')) and not(contains('34600934,264633671,45487837,45531137,141101735,40169961,40181176,40181176,287935773,248270589,248270587,233276228', osm:way/@fid))">
<LineString><coordinates><xsl:value-of select="osm:way/osm:geometryProperty/gml:LineString/gml:coordinates"/></coordinates></LineString>
</xsl:if>
</xsl:for-each>
</MultiGeometry>
</Placemark>

<Placemark>
<name>&lt;a href="http://en.wikipedia.org/wiki/Estonia" target="_blank"&gt;Eesti&lt;/a&gt; / &lt;a href="http://en.wikipedia.org/wiki/Russia" target="_blank"&gt;Россия&lt;/a&gt;</name>
<color>#9C069C</color>
<MultiGeometry>
<xsl:for-each select="osm:FeatureCollection/gml:featureMember">
<xsl:if test="osm:way/osm:admin_level=2">
<LineString><coordinates><xsl:value-of select="osm:way/osm:geometryProperty/gml:LineString/gml:coordinates"/></coordinates></LineString>
</xsl:if>
</xsl:for-each>
</MultiGeometry>
</Placemark>

</Document>
</kml>
</xsl:template>

</xsl:stylesheet>