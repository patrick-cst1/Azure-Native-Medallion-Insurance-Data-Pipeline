#!/usr/bin/env python3
"""
Update Synapse notebook configurations with actual storage account name.
This script replaces the placeholder '<storage-account-name>' in all notebooks
with the actual storage account name from deployment outputs.
"""

import json
import os
import sys
from pathlib import Path


def update_notebook_storage_account(notebook_path: Path, storage_account_name: str) -> bool:
    """
    Update storage account placeholder in a Jupyter notebook.
    
    Args:
        notebook_path: Path to the notebook file
        storage_account_name: Actual storage account name
        
    Returns:
        True if updated, False otherwise
    """
    try:
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook_data = json.load(f)
        
        updated = False
        for cell in notebook_data.get('cells', []):
            if cell.get('cell_type') == 'code':
                source = cell.get('source', [])
                new_source = []
                for line in source:
                    if '<storage-account-name>' in line:
                        line = line.replace('<storage-account-name>', storage_account_name)
                        updated = True
                    new_source.append(line)
                cell['source'] = new_source
        
        if updated:
            with open(notebook_path, 'w', encoding='utf-8') as f:
                json.dump(notebook_data, f, indent=2, ensure_ascii=False)
            print(f"✓ Updated: {notebook_path.name}")
            return True
        else:
            print(f"  Skipped: {notebook_path.name} (no placeholder found)")
            return False
            
    except Exception as e:
        print(f"✗ Error updating {notebook_path.name}: {str(e)}")
        return False


def main():
    """Main function to update all notebooks."""
    if len(sys.argv) < 2:
        print("Usage: python update_notebook_config.py <storage-account-name>")
        print("\nExample:")
        print("  python update_notebook_config.py insurancemldevxyz123")
        sys.exit(1)
    
    storage_account_name = sys.argv[1]
    
    # Validate storage account name
    if not storage_account_name or storage_account_name == '<storage-account-name>':
        print("Error: Please provide a valid storage account name")
        sys.exit(1)
    
    # Get notebook directory
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    notebooks_dir = repo_root / 'synapse' / 'notebooks'
    
    if not notebooks_dir.exists():
        print(f"Error: Notebooks directory not found: {notebooks_dir}")
        sys.exit(1)
    
    # Find all notebook files
    notebook_files = list(notebooks_dir.glob('*.ipynb'))
    
    if not notebook_files:
        print(f"Warning: No notebook files found in {notebooks_dir}")
        sys.exit(0)
    
    print(f"Found {len(notebook_files)} notebook(s)")
    print(f"Updating storage account name to: {storage_account_name}\n")
    
    updated_count = 0
    for notebook_path in sorted(notebook_files):
        if update_notebook_storage_account(notebook_path, storage_account_name):
            updated_count += 1
    
    print(f"\n{'='*60}")
    print(f"Summary: Updated {updated_count} out of {len(notebook_files)} notebook(s)")
    print(f"{'='*60}")


if __name__ == '__main__':
    main()
