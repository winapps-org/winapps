#!/usr/bin/env bash
# Copyright (c) 2024 kahkhang
# All rights reserved.
#
# SPDX-License-Identifier: MIT
# For original source, see https://github.com/kahkhang/Inquirer.sh

### GLOBAL CONSTANTS ###
declare -r ANSI_LIGHT_BLUE="\033[1;94m" # Light blue text.
declare -r ANSI_LIGHT_GREEN="\033[92m"  # Light green text.
declare -r ANSI_CLEAR_TEXT="\033[0m"    # Default text.
declare -r DIALOG_HEIGHT=14             # Height of dialog window.
declare -r TEXT_WIDTH_OFFSET=4          # Offset for fitting title text.
declare -r CHK_OPTION_WIDTH_OFFSET=10   # Offset for fitting options.
declare -r MNU_OPTION_WIDTH_OFFSET=7    # Offset for fitting options.

### FUNCTIONS ###
function inqMenu() {
    # DECLARE VARIABLES.
    # Variables created from function arguments:
    declare DIALOG_TEXT="$1"                      # Dialog heading.
    declare INPUT_OPTIONS_VAR="$2"                # Input variable name.
    declare RETURN_STRING_VAR="$3"                # Output variable name.
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR" # Input array nameref.
    declare -n RETURN_STRING="$RETURN_STRING_VAR" # Output string nameref.
    # Note: namerefs allow changes made through the nameref to affect the
    # referenced variable, even across different scopes like function calls.

    # Other variables:
    declare TRIMMED_OPTIONS=()         # Input array post-trimming.
    declare PADDED_OPTIONS=()          # Input array with extra white space.
    declare DIALOG_OPTIONS=()          # Input array for options dialog.
    declare DIALOG_WIDTH=0             # Width of dialog window.
    declare OPTION_NUMBER=0            # Number of options in dialog window.
    declare SELECTED_OPTIONS_STRING="" # Output value from dialog window.

    # MAIN LOGIC.
    # Trim leading and trailing white space for each option.
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        TRIMMED_OPTIONS+=("$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')")
    done

    # Find the length of the longest option to set the dialog width.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        if [ "${#OPTION}" -gt "$DIALOG_WIDTH" ]; then
            DIALOG_WIDTH=${#OPTION}
        fi
    done

    # Apply the offset value to the dialog width.
    DIALOG_WIDTH=$((DIALOG_WIDTH + MNU_OPTION_WIDTH_OFFSET))

    # Adjust the dialog width again if the dialog text is longer.
    if [ "$DIALOG_WIDTH" -lt $((${#DIALOG_TEXT} + TEXT_WIDTH_OFFSET)) ]; then
        DIALOG_WIDTH="$((${#DIALOG_TEXT} + TEXT_WIDTH_OFFSET))"
    fi

    # Pad option text with trailing white space to left-align all options.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        local PAD_LENGTH=$((DIALOG_WIDTH - MNU_OPTION_WIDTH_OFFSET - ${#OPTION}))
        # shellcheck disable=SC2155
        local PADDED_OPTION="${OPTION}$(printf '%*s' $PAD_LENGTH)"
        PADDED_OPTIONS+=("$PADDED_OPTION")
    done

    # Convert options into the appropriate format for a 'dialog' menu.
    for PADDED_OPTION in "${PADDED_OPTIONS[@]}"; do
        DIALOG_OPTIONS+=("$PADDED_OPTION" "")
    done

    # Store the number of options.
    OPTION_NUMBER="${#INPUT_OPTIONS[@]}"

    # Produce checkbox.
    # The output string contains options delimited by spaces.
    # Each option is enclosed in double quotes within the output string.
    # For example: '"Option 1  " "The  Second Option   " "    Option Number 3 "'
    SELECTED_OPTIONS_STRING=$(dialog \
        --keep-tite \
        --clear \
        --no-shadow \
        --menu \
        "$DIALOG_TEXT" \
        "$DIALOG_HEIGHT" \
        "$DIALOG_WIDTH" \
        "$OPTION_NUMBER" \
        "${DIALOG_OPTIONS[@]}" \
        2>&1 >/dev/tty) || exit 0

    # Remove white space added previously.
    RETURN_STRING=$(echo "$SELECTED_OPTIONS_STRING" |
        sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Remove escapes (introduced by 'dialog' if options have parentheses).
    RETURN_STRING="${RETURN_STRING//\\/}" # ${variable//search/replace}

    # Display question and response.
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${RETURN_STRING}${ANSI_CLEAR_TEXT}"
}

function inqChkBx() {
    # DECLARE VARIABLES.
    # Variables created from function arguments:
    declare DIALOG_TEXT="$1"                      # Dialog heading.
    declare INPUT_OPTIONS_VAR="$2"                # Input variable name.
    declare RETURN_ARRAY_VAR="$3"                 # Output variable name.
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR" # Input array nameref.
    declare -n RETURN_ARRAY="$RETURN_ARRAY_VAR"   # Output array nameref.
    # Note: namerefs allow changes made through the nameref to affect the
    # referenced variable, even across different scopes like function calls.

    # Other variables:
    declare TRIMMED_OPTIONS=()         # Input array post-trimming.
    declare PADDED_OPTIONS=()          # Input array with extra white space.
    declare DIALOG_OPTIONS=()          # Input array for options dialog.
    declare DIALOG_WIDTH=0             # Width of dialog window.
    declare OPTION_NUMBER=0            # Number of options in dialog window.
    declare SELECTED_OPTIONS_STRING="" # Output value from dialog window.

    # MAIN LOGIC.
    # Trim leading and trailing white space for each option.
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        TRIMMED_OPTIONS+=("$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')")
    done

    # Find the length of the longest option to set the dialog width.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        if [ "${#OPTION}" -gt "$DIALOG_WIDTH" ]; then
            DIALOG_WIDTH=${#OPTION}
        fi
    done

    # Apply the offset value to the dialog width.
    DIALOG_WIDTH=$((DIALOG_WIDTH + CHK_OPTION_WIDTH_OFFSET))

    # Adjust the dialog width again if the dialog text is longer.
    if [ "$DIALOG_WIDTH" -lt $((${#DIALOG_TEXT} + TEXT_WIDTH_OFFSET)) ]; then
        DIALOG_WIDTH="$((${#DIALOG_TEXT} + TEXT_WIDTH_OFFSET))"
    fi

    # Pad option text with trailing white space to left-align all options.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        local PAD_LENGTH=$((DIALOG_WIDTH - CHK_OPTION_WIDTH_OFFSET - ${#OPTION}))
        # shellcheck disable=SC2155
        local PADDED_OPTION="${OPTION}$(printf '%*s' $PAD_LENGTH)"
        PADDED_OPTIONS+=("$PADDED_OPTION")
    done

    # Convert options into the appropriate format for a 'dialog' checkbox.
    for PADDED_OPTION in "${PADDED_OPTIONS[@]}"; do
        DIALOG_OPTIONS+=("$PADDED_OPTION" "" off)
    done

    # Store the number of options.
    OPTION_NUMBER="${#INPUT_OPTIONS[@]}"

    # Produce checkbox.
    # The output string contains options delimited by spaces.
    # Each option is enclosed in double quotes within the output string.
    # For example: '"Option 1  " "The  Second Option   " "    Option Number 3 "'
    SELECTED_OPTIONS_STRING=$(dialog \
        --keep-tite \
        --clear \
        --no-shadow \
        --checklist \
        "$DIALOG_TEXT" \
        "$DIALOG_HEIGHT" \
        "$DIALOG_WIDTH" \
        "$OPTION_NUMBER" \
        "${DIALOG_OPTIONS[@]}" \
        2>&1 >/dev/tty) || exit 0

    # Convert the output string into an array.
    # shellcheck disable=SC2001
    while IFS= read -r LINE; do
        LINE="${LINE/#\"/}"     # Remove leading double quote.
        LINE="${LINE/%\"/}"     # Remove trailing double quote.
        RETURN_ARRAY+=("$LINE") # Add to array.
    done < <(echo "$SELECTED_OPTIONS_STRING" | sed 's/\" \"/\"\n\"/g')

    # Final modifications.
    for ((i = 0; i < ${#RETURN_ARRAY[@]}; i++)); do
        # Remove white space added previously.
        # shellcheck disable=SC2001
        RETURN_ARRAY[i]=$(echo "${RETURN_ARRAY[i]}" |
            sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        # Remove escapes (introduced by 'dialog' if options have parentheses).
        RETURN_ARRAY[i]=${RETURN_ARRAY[i]//\\/} # ${variable//search/replace}
    done
}
