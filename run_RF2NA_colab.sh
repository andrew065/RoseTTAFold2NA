#!/bin/bash

# make the script stop when error (non-true exit code) occurs
set -e

############################################################
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('conda' 'shell.bash' 'hook' 2> /dev/null)"
eval "$__conda_setup"
unset __conda_setup
# <<< conda initialize <<<
############################################################

SCRIPT=`realpath -s $0`
export PIPEDIR=`dirname $SCRIPT`
HHDB="$PIPEDIR/pdb100_2021Mar03/pdb100_2021Mar03"

CPU="8"  # number of CPUs to use
MEM="64" # max memory (in GB)

WDIR=`realpath -s $1`  # working folder
mkdir -p $WDIR/log

conda activate RF2NA

# process protein (MSA + homology search)
function proteinMSA {
    seqfile=$1
    tag=$2

    ############################################################
    # generate MSAs using ColabFold
    ############################################################
    if [ ! -s $WDIR/$tag.msa0.a3m ]
    then
        echo "Running ColabFold for MSA generation"
        echo " -> Running command: $PIPEDIR/input_prep/make_protein_msa_colabfold.sh $seqfile $WDIR $tag $CPU $MEM"
        $PIPEDIR/input_prep/make_protein_msa_colabfold.sh $seqfile $WDIR $tag $CPU $MEM > $WDIR/log/make_msa.$tag.stdout 2> $WDIR/log/make_msa.$tag.stderr
    fi


    ############################################################
    # search for templates
    ############################################################
    if [ ! -s $WDIR/$tag.hhr ]
    then
        echo "Running hhsearch"
        HH="hhsearch -b 50 -B 500 -z 50 -Z 500 -mact 0.05 -cpu $CPU -maxmem $MEM -aliw 100000 -e 100 -p 5.0 -d $HHDB"
        echo " -> Running command: $HH -i $WDIR/$tag.msa0.ss2.a3m -o $WDIR/$tag.hhr -atab $WDIR/$tag.atab -v 0"
        $HH -i $WDIR/$tag.msa0.a3m -o $WDIR/$tag.hhr -atab $WDIR/$tag.atab -v 0 > $WDIR/log/hhsearch.$tag.stdout 2> $WDIR/log/hhsearch.$tag.stderr
    fi
}

# process DNA (copy DNA files)
function DNAMSA {
    seqfile=$1
    tag=$2

    ############################################################
    # copy DNA files
    ############################################################
    if [ ! -s $WDIR/$tag.fa ]
    then
        echo "Copying DNA file"
        echo " -> Running command: cp $seqfile $WDIR/$tag.fa"
        cp $seqfile $WDIR/$tag.fa
    fi
}

argstring=""

shift
nP=0
nD=0
for i in "$@"
do
    type=`echo $i | awk -F: '{if (NF==1) {print "P"} else {print $1}}'`
    type=${type^^}
    fasta=`echo $i | awk -F: '{if (NF==1) {print $1} else {print $2}}'`
    tag=`basename $fasta | sed -E 's/\.fasta$|\.fas$|\.fa$//'`

    if [ $type = 'P' ]
    then
        proteinMSA $fasta $tag
        argstring+="P:$WDIR/$tag.msa0.a3m:$WDIR/$tag.hhr:$WDIR/$tag.atab "
        nP=$((nP+1))
        lastP="$tag"
    elif [ $type = 'D' ]
    then
        DNAMSA $fasta $tag
        argstring+="D:$WDIR/$tag.fa "
        nD=$((nD+1))
        lastD="$tag"
    elif [ $type = 'S' ]
    then
        cp $fasta $WDIR/$tag.fa
        argstring+="S:$WDIR/$tag.fa "
        nD=$((nD+1))
    fi
done

############################################################
# Merge MSAs for Protein-DNA
############################################################
if [ $nP -eq 1 ] && [ $nD -eq 1 ]
then
    echo "Creating joint Protein-DNA MSA"
    echo " -> Running command: $PIPEDIR/input_prep/merge_msa_prot_dna.py $WDIR/$lastP.msa0.a3m $WDIR/$lastD.fa $WDIR/$lastP.$lastD.a3m"
    $PIPEDIR/input_prep/merge_msa_prot_dna.py $WDIR/$lastP.msa0.a3m $WDIR/$lastD.fa $WDIR/$lastP.$lastD.a3m > $WDIR/log/make_pMSA.$tag.stdout 2> $WDIR/log/make_pMSA.$tag.stderr
    argstring="PD:$WDIR/$lastP.$lastD.a3m:$WDIR/$lastP.hhr:$WDIR/$lastP.atab"
fi

############################################################
# end-to-end prediction
############################################################
echo "Running RoseTTAFold2NA to predict structures"
echo " -> Running command: python $PIPEDIR/network/predict.py -inputs $argstring -prefix $WDIR/models/model -model $PIPEDIR/network/weights/RF2NA_apr23.pt -db $HHDB"
mkdir -p $WDIR/models

python $PIPEDIR/network/predict.py \
    -inputs $argstring \
    -prefix $WDIR/models/model \
    -model $PIPEDIR/network/weights/RF2NA_apr23.pt \
    -db $HHDB #2> $WDIR/log/network.stderr #1> $WDIR/log/network.stdout 

echo "Done" 

python /network/predict.py \
    -inputs $argstring \
    -prefix $WDIR/models/model \
    -model $PIPEDIR/network/weights/RF2NA_apr23.pt \
    -db $HHDB #2> $WDIR/log/network.stderr #1> $WDIR/log/network.stdout 


/hpf/projects/mkoziarski/alian/igem/RoseTTAFold2NA/input_prep/merge_msa_prot_dna.py 
/hpf/projects/mkoziarski/alian/igem/RoseTTAFold2NA/experiments/test_docking_20619769/CXCL9.msa0.a3m 
/hpf/projects/mkoziarski/alian/igem/RoseTTAFold2NA/experiments/test_docking_20619769/CXCL9_aptaprimer_98nt.fa 
/hpf/projects/mkoziarski/alian/igem/RoseTTAFold2NA/experiments/test_docking_20619769/CXCL9.CXCL9_aptaprimer_98nt.a3m