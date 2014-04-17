<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:osm="http://www.openstreetmap.org/gml/"
  xmlns:gml="http://www.opengis.net/gml">

<xsl:output method="xml"/>
<xsl:output indent="yes"/>
<xsl:output encoding="UTF-8"/>

<xsl:template match="/">
<f>
<xsl:for-each select="osm:FeatureCollection/gml:featureMember">
<xsl:if test="not(osm:way/osm:building) and osm:way/osm:geometryProperty/gml:LineString and osm:way/osm:name and osm:way/osm:name != '' and substring(osm:way/osm:highway, string-length(osm:way/osm:highway) - 4) != '_link' and not(contains('steps,footway,path,track,cycleway,platform', osm:way/osm:highway))">
<w n="{osm:way/osm:name}" h="{osm:way/osm:highway}" g="{osm:way/osm:geometryProperty/gml:LineString/gml:coordinates}"/>
<!-- i="{osm:way/@fid}" t="{osm:way/osm:timestamp}" -->
</xsl:if>
</xsl:for-each>
</f>
</xsl:template>

</xsl:stylesheet>

