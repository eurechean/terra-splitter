#!/bin/bash

# Function to prompt for input
prompt() {
  local prompt_text="$1"
  local default_value="$2"
  read -p "$prompt_text [$(pwd)$default_value]: " input
  echo "${input:-$(pwd)$default_value}"
}

# Get input and output state file paths
in_state_path="${STATE_PATH:-$(prompt 'Please enter the absolute input state file path.' '/in-terraform.tfstate')}"
out_state_path="${STATE_PATH:-$(prompt 'Please enter the absolute output state file path.' '/out-terraform.tfstate')}"

terraform init

# Check if the source file exists
if [ -f "$in_state_path" ]; then
    # Prompt the user for input
    read -p "Do you want to delete the source file and download a new one? (y/n): " choice

    # Evaluate the user's input
    if [ "$choice" = "y" ]; then
        rm $in_state_path*
        echo "Source file deleted."
        echo "Downloading new source file..."
        terraform state pull > $in_state_path
        echo "Source file downloaded."
    else
        echo "Source file not deleted."
    fi
else
    echo "Source file does not exist."
    echo "Downloading new source file..."
    terraform state pull > $in_state_path
    echo "Source file downloaded."
fi

# Check if the source file exists
if [ -f "$out_state_path" ]; then
    # Prompt the user for input
    read -p "Do you want to delete the destination file? (y/n): " choice

    # Evaluate the user's input
    if [ "$choice" = "y" ]; then
        rm $out_state_path*
        echo "Destination file deleted."
    else
        echo "Source file not deleted."
    fi
fi

# Prompt for resources to be moved
echo "Resources to be moved."
terraform state list -state=$in_state_path
resource_name="$(prompt 'Use the resource name to select):')"

resource_list=$(terraform state list -state=$in_state_path $resource_name)

while IFS= read -r resource; do
    resource_prep=$(echo $resource | sed 's/\"/\\\"/g' )
    command=$(echo terraform state mv -state="$in_state_path" -state-out="$out_state_path" -ignore-remote-version -lock=false "\"$resource_prep\"" "\"$resource_prep\"")
    eval $command
done <<< "$resource_list"

# Cleaning

rm $in_state_path*backup
rm $out_state_path*backup
