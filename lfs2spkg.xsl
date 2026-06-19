<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:exsl="http://exslt.org/common"
        extension-element-prefixes="exsl"
        version="1.0">

<!-- Parameters -->
<!-- End parameters -->

<xsl:output method="text"/>

<!-- Start of templates -->
<xsl:template match="/">    
        <xsl:text>=== lfs2spkg&#xA;</xsl:text>
        <xsl:apply-templates select="//chapter[
                @id='chapter-cross-tools' or
                @id='chapter-temporary-tools' or
                @id='chapter-chroot-temporary-tools' or
                @id='chapter-building-system' or
                @id='chapter-bootable']"/>
        <xsl:text>=== &#xA;</xsl:text>
</xsl:template>

<xsl:template match="chapter">      
        <xsl:text>=== chapter&#xA;</xsl:text>
        <xsl:variable name="ch-pi" select="processing-instruction('dbhtml')"/>
        <xsl:variable name="ch-num-q" select="substring-after($ch-pi, 'chapter')"/>
        <xsl:variable name="ch-num" select="substring($ch-num-q,1,2)"/>

        <xsl:value-of select="$ch-num"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:value-of select="title"/>
        <xsl:text>&#xA;</xsl:text>
        <!-- pass1 tools go in $LFS/tools and get discarded
             we avoid them so they will have to be built by hand -->
        <xsl:apply-templates select="./sect1[
                                        not(@id='ch-tools-binutils-pass1') and
                                        not(@id='ch-tools-gcc-pass1') and
                                        sect2[@role='installation']]"/>
        <xsl:text>=== &#xA;</xsl:text>
</xsl:template>

<xsl:template match="sect1">
        <xsl:text>=== package&#xA;</xsl:text>

        <xsl:text>=== info&#xA;</xsl:text>
        <xsl:value-of select="sect1info/productname"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:value-of select="sect1info/productnumber"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== sources&#xA;</xsl:text>
        <xsl:call-template name="source-details">
                <xsl:with-param name="section" select="'packages'"/>
                <xsl:with-param name="file" select="sect1info/address"/>
        </xsl:call-template>
        <xsl:for-each select=".//userinput[contains(text(), '.patch')]">
                <xsl:call-template name="patch-source-details">
                        <xsl:with-param name="has-patch" select="."/>
                </xsl:call-template>
        </xsl:for-each> 
        <xsl:for-each select=".//userinput[contains(text(), 'tar -xf ../')]">
                <xsl:call-template name="tar-source-details">
                        <xsl:with-param name="has-tar" select="."/>
                </xsl:call-template>
        </xsl:for-each> 
        <xsl:for-each select=".//userinput[contains(text(), 'tar ') 
                and contains(substring-after(text(), 'tar '), ' -xvf ../')]">
                <xsl:call-template name="tar-source-details">
                        <xsl:with-param name="has-tar" select="."/>
                        <xsl:with-param name="tar-cmd" select="concat(' -xvf ', '../')"/>
                </xsl:call-template>
        </xsl:for-each> 

        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== build&#xA;</xsl:text>
        <xsl:apply-templates select=".//userinput[@remap='pre' or
                                                        @remap='configure' or
                                                        @remap='make']"/>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== test&#xA;</xsl:text>
        <xsl:apply-templates select=".//userinput[@remap='test']"/>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== install&#xA;</xsl:text>
	<xsl:apply-templates select=".//userinput[@remap='install']"/>
	<!-- special for glibc final pass -->
	<xsl:apply-templates select=".//sect3[title='Adding nsswitch.conf']//screen[not(@role='nodump')]//userinput"/>
	<xsl:apply-templates select=".//sect3[title='Configuring the Dynamic Loader']//screen[not(@role='nodump')]//userinput"/>
	<!-- -->
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== post-install&#xA;</xsl:text>
        <xsl:apply-templates select=".//userinput[@remap='adjust' or @remap='locale-test']"/>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>===&#xA;</xsl:text>

	<!-- separate tzdata from glibc final -->
	<xsl:if test="@id='ch-system-glibc'">
		<xsl:call-template name="tzdata">
			<xsl:with-param name="tzconfig" select="sect2[@id='conf-glibc']/sect3[title='Adding Time Zone Data']//screen[not(@role='nodump')]//userinput"/>
		</xsl:call-template>
	</xsl:if>
	<!-- -->
</xsl:template>

<xsl:template match="userinput">
        <xsl:value-of select='.'/>
        <xsl:text>&#xA;</xsl:text>
</xsl:template>

<xsl:template name="patch-source-details">
        <xsl:param name="has-patch"/>
        <xsl:variable name="patch-file" select="concat(substring-after(substring-before($has-patch, '.patch'), '../'),'.patch')"/>
        <xsl:call-template name="source-details">
                <xsl:with-param name="section" select="'patches'"/>
                <xsl:with-param name="file" select="$patch-file"/>
        </xsl:call-template>
</xsl:template>

<xsl:template name="tar-source-details">
        <xsl:param name="has-tar"/>
        <xsl:param name="tar-cmd" select="concat('tar -xf', ' ../')"/>
        <xsl:variable name="t1" select="substring-after($has-tar, $tar-cmd)"/>
        <xsl:variable name="tar-file"> 
                <xsl:call-template name="tar-filename">
                        <xsl:with-param name="input" select="$t1"/>
                </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="source-details">
                <xsl:with-param name="section" select="'packages'"/>
                <xsl:with-param name="file" select="$tar-file"/>
        </xsl:call-template>
        <xsl:if test="contains($t1, $tar-cmd)">
                <xsl:call-template name="tar-source-details">
                        <xsl:with-param name="has-tar" select="$t1"/>
                </xsl:call-template>
        </xsl:if>
</xsl:template>

                
<xsl:template name="source-details">
        <xsl:param name="section"/>
        <xsl:param name="file"/>
        <xsl:call-template name="url-md5">
                <xsl:with-param name="url-para" select="//sect1[@id=concat('ch-materials-',$section)]//para[text()='Download: ' and contains(ulink/@url, $file)]"/>
        </xsl:call-template>
</xsl:template>

<xsl:template name="url-md5">
        <xsl:param name="url-para"/>
        <xsl:value-of select="$url-para/ulink/@url"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:value-of select="$url-para/following-sibling::para/literal"/>
        <xsl:text>&#xA;</xsl:text>
</xsl:template>

<!-- tar file name will be on first line of what maybe a multipline block
        additionally it may be followed by bash line continuation or arguments
        This code makes the assumption that tar filenames do not contain spaces
        which holds for LFS book v13.0
-->
<xsl:template name="tar-filename">
        <xsl:param name="input"/>
        <xsl:variable name="line">
                <xsl:choose>
                        <xsl:when test="contains($input, '&#xA;')">
                                <xsl:value-of select="substring-before($input, '&#xA;')"/>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:value-of select="$input"/>
                        </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <xsl:choose>
                <xsl:when test="contains($line,'/')">
                        <xsl:call-template name="tar-filename">
                                <xsl:with-param name="input" select="substring-after($line,'/')"/>
                        </xsl:call-template>
                </xsl:when>
                <xsl:when test="contains($line, ' ')">
                        <xsl:value-of select="substring-before($line, ' ')"/>
                </xsl:when>
                <xsl:otherwise>
                        <xsl:value-of select="$line"/>
                </xsl:otherwise>
        </xsl:choose>
</xsl:template>

<!-- special to separate tzdata from glibc into own package
-->
<xsl:template name="tzdata">
	<xsl:param name="tzconfig"/>
        <xsl:variable name="tar-file"> 
                <xsl:call-template name="tar-filename">
			<xsl:with-param name="input" select="substring-after($tzconfig, 'tar -xf ../../')"/>
                </xsl:call-template>
        </xsl:variable>
	<xsl:variable name="tzversion" select="substring-after(substring-before($tar-file, '.'), 'tzdata')"/>

        <xsl:text>=== package&#xA;</xsl:text>

        <xsl:text>=== info&#xA;</xsl:text>
	<xsl:text>tzdata</xsl:text>
        <xsl:text>&#xA;</xsl:text>
        <xsl:value-of select="$tzversion"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== sources&#xA;</xsl:text>
        <xsl:call-template name="source-details">
                <xsl:with-param name="section" select="'packages'"/>
                <xsl:with-param name="file" select="$tar-file"/>
        </xsl:call-template>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== build&#xA;</xsl:text>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== test&#xA;</xsl:text>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== install&#xA;</xsl:text>
        <xsl:value-of select="substring-after($tzconfig, '&#xA;')"/>
        <xsl:text>&#xA;</xsl:text>
	<xsl:apply-templates select="$tzconfig[position() > 1]"/>
        <xsl:text>===&#xA;</xsl:text>

        <xsl:text>=== post-install&#xA;</xsl:text>
        <xsl:text>===&#xA;</xsl:text>


        <xsl:text>===&#xA;</xsl:text>
</xsl:template>


</xsl:stylesheet>
