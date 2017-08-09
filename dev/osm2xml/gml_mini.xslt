<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:o="http://www.openstreetmap.org/gml/"
  xmlns:g="http://www.opengis.net/gml" version="1.0"
  xmlns:osm="http://www.openstreetmap.org/gml/"
  xmlns:gml="http://www.opengis.net/gml">

<xsl:output method="xml"/>
<xsl:output indent="yes"/>
<xsl:output encoding="UTF-8"/>

<xsl:template match="/">
<o:FeatureCollection>
<xsl:for-each select="osm:FeatureCollection/gml:featureMember">
<xsl:if test="not(osm:way/osm:building) and not(osm:way/osm:bicycle) and osm:way/osm:geometryProperty/gml:LineString and osm:way/osm:name and osm:way/osm:name != '' and substring(osm:way/osm:highway, string-length(osm:way/osm:highway) - 4) != '_link' and not(contains('steps,footway,path,track,trunk,cycleway,platform,residential,proposed', osm:way/osm:highway))">
<g:featureMember>
<o:w fid="{osm:way/@fid}">
  <o:n><xsl:value-of select="osm:way/osm:name"/></o:n>
  <o:g>
      <g:LineString>
        <g:coordinates><xsl:value-of select="osm:way/osm:geometryProperty/gml:LineString/gml:coordinates"/></g:coordinates>
      </g:LineString>
  </o:g>
</o:w>
</g:featureMember>
</xsl:if>
</xsl:for-each>
</o:FeatureCollection>
</xsl:template>

</xsl:stylesheet>

