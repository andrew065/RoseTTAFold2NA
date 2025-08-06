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

## Advantages

- **No local database downloads**: Saves 300+ GB storage
- **Always updated**: Uses latest database versions
- **Fast**: MMseqs2 is faster than HHblits
- **Easy setup**: Just install ColabFold

## Disadvantages

- **Internet dependency**: Requires stable connection
- **Rate limiting**: May have usage limits
- **Privacy**: Sequences sent to external servers

## Output Files

The script generates the same output files as the original:

- `tag.msa0.a3m` - Multiple sequence alignment (A3M format)
- `tag.hhr` - HHsearch results (if HHsearch database provided)
- `tag.atab` - HHsearch alignment table (if HHsearch database provided)

## Databases Used

- **UniRef30**: Primary protein sequence database
- **BFD**: Backup database (Big Fantastic Database)
- **PDB100**: Structure database for templates (via HHsearch)

## Comparison with Original

| Feature | Original (HHblits) | ColabFold |
|---------|-------------------|-----------|
| Databases | Local UniRef30/BFD | Online UniRef30/BFD |
| Speed | Slower | Faster (MMseqs2) |
| Storage | 300+ GB | 0 GB |
| Setup | Complex | Simple |
| Updates | Manual | Automatic |
| Privacy | Local | External servers |

## Troubleshooting

### ColabFold Import Error
```bash
pip install colabfold
```

### Network Issues
- Check internet connection
- Try again later (rate limiting)
- Use local databases as fallback

### Memory Issues
- Reduce `--mem` parameter
- Use fewer CPUs with `--cpu`

## Example

```bash
# Generate MSA for a protein
./make_protein_msa_colabfold.sh protein.fa output_dir protein 8 64

# Check output
ls -la output_dir/protein.*
# Should see: protein.msa0.a3m
``` 