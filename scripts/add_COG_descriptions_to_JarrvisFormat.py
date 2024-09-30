import pandas as pd
import csv
from collections import defaultdict

import argparse, sys, textwrap

parser=argparse.ArgumentParser()

parser.add_argument('--jarrvisInputfile', help=textwrap.dedent('''
    File contiaing the table of functions annotated
    in Bins
     '''))
parser.add_argument('--COGdescriptionsFile', help = "File containing taxa labels for the bins")
parser.add_argument('--outFileName', help = "Specify the output file to write stratified  table")
def main():
 args = parser.parse_args()
 JarrvisFileN = args.jarrvisInputfile
 descFileN = args.COGdescriptionsFile
 outfile = args.outFileName
 df = pd.read_csv(JarrvisFileN, sep='\t', header=0)
 COGFuncDict = parseCOGLabelfile(descFileN)

 df['GeneWithDesc'] = df['Gene'].map(COGFuncDict)
 df.drop('Gene', inplace=True, axis=1)
 cols = df.columns.tolist()
 print("Old column order:", cols)
 cols[2],cols[3] = cols[3],cols[2]
 print("New column order:", cols)
 df = df[cols]
 df = df.rename(columns={'GeneWithDesc': 'Gene'})

 #dfT = df.T
 #df_long = df.melt(id_vars=["function", "sequence"], var_name="Sample", value_name="Contribution")
 #df_long = df_long.rename(columns={"function": "Sample", "sequence": "Genus","Sample": "Gene"})
 pd.DataFrame.to_csv(df, path_or_buf=outfile, sep='\t', na_rep='', header=True, index=False, index_label='function',
                     mode='w', escapechar=None, decimal='.')


def parseCOGLabelfile(filename):
 COG_func_Dict = {}
 labeldf = pd.read_csv(filename, sep='\t',header=0)
 #labeldf['TaxaStr'] = taxadf[['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species']].apply(lambda x: ';'.join(x), axis=1)

 COG_func_Dict = dict(zip(labeldf.accession, labeldf.description))

 return COG_func_Dict



if __name__ == "__main__":
 main();
