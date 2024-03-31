<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">
  <xsl:variable name="part1"><![CDATA[<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE chapter PUBLIC "-//OASIS//DTD DocBook XML V4.5//EN"
  "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" [
<!ENTITY % general-entities SYSTEM "../../../general.ent">
 %general-entities;

  <!ENTITY pythonhosted-download-http "Se Under">
  <!ENTITY pythonhosted-download-ftp  " ">
  <!ENTITY pythonhosted-md5sum        "Se Under">
  <!ENTITY pythonhosted-size          "14 MB">
  <!ENTITY pythonhosted-buildsize     "2.2 MB">
  <!ENTITY pythonhosted-time          "TBD SBU)">
]>

<sect2 id="pythonhosted" xreflabel="pythonhosted filer">
   <!--<?dbhtml filename="pythonhosted.html"?>-->

  <title>Bygge pythonhosted.org Filer</title>

  <indexterm zone="pythonhosted">
     <primary sortas="a-pythonhosted">pythonhosted</primary>
  </indexterm>

  <sect3 role="package">
   <title>Introduksjon til pythonhosted.org Filer</title>

  <para>
     Denne delen er for brukervennlighet og er valgfri.
     Den kan brukes til å hente og installere hele pythonhosted.org modul
     pakker nedenfor i to praktiske skript.
  </para>

  &lfs112_checked;

  <bridgehead renderas="sect4">Pakkeinformasjon</bridgehead>
  <itemizedlist spacing="compact">
    <listitem>
      <para>
        Nedlasting (HTTP): &pythonhosted-download-http;
      </para>
    </listitem>
    <listitem>
      <para>
        Nedlasting (FTP): <ulink url="&pythonhosted-download-ftp;"/>
      </para>
    </listitem>
    <listitem>
      <para>
        Nedlasting MD5 sum: &pythonhosted-md5sum;
      </para>
    </listitem>
    <listitem>
      <para>
        Nedlastingsstørrelse: &pythonhosted-size;
      </para>
    </listitem>
    <listitem>
      <para>
        Estimert diskplass som kreves: &pythonhosted-buildsize;
      </para>
    </listitem>
    <listitem>
      <para>
        Estimert byggetid: &pythonhosted-time;
      </para>
    </listitem>
  </itemizedlist>

  <bridgehead renderas="sect4">Pythonhosted.org Avhengigheter</bridgehead>

  <bridgehead renderas="sect5">Påkrevd</bridgehead>
  <para role="required">
    TBD
    <!--<xref linkend="fontforge"/>,-->
    <!-- does not seem to be needed as of 5.22.4 <xref linkend="GConf"/>, -->
  </para>

  <bridgehead renderas="sect5">Anbefalt</bridgehead>
  <para role="recommended">
     TBD
     <!--<xref linkend="fftw"/>,-->
  </para>

  <bridgehead renderas="sect5">Valgfri</bridgehead>
  <para role="optional">
     TBD
     <!--
    <xref linkend="glu"/>,
    <ulink url="http://www.dest-unreach.org/socat/">socat</ulink> (for pam_kwallet)-->
  </para>
  <!--
  <para condition="html" role="usernotes">Brukernotater:
  <ulink url="&blfs-wiki;/pythonhosted"/></para>
  -->
  </sect3>

   <sect3>
    <title>Laste ned alle Pythonhosted modulfiler</title>

    <para>
      Den enkleste måten å installere modulene på fra nettstedet files.pythonhosted.org
      er å kjøre et skript for å installere dem alle samtidig.
    </para>

    <para>
      Rekkefølgen på byggefiler er viktig på grunn av interne avhengigheter.
      Først lager du listen over filer i riktig rekkefølge som følger:
    </para>

<screen><userinput>cat &gt; pythonhosted-files.md5 &lt;&lt; "EOF"
<literal>]]></xsl:variable>
  <xsl:variable name="part2"><![CDATA[</literal>
EOF</userinput></screen>

    <para>
      Deretter lager du et skript for å hente filene:
    </para>

    <screen><userinput>cat &gt; get-pythonhosted-files.sh &lt;&lt; "EOF"
<literal>#! /bin/bash

PYTHONHOSTED=https://files.pythonhosted.org/packages/source

mkdir -p pythonhosted
cd pythonhosted

for package in $(grep -v '^#' ../pythonhosted-files.md5 | awk '{print $2}')
do
  # Don't try to get a package that is already present
  [ -e $package ] &amp;&amp; continue
  basename=$(echo $package|sed 's/-[[:digit:]].*$//')
  basechar=$(echo $basename|cut -c 1)
  url=$PYTHONHOSTED/$basechar/$basename/$package
  wget $url
done
EOF</literal></userinput></screen>

    <para>
      Kjør skriptet og sjekk filene:
    </para>

   <screen><userinput>bash get-pythonhosted-files.sh &amp;&amp;
   md5sum -c ../pythonhosted-files.md5</userinput></screen>

   </sect3>

  <sect3 role="installation">
    <title>Installasjon av Pythonhosted Modules</title>

    <para>
      Sett opp et skript for å installere alle pakkene:
    </para>

    <screen><userinput>cat &gt; install-pythonhosted-files.sh &lt;&lt; "EOF"
<literal>#! /bin/bash

cd pythonhosted

for package in $(grep -v '^#' ../pythonhosted-files.md5 | awk '{print $2}')
do
  name=$(echo $package|sed 's/-[[:digit:]].*$//')

  # Don't try to install the package if it already installed
  installed=$(pip3 show $name 2&gt; /dev/null | grep Version:)

  unset version
  if [ -n $installed ]; then
    version=$(echo $installed | awk '{print $2}')
  fi

  if [ -n "$version" ]; then
    if [ ! $(echo $package | grep -q $version) ]; then
      echo $package is already installed
      continue
    fi
  fi

  # Now install the package
  packagedir=${package%.tar.?z*}
  rm -rf $packagedir
  tar -xf $package
  pushd $packagedir
    pip3 wheel -w dist --no-build-isolation --no-deps $PWD
    sudo pip3 install --no-index --find-links dist --no-cache-dir \
                      --no-user --upgrade $name
  popd
done</literal></userinput></screen>

    <para>
       Kjør nå skriptet for å installere filene. Hvis skriptet kjøres
       flere ganger, vil den ikke prøve å installere modulene på nytt med mindre
       versjonen i .md5-filen er endret.
    </para>

   <screen><userinput>bash install-pythonhosted-files.sh</userinput></screen>

   <para>Noen av pakkene har testprosedyrer. Se den enkelte
   pakkedelene nedenfor for å kjøre eventuelle ønskede tester.</para>

  </sect3>

  <sect3 role="content">
    <title>Contents</title>

    <para>
       Se innholdet i de enkelte pakkedelene nedenfor.
    </para>

  </sect3>

</sect2>]]></xsl:variable>

</xsl:stylesheet>
