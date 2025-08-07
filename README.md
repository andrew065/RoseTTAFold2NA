# RF2NA
RoseTTAFold2NA predicts 3D structures of protein-nucleic acid complexes using deep learning. 

This repository extends RoseTTAFold2 to handle protein MSA generation using ColabFold for simplified setup without large database downloads. This is primarily intended for protein-DNA complex predictions.

**New: April 13, 2023 v0.2**
* Updated weights (https://files.ipd.uw.edu/dimaio/RF2NA_apr23.tgz) for better prediction of homodimer:DNA interactions and better DNA-specific sequence recognition
* Bugfixes in MSA generation pipeline
* Support for paired protein/RNA MSAs

## Installation

1. Clone the package
```
git clone https://github.com/uw-ipd/RoseTTAFold2NA.git
cd RoseTTAFold2NA
```

2. Create conda environment
All external dependencies are contained in `RF2na-linux.yml`
```
# create conda environment for RoseTTAFold2NA
conda env create -f RF2na-linux.yml
```
You also need to install NVIDIA's SE(3)-Transformer (**please use SE3Transformer in this repo to install**).
```
conda activate RF2NA
cd SE3Transformer
pip install --no-cache-dir -r requirements.txt
python setup.py install
cd ..
```

3. Download pre-trained weights under network directory
```
cd network
wget https://files.ipd.uw.edu/dimaio/RF2NA_apr23.tgz
tar xvfz RF2NA_apr23.tgz
ls weights/ # it should contain a 1.1GB weights file
cd ..
```

4. Download sequence and structure databases

Note: This repository uses ColabFold for protein MSA generation via online databases. Local MSA database downloads (UniRef30 + BFD ~318GB) are not required. Only structure templates are needed.

```
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

## ColabFold Integration

ColabFold integration eliminates large database downloads by accessing UniRef30/BFD online. See `README_colabfold.md` for details.

# RNA databases
mkdir -p RNA
cd RNA

# Rfam [300M]
wget ftp://ftp.ebi.ac.uk/pub/databases/Rfam/CURRENT/Rfam.full_region.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/Rfam/CURRENT/Rfam.cm.gz
gunzip Rfam.cm.gz
cmpress Rfam.cm

# RNAcentral [12G]
wget ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/current_release/rfam/rfam_annotations.tsv.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/current_release/id_mapping/id_mapping.tsv.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/current_release/sequences/rnacentral_species_specific_ids.fasta.gz
../input_prep/reprocess_rnac.pl id_mapping.tsv.gz rfam_annotations.tsv.gz   # ~8 minutes
gunzip -c rnacentral_species_specific_ids.fasta.gz | makeblastdb -in - -dbtype nucl  -parse_seqids -out rnacentral.fasta -title "RNACentral"

# nt [151G]
update_blastdb.pl --decompress nt
cd ..
```

## Usage

For running on SLURM clusters, use the provided job submission script:
```bash
# Submit protein-DNA docking job
sbatch scripts/protein_dna_docking.sh [experiment_name]

# Example:
sbatch scripts/protein_dna_docking.sh CXCL9_aptamer
```

The SLURM script automatically handles:
- Environment activation
- GPU allocation
- Experiment directory creation
- Result organization
### Inputs
* The first argument to the script is the output folder
* The remaining arguments are fasta files for individual chains in the structure.  Use the tags `P:xxx.fa` `R:xxx.fa` `D:xxx.fa` `S:xxx.fa` to specify protein, RNA, double-stranded DNA, and single-stranded DNA, respectively.  Use the tag `PR:xxx.fa` to specify paired protein/RNA.    Each chain is a separate file; 'D' will automatically generate a complementary DNA strand to the input strand.  

### Expected outputs

**Output Organization:**
* Outputs are organized in experiment directories: `experiments/{experiment_name}_{job_id}/`
* Each experiment contains:
  - `slurm_{job_id}.out` - Job log file
  - `models/` - Prediction results subfolder
  - MSA and intermediate files

**Output Files:**
* `models/model_00.pdb` - Predicted structure with per-residue LDDT in B-factor column
* `models/model_00.npz` - Numpy file containing three tables (L=complex length):
   - dist (L x L x 37) - the predicted distogram
   - lddt (L) - the per-residue predicted lddt
   - pae (L x L) - the per-residue pair predicted error

## Results Analysis

For analyzing the prediction results, see `notebooks/rf2na_results_analysis.ipynb` which provides tools to visualize and interpret the distogram, LDDT scores, and PAE matrices from the numpy output files.
