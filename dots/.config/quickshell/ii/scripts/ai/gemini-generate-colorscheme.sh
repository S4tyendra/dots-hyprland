#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <image_path> [model]"
    exit 1
fi

SOURCE_IMG_PATH="$1"
MODEL="${2:-${GEMINI_COLORSCHEME_MODEL:-gemini-3.6-flash}}"
RESIZED_IMG_PATH="/tmp/quickshell/ai/wallpaper_colorscheme.jpg"

XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$XDG_STATE_HOME/quickshell"
OUTPUT_FILE="$STATE_DIR/user/generated/colors.json"

# Notify user that generation has started
notify-send -a "AI Color Generator" -u low "Generating Theme..." "Gemini 3.6 Flash is analyzing the wallpaper..."

# Resize image for fast transmission
mkdir -p "$(dirname "$RESIZED_IMG_PATH")"
mkdir -p "$(dirname "$OUTPUT_FILE")"
magick "$SOURCE_IMG_PATH" -resize 200x -quality 50 "$RESIZED_IMG_PATH"

# Retrieve API key
API_KEY=$(secret-tool lookup 'application' 'illogical-impulse' 2>/dev/null | jq -r '.apiKeys.gemini // empty')

if [[ -z "$API_KEY" ]]; then
    notify-send -a "AI Color Generator" "Gemini API Key Missing" "Please set your Gemini API key in the shell sidebar."
    echo "Error: Gemini API key not found in secret-tool." >&2
    exit 1
fi

# Base64 encode image
if [[ "$(base64 --version 2>&1)" = *"FreeBSD"* ]]; then
    B64FLAGS="--input"
else
    B64FLAGS="-w0"
fi
B64DATA="$(base64 $B64FLAGS "$RESIZED_IMG_PATH")"

PROMPT="Analyze this wallpaper image and generate a complete Material 3 color scheme in JSON format based on the image colors, atmosphere, and aesthetic. You decide whether a dark or light theme fits best. Colors could be more random; there is no need for them to be strictly seed based. Generate creative yet visually usable 6-character hex color codes (e.g. #1a1b26) for all requested color tokens ensuring legibility and contrast."

payload=$(cat <<EOF
{
    "contents": [{
        "parts": [
            {
                "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": "${B64DATA}"
                }
            },
            { "text": "${PROMPT}" }
        ]
    }],
    "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": {
            "type": "OBJECT",
            "properties": {
                "background": { "type": "STRING" },
                "error": { "type": "STRING" },
                "error_container": { "type": "STRING" },
                "inverse_on_surface": { "type": "STRING" },
                "inverse_primary": { "type": "STRING" },
                "inverse_surface": { "type": "STRING" },
                "on_background": { "type": "STRING" },
                "on_error": { "type": "STRING" },
                "on_error_container": { "type": "STRING" },
                "on_primary": { "type": "STRING" },
                "on_primary_container": { "type": "STRING" },
                "on_primary_fixed": { "type": "STRING" },
                "on_primary_fixed_variant": { "type": "STRING" },
                "on_secondary": { "type": "STRING" },
                "on_secondary_container": { "type": "STRING" },
                "on_secondary_fixed": { "type": "STRING" },
                "on_secondary_fixed_variant": { "type": "STRING" },
                "on_surface": { "type": "STRING" },
                "on_surface_variant": { "type": "STRING" },
                "on_tertiary": { "type": "STRING" },
                "on_tertiary_container": { "type": "STRING" },
                "on_tertiary_fixed": { "type": "STRING" },
                "on_tertiary_fixed_variant": { "type": "STRING" },
                "outline": { "type": "STRING" },
                "outline_variant": { "type": "STRING" },
                "primary": { "type": "STRING" },
                "primary_container": { "type": "STRING" },
                "primary_fixed": { "type": "STRING" },
                "primary_fixed_dim": { "type": "STRING" },
                "scrim": { "type": "STRING" },
                "secondary": { "type": "STRING" },
                "secondary_container": { "type": "STRING" },
                "secondary_fixed": { "type": "STRING" },
                "secondary_fixed_dim": { "type": "STRING" },
                "shadow": { "type": "STRING" },
                "surface": { "type": "STRING" },
                "surface_bright": { "type": "STRING" },
                "surface_container": { "type": "STRING" },
                "surface_container_high": { "type": "STRING" },
                "surface_container_highest": { "type": "STRING" },
                "surface_container_low": { "type": "STRING" },
                "surface_container_lowest": { "type": "STRING" },
                "surface_dim": { "type": "STRING" },
                "surface_tint": { "type": "STRING" },
                "surface_variant": { "type": "STRING" },
                "tertiary": { "type": "STRING" },
                "tertiary_container": { "type": "STRING" },
                "tertiary_fixed": { "type": "STRING" },
                "tertiary_fixed_dim": { "type": "STRING" }
            },
            "required": [
                "background", "error", "error_container", "inverse_on_surface", "inverse_primary", "inverse_surface",
                "on_background", "on_error", "on_error_container", "on_primary", "on_primary_container", "on_primary_fixed",
                "on_primary_fixed_variant", "on_secondary", "on_secondary_container", "on_secondary_fixed", "on_secondary_fixed_variant",
                "on_surface", "on_surface_variant", "on_tertiary", "on_tertiary_container", "on_tertiary_fixed", "on_tertiary_fixed_variant",
                "outline", "outline_variant", "primary", "primary_container", "primary_fixed", "primary_fixed_dim", "scrim", "secondary",
                "secondary_container", "secondary_fixed", "secondary_fixed_dim", "shadow", "surface", "surface_bright", "surface_container",
                "surface_container_high", "surface_container_highest", "surface_container_low", "surface_container_lowest", "surface_dim",
                "surface_tint", "surface_variant", "tertiary", "tertiary_container", "tertiary_fixed", "tertiary_fixed_dim"
            ]
        },
        "temperature": 1.0
    }
}
EOF
)

response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
-H "x-goog-api-key: $API_KEY" \
-H 'Content-Type: application/json' \
-X POST \
-d "$payload")

json_output=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty')

if [[ -n "$json_output" ]] && echo "$json_output" | jq -e '.primary' >/dev/null 2>&1; then
    echo "$json_output" | jq '.' > "$OUTPUT_FILE"
    notify-send -a "AI Color Generator" "Theme Generated" "Gemini generated a new color scheme from the wallpaper."
else
    echo "Error: Failed to generate color scheme from Gemini response." >&2
    echo "$response" >&2
    notify-send -a "AI Color Generator" "Generation Failed" "Could not generate color scheme from Gemini."
    exit 1
fi
