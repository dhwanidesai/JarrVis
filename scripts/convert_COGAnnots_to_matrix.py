#import numpy as np
import pandas as pd
import csv
from collections import defaultdict

import argparse, sys, textwrap

parser=argparse.ArgumentParser()

parser.add_argument('--AnvioFunctionFileList', help=textwrap.dedent('''
    List file containing paths to the Anvio function files 
    (COG, KoFam, KEGG etc) for each Bin or Mag or Genome   
    '''))
parser.add_argument('--outFileName', help = "Specify the output file to write the function table")

def main():
 args = parser.parse_args()
 FuncFileList = args.AnvioFunctionFileList
 outfile = args.outFileName

 with open(FuncFileList, newline='') as multif:
  multi_reader = csv.reader(multif, delimiter='\t')
  SampleFuncCountdict = {}
  for line in multi_reader:
   print("Sample:", line)
   sampletag = line[0]
   FuncFile = line[1]
   funcCountsDict = parseAnvioFuncFile(FuncFile)
   first10pairs = {k: funcCountsDict[k] for k in list(funcCountsDict)[100:120]}
   print("resultant dictionary taxa and func: \n", first10pairs)
   SampleFuncCountdict[sampletag] = funcCountsDict

  pdDF = pd.DataFrame.from_dict(SampleFuncCountdict, orient='index')
  pdDF.fillna(0, inplace=True)
  pd.DataFrame.to_csv(pdDF, path_or_buf=outfile, sep='\t', na_rep='', header=True, index=True, index_label='function',
                      mode='w', escapechar=None, decimal='.')





def parseAnvioFuncFile(filename):
 d = {}
 df = pd.read_csv(filename, sep='\t', header=0)
 print ("In parse",df.head())
 Accession_list = df['accession'].tolist()
 d = {x: Accession_list.count(x) for x in Accession_list}
 return d

if __name__ == "__main__":
 main();
