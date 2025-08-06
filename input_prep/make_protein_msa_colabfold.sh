#!/bin/bash

# ColabFold-based protein MSA generation wrapper
# Matches the interface of make_protein_msa.sh

# inputs
in_fasta="$1"
out_dir="$2"
tag="$3"

# resources
CPU="$4"
MEM="$5"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if ColabFold is available
if ! python3 -c "import colabfold" 2>/dev/null; then
    echo "ERROR: ColabFold not installed. Install with: pip install colabfold"
    exit 1
fi

# Run the Python script
python3 "$SCRIPT_DIR/protein_msa_colabfold.py" \
    "$in_fasta" \
    "$out_dir" \
    "$tag" \
    --cpu "$CPU" \
    --mem "$MEM"

# Check if MSA was generated successfully
if [ ! -s "$out_dir/$tag.msa0.a3m" ]; then
    echo "ERROR: Failed to generate MSA file"
    exit 1
fi

echo "ColabFold MSA generation completed: $out_dir/$tag.msa0.a3m" 