<?xml version="1.0" encoding="UTF-8"?>
<!--
Version 0.2 by Stefan Keller, http://geoconverter.hsr.ch
Original version by Schuyler Erle.
Based on OSM REST API 0.5.
/-->
<xsl:stylesheet xmlns="http://osm.maptools.org/"
  xmlns:osm="http://www.openstreetmap.org/gml/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:gml="http://www.opengis.net/gml" version="1.0">
<xsl:output method="xml"/>
<xsl:output indent="yes"/>

<xsl:template match="/">
  <xsl:text>
</xsl:text>
  <osm:FeatureCollection>
    <xsl:for-each select="/osm/way">
      <xsl:call-template name="way"/>
    </xsl:for-each>
    <xsl:text>

</xsl:text>
  </osm:FeatureCollection>
</xsl:template>

<xsl:template match="/osm/way" name="way">
  <xsl:text>

</xsl:text>
  <gml:featureMember>
    <osm:way fid="{@id}">
      <osm:id><xsl:value-of select="@id"/></osm:id>
      <osm:timestamp><xsl:value-of select="@timestamp"/></osm:timestamp>
      <osm:user><xsl:value-of select="@user"/></osm:user>
      <osm:geometryProperty>
        <gml:LineString>
          <gml:coordinates><xsl:apply-templates select="nd"/></gml:coordinates>
        </gml:LineString>
      </osm:geometryProperty>
      <xsl:apply-templates select="tag"/>
    </osm:way>
  </gml:featureMember>
</xsl:template>

<xsl:key name='nodeById' match='/osm/node' use='@id'/>

<xsl:template match="/osm/way/nd">
  <xsl:variable name='ref' select="@ref"/>
  <xsl:variable name='node' select='key("nodeById",$ref)'/>
  <xsl:value-of select="$node/@lon"/>,<xsl:value-of select="$node/@lat"/>
  <xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="/osm/way/tag">
  <xsl:variable name="osm_element" select="translate(@k, translate(@k, 'aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_-.0123456789', ''), '_')"/>
  <!-- xsl:variable name="osm_element" select="@k"/ -->
  <xsl:if test="string($osm_element)">
    <xsl:element name="osm:{$osm_element}">
      <xsl:value-of select="@v"/>
    </xsl:element>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>