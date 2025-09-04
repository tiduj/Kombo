#!/bin/bash
# Base input and output directories
INPUT_DIR="/input"
OUTPUT_DIR="/output"
NEW_EXTENSION="${FORMAT:-epub}"
NO_KEPUB="${NO_KEPUB:-false}"

# File to keep track of processed files
PROCESSED_FILES_LOG="/config/processed_files.log"
# Create the processed files log if it doesn't exist
touch "$PROCESSED_FILES_LOG"

process_file() {
  local INPUT_FILE="$1"
  local OUTPUT_FILE="$2"

  if [[ ! -f "$OUTPUT_FILE" ]]; then
    # Check if the file has been processed before
    if ! grep -qF -- "$INPUT_FILE" "$PROCESSED_FILES_LOG"; then
      echo "Processing file: $INPUT_FILE -> $OUTPUT_FILE"
      mkdir -p "$(dirname "$OUTPUT_FILE")"

      EXT="${INPUT_FILE##*.}"
      EXT="${EXT,,}" # normalize to lowercase

      # Only unpack cb7 and 7z, process rest as usual
      if [[ "$EXT" == "cb7" || "$EXT" == "7z" ]]; then
        TMP_UNPACK_DIR="/tmp/unpacked/$(basename "${INPUT_FILE%.*}")_$$"
        mkdir -p "$TMP_UNPACK_DIR"
        7z x "$INPUT_FILE" -o"$TMP_UNPACK_DIR"
        INPUT_TO_KCC="$TMP_UNPACK_DIR"
      else
        INPUT_TO_KCC="$INPUT_FILE"
      fi

      echo "Using KCC parameters: $INPUT_TO_KCC ${NO_KEPUB:+--nokepub} --forcecolor --profile $PROFILE --output $(dirname "$OUTPUT_FILE")"

      python3 kcc/kcc-c2e.py "$INPUT_TO_KCC" ${NO_KEPUB:+--nokepub} --forcecolor --profile "$PROFILE" --output "$(dirname "$OUTPUT_FILE")"
      
      # Clean up temporary directory if created
      if [[ "$EXT" == "cb7" || "$EXT" == "7z" ]]; then
        rm -rf "$TMP_UNPACK_DIR"
      fi

      # Log the processed input file
      echo "$INPUT_FILE" >>"$PROCESSED_FILES_LOG"
    else
      echo "File already processed: $INPUT_FILE"
    fi
  else
    echo "Output file already exists, skipping: $OUTPUT_FILE"
  fi
}

# Initial check: Process all existing files in the input directory
find "$INPUT_DIR" -type f \( -iname '*.cbz' -o -iname '*.cbr' -o -iname '*.cb7' -o -iname '*.7z' \) | while read -r INPUT_FILE; do
  RELATIVE_PATH="${INPUT_FILE#$INPUT_DIR/}"
  OUTPUT_FILE="$OUTPUT_DIR/${RELATIVE_PATH%.*}.$NEW_EXTENSION"
  process_file "$INPUT_FILE" "$OUTPUT_FILE"
done

# Monitor the input folder for changes
inotifywait -m -r -e close_write,moved_to,create "$INPUT_DIR" | while read -r directory events filename; do
  case "$filename" in
    *.cbz|*.cbr|*.cb7|*.7z)
      INPUT_FILE="$directory$filename"
      RELATIVE_PATH="${INPUT_FILE#$INPUT_DIR/}"
      OUTPUT_FILE="$OUTPUT_DIR/${RELATIVE_PATH%.*}.$NEW_EXTENSION"
      process_file "$INPUT_FILE" "$OUTPUT_FILE"
      ;;
    *) ;;
  esac
done
