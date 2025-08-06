#!/usr/bin/env python3
"""
Pytest tests for protein_msa_colabfold.py
Tests the ColabFold-based MSA generation functionality
"""

import os
import sys
import tempfile
import subprocess
import shutil
import pytest
from pathlib import Path

# Use the Python interpreter from the RF2NA conda environment
CONDA_PYTHON = "/hpf/projects/mkoziarski/alian/miniconda3/envs/RF2NA/bin/python"

def create_test_fasta():
    """Create a test FASTA file with a sample protein sequence"""
    test_sequence = """MKTVRQERLKSIVRILERSKEPVSGAQLAEELSVSRQVIVQDIA
TYMLGGKQFEAMGPNMTAGDHDDAGQAGDIALERAFAPWYARWAVSQ
FNWMMRDYQAVRVVFEPAVRGFDIDAVKTVTEEAAEVTQATTETL
RAKVEELKNAMVKKYVEEMKAKEGLLGEYALPELIERVYLEDMC
AGFDDPSAVAIKMVKELGINPEFMRRSVESLLQKLPKEAKKEL
VEFEDKVLVRGEITLLALFQAGIERAGELELRVGEVEQEVH
RLKKEGVEHVKKKVDDLVKALRACGPTHLGLVAGFTGEPLP
MAAYIAELGLSALSRVAGVPELIRTLLNTICIQVAGLRERY
LTVKRRPVDPASQREPRMVVLLKAVWAIGCGFMLVLLTSV
QGKIKGLLLCLAVSGMVAGALVWKLVTQRSEFDTLFRVGN
LQAGDGDQAVEVWIGRLHALLGDVQIRDNLLDYKGVSPL
FDFTQVQMLLDGVWLLDRTLTLKRSEQVEEFRDGFLLTAR
AGVGYVVLAKALRDLPWLKQPTGGARFLPVEKDGRTLIA
LGGVISFALGVALSNPASRDPLLLGATSVDLAETVKTDL
LFLTAGLWGRKSVEEAERVGLIRDVTRLVLDPRELLYRM
VDYIMLVCLFSILAGLTLRSLQKLLLSLTLLVLSVLLL
LLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLV
LLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLV
LLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLVLLV"""
    
    # Clean up the sequence (remove newlines and spaces)
    test_sequence = test_sequence.replace('\n', '').replace(' ', '')
    
    return f">test_protein\n{test_sequence}"

@pytest.fixture
def test_fasta_file():
    """Fixture to create a temporary test FASTA file"""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.fa', delete=False) as f:
        f.write(create_test_fasta())
        temp_file = f.name
    
    yield temp_file
    
    # Cleanup
    if os.path.exists(temp_file):
        os.unlink(temp_file)

@pytest.fixture
def temp_output_dir():
    """Fixture to create a temporary output directory"""
    temp_dir = tempfile.mkdtemp()
    yield temp_dir
    
    # Cleanup
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)

def test_colabfold_import():
    """Test if ColabFold can be imported"""
    try:
        import colabfold
        assert True, "ColabFold import successful"
    except ImportError as e:
        pytest.fail(f"ColabFold import failed: {e}")

def test_script_exists():
    """Test that the protein_msa_colabfold.py script exists"""
    script_path = "../input_prep/protein_msa_colabfold.py"
    assert os.path.exists(script_path), f"Script not found: {script_path}"

def test_bash_wrapper_exists():
    """Test that the bash wrapper script exists"""
    wrapper_path = "../input_prep/make_protein_msa_colabfold.sh"
    assert os.path.exists(wrapper_path), f"Wrapper script not found: {wrapper_path}"


def test_script_execution(test_fasta_file, temp_output_dir):
    """Test the protein_msa_colabfold.py script execution"""
    script_path = "../input_prep/protein_msa_colabfold.py"
    
    # Run the script
    cmd = [
        CONDA_PYTHON, script_path,
        test_fasta_file,
        temp_output_dir,
        "test_protein",
        "--cpu", "1",
        "--mem", "8"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    
    # Check if script ran successfully
    assert result.returncode == 0, f"Script execution failed: {result.stderr}"
    
    # Check if output file was created
    output_file = os.path.join(temp_output_dir, "test_protein.msa0.a3m")
    assert os.path.exists(output_file), f"Output file not created: {output_file}"
    
    # Check file size
    file_size = os.path.getsize(output_file)
    assert file_size > 0, f"Output file is empty: {file_size} bytes"
    
    # Check if it's a valid A3M file
    with open(output_file, 'r') as f:
        content = f.read()
        assert content.startswith('>'), "Output file doesn't start with '>'"
        assert 'test_protein' in content, "Output file doesn't contain test protein name"

def test_bash_wrapper_execution(test_fasta_file, temp_output_dir):
    """Test the bash wrapper script execution"""
    wrapper_path = "../input_prep/make_protein_msa_colabfold.sh"
    
    # Make it executable
    os.chmod(wrapper_path, 0o755)
    
    # Run the wrapper
    cmd = [
        f"./{wrapper_path}",
        test_fasta_file,
        temp_output_dir,
        "test_protein",
        "1",
        "8"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    
    # Check if wrapper ran successfully
    assert result.returncode == 0, f"Bash wrapper execution failed: {result.stderr}"
    
    # Check if output file was created
    output_file = os.path.join(temp_output_dir, "test_protein.msa0.a3m")
    assert os.path.exists(output_file), f"Output file not created: {output_file}"

def test_interface_compatibility():
    """Test that the script has the same interface as the original"""
    script_path = "../input_prep/protein_msa_colabfold.py"
    
    # Test help output
    result = subprocess.run([CONDA_PYTHON, script_path, "--help"], 
                          capture_output=True, text=True)
    
    assert result.returncode == 0, "Could not get help output"
    
    help_text = result.stdout.lower()
    
    # Check for expected arguments (same as make_protein_msa.sh)
    expected_args = ["in_fasta", "out_dir", "tag", "cpu", "mem"]
    missing_args = [arg for arg in expected_args if arg not in help_text]
    
    assert not missing_args, f"Missing expected arguments: {missing_args}"

def test_invalid_input():
    """Test script behavior with invalid input"""
    script_path = "../input_prep/protein_msa_colabfold.py"
    
    with tempfile.TemporaryDirectory() as temp_dir:
        # Test with non-existent input file
        cmd = [
            CONDA_PYTHON, script_path,
            "non_existent_file.fa",
            temp_dir,
            "test_protein",
            "--cpu", "1",
            "--mem", "8"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Should fail with non-existent file
        assert result.returncode != 0, "Script should fail with non-existent input file"

def test_output_format(test_fasta_file, temp_output_dir):
    """Test that the output is in correct A3M format"""
    script_path = "../input_prep/protein_msa_colabfold.py"
    
    # Run the script
    cmd = [
        CONDA_PYTHON, script_path,
        test_fasta_file,
        temp_output_dir,
        "test_protein",
        "--cpu", "1",
        "--mem", "8"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    
    assert result.returncode == 0, f"Script execution failed: {result.stderr}"
    
    # Check output file
    output_file = os.path.join(temp_output_dir, "test_protein.msa0.a3m")
    assert os.path.exists(output_file), f"Output file not created: {output_file}"
    
    # Read and validate A3M format
    with open(output_file, 'r') as f:
        lines = f.readlines()
        
        # Should have at least one sequence
        assert len(lines) >= 2, "A3M file should have at least header and sequence"
        
        # First line should be a header
        assert lines[0].startswith('>'), "First line should be a header starting with '>'"
        
        # Should contain the query sequence
        sequence_lines = [line.strip() for line in lines[1:] if line.strip() and not line.startswith('>')]
        assert len(sequence_lines) > 0, "A3M file should contain at least one sequence"

if __name__ == "__main__":
    # Run pytest with this module
    pytest.main([__file__, "-v"]) 