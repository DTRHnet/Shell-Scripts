#!/bin/bash

usage() {
    echo "Usage:"
    echo "  $0 <url>                   # Download and merge segments from the given m3u8 URL"
    echo "  $0 -d|--download <url>      # Only download segments from the given m3u8 URL"
    echo "  $0 -m|--merge <folder>      # Only merge TS files from the specified folder"
    exit 1
}

# Initialize flags and variables
DO_DOWNLOAD=0
DO_MERGE=0
DOWNLOAD_URL=""
MERGE_FOLDER=""

# If only one argument is provided and it does not start with a dash, do both download and merge.
if [[ "$#" -eq 1 && "$1" != -* ]]; then
    DO_DOWNLOAD=1
    DO_MERGE=1
    DOWNLOAD_URL="$1"
elif [[ "$#" -ge 2 ]]; then
    # Parse options
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -d|--download)
                DO_DOWNLOAD=1
                if [[ -n "$2" && "$2" != -* ]]; then
                    DOWNLOAD_URL="$2"
                    shift 2
                else
                    echo "ERROR: Missing URL for download"
                    usage
                fi
                ;;
            -m|--merge)
                DO_MERGE=1
                if [[ -n "$2" && "$2" != -* ]]; then
                    MERGE_FOLDER="$2"
                    shift 2
                else
                    echo "ERROR: Missing folder for merge"
                    usage
                fi
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
fi

# If no operation was selected, show usage.
if [[ $DO_DOWNLOAD -eq 0 && $DO_MERGE -eq 0 ]]; then
    usage
fi

# If merge option is specified but no folder given, use the default "video_parts"
if [[ $DO_MERGE -eq 1 && -z "$MERGE_FOLDER" ]]; then
    MERGE_FOLDER="video_parts"
fi

# ------------------ Functions ------------------

download_segments() {
    local url="$1"
    local download_dir="video_parts"
    local ffmpeg_list="ffmpeg_concat.txt"

    echo "Cleaning up previous downloads..."
    rm -rf "$download_dir" "$ffmpeg_list" "playlist.m3u8" output.mp4
    mkdir -p "$download_dir"

    echo "Fetching M3U8 playlist from: $url"
    if ! wget -q -O playlist.m3u8 "$url"; then
        echo "ERROR: Failed to download M3U8 file!"
        exit 1
    fi

    # Only process lines starting with "/" or "http"
    TS_LINKS=$(grep -E '^(/|http)' playlist.m3u8 | sed 's/^[ \t]*//;s/[ \t]*$//')
    if [ -z "$TS_LINKS" ]; then
        echo "ERROR: No valid segments found in M3U8 file!"
        exit 1
    fi

    echo "Starting video segment downloads..."
    rm -f "$ffmpeg_list"
    COUNT=1
    while read -r SEGMENT; do
        # Build full URL based on the segment format
        if [[ "$SEGMENT" =~ ^http ]]; then
            FULL_URL="$SEGMENT"
        elif [[ "$SEGMENT" =~ ^/ ]]; then
            BASE_DOMAIN=$(echo "$url" | awk -F/ '{print $1"//"$3}')
            FULL_URL="$BASE_DOMAIN$SEGMENT"
        else
            BASE_URL=$(dirname "$url" | sed 's#/$##')
            FULL_URL="$BASE_URL/$SEGMENT"
        fi

        # Normalize duplicate slashes in the URL path (preserving protocol)
        if [[ "$FULL_URL" =~ ^(https?://)(.*)$ ]]; then
            PROTOCOL="${BASH_REMATCH[1]}"
            URL_PART="${BASH_REMATCH[2]}"
            URL_PART=$(echo "$URL_PART" | sed 's#/\+#/#g')
            FULL_URL="${PROTOCOL}${URL_PART}"
        fi

        FILE_NAME="segment_${COUNT}.ts"
        FILE_PATH="$download_dir/$FILE_NAME"

        ATTEMPTS=0
        while [ ! -s "$FILE_PATH" ] && [ $ATTEMPTS -lt 3 ]; do
            echo "[$COUNT] Downloading: $FULL_URL (Attempt: $((ATTEMPTS+1)))"
            wget -q --show-progress -O "$FILE_PATH" "$FULL_URL"
            ATTEMPTS=$((ATTEMPTS + 1))
        done

        if [ ! -s "$FILE_PATH" ]; then
            echo "ERROR: Download failed after 3 attempts: $FILE_NAME"
            exit 1
        fi

        echo "file '$FILE_PATH'" >> "$ffmpeg_list"
        COUNT=$((COUNT + 1))
    done <<< "$TS_LINKS"

    echo "Download complete! Segments saved in $download_dir"
}

merge_segments() {
    local folder="$1"
    local ffmpeg_list="ffmpeg_concat.txt"
    local output_file="output.mp4"

    echo "Merging video segments from folder: $folder"
    rm -f "$ffmpeg_list"
    
    # Create ffmpeg concat list from all .ts files in the folder (sorted in natural order)
    for file in $(ls "$folder"/*.ts 2>/dev/null | sort -V); do
        echo "file '$file'" >> "$ffmpeg_list"
    done

    if [ ! -s "$ffmpeg_list" ]; then
        echo "ERROR: No TS files found in folder: $folder"
        exit 1
    fi

    echo "Merging video segments into: $output_file"
    if ! ffmpeg -f concat -safe 0 -i "$ffmpeg_list" -c copy "$output_file"; then
        echo "ERROR: FFmpeg failed to merge video!"
        exit 1
    fi

    echo "Merge complete! Output saved as: $output_file"
    rm -f "$ffmpeg_list"
}

# ------------------ Main Execution ------------------

# If download is requested, check for ffmpeg (only needed if merge is also to be run later)
if [[ $DO_DOWNLOAD -eq 1 ]]; then
    # Check if ffmpeg is installed if merging is intended
    if [[ $DO_MERGE -eq 1 && -z $(command -v ffmpeg) ]]; then
        echo "ERROR: ffmpeg is not installed. Please install ffmpeg to merge segments."
        exit 1
    fi
    download_segments "$DOWNLOAD_URL"
fi

if [[ $DO_MERGE -eq 1 ]]; then
    # For merge-only mode, ensure the folder exists
    if [ ! -d "$MERGE_FOLDER" ]; then
        echo "ERROR: Folder '$MERGE_FOLDER' does not exist."
        exit 1
    fi
    # Check if ffmpeg is available
    if ! command -v ffmpeg &> /dev/null; then
        echo "ERROR: ffmpeg is not installed. Please install ffmpeg and try again."
        exit 1
    fi
    merge_segments "$MERGE_FOLDER"
fi
