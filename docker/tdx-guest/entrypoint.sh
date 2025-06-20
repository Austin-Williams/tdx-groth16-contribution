#!/bin/sh
# Exit immediately if a command exits with a non-zero status.
set -e

INPUT_PARAMS_FILE="/mnt/tdx_share/input.params"
OUTPUT_PARAMS_FILE="/mnt/tdx_share/output.params"

echo "TDX Guest Entrypoint: Starting script."

# 1. Check if the input.params file exists
echo "Checking for input file at ${INPUT_PARAMS_FILE}..."
if [ ! -f "${INPUT_PARAMS_FILE}" ]; then
  echo "Error: Input parameters file not found at ${INPUT_PARAMS_FILE}" >&2
  exit 1
fi
echo "Input parameters file found."

# 2. Run zokrates mpc contribute with ephemeral entropy
echo "Running ZoKrates contribution with ephemeral entropy..."
zokrates mpc contribute -i "${INPUT_PARAMS_FILE}" -o "${OUTPUT_PARAMS_FILE}" -e "$(head -c 32 /dev/urandom | xxd -p -c 64)"
echo "ZoKrates contribution command finished successfully."

# 3. Console.log "hello world" (using echo for shell)
echo "hello world"

# 4. Shut down (happens automatically when script ends)
echo "TDX Guest Entrypoint: Script finished. Container will now exit."