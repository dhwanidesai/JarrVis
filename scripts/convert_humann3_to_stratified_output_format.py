# Create a simple dataframe 
  
# importing pandas as pd 
import pandas as pd 
import argparse, sys, textwrap
import numpy as np

parser=argparse.ArgumentParser()
parser.add_argument('--Humann3OutputFilename', help = 'stratified humann3 output, e.g *abun_contrib.tsv')
parser.add_argument('--outfilename', help = 'Output filename to store stratified output')

def main():
    # creating a dataframe
    args = parser.parse_args()
    StratfileN = args.Humann3OutputFilename
    #taxFileN = args.Qiime2TaxonomyForASVs
    outputfileN = args.outfilename
    
    #pwayID_map_flag = args.mapMetaCycID2names
    #pway_mapfile = args.MetaCycMapfile
 
    df = pd.read_csv(StratfileN, sep = '\t',header=0)
    print (df.head())

    df[['Gene', 'Genus']] = df['pathway'].str.split('|', expand=True)
    df = df.drop('pathway', axis=1)
    print(df.head())

    ranks_lst = ["phylum","class","order","family","genus","species"]
    prefix_dict = {
        "p__": "phylum",
        "c__": "class",
        "o__": "order",
        "f__": "family",
        "g__": "genus",
        "s__": "species"
    }

    df['Genus'] = df['Genus'].map(lambda x:checkCompleteTaxStr(x,prefix_dict,ranks_lst))


    cols = df.columns.tolist()
    print("column names:",cols)

    # Move the last two columns (Gene and Genus) to the front
    cols.insert(0, cols.pop())
    cols.insert(0, cols.pop())
    print("column names:", cols)
    df = df[cols]
    print(df.head())
    df_long = df.melt(id_vars=["Gene", "Genus"], var_name="Sample", value_name="Contribution")
    print(df_long.head())

    long_cols = df_long.columns.tolist()
    long_cols[0], long_cols[2] = long_cols[2], long_cols[0]
    #print("Final Columns of DF:", cols)

    df_long = df_long[long_cols]

    # DF_long[~DF_long.Sample.str.contains("OTU", na=False)]

    pd.DataFrame.to_csv(df_long, path_or_buf=outputfileN, sep='\t', na_rep='NA', header=True, index=False, mode='w',
                        lineterminator='\n', escapechar=None, decimal='.')
def checkCompleteTaxStr(taxString,prefDict,ranksLst):
    inputTaxaDict = {}
    fullTaxaString = ""
    if taxString is not None and taxString != "":
        arrayTax = taxString.split(".")
        for taxa in arrayTax:
            if "__" in taxa:
                inpt_tax_list = taxa.split("__",1)
                #print("input taxxa list", inpt_tax_list)
                key = inpt_tax_list[0]+"__"
                inputTaxaDict[key] = inpt_tax_list[1]

        print("In checkTaxa ...:",inputTaxaDict)
        for prefix in prefDict.keys():
            if prefix not in inputTaxaDict.keys():
                inputTaxaDict[prefix] = "NA"

        print("Still In checkTaxa ...:", inputTaxaDict)
        for rank in ranksLst:
            pref = [k for k,v in prefDict.items() if v == rank][0]
            #print("prefix is:",pref)
            taxa_name = inputTaxaDict[str(pref)]
            fullTaxaString = fullTaxaString + pref + taxa_name + ";"

    print ("Almost out of checkTaxa:",fullTaxaString)
    #fullTaxaString_final = fullTaxaString.rstrip(fullTaxaString[-1])
    fullTaxaString = fullTaxaString[:-1]
    return fullTaxaString






def return_tax_dict(taxfile):
    d = {}
    with open(taxfile) as f:
        for line in f:
            (key, val) = line.rstrip("\n").split("\t")
            d[str(key)] = val

    #print (d) 

    return d

def return_pwayIDNameMap(pwayMapF):
    d = {}
    with open(pwayMapF) as f:
        for line in f:
            fields = line.split(",")
            key = fields[0]
            val = fields[1] 
            d[str(key)] = str(val)
            #d[key].append(val)
    
    return d

if __name__ == "__main__":
        main();
