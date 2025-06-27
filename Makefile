# vim:ts=3
# Makefile for BLFS Book generation.
# By Tushar Teredesai <tushar@linuxfromscratch.org>
# 2004-01-31

# Adjust these to suit your installation
RENDERTMP   ?= $(HOME)/tmp
CHUNK_QUIET  = 1
ROOT_ID      =
SHELL        = /bin/bash

ALLXML := $(filter-out $(RENDERTMP)/%, \
	$(wildcard *.xml */*.xml */*/*.xml */*/*/*.xml */*/*/*/*.xml))
ALLXSL := $(filter-out $(RENDERTMP)/%, \
	$(wildcard *.xsl */*.xsl */*/*.xsl */*/*/*.xsl */*/*/*/*.xsl))

ifdef V
  Q =
else
  Q = @
endif

ifndef REV
  REV = sysv
endif

ifneq ($(REV), sysv)
  ifneq ($(REV), systemd)
    $(feil REV må være 'sysv' (standard) eller 'systemd'.)
  endif
endif

ifeq ($(REV), sysv)
  BASEDIR         ?= $(HOME)/public_html/blfs-book
  NOCHUNKS_OUTPUT ?= blfs-book.html
  DUMPDIR         ?= ~/blfs-commands
  BLFSHTML        ?= blfs-html.xml
  BLFSHTML2       ?= blfs-html2.xml
  BLFSFULL        ?= blfs-full.xml
else
  BASEDIR         ?= $(HOME)/public_html/blfs-systemd
  NOCHUNKS_OUTPUT ?= blfs-sysd-book.html
  DUMPDIR         ?= ~/blfs-sysd-commands
  BLFSHTML        ?= blfs-systemd-html.xml
  BLFSHTML2       ?= blfs-systemd-html2.xml
  BLFSFULL        ?= blfs-systemd-full.xml

endif

blfs: html wget-list

help:
	@echo ""
	@echo "make <parametere> <mål>"
	@echo ""
	@echo "Parametere:"
	@echo "  REV=<rev>            Bygg variant av boken"
	@echo "                       Gyldige verdier for REV er:"
	@echo "                       * sysv    - Bygg boken for SysV"
	@echo "                       * systemd - Bygg boken for systemd"
	@echo "                       Standard er 'sysv'"
	@echo ""
	@echo "  BASEDIR=<dir>        Plasser utdataene i mappen <dir>."
	@echo "                       Standard er"
	@echo "                       'HOME/public_html/blfs-book' hvis REV=sysv (eller ikke-satt)"
	@echo "                       eller"
	@echo "                       'HOME/public_html/blfs-book-systemd' hvis REV=systemd"
	@echo ""
	@echo "  V=<val>              Hvis <val> er en ikke-tom verdi, alle"
	@echo "                       trinnene for å produsere resultatet vises."
	@echo "                       Standard er ikke-satt."
	@echo ""
	@echo "Mål:"
	@echo "  help                 Vis denne hjelpeteksten."
	@echo ""
	@echo "  blfs                 Bygger målene 'html' og 'wget-list'."
	@echo ""
	@echo "  html                 Bygger HTML sidene til boken."
	@echo ""
	@echo "  wget-list            Lager en liste over alle pakker som skal lastes ned."
	@echo "                       Utdata er BASEDIR/wget-list"
	@echo ""
	@echo "  nochunks             Bygger boken som en én-siders bok. Resultatet"
	@echo "                       er en stor enkelt HTML side som inneholder"
	@echo "                       hele boken."
	@echo ""
	@echo "                       Parameteren NOCHUNKS_OUTPUT=<filename> kontrollerer"
	@echo "                       navnet på HTML filen."
	@echo ""
	@echo "  validate             Kjører valideringskontroller på XML filene."
	@echo ""
	@echo "  test-links           Kjører valideringskontroller på nettadresser i boken."
	@echo "                       Produserer en fil med navnet BASEDIR/bad_urls som inneholder"
	@echo "                       nettadresser som er ugyldige og en BASEDIR/good_urls"
	@echo "                       som inneholder alle gyldige nettadresser."
	@echo ""

all: blfs nochunks
world: all blfs-patch-list dump-commands test-links

html: $(BASEDIR)/index.html
$(BASEDIR)/index.html: $(RENDERTMP)/$(BLFSHTML) version
	@echo "Generering av delte XHTML filer..."
	$(Q)xsltproc --nonet                                    \
                --stringparam chunk.quietly $(CHUNK_QUIET) \
                --stringparam rootid "$(ROOT_ID)"          \
                --stringparam base.dir $(BASEDIR)/         \
                stylesheets/blfs-chunked.xsl               \
                $(RENDERTMP)/$(BLFSHTML)

	@echo "Kopiering av CSS kode og bilder..."
	$(Q)if [ ! -e $(BASEDIR)/stylesheets ]; then \
      mkdir -p $(BASEDIR)/stylesheets;          \
   fi;

	$(Q)cp stylesheets/lfs-xsl/*.css $(BASEDIR)/stylesheets
	$(Q)sed -i 's|../stylesheet|stylesheet|' $(BASEDIR)/index.html

	$(Q)if [ ! -e $(BASEDIR)/images ]; then \
      mkdir -p $(BASEDIR)/images;          \
   fi;
	$(Q)cp images/*.png $(BASEDIR)/images

	$(Q)cd $(BASEDIR)/; sed -e "s@../images@images@g"           \
                           -i *.html

	@echo "Kjører Tidy og obfuscate.sh på delt XHTML..."
	$(Q)for filename in `find $(BASEDIR) -name "*.html"`; do       \
      tidy -config tidy.conf $$filename;                          \
      true;                                                       \
      bash obfuscate.sh $$filename;                               \
      sed -i -e "1,20s@text/html@application/xhtml+xml@g" $$filename; \
   done;

nochunks: $(BASEDIR)/$(NOCHUNKS_OUTPUT)
$(BASEDIR)/$(NOCHUNKS_OUTPUT): $(RENDERTMP)/$(BLFSHTML) version
	@echo "Genererer ikke-delt XHTML fil..."
	$(Q)xsltproc --nonet                                \
                --stringparam rootid "$(ROOT_ID)"      \
                --output $(BASEDIR)/$(NOCHUNKS_OUTPUT) \
                stylesheets/blfs-nochunks.xsl          \
                $(RENDERTMP)/$(BLFSHTML)

	@echo "Kjører Tidy og obfuscate.sh på ikke-delt XHTML..."
	$(Q)tidy -config tidy.conf $(BASEDIR)/$(NOCHUNKS_OUTPUT) || true
	$(Q)bash obfuscate.sh $(BASEDIR)/$(NOCHUNKS_OUTPUT)
	$(Q)sed -i -e "1,20s@text/html@application/xhtml+xml@g" $(BASEDIR)/$(NOCHUNKS_OUTPUT)

tmpdir: $(RENDERTMP)
$(RENDERTMP):
	@echo "Oppretter $(RENDERTMP)"
	$(Q)[ -d $(RENDERTMP) ] || mkdir -p $(RENDERTMP)

clean:
	@echo "Renser $(RENDERTMP)"
	$(Q)rm -f $(RENDERTMP)/blfs*

validate: $(RENDERTMP)/$(BLFSFULL)
$(RENDERTMP)/$(BLFSFULL): general.ent packages.ent $(ALLXML) $(ALLXSL) version
	$(Q)[ -d $(RENDERTMP) ] || mkdir -p $(RENDERTMP)

	@echo "Justerer for revisjon $(REV)..."
	$(Q)xsltproc --nonet                               \
                --xinclude                            \
                --output $(RENDERTMP)/$(BLFSHTML2)    \
                --stringparam profile.revision $(REV) \
                stylesheets/lfs-xsl/profile.xsl       \
                index.xml

	@echo "Validerer boken..."
	$(Q)xmllint --nonet                             \
               --noent                             \
               --postvalid                         \
               --output $(RENDERTMP)/$(BLFSFULL)   \
               $(RENDERTMP)/$(BLFSHTML2)

profile-html: $(RENDERTMP)/$(BLFSHTML)
$(RENDERTMP)/$(BLFSHTML): $(RENDERTMP)/$(BLFSFULL) version
	@echo "Genererer profilert XML for XHTML..."
	$(Q)xsltproc --nonet                              \
                --stringparam profile.condition html \
                --output $(RENDERTMP)/$(BLFSHTML)    \
                stylesheets/lfs-xsl/profile.xsl      \
                $(RENDERTMP)/$(BLFSFULL)

blfs-patch-list: blfs-patches.sh
	@echo "Genererer blfs oppdateringsliste..."
	$(Q)awk '{if ($$1 == "copy") {sub(/.*\//, "", $$2); print $$2}}' \
	  blfs-patches.sh > blfs-patch-list

blfs-patches.sh: $(RENDERTMP)/$(BLFSFULL) version
	@echo "Genererer blfs oppdateringsskript..."
	$(Q)xsltproc --nonet                     \
                --output blfs-patches.sh    \
                stylesheets/patcheslist.xsl \
                $(RENDERTMP)/$(BLFSFULL)

wget-list: $(BASEDIR)/wget-list
$(BASEDIR)/wget-list: $(RENDERTMP)/$(BLFSFULL) version
	@echo "Genererer wget liste for $(REV) på $(BASEDIR)/wget-list ..."
	$(Q)mkdir -p $(BASEDIR)
	$(Q)xsltproc --nonet                       \
                --output $(BASEDIR)/wget-list \
                stylesheets/wget-list.xsl     \
                $(RENDERTMP)/$(BLFSFULL)

test-links: $(BASEDIR)/test-links
$(BASEDIR)/test-links: $(RENDERTMP)/$(BLFSFULL) version
	@echo "Genererer testlenke fil..."
	$(Q)mkdir -p $(BASEDIR)
	$(Q)xsltproc --nonet                        \
                --stringparam list_mode full   \
                --output $(BASEDIR)/test-links \
                stylesheets/wget-list.xsl      \
                $(RENDERTMP)/$(BLFSFULL)

	@echo "Sjekk av nettadresser, første omgang..."
	$(Q)rm -f $(BASEDIR)/{good,bad,true_bad}_urls
	$(Q)for URL in `cat $(BASEDIR)/test-links`; do                     \
         wget --spider --tries=2 --timeout=60 $$URL >>/dev/null 2>&1; \
         if test $$? -ne 0 ; then                                     \
            echo $$URL >> $(BASEDIR)/bad_urls ;                       \
         else                                                         \
            echo $$URL >> $(BASEDIR)/good_urls 2>&1;                  \
         fi;                                                          \
   done

	@echo "Sjekk av nettadresser, andre omgang..."
	$(Q)for URL2 in `cat $(BASEDIR)/bad_urls`; do                       \
         wget --spider --tries=2 --timeout=60 $$URL2 >>/dev/null 2>&1; \
         if test $$? -ne 0 ; then                                      \
           echo $$URL2 >> $(BASEDIR)/true_bad_urls ;                   \
         else                                                          \
           echo $$URL2 >> $(BASEDIR)/good_urls 2>&1;                   \
         fi; \
   done

bootscripts:
	@VERSION=`grep "bootscripts-version " general.ent | cut -d\" -f2`; \
   BOOTSCRIPTS="blfs-bootscripts-$$VERSION";                          \
   if [ ! -e $$BOOTSCRIPTS.tar.xz ]; then                             \
     rm -rf $(RENDERTMP)/$$BOOTSCRIPTS;                               \
     mkdir $(RENDERTMP)/$$BOOTSCRIPTS;                                \
     cp -a ../bootscripts/* $(RENDERTMP)/$$BOOTSCRIPTS;               \
     rm -rf ../bootscripts/archive;                                   \
     tar  -cJhf $$BOOTSCRIPTS.tar.xz -C $(RENDERTMP) $$BOOTSCRIPTS;   \
   fi

systemd-units:
	@VERSION=`grep "systemd-units-version " general.ent | cut -d\" -f2`; \
   UNITS="blfs-systemd-units-$$VERSION";                                \
   if [ ! -e $$UNITS.tar.xz ]; then                                     \
     rm -rf $(RENDERTMP)/$$UNITS;                                       \
     mkdir $(RENDERTMP)/$$UNITS;                                        \
     cp -a ../systemd-units/* $(RENDERTMP)/$$UNITS;                     \
     tar -cJhf $$UNITS.tar.xz -C $(RENDERTMP) $$UNITS;                  \
   fi

test-options:
	$(Q)xsltproc --xinclude --nonet stylesheets/test-options.xsl index.xml

dump-commands: $(DUMPDIR)
$(DUMPDIR): $(RENDERTMP)/$(BLFSFULL) version
	@echo "Dumping av bokkommandoer..."
	$(Q)xsltproc --output $(DUMPDIR)/          \
                stylesheets/dump-commands.xsl \
                $(RENDERTMP)/$(BLFSFULL)
	$(Q)touch $(DUMPDIR)

.PHONY: blfs all world html nochunks tmpdir clean             \
   validate profile-html blfs-patch-list wget-list test-links \
   dump-commands  bootscripts systemd-units version test-options

version:
	$(Q)./git-version.sh $(REV)
