# My script to run hicexplorer

## Environment configuration
I recommend Using conda to build your analysis env.
```
conda create -n hicexplorer
conda activate hicexplorer
conda install hicexplorer seqkit bwa bwa-meme
```

## How to use?
### 1. Config your own enzyme file. Put your Hi-C genereate enzymes in the file called `enzyme.txt`
Like:
`enzyme.txt`
```
GATC
GA.TC
CT.AG
TTAA
```

### 2. Copy or soft link your Hi-C raw data to your current working directory.

### 3. Using `vim` open the `automate_hicexplorer.sh` file and change the config parameters.


## To-do list:
1. Improve the `if` judging condition
2. Improve the pipeline consistency
3. Add more error alerts and hints.
