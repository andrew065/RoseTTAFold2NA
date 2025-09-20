#!/bin/bash

#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=80G
#SBATCH --gres=gpu:1
#SBATCH --time=24:00:00
#SBATCH --reservation=mkoziarski_gpu
#SBATCH --job-name=rf2na_docking
#SBATCH --output=slurm_%j.out

source $HOME/.bashrc
conda activate RF2NA


# SLURM job submission script for RoseTTAFold2NA protein-DNA docking experiments
# Usage: sbatch submit_protein_dna_docking.sh [experiment_name]

# =============================================================================
# CUSTOMIZE THESE VARIABLES FOR YOUR EXPERIMENT
# =============================================================================

# Set project root directory (absolute path)
PROJECT_ROOT="/hpf/projects/mkoziarski/alian/igem/RoseTTAFold2NA"

# Input files (use absolute paths)
PROTEIN_FASTA="$PROJECT_ROOT/data/CXCL9.fa"                      # Protein FASTA file
DNA_FASTA="$PROJECT_ROOT/data/CXCL9_aptaprimer_104.fa"           # DNA FASTA file


# Set the experiment name to the first command-line argument, or use "test" as default if not provided
EXPERIMENT_NAME=${1:-"test"}

# =============================================================================
# SCRIPT LOGIC (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Get SLURM job ID
SLURM_JOB_ID=${SLURM_JOB_ID:-$(date +%s)}

# Create unique experiment directory
EXPERIMENT_DIR="experiments/${EXPERIMENT_NAME}_${SLURM_JOB_ID}"
mkdir -p $EXPERIMENT_DIR

mv "slurm_${SLURM_JOB_ID}.out" "$EXPERIMENT_DIR/"

echo "============================================="
echo "RoseTTAFold2NA Protein-DNA Docking Experiment"
echo "============================================="
echo ''
echo "Job ID: $SLURM_JOB_ID"
echo "Node(s): $SLURM_NODELIST"
echo "Start: $(date)"
echo "Experiment directory: $EXPERIMENT_DIR"
echo "Protein FASTA: $PROTEIN_FASTA"
echo "DNA FASTA: $DNA_FASTA" 
echo ''
echo "============================================="
echo ''

# Check if input files exist
if [ ! -f "$PROTEIN_FASTA" ]; then
    echo "ERROR: Protein FASTA file not found: $PROTEIN_FASTA"
    echo "Please update the PROTEIN_FASTA variable in the script"
    exit 1
fi

if [ ! -f "$DNA_FASTA" ]; then
    echo "ERROR: DNA FASTA file not found: $DNA_FASTA"
    echo "Please update the DNA_FASTA variable in the script"
    exit 1
fi

# Change to experiment directory
cd $EXPERIMENT_DIR

# Run RoseTTAFold2NA with ColabFold
echo "Starting RoseTTAFold2NA with ColabFold MSA generation..."
echo "Command: $PROJECT_ROOT/scripts/run_RF2NA_colab.sh . P:$PROTEIN_FASTA D:$DNA_FASTA"
echo ''

# Run docking with single stranded DNA using `S` tag
$PROJECT_ROOT/scripts/run_RF2NA_colab.sh . P:$PROTEIN_FASTA S:$DNA_FASTA

# Run docking with double stranded DNA using `D` tag (complentary sequence will be auto generated)
# $PROJECT_ROOT/scripts/run_RF2NA_colab.sh . P:$PROTEIN_FASTA D:$DNA_FASTA

echo ''
echo "============================================="
echo "End time: $(date)"
echo "Results are in: $EXPERIMENT_DIR"
echo "=============================================" 