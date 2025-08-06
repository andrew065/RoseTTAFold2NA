#!/bin/bash

#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --gres=gpu:1
#SBATCH --time=72:00:00
#SBATCH --job-name=download_dbs
#SBATCH --reservation=mkoziarski_gpu

#SBATCH --output=experiments/protein-dna/run_prot_dna_%j.out

echo "-----------------------------"
echo "Job ID: $SLURM_JOB_ID"
echo "Node(s): $SLURM_NODELIST"
echo "Start: $(date)"
echo "-----------------------------"

source $HOME/.bashrc
conda activate rgfn


