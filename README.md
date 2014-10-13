Article Downloader
==================

Script that downloads articles/abstracts from PubMed using a list of PMIDs.


**article_downloader.pl**

This script reads a list of PMIDs and checks which of them
are not downloaded yet. After that, it downloads medline records,
then it creates a tabular medline file (with information of each article)
and finally it downloads abstracts and epubs (if available at PMC) 

	Requirements:
		- In order to work properly, the next following folder structure
		  has to be created first:

		Article_analysis/
			epubs/
			abstracts/
			epubabs/
			medline/
	
	Arguments:
		- A list of PMIDs in plain text.

	Options:
		-a : download only abstracts
		-f : skip the 'checking', it will download every article in 
		     the list of PMIDs

**makefile**

Commands:

	make all - do everything

	make download :
        default: download abstracts (and epubs if possible) of ids in PMIDs.txt that have not been already downloaded.
        Options:
            opt=-a : download only abstracts
            opt=-f : force download of already downloaded files
            If you use both options at the same time (opt=-af) you will download all the abstracts (and not any epub) 		regardless of whether you have downloaded the abstracts before or not. 

 

	make pdf - process pdf files (creates raw, text_sentences and stats).
	make epub - process epub files (creates raw, text_sentences and stats).
	make abstract - process abstracts (creates text_sentences and stats).
	make epubabs - process abstracts of articles with a PMC id (creates text_sentences and stats). 

 
	make cleanall - remove everything.
	make cleantext -remove all intermediary text files (everything inside 'raw_text/' 'text_sentences/' 'stats/').
	make cleanepub - remove epubs.
	make cleanepubabs - remove abstracts from articles with PMC ids.
	make cleanabstract - remove abstracts.
	make cleanmedline - remove all medline records.
	make cleanstats - remove all stat files. 
