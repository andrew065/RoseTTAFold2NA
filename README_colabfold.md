# ColabFold-based Protein MSA Generation for RF2NA

This directory contains a ColabFold-based alternative to `make_protein_msa.sh` that uses online databases instead of local downloads.

## Files

- `protein_msa_colabfold.py` - Main Python script using ColabFold
- `make_protein_msa_colabfold.sh` - Bash wrapper matching original interface
- `README_colabfold.md` - This documentation

## Installation

1. Install ColabFold:
```bash
pip install colabfold
```

2. Make scripts executable:
```bash
chmod +x make_protein_msa_colabfold.sh
chmod +x protein_msa_colabfold.py
```

## Usage

### Direct Python Usage

```bash
python3 protein_msa_colabfold.py input.fa output_dir tag --cpu 8 --mem 64
```

### Bash Wrapper (matches original interface)

```bash
./make_protein_msa_colabfold.sh input.fa output_dir tag 8 64
```

### Integration with RF2NA

To use ColabFold instead of local databases in RF2NA:

1. **Option 1**: Replace the call in `run_RF2NA.sh`:
```bash
# Replace this line:
$PIPEDIR/input_prep/make_protein_msa.sh $seqfile $WDIR $tag $CPU $MEM

# With this:
$PIPEDIR/input_prep/make_protein_msa_colabfold.sh $seqfile $WDIR $tag $CPU $MEM
```

2. **Option 2**: Use the Python script directly in your pipeline
