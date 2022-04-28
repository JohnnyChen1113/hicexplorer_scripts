#!/usr/bin/env bash

# To run the hicexplorer automatically
# Author: Junhao Chen
# Date: 2022-04-28
# Version: 0.1.1: Using bwa-meme replaced bwa to accelerate the processing speed. Add portability for this script.

# The config files:
# - enzyme.txt: The enzymes used to genereate the hi-c raw data.
# 	GATC
# 	GA.TC
# 	CT.AG
# 	TTAA
#
# The tools need:
# - seqkit
# - hicexplorer=3.7.2
# - bwa or bwa-meme
# 

########## parameters ####
# Generate the top scaffolds you want
topNum=25
file1=${PWD}/1_R1.fastq.gz
file2=${PWD}/1_R2.fastq.gz

# Show the uasge

if [ -z ${1} ]
then
  	echo "Usage: nohup bash ${0} <genome_file> > out.log &"
	exit $E_BADARGS
fi

# Sort the genome

if [ ! -f ${1%.*}/${1%.*}.sorted.fasta ]
then
seqkit sort -r -l ${1} -o ${1%.*}/${1%.*}.sorted.fasta
else
    ho "The ${1} already sorted!"
fi
# check and generate the folder
if [ ! -d ${1%.*} ]
then
  mkdir ${1%.*}
else
  echo "The ${1%.*} folder already exist!"
fi
# Generate the enzyme files
if [ ! -f ${1%.*}/TTAA.bed ]
then
for i in `cat ${PWD}/enzyme.txt` 
do 
        hicFindRestSite --fasta ${1%.*}/${1%.*}.sorted.fasta --searchPattern ${i} -o ${1%.*}/${i}.bed
done
else
  echo "The enzyme files already done!"
fi

# Build the index
if [ ! -f ${1%.*}/${1%.*}.bwt ]
then
#bwa index -p ${1%.*}/${1%.*} ${1%.*}/${1%.*}.sorted.fasta
bwa-meme index -a meme -t 16 -p ${1%.*}/${1%.*} ${1%.*}/${1%.*}.sorted.fasta
else
  echo "The bwa index alreadt exist!"
fi

# Mapping with bwa
if [ ! -f ${1%.*}/1.bam ]
then
  #bwa mem -A 1 -B 4 -E 50 -L 0 -t 16 ${1%.*}/${1%.*} 1_R1.fastq.gz | samtools view -Shb - > ${1%.*}/1.bam 
  bwa-meme mem -A 1 -B 4 -E 50 -L 0 -t 16 ${1%.*}/${1%.*} ${file1} | samtools view -Shb - > ${1%.*}/1.bam
else
  echo "The 1.bam already mapped!"
fi
if [ ! -f ${1%.*}/2.bam ]
then
  #bwa mem -A 1 -B 4 -E 50 -L 0 -t 16 ${1%.*}/${1%.*} 1_R2.fastq.gz | samtools view -Shb - > ${1%.*}/2.bam
  bwa-meme mem -A 1 -B 4 -E 50 -L 0 -t 16 ${1%.*}/${1%.*} ${file2} | samtools view -Shb - > ${1%.*}/2.bam
else
  echo "The 2.bam already mapped!"
fi
# Build the hicMatrix
if [ ! -f ${1%.*}/${1%.*}.h5 ]
then
mkdir ${1%.*}/hicQC 

hicBuildMatrix \
--samFiles ${1%.*}/1.bam ${1%.*}/2.bam \
--binSize 10000 \
--restrictionCutFile ${1%.*}/CT.AG.bed  ${1%.*}/GA.TC.bed  ${1%.*}/GATC.bed ${1%.*}/TTAA.bed \
--restrictionSequence GATC GA.TC CT.AG TTAA \
--danglingSequence GATC A.T T.A TA \
--outFileName ${1%.*}/${1%.*}.h5 \
--outBam ${1%.*}/${1%.*}.bam \
--threads 8 \
--QCfolder ${1%.*}/hicQC \
--inputBufferSize 400000
fi

# Merge matrix bins for plotting
if [ ! -f ${1%.*}/${1%.*}.100bins.h5 ]
then
hicMergeMatrixBins \
--matrix ${1%.*}/${1%.*}.h5 \
--numBins 100 \
--outFileName ${1%.*}/${1%.*}.100bins.h5
fi

# Plot the corrected Hi-C matrix
if [ ! -f ${1%.*}/${1%.*}_1Mb_matrix.png ]
then
hicPlotMatrix \
--matrix ${1%.*}/${1%.*}.100bins.h5 \
--log1p \
--dpi 300 \
--clearMaskedBins \
--colorMap jet \
--title "Hi-C matrix for ${1}" \
--outFileName ${1%.*}/${1%.*}_1Mb_matrix.png
fi

# Plot the logest ${topNum} contigs
# Get the ids of this contigs
cat ${1%.*}/${1%.*}.sorted.fasta | grep ">" | head -${topNum} | tr -d '>' | paste -s -d ' ' > ${1%.*}/logest${topNum}.id && \
if [ ! -f ${1%.*}/${1%.*}_logest${topNum}_1Mb_matrix.png ]
then
hicPlotMatrix \
--matrix ${1%.*}/${1%.*}.100bins.h5 \
--log1p \
--dpi 300 \
--chromosomeOrder `cat ${1%.*}/logest${topNum}.id` \
--clearMaskedBins \
--colorMap jet \
--title "Logest${topNum} scaffolds Hi-C matrix for ${1}" \
--outFileName ${1%.*}/${1%.*}_logest${topNum}_1Mb_matrix.png
fi


