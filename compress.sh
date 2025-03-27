#!/bin/bash
set -e

BASE_BRANCH=$1
QUALITY=$2
MIN_SAVING=$3
echo "Base branch: $BASE_BRANCH"
echo "JPEG Quality: $QUALITY"
echo "Min saving percent: $MIN_SAVING"

# Fetch base branch
git fetch origin "$BASE_BRANCH" --depth=1

# Get changed files
CHANGED_FILES=$(git diff --name-only --diff-filter=ACMR "origin/$BASE_BRANCH"..HEAD)
echo "Changed files: $CHANGED_FILES"

COMPRESSED=false

for file in $CHANGED_FILES; do
  if [[ "$file" == *.jpg || "$file" == *.jpeg || "$file" == *.png ]]; then
    echo "Processing $file"
    ORIGINAL_SIZE=$(stat -c%s "$file")

    # Compress the image
    if [[ "$file" == *.jpg || "$file" == *.jpeg ]]; then
      jpegoptim --max="$QUALITY" "$file"
    elif [[ "$file" == *.png" ]]; then
      optipng "$file"
    fi

    COMPRESSED_SIZE=$(stat -c%s "$file")
    SAVING=$(( (ORIGINAL_SIZE - COMPRESSED_SIZE) * 100 / ORIGINAL_SIZE ))

    echo "Original size: $ORIGINAL_SIZE bytes"
    echo "Compressed size: $COMPRESSED_SIZE bytes"
    echo "Saving: $SAVING%"

    # Check if saving is greater than threshold
    if (( SAVING >= MIN_SAVING )); then
      echo "$file was compressed by $SAVING%"
      COMPRESSED=true
    else
      echo "$file was not compressed by enough ($SAVING%)"
      git restore "$file"  # Revert changes if not enough saving
    fi
  fi
done

# Set environment variable
if $COMPRESSED; then
  echo "compressed=true" >> $GITHUB_ENV
else
  echo "compressed=false" >> $GITHUB_ENV
fi
