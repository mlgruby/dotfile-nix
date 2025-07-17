#!/usr/bin/env python3
"""
Check all markdown links in the docs directory to identify broken links.
"""

import os
import re
import sys
from pathlib import Path

def find_markdown_links(content):
    """Find all markdown links in content."""
    # Pattern to match [text](path.md) links
    pattern = r'\[([^\]]+)\]\(([^)]+\.md)\)'
    return re.findall(pattern, content)

def resolve_link_path(current_file, link_path):
    """Resolve a relative link path from the current file."""
    current_dir = os.path.dirname(current_file)
    
    # Handle relative paths
    if link_path.startswith('../'):
        resolved = os.path.normpath(os.path.join(current_dir, link_path))
    elif link_path.startswith('./'):
        resolved = os.path.normpath(os.path.join(current_dir, link_path[2:]))
    elif '/' in link_path:
        # Absolute path from docs root
        resolved = os.path.join('docs', link_path)
    else:
        # Same directory
        resolved = os.path.join(current_dir, link_path)
    
    return resolved

def check_all_links():
    """Check all markdown links in the docs directory."""
    docs_dir = Path('docs')
    broken_links = []
    all_links = []
    
    if not docs_dir.exists():
        print("Error: docs directory not found")
        return
    
    # Find all markdown files
    md_files = list(docs_dir.rglob('*.md'))
    
    for md_file in md_files:
        try:
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {md_file}: {e}")
            continue
        
        # Find all links in this file
        links = find_markdown_links(content)
        
        for link_text, link_path in links:
            # Skip external links (http/https)
            if link_path.startswith(('http://', 'https://')):
                continue
                
            # Skip anchors/fragments for now
            if '#' in link_path:
                link_path = link_path.split('#')[0]
                if not link_path:  # Pure anchor link
                    continue
            
            resolved_path = resolve_link_path(str(md_file), link_path)
            all_links.append((str(md_file), link_text, link_path, resolved_path))
            
            # Check if target file exists
            if not os.path.exists(resolved_path):
                broken_links.append({
                    'source_file': str(md_file),
                    'link_text': link_text,
                    'link_path': link_path,
                    'resolved_path': resolved_path
                })
    
    # Report results
    print(f"📊 Link Check Results")
    print(f"{'='*50}")
    print(f"Total markdown files: {len(md_files)}")
    print(f"Total links found: {len(all_links)}")
    print(f"Broken links: {len(broken_links)}")
    print()
    
    if broken_links:
        print("🔴 Broken Links:")
        print("-" * 50)
        for link in broken_links:
            print(f"File: {link['source_file']}")
            print(f"Text: {link['link_text']}")
            print(f"Link: {link['link_path']}")
            print(f"Resolved: {link['resolved_path']}")
            print()
    else:
        print("✅ All links are working!")
    
    # Show file structure for reference
    print("📁 Actual file structure:")
    print("-" * 30)
    for md_file in sorted(md_files):
        print(f"  {md_file}")

if __name__ == "__main__":
    check_all_links() 