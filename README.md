# JarrVis
A shiny app for visualizing stratified rpkm output from metagenomic pipelines - JARRVIS (Just Another stRatified Rpkm VISualizer)

<p align="center">
	<img src="images/jarrvis_logo.png?raw=true" alt="Logo" width=65% height=65%>
</p>

This repository provides the source code and the test data files for running the JarrVis app locally.

## Running the app locally in Rstudio
First step would be to clone the Git repository.

If you are using a unix system (mac or Linux), open a terminal and run the following:
```
git clone https://github.com/dhwanidesai/JarrVis.git
```
This should download the app.R and other files from this repository into a folder called "JarrVis"
To run this app you would require a local install of Rstudio (R version >=3.6) with the shiny package (required). Once Rstudio is installed, open it and run app.R file using the "Run App" button in Rstudio

## Running through Github Gist from Rstudio

Just run the following commands in Rstudio

```
library(shiny)
runGist("943ff5fdbd94815cc27f302d9f56ff0b")
```
## Input File formats
The following section will describe the steps required to process the stratified RPKM output generated in the above steps to convert it into input for the Visualizer app:
#### Example: Stratified EC number rpkm visualisation
***
Following is a sample of the 4-column input file required:
***
```
Sample	Genus	Gene	Contribution
31D	p__Chordata;c__Mammalia;o__NA;f__NA;g__NA;s__NA	EC:5.6.1.7	0.8095988800249774
31D	p__Chordata;c__Mammalia;o__NA;f__NA;g__NA;s__NA	EC:2.4.1.131	1.2837072456944525
31D	p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;s__NA	EC:4.1.1.31	16.230874609024266
31D	p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;s__Streptococcus cristatus	EC:4.1.1.31	5.8013837528095165
31D	p__Actinobacteria;c__Actinobacteria;o__Corynebacteriales;f__Corynebacteriaceae;g__Corynebacterium;s__Corynebacterium matruchotii	EC:4.1.1.31	7.240397583735735
31D	p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;s__Streptococcus sp. 2_1_36FAA	EC:4.1.1.31	6.115064692694273
31D	p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;s__Streptococcus sanguinis	EC:4.1.1.31	9.928303115746663
31D	p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;s__Streptococcus gordonii	EC:4.1.1.31	0.3053339527728727
31D	p__Actinobacteria;c__Actinobacteria;o__Corynebacteriales;f__Corynebacteriaceae;g__Corynebacterium;s__Corynebacterium durum	EC:4.1.1.31	0.4697140517147269
``` 
***
Following is a sample of the metadata file format required as input by the Visualizer. 

NOTE:- you can have multiple columns or categories (tab-delimited) of the samples in the metadata file; However, the first column needs to be labeled "sample_id" (REQUIRED!)
***
```
sample_id	type
31D	A
32Da	A
34D	A
35Da	A
36Da	A
C16	B
C18	B
C19	B
C22	B
```
***

* Convert stratified output to 4 column format
For this, we first need to convert the Kraken2 output files for each of the metagenomes into an abundance (counts) matrix. This file also be useful for the Metacoder visalization (https://rpubs.com/dhwanikdesai/736732)

First we need to get a list of the sample tags and the corresponding kraken2 output files (such as in the example below)
```
31D	kraken2_outraw_0.05/31D.kraken.txt
32Da	kraken2_outraw_0.05/32Da.kraken.txt
34D	kraken2_outraw_0.05/34D.kraken.txt
35Da	kraken2_outraw_0.05/35Da.kraken.txt
36Da	kraken2_outraw_0.05/36Da.kraken.txt
C16	kraken2_outraw_0.05/C16.kraken.txt
C18	kraken2_outraw_0.05/C18.kraken.txt
C19	kraken2_outraw_0.05/C19.kraken.txt
C22	kraken2_outraw_0.05/C22.kraken.txt
C23	kraken2_outraw_0.05/C23.kraken.txt

```

This can be done by cutting the sample_id column from the metadata file.

Next, make a list of the Kraken2 output files for each sample (generated in step 3.1), and then paste the two together

```
cut -f 1 <project>_metadata.txt > sample_tags.txt

ls -1 kraken2_outraw/* > kraken2_results.txt

paste sample_tags.txt kraken2_results.txt > input_for_taxonomy_abundance_script.txt
```
Once this input file is ready run the add_6levelsTaxonomy_to_Kraken2Results.py python script (You would need the ete3 package installed):
```
python /home/dhwani/MyGit/MH2_test/add_6levelsTaxonomy_to_Kraken2Results.py --taxafilelist input_for_taxonomy_abundance_script.txt --outfile PROJECT-kraken2_abundance_matrix-6level-tax.txt
```

Finally, run the following script to convert the stratified RPKM output file generated in step 5.2 to the 4-column format required by the Visualizer app

```
python /home/dhwani/MyGit/MH2_test/convert_stratifiedRpkm_to_SankeyFormat.py --StratFileName PROJECT-strat-matrix-RPKM.txt --taxaAbundFile PROJECT-kraken2_abundance_matrix-6level-tax.txt --outfile PROJECT-rpkm-stratified-SankeyFormat.txt
```

The interactive changes (dragging the nodes to different positions) can also be saved as scalable graphics (png). To do this, yo can save the plot as html. Then open the html in a browser such as Chrome or Firefox using the File -> Open File menu. Once the plot is displayed in the browser, you can open the web developer tools by going to More Tools -> Web Developer Tools. This opens the the html inspector window. Here, you can select the svg element by searching for the <svg> tag. Right-clicking on this element will open a menu from which you can select the "Screenshot Node" option. This will save the modified plot as a png. This has been tested in Chrome version 110.0.5481.100 and Firefox version 110.0.1. 
