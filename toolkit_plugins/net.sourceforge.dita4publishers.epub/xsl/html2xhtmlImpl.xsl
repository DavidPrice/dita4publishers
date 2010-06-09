<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs xd"
  version="2.0">
  <!-- Transform unnamespaced HTML docs into namespaced XHTML docs are required by the epub spec. 
  
       Also cleans up anything generated by the base Toolkit HTML transforms that is not allowed
       in ePub XHTML.
      -->
  
  <xsl:template match="html | HTML" mode="html2xhtml" priority="10">
    <html>
      <xsl:apply-templates mode="#current"/>
    </html>
  </xsl:template>
  
  <xsl:template mode="html2xhtml" match="img[not(@alt)]">
    <xsl:element name="{name(.)}">
      <xsl:attribute name="alt" select="@src"/>
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <!-- <a> elements used for IDs are not used in XHTML -->
  <xsl:template match="a[@name and not(@href)]" priority="10" mode="html2xhtml"/>
  
  <xsl:template mode="html2xhtml" match="*">
    <xsl:element name="{name(.)}">
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@lang" priority="10"/>
  
  <xsl:template mode="html2xhtml" match="@*|text()|processing-instruction()|comment()">
    <xsl:copy-of select="."/>
  </xsl:template>
</xsl:stylesheet>
