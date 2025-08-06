#!/bin/bash

#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --gres=gpu:1
#SBATCH --time=72:00:00
#SBATCH --job-name=download_dbs
#SBATCH --reservation=mkoziarski_gpu

echo "-----------------------------"
echo "Job ID: $SLURM_JOB_ID"
echo "Node(s): $SLURM_NODELIST"
echo "Start: $(date)"
echo "-----------------------------"

source $HOME/.bashrc
conda activate rgfn


# uniref30 [46G]
wget http://wwwuser.gwdg.de/~compbiol/uniclust/2020_06/UniRef30_2020_06_hhsuite.tar.gz
mkdir -p UniRef30_2020_06
tar xfz UniRef30_2020_06_hhsuite.tar.gz -C ./UniRef30_2020_06

# BFD [272G]
wget https://bfd.mmseqs.com/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt.tar.gz
mkdir -p bfd
tar xfz bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt.tar.gz -C ./bfd

# structure templates (including *_a3m.ffdata, *_a3m.ffindex)
wget https://files.ipd.uw.edu/pub/RoseTTAFold/pdb100_2021Mar03.tar.gz
tar xfz pdb100_2021Mar03.tar.gz

echo "End time: $(date)"