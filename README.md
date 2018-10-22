This scraper queries Wikidata for articles on the [ScienceSource focus list](https://www.wikidata.org/wiki/Wikidata:ScienceSource_focus_list) with a PubMed Central ID, but where the license is unknown.

It then looks up the article on the [PubMed website](https://www.ncbi.nlm.nih.gov/pmc/) to see if there's a [Creative Commons](https://creativecommons.org/) license mentioned on the article page, and if so generates [QuickStatements](https://tools.wmflabs.org/quickstatements/)-compatible commands for adding that license information to Wikidata.

## History

This was originally written as part of the [ContentMine/Cambridge Wikidata Workshop](https://www.wikidata.org/wiki/Wikidata:ContentMine/Cambridge_Wikidata_Workshop) in October 2018.

## Possible Expansions

Rather than ignoring any non-CC licenses, it would be useful to set something useful about the license onto the Wikidata item, and/or remove it from the focus list.

