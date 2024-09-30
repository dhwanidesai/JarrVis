import pandas as pd

import argparse, sys, textwrap

parser=argparse.ArgumentParser()
parser.add_argument('--PathAbundancesF', help = 'Pathway abundances file from humann3')
parser.add_argument('--selectedIdsFile', help = 'Sample Ids to select')
parser.add_argument('--outfilename', help = 'Output filename to store stratified output')

def main():
    args = parser.parse_args()
    PathAbundF = args.PathAbundancesF
    selIdsF = args.selectedIdsFile
    outputfileN = args.outfilename
    df = pd.read_csv(PathAbundF, sep='\t', header=0, index_col=0)
    print (df.head())
    listSelectedIds = pd.read_csv(selIdsF, header=None)[0].tolist()
    print ("Selected sample Ids:",listSelectedIds)
    selectedDF = df[[c for c in df.columns if c in listSelectedIds]]
    print(selectedDF.head())
    pd.DataFrame.to_csv(selectedDF, path_or_buf=outputfileN, sep='\t', na_rep='', header=True, mode='w',
                        lineterminator='\n', escapechar=None, decimal='.')

if __name__ == "__main__":
        main();
