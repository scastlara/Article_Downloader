#################################################################################
#                               MAKEFILE							    		#
#################################################################################
#
#	This makefile automates the download and the conversion to text of PMC articles
#	and PubMed abstracts. It also automates the extraction of text from pdf articles.
#	
#	You can use options as follows:
#		make <command> opt=-a
#		make <command> opt=-f
#		make <command> opt=-af
#

#********************************************************************************
#        Copyright (C) 2014 - Sergio CASTILLO
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#********************************************************************************



## THIS IS THE DIRECTORY OF THE PROJECT
ROOTDIR = /home/compgen/users/scastillo/Article_analysis/


## SUBDIRECTORIES

# Input 
pdfDIR = pdfs/
epubDIR = epubs/
absDIR = abstracts/
epubabsDIR = epubabs/

# Output
rawDIR = raw_text/
txtDIR = text_sentences/
statsDIR = stats/
mtchesDIR = mtches/

# Programs
EXTRACTOR = /home/compgen/users/scastillo/practicum/pdf_to_text_project/lapdftext/
BIN = /home/compgen/users/scastillo/bin/

## FILE VARIABLES

# Input variables
PDF = $(wildcard $(pdfDIR)*.pdf)
EPUBS = $(wildcard $(epubDIR)*.epub)
ABST = $(wildcard $(absDIR)*.txt)
EPUBABS = $(wildcard $(epubabsDIR)*.txt)

# Output variables: abstracts
TXTabs = $(patsubst $(absDIR)%.txt,$(txtDIR)%.txt,$(ABST))
STATSabs = $(patsubst $(absDIR)%.txt,$(statsDIR)%.stats,$(ABST))

# Output variables: epubabs
TXTepubabs = $(patsubst $(epubabsDIR)%.txt,$(txtDIR)%.txt,$(EPUBABS))
STATSepubabs = $(patsubst $(epubabsDIR)%.txt,$(statsDIR)%.stats,$(EPUBABS))

# Output variables: epub
RAWepub= $(patsubst $(epubDIR)%.epub,$(rawDIR)%_fullText.txt,$(EPUBS))
TXTepub = $(patsubst $(epubDIR)%.epub,$(txtDIR)%.txt,$(EPUBS))
STATSepub = $(patsubst $(epubDIR)%.epub,$(statsDIR)%.stats,$(EPUBS))

# Output variables: pdf
RAW = $(patsubst $(pdfDIR)%.pdf,$(rawDIR)%_fullText.txt,$(PDF))
TXT = $(patsubst $(pdfDIR)%.pdf,$(txtDIR)%.txt,$(PDF))
STATS = $(patsubst $(pdfDIR)%.pdf,$(statsDIR)%.stats,$(PDF))

# Full text: inside text_sentences/
TXT_SENT = $(wildcard $(txtDIR)*.txt)

# Tagged text: inside mtches/
MTCHES = $(patsubst $(txtDIR)%.txt,$(mtchesDIR)%.mtches,$(TXT_SENT))

# gene_finder arguments
HUGO = ~/code/gene_synonyms/HUGO_synonyms.tbl
STOP = ~/code/gene_synonyms/long_stopwords.txt

# ******************************************************************************
# WHAT DO YOU WANT TO DO? COMMANDS

# Do everything
all: $(ROOTDIR)medline.tbl $(TXTabs) $(STATSabs) $(RAW) $(TXT) $(STATS)  $(RAWepub) $(TXTepub) $(STATSepub) $(MTCHES)

# Download abstracts or articles if possible (epubs)
download: $(ROOTDIR)medline.tbl

# Extract text from pdfs
pdf: $(RAW) $(TXT) $(STATS)

# Extract text from epubs
epub:  $(RAWepub) $(TXTepub) $(STATSepub) 

# Process text from abstracts
abstract: $(TXTabs) $(STATSabs)

# Process text from epub-abstracts
epubabs: $(TXTepubabs) $(STATSepubabs)

# Find genes
genes: $(MTCHES)



# ******************************************************************************
## EPUB AND ABSTRACT DOWNLOAD...

download:
$(ROOTDIR)medline.tbl: $(ROOTDIR)PMIDs.txt 
	$(BIN)article_downloader.pl $(opt) PMIDs.txt

# ******************************************************************************
## FOR PDFs...

pdf: 
$(rawDIR)%_fullText.txt: $(pdfDIR)%.pdf
	@echo "###EXTRACTING TEXT FROM PDF $<..." 1>&2;
	$(EXTRACTOR)extractFullText\
	 $(ROOTDIR)$<\
	 $(ROOTDIR)raw_text

$(txtDIR)%.txt: $(rawDIR)%_fullText.txt
	@echo "###PROCESSING $< RAW TEXT ..." 1>&2;
	$(BIN)style_enhancer.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@

$(statsDIR)%.stats: $(txtDIR)%.txt
	@echo "###CREATING $< STATS FILES..." 1>&2;
	$(BIN)text_stats.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@


# ******************************************************************************
## FOR ABSTRACTS...
abstract:

$(txtDIR)%.txt: $(absDIR)%.txt
	@echo "###PROCESSING $< ABSTRACT RAW TEXT ..." 1>&2;
	$(BIN)style_enhancer.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@

$(statsDIR)%.stats: $(txtDIR)%.txt
	@echo "###CREATING $< ABSTRACT STATS FILES..." 1>&2;
	$(BIN)text_stats.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@


# ******************************************************************************
## FOR EPUBS...
epub:

$(rawDIR)%_fullText.txt: $(epubDIR)%.epub
	@echo "###EXTRACTING TEXT FROM EPUB $<..." 1>&2;
	ebook-convert $(ROOTDIR)$<\
	 $(ROOTDIR)$@ 
# ojo aqui arriba, raw dir, sí o no?

$(txtDIR)%.txt: $(rawDIR)%_fullText.txt
	@echo "###PROCESSING $< RAW TEXT ..." 1>&2;
	$(BIN)style_enhancer.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@

$(statsDIR)%.stats: $(txtDIR)%.txt
	@echo "###CREATING $< STATS FILES..." 1>&2;
	$(BIN)text_stats.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@

# ******************************************************************************
## FOR EPUBABS...
epubabs:

$(txtDIR)%.txt: $(epubabsDIR)%.txt
	@echo "###PROCESSING $< ABSTRACT RAW TEXT ..." 1>&2;
	$(BIN)style_enhancer.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@

$(statsDIR)%.stats: $(txtDIR)%.txt
	@echo "###CREATING $< ABSTRACT STATS FILES..." 1>&2;
	$(BIN)text_stats.pl\
	 $(ROOTDIR)$<\
	 > $(ROOTDIR)$@

# ******************************************************************************
## FOR TAGGING GENES...
genes:
$(mtchesDIR)%.mtches: $(txtDIR)%.txt
	@echo "\n### TAGGING GENES ..." 1>&2;
	$(BIN)gene_finder.pl $(HUGO) $(STOP) $<;


# ******************************************************************************
cleanall:
	@echo "\n### REMOVING ALL FILES ..." 1>&2;
	/bin/rm -vf $(ROOTDIR)raw_text/*_fullText.txt core;
	/bin/rm -vf $(ROOTDIR)stats/*.stats core;
	/bin/rm -vf $(ROOTDIR)text_sentences/*.txt core;
	/bin/rm -vf $(ROOTDIR)medline/*.medline core;
	/bin/rm -vf $(ROOTDIR)abstracts/*.txt core;
	/bin/rm -vf $(ROOTDIR)epubs/*.epub core;
	/bin/rm -vf $(ROOTDIR)epubabs/*.txt core;

cleanepub:
	@echo "\n### REMOVING EPUBS ..." 1>&2;	
	/bin/rm -vf $(ROOTDIR)epubs/*.epub core;

cleanepubabs:
	@echo "\n### REMOVING EPUBABS ..." 1>&2;	
	/bin/rm -vf $(ROOTDIR)epubabs/*.txt core;

cleantext:
	/bin/rm -vf $(ROOTDIR)raw_text/*_fullText.txt core;
	/bin/rm -vf $(ROOTDIR)stats/*.stats core;
	/bin/rm -vf $(ROOTDIR)text_sentences/*.txt core;

cleanabstract:
	/bin/rm -vf $(ROOTDIR)abstracts/*.txt core;

cleanmedline:
	/bin/rm -vf $(ROOTDIR)medline/*.medline core;

cleanstats:
	/bin/rm -vf $(ROOTDIR)stats/*.stats core;

cleangenes:
	/bin/rm .vf $(ROOTDIR)mtches/*.mtches;
