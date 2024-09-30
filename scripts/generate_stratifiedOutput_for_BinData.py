import pandas as pd
import csv
from collections import defaultdict

import argparse, sys, textwrap

parser=argparse.ArgumentParser()

parser.add_argument('--BinFunctionMatrix', help=textwrap.dedent('''
    File contiaing the table of functions annotated
    in Bins
     '''))
parser.add_argument('--BinTaxaLabels', help = "File containing taxa labels for the bins")
parser.add_argument('--outFileName', help = "Specify the output file to write stratified  table")
def main():
 args = parser.parse_args()
 FuncFileN = args.BinFunctionMatrix
 taxaFileN = args.BinTaxaLabels
 outfile = args.outFileName
 df = pd.read_csv(FuncFileN, sep='\t', header=0)
 binTaxaDict = parseTaxaFile(taxaFileN)

 df['sequence'] = df['function'].map(binTaxaDict)
 #dfT = df.T
 df_long = df.melt(id_vars=["function", "sequence"], var_name="Sample", value_name="Contribution")
 df_long = df_long.rename(columns={"function": "Sample", "sequence": "Genus","Sample": "Gene"})
 pd.DataFrame.to_csv(df_long, path_or_buf=outfile, sep='\t', na_rep='', header=True, index=False, index_label='function',
                     mode='w', escapechar=None, decimal='.')


def parseTaxaFile(filename):
 Bin_Taxa_Dict = {}
 taxadf = pd.read_csv(filename, sep='\t',header=0)
 taxadf['TaxaStr'] = taxadf[['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species']].apply(lambda x: ';'.join(x), axis=1)

 Bin_Taxa_Dict = dict(zip(taxadf.Genome, taxadf.TaxaStr))

 return Bin_Taxa_Dict



if __name__ == "__main__":
 main();
