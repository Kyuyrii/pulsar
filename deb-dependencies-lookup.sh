#!/bin/bash

# Path to the Electron binary (adjust if needed)
BINARY="/tmp/pulsar/node_modules/electron/dist/electron"

# Check if the binary exists
if [[ ! -f "$BINARY" ]]
then
  echo "Error: Binary not found at $BINARY"
  echo "Please adjust the BINARY path in the script."
  exit 1
fi

# Check if apt-file is installed
if ! command -v apt-file >/dev/null 2>&1
then
  echo "apt-file is not installed. Installing it now..."
  apt update
  apt install -y apt-file
fi

# Update apt-file database if needed
echo "Updating apt-file database (this may take a moment)..."
apt-file update

echo "Analyzing shared library dependencies of: $BINARY"
echo "=================================================="

# Extract NEEDED libraries using objdump, clean up names
mapfile -t libraries < <(
    objdump -p "$BINARY" 2>/dev/null | grep 'NEEDED' | awk '{print $2}' | sort -u
)

# Array to store found packages
declare -A found_packages

echo "Searching for packages providing required libraries..."
echo

for lib in "${libraries[@]}"; do
  # Skip common system libraries that are part of libc/glibc (usually not in separate packages)
  case "$lib" in
    libc.so.6|libm.so.6|libpthread.so.0|libdl.so.2|libgcc_s.so.1|ld-linux-x86-64.so.2)
      printf "  %-30s → (provided by glibc/core system)\n" "$lib"
      continue
      ;;
  esac

  # Search using apt-file
  package=$(apt-file search "$lib" 2>/dev/null | grep --max-count 1 "/$lib$" | cut -d ':' -f 1)

  if [[ -n "$package" ]]
  then
    found_packages["$package"]=1
    printf "  %-30s → %s\n" "$lib" "$package"
  else
    printf "  %-30s → \033[0;33m(not found in apt repositories)\033[0m\n" "$lib"
    # Special case: libffmpeg.so is often bundled or from chromium-browser
    [[ "$lib" == "libffmpeg.so" ]] && echo "     → Usually bundled with Electron; not needed at runtime on most systems"
  fi
done

echo
echo "=================================================="
echo "Recommended packages to install (unique list):"
echo

if [[ ${#found_packages[@]} -gt 0 ]]
then
  printf '%s\n' "${!found_packages[@]}" | sort | xargs echo
  echo
  echo "To install them all, run:"
  echo "  apt install $(printf '%s ' "${!found_packages[@]}" | sort)"
else
  echo "No additional packages found."
fi

echo
echo "Done."
