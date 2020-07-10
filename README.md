# Lesson 4 -- RNA assembly with Trinity

Initially forked from [here](https://github.com/binder-examples/conda). Thank you to the awesome [binder](https://mybinder.org/) team!

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/alexismarshall/bvcn-binder-trinity/master?urlpath=lab)
Click the Binder Badge to start. This binder may take some time to load ~5-10 min

Part of the [Bioinformatics Virtual Coordination Network](https://biovcnet.github.io/) :)

This tutorial is a step-by-step guide on how to de novo assemble pared-end RNA reads.   

## Recommended knowledge base and/or pre-reading

[Quality Control using FastQC and MultiQC](https://github.com/biovcnet/biovcnet.github.io/wiki/TOPIC%3A-Transcriptomics#lesson-2----rrna-depletion-wet-lab-and-in-silico)

[rRNA depletion](https://github.com/biovcnet/biovcnet.github.io/wiki/TOPIC%3A-Transcriptomics#lesson-2----rrna-depletion-wet-lab-and-in-silico)

## About this tutorial 
This tutorial will take you through the general advice provided on the [Best practices for de novo transcriptome assembly with Trinity](https://informatics.fas.harvard.edu/best-practices-for-de-novo-transcriptome-assembly-with-trinity.html) and show you how to assemble these quality trimmed and corrected reads with the de novo RNA assembler [Trinity](https://github.com/trinityrnaseq/trinityrnaseq/wiki)

We have provided two subsampled datasets from the following studies:
1. Sieradzki, E., Ignacio-Espinoza, J.C., Needham, D. et al. Dynamic marine viral infections and major contribution to photosynthetic processes shown by spatiotemporal picoplankton metatranscriptomes. Nat Commun 10, 1169 (2019). https://doi.org/10.1038/s41467-019-09106-z

2. Husnik F, Nikoh N, Koga R, et al. Horizontal gene transfer from diverse bacteria to an insect genome enables a tripartite nested mealybug symbiosis. Cell. 2013;153(7):1567-1578. doi:10.1016/j.cell.2013.05.040 
   Total dataset is available here https://www.ncbi.nlm.nih.gov/sra/SRX7867216[accn] 
   For more information see the following [MicroSeminar talk](https://www.youtube.com/watch?v=sG5qWK_9sf8&t=5s)

