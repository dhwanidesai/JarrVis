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
git clone 
```

To run this app you would require a local install of Rstudio (R version >=3.6) with the shiny package (required). Once Rstudio is installed, open it and run app.R file using the "Run App" button in Rstudio

## Running through Github Gist from Rstudio

Just run the following commands in Rstudio

```
library(shiny)
runGist("943ff5fdbd94815cc27f302d9f56ff0b")
```

## Navigating the interface
Running the app.R file in Rstudio (either locally or using the Github Gist) should bring up the app interface.

### Loading the RPKM input file and the metadata file

You can upload the stratified Rpkm file (in the 4-column format that we generated above) and the metadata file (provided in the test_data folder), by clicking the "Browse" button and locating the file on your computer.

Once the metadata file is uploaded, you can click on the "Select Metadata Categories" button to load the metadata categories in the dropdown menu below. PLease select the appropriate metadata category from the dropdown menu. For a selected metadata category, the mean RPKM values for each taxa and function in the samples in each category will be displayed 

### Setting the taxonomic level to display
The app has options for collapsing the RPKM table at the desired level of taxonomy (out of Phylum, Class, Order, Family, Genus or species) for visualization. For a selected taxonomic level (e.g Genus), the mean RPKM values for the genera in all samples per metadata category will be displayed. 

### Setting the RPKM filtering threshold range
The RPKM range (minimum and maximum) can be selected using the Slider input. By default the minimum is set to 5 and the maximum is set to 10. After the first plot is generated using this default value, you can re-calibrate the range by clicking the "Update the Gene Contribution Threshold from data" button. This will reset the range from the median RPKM value in the data to the maximum RPKM value. You can now select an appropriate range of RPKM values to display by sliding the minimum and maximum buttons to the desired values. Clicking the "Display Plot" button thereafter will display the plot for the selected RPKM range 

### Interactive Sankey plot
Once all the parameters are set, you can click on "Display Plot" to generate the Sankey plot.

Right-Clicking on the Sample group nodes will highlight the linkages all the way through to the taxonomy nodes and the corresponding function nodes. Right-clicking on the Function nodes will hightlight the linkages all the way through to taxonomy nodes and the corresponding Sample group nodes.

Left-click and drag the nodes to change their position.

Hovering over nodes or links will display the underlying rpkm value.

### Saving the plots

You can download the resulting plot as html, png, pdf or jpeg. You can select the format using the "Save Plot as" radio buttons.

The interactive changes (dragging the nodes to different positions) can also be saved as scalable graphics (png). To do this, yo can save the plot as html. Then open the html in a browser such as Chrome or Firefox using the File -> Open File menu. Once the plot is displayed in the browser, you can open the web developer tools by going to More Tools -> Web Developer Tools. This opens the the html inspector window. Here, you can select the svg element by searching for the <svg> tag. Right-clicking on this element will open a menu from which you can select the "Screenshot Node" option. This will save the modified plot as a png. This has been tested in Chrome version 110.0.5481.100 and Firefox version 110.0.1. 
