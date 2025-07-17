#!/bin/bash

# Script to generate Git commit messages using OpenAI API
# Usage: ./generate_commit_message.sh
# Dependencies: curl, jq

set -e

# Check if API key is set
if [ -z "$OPENAI_API_KEY" ]; then
  echo "Error: OPENAI_API_KEY environment variable is not set."
  echo "Please set it with: export OPENAI_API_KEY='your-api-key'"
  exit 1
fi

# Check if git is available
if ! command -v git &> /dev/null; then
  echo "Error: git command not found."
  exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "Error: jq command not found. Please install jq to use this script."
  exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
  echo "Error: Not in a git repository."
  exit 1
fi

# Get the staged changes
staged_diff=$(git diff --staged)

# If no staged changes, check if there are any unstaged changes
if [ -z "$staged_diff" ]; then
  echo "No staged changes found. Checking for unstaged changes..."
  unstaged_diff=$(git diff)
  
  if [ -z "$unstaged_diff" ]; then
    echo "No changes to commit. Please make and stage changes first."
    exit 1
  else
    echo "Found unstaged changes. Would you like to:"
    echo "1) Generate a commit message for unstaged changes (won't be committed)"
    echo "2) Stage all changes and then generate a commit message"
    echo "3) Exit"
    read -r -p "Enter your choice (1-3): " choice
    
    case $choice in
      1)
        diff_to_analyze=$unstaged_diff
        echo "Generating commit message for unstaged changes (these won't be committed automatically)..."
        ;;
      2)
        git add -A
        staged_diff=$(git diff --staged)
        diff_to_analyze=$staged_diff
        echo "All changes staged. Generating commit message..."
        ;;
      3)
        echo "Exiting."
        exit 0
        ;;
      *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
    esac
  fi
else
  diff_to_analyze=$staged_diff
  echo "Generating commit message for staged changes..."
fi

# Get the list of changed files
changed_files=$(git diff --staged --name-only)

# Get repository name
repo_name=$(basename "$(git rev-parse --show-toplevel)")

# Prepare the prompt for the API
prompt="You are a helpful assistant that generates concise, descriptive git commit messages based on code changes. 
I'll provide you with the diff of my changes, and you should:

1. Analyze the changes to understand what was modified.
2. Generate a commit message with:
   - A short, clear title (max 50 chars) that summarizes the change
   - A bulleted list description of what was changed and why (if possible)

Format your response as:
TITLE: [your generated title]
DESCRIPTION:
- [first point]
- [second point]
- etc.

Here is the diff from the repository '$repo_name' for files: $changed_files

$diff_to_analyze"

# Trim the prompt if it's too long (OpenAI has token limits)
max_chars=14000
if [ ${#prompt} -gt $max_chars ]; then
  prompt="${prompt:0:$max_chars}... [diff truncated due to size]"
fi

# Make the API call to OpenAI
response=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"gpt-3.5-turbo\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}],
    \"max_tokens\": 500,
    \"temperature\": 0.7
  }")

# Check if the API call was successful
if echo "$response" | jq -e '.error' > /dev/null; then
  error_message=$(echo "$response" | jq -r '.error.message')
  echo "Error from OpenAI API: $error_message"
  exit 1
fi

# Extract the message content
commit_message=$(echo "$response" | jq -r '.choices[0].message.content')

# Display the generated commit message
echo -e "\n===== Generated Commit Message =====\n"
echo "$commit_message"
echo -e "\n===================================="

# Ask if user wants to commit with this message
echo ""
echo "Options:"
echo "1) Commit with this message"
echo "2) Edit the message before committing"
echo "3) Copy to clipboard only (won't commit)"
echo "4) Exit without committing"
read -r -p "Enter your choice (1-4): " commit_choice

case $commit_choice in
  1)
    # Extract title and description
    title=$(echo "$commit_message" | grep -i "^TITLE:" | sed 's/^TITLE: *//')
    description=$(echo "$commit_message" | sed -n '/^DESCRIPTION:/,$p' | sed '1d')
    
    # If no title was found in the expected format, use the first line
    if [ -z "$title" ]; then
      title=$(echo "$commit_message" | head -n 1)
      description=$(echo "$commit_message" | tail -n +2)
    fi
    
    # Commit with the generated message
    git commit -m "$title" -m "$description"
    echo "Changes committed successfully!"
    ;;
  2)
    # Create a temporary file with the commit message
    temp_file=$(mktemp)
    echo "$commit_message" > "$temp_file"
    
    # Open the file in the default editor
    ${EDITOR:-nano} "$temp_file"
    
    # Read the edited message
    edited_message=$(cat "$temp_file")
    
    # Commit with the edited message
    git commit -m "$(echo "$edited_message" | head -n 1)" -m "$(echo "$edited_message" | tail -n +2)"
    echo "Changes committed with edited message!"
    
    # Clean up
    rm "$temp_file"
    ;;
  3)
    # Copy to clipboard if pbcopy (macOS) or xclip (Linux) is available
    if command -v pbcopy &> /dev/null; then
      echo "$commit_message" | pbcopy
      echo "Commit message copied to clipboard!"
    elif command -v xclip &> /dev/null; then
      echo "$commit_message" | xclip -selection clipboard
      echo "Commit message copied to clipboard!"
    else
      echo "No clipboard command found. Cannot copy to clipboard."
    fi
    ;;
  4)
    echo "Exiting without committing."
    ;;
  *)
    echo "Invalid choice. Exiting without committing."
    ;;
esac

exit 0 