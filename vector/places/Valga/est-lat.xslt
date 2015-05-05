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

<!--
<xsl:for-each select="osm:FeatureCollection/gml:featureMember">
<Placemark>
<name><xsl:value-of select="osm:way/@fid"/></name>
<color>#0044FF</color>
<LineString><coordinates><xsl:value-of select="osm:way/osm:geometryProperty/gml:LineString/gml:coordinates"/></coordinates></LineString>
</Placemark>
</xsl:for-each>
-->

<Placemark>
<name>&lt;a href="http://en.wikipedia.org/wiki/Estonia" target="_blank"&gt;Eesti&lt;/a&gt; / &lt;a href="http://en.wikipedia.org/wiki/Latvia" target="_blank"&gt;Latvija&lt;/a&gt;</name>
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