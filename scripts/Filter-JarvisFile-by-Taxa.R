# Invoke the libraries
library(dplyr)
library(stringr)

# Set working directory to where your DB file is
setwd("/Users/falgunidesai/work/Jarrvis-testing/IBD-metatrascriptomes/")

# Read in the complete DB file
results_mat <- read.delim2('selectedID-JarrVis-input.txt', 
                           header = T, sep = "\t", fill = T, as.is = T, stringsAsFactors = F,
                           na.strings = "NA", blank.lines.skip = T, row.names = NULL
                          )

# Here you can specify keyword string you want to search and the column you want search in
selectedMat <- results_mat %>%
  filter(str_detect(Genus, 
                    regex("Alistipes|Bacteroides|Bifidobacterium|Coprococcus
        |Faecalibacterium|Subdoligranulum
        |Escherichia|Eubacterium|Lachnospiraceae
        |Roseburia|Ruminococcus",ignore_case = T)),
  )

# Write out the selected subset of rows as a tab-delimited text file
# This file can be used as input to JarrVis along with a suitable
# metadata file
# For more details on JarrVis usage:
# https://github.com/dhwanidesai/JarrVis
write.table(selectedMat, file = paste("ibd-selected-samples-selected-Genera","inputForJarrVis","txt", sep = "."), sep = "\t", quote = F, 
            append = F, na = "missing",
            row.names = F, eol = "\r\n"
)
