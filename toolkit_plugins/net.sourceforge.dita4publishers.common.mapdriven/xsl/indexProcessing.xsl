<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:df="http://dita2indesign.org/dita/functions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:relpath="http://dita2indesign/functions/relpath"
                xmlns:index-terms="http://dita4publishers.org/index-terms"
                xmlns:htmlutil="http://dita4publishers.org/functions/htmlutil"                
                xmlns:local="urn:functions:local"
                exclude-result-prefixes="local xs df xsl relpath index-terms htmlutil"
  >
  <!-- =============================================================
    
    DITA Map to HTML Transformation
    
    Back-of-the-book index generation. This transform generates the HTML markup
    for a back-of-the-book index reflecting the index entries in the map and
    topic set.
    
    NOTE: This functionality is not completely implemented.
    
    Copyright (c) 2010, 2011 DITA For Publishers
    
    Licensed under Common Public License v1.0 or the Apache Software Foundation License v2.0.
    The intent of this license is for this material to be licensed in a way that is
    consistent with and compatible with the license of the DITA Open Toolkit.
    
    This transform requires XSLT 2.
    ================================================================= -->    
  
  <xsl:import href="../../net.sourceforge.dita4publishers.common.xslt/xsl/lib/dita-support-lib.xsl"/>
  <xsl:import href="../../net.sourceforge.dita4publishers.common.xslt/xsl/lib/relpath_util.xsl"/>
  
  <xsl:import href="../../net.sourceforge.dita4publishers.common.xslt/xsl/lib/html-generation-utils.xsl"/>

  <xsl:template match="index-terms:index-terms" mode="group-and-sort-index">
    
    <xsl:message> + [DEBUG] group-and-sort-index: index-terms...</xsl:message>
    
    <!-- Group first-level terms by index group -->
    <!-- FIXME: Implement usual index grouping localization and configuration per
         I18N library. 
      -->
    <xsl:for-each-group select="index-terms:index-term"
      group-by="./@grouping-key"
      >
      <xsl:sort select="./@sorting-key"/>
      <xsl:message> + [DEBUG] Index group "<xsl:sequence select="local:construct-index-group-label(current-group()[1])"
      />", grouping key: "<xsl:sequence select="current-grouping-key()"
      />", sort key: "<xsl:sequence select="local:construct-index-group-sort-key(.)"
      />"</xsl:message>
      <index-terms:index-group 
        grouping-key="{current-grouping-key()}"
        sorting-key="{@sorting-key}"
        >
        <index-terms:label><xsl:sequence select="local:construct-index-group-label(current-group()[1])"/></index-terms:label>
        <!-- At this point, the current group is all entries within the group. 
          
          Now group entries by primary term.
        -->
        <index-terms:sub-terms>
          <xsl:call-template name="process-index-terms">
            <xsl:with-param name="index-terms" as="node()*" select="current-group()"/>
            <xsl:with-param name="term-depth" as="xs:integer" select="1"/>
          </xsl:call-template>
        </index-terms:sub-terms>
      </index-terms:index-group>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template name="process-index-terms">
    <!-- Given a group of index terms, process each group. -->
    <xsl:param name="index-terms" as="node()*"/>
    <xsl:param name="term-depth" as="xs:integer"/>
    
    <xsl:for-each-group select="$index-terms" 
      group-by="@grouping-key">
      <xsl:sort select="@sorting-key"/>
      <!-- Each group is all the entries for a given term key -->
      <xsl:variable name="firstTerm" select="current-group()[1]" as="element()"/>
      <xsl:if test="$term-depth > 3">
        <xsl:message> - [WARNING] Index entry is more than 3 levels deep: <xsl:value-of select="index-terms:label"/></xsl:message>
      </xsl:if>
      <xsl:message> + [DEBUG] group-and-sort-index: index term level <xsl:sequence select="$term-depth"/>: "<xsl:value-of select="index-terms:label"/></xsl:message>
      <index-terms:index-term 
        grouping-key="{@grouping-key}"
        sorting-key="{@sorting-key}"
        >
        <index-terms:label><xsl:apply-templates select="$firstTerm/index-terms:label" mode="#current"/></index-terms:label>
        <xsl:if test="current-group()/index-terms:target">
          <index-terms:targets>
            <xsl:sequence select="current-group()/index-terms:target"/>
          </index-terms:targets>
        </xsl:if>
        <index-terms:sub-terms>
          <xsl:call-template name="process-index-terms">
            <xsl:with-param name="index-terms" as="node()*" select="current-group()/index-terms:index-term"/>
            <xsl:with-param name="term-depth" select="$term-depth + 1" as="xs:integer"/>
          </xsl:call-template>
        </index-terms:sub-terms>
      </index-terms:index-term>
    </xsl:for-each-group>    
  </xsl:template>
  
  <xsl:template match="index-terms:label" mode="group-and-sort-index">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template mode="gather-index-terms" 
    match="*[df:class(.,'map/topicmeta')] | *[df:class(., 'topic/topic')]">
    <xsl:apply-templates 
      select=".//*[df:class(.,'topic/indexterm')]" mode="generate-index"/>
  </xsl:template>
  
  <xsl:template mode="gather-index-terms" 
    match="*[df:class(.,'topic/indexterm')]"> 
    <xsl:param name="targetUri" as="xs:string" tunnel="yes"/>
    
    <xsl:variable name="labelContent" as="node()*">
      <xsl:apply-templates select="*[not(df:class(., 'topic/indexterm')) and 
        not(df:class(., 'topic/index-see')) and 
        not(df:class(., 'topic/index-seealso'))] | 
        text()" mode="index-term-label"/>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="normalize-space(string-join($labelContent, '')) = '' and not(./*)">
        <xsl:message> + [INFO] Skipping empty <xsl:sequence select="name(.)"/> element in <xsl:sequence select="string(@xtrf)"/>...</xsl:message>
      </xsl:when>
      <xsl:when test="normalize-space(string-join($labelContent, '')) = '' and ./*">
        <xsl:message> - [WARN] Empty index entry label for index entry with child elements in <xsl:sequence select="string(@xtrf)"/></xsl:message>
        <xsl:message> - [WARN]   Entry: <xsl:apply-templates mode="report-element" select="."/></xsl:message>
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:otherwise>        
        <xsl:variable name="grouping-key" 
          select="if (parent::*[df:class(., 'topic/indexterm')]) 
          then local:construct-index-term-grouping-key($labelContent)
          else local:construct-index-group-key($labelContent)" as="xs:string"/>
        <xsl:variable name="sorting-key" select="if (parent::*[df:class(., 'topic/indexterm')])
          then local:construct-index-term-sorting-key($labelContent)
          else local:construct-index-group-sort-key($labelContent)" as="xs:string"/>
        <xsl:message> + [DEBUG] gather-index-terms: grouping-key="<xsl:sequence select="$grouping-key"/>"</xsl:message>        
        <xsl:message> + [DEBUG] gather-index-terms: sorting-key= "<xsl:sequence select="$sorting-key"/>"</xsl:message>        
        <index-terms:index-term
          grouping-key="{$grouping-key}"
          sorting-key="{$sorting-key}"
          item-id="{generate-id()}"
          >
          <index-terms:label><xsl:sequence select="$labelContent"/></index-terms:label>
          <index-terms:target target-uri="{$targetUri}">
            <xsl:sequence select="."/><!-- Make the original index term available -->
          </index-terms:target>
          <!--<xsl:message> + [DEBUG] Handling nested index terms...</xsl:message>-->
          <xsl:apply-templates select="*[df:class(., 'topic/indexterm')]" mode="#current"/>
          <!--<xsl:message> + [DEBUG] Nested index terms handled.</xsl:message>-->
        </index-terms:index-term>
      </xsl:otherwise>
    </xsl:choose>
    
    
  </xsl:template>
  
  <xsl:template match="text()" mode="gather-index-terms" priority="-1"/>    

  <xsl:template match="text()" mode="index-term-label"
  >
    <xsl:sequence select="."></xsl:sequence>
    <!-- Keep text for labels -->
  </xsl:template>    
  
  <xsl:template mode="index-term-label" 
    match="*[not(df:class(., 'topic/indexterm')) and 
    not(df:class(., 'topic/index-see'))and 
    not(df:class(., 'topic/index-seealso'))
    ]">
    <!-- Delegate to default mode processing for elements within index terms -->
    <xsl:apply-templates select="." mode="#default"/>
  </xsl:template>
  
  <xsl:template match="*[df:isTopicRef(.)]" mode="gather-index-terms">
    <xsl:param name="rootMapDocUrl" as="xs:string" tunnel="yes"/>

    <xsl:variable name="topic" select="df:resolveTopicRef(.)" as="element()*"/>
    
    <xsl:choose>
        <xsl:when test="not($topic)">
          <!-- Do nothing. Unresolveable topics will already have been reported. -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="targetUri" select="htmlutil:getTopicResultUrl($outdir, root($topic), $rootMapDocUrl)" as="xs:string"/>
          <xsl:variable name="relativeUri" select="relpath:getRelativePath($outdir, $targetUri)" as="xs:string"/>
            <!-- Any subordinate topics in the currently-referenced topic are
              reflected in the ToC before any subordinate topicrefs.
            -->
            <!--<xsl:message> + [DEBUG] gather-index-terms: applying templates to indexterms in referenced topic:
              <xsl:apply-templates select="$topic//*[df:class(., 'topic/indexterm')][not(parent::*[df:class(., 'topic/indexterm')])]" mode="report-element"></xsl:apply-templates>
            </xsl:message>-->
            <xsl:apply-templates mode="#current" 
              select="$topic//*[df:class(., 'topic/indexterm')][not(parent::*[df:class(., 'topic/indexterm')])], *[df:class(., 'map/topicref')]">
              <xsl:with-param name="targetUri" as="xs:string" tunnel="yes"
                select="$targetUri"
              />
            </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>    
        
  </xsl:template>
  
  <xsl:function name="local:construct-index-group-key" as="xs:string">
    <xsl:param name="label" as="node()*"/>
    <xsl:variable name="labelStr" select="string($label)" as="xs:string"/>
    <!-- FIXME: This is a very quick-and-dirty grouping key implementation.
      
         A full implementation must be extensible and must be locale-specific.
      -->
    <xsl:variable name="key" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($labelStr, '^[0-9]')">
          <xsl:sequence select="'#numeric'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="lower-case(substring($labelStr,1,1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:sequence select="$key"/>
  </xsl:function>

  <xsl:function name="local:construct-index-group-sort-key" as="xs:string">
    <xsl:param name="label" as="node()*"/>
    <!-- This label-to-label string anticipates more sophisticated label construction -->
    <xsl:variable name="labelStr" as="xs:string" select="string($label)"/>
    <!-- FIXME: This is a very quick-and-dirty sorting key implementation.
      
      A full implementation must be extensible and must be locale-specific.
      
      Need to control whether non-alpha items come first or last in collation
      order.
    -->
    <xsl:variable name="key" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($labelStr, '^[0-9]')">
          <xsl:sequence select="'#numeric'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="lower-case(substring($labelStr,1,1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:sequence select="$key"/>
  </xsl:function>
  
  <xsl:function name="local:construct-index-group-label" as="xs:string">
    <xsl:param name="index-term" as="element()"/>
    <!-- FIXME: This is a very quick-and-dirty label implementation.
      
      A full implementation must be extensible and must be locale-specific.
      
      Need to control whether non-alpha items come first or last in collation
      order.
    -->
    <xsl:variable name="label" select="normalize-space($index-term/index-terms:label)" as="xs:string"/>
    <xsl:variable name="groupLabel" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($label, '^[0-9]')">
          <xsl:sequence select="'Numeric'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="upper-case(substring($label,1,1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:sequence select="$groupLabel"/>
  </xsl:function>
  
  <xsl:function name="local:construct-index-term-grouping-key" as="xs:string">
    <xsl:param name="context" as="node()*"/>
    <xsl:variable name="grouping-key" as="xs:string" select="normalize-space(string-join($context))"/>
    <xsl:sequence select="$grouping-key"/>
  </xsl:function>
  
  <xsl:function name="local:construct-index-term-sorting-key" as="xs:string">
    <xsl:param name="context" as="node()*"/>
    <xsl:variable name="grouping-key" as="xs:string" select="lower-case(normalize-space($context))"/>
    <xsl:sequence select="$grouping-key"/>
  </xsl:function>
  
  
</xsl:stylesheet>
