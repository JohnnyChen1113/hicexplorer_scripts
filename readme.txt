# My script to run hicexplorer

## Environment configuration
I recommend Using conda to build your analysis env.
```
conda create -n hicexplorer
conda activate hicexplorer
conda install hicexplorer seqkit bwa bwa-meme
```

## How to use?
### 1. make your own enzyme file. Put your Hi-C genereate enzymes in the file called `enzyme.txt`
Like:
`enzyme.txt`
```
GATC
GA.TC
CT.AG
TTAA
```
