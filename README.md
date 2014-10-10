Article Downloader
==================

Script that downloads articles/abstracts from PubMed using a list of PMIDs.


article_downloader.pl

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
