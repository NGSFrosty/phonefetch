#!/bin/sh
# install.sh - install phonefetch into a user's PATH
set -e

script_name="phonefetch"

# ensure the script file exists in this dir
if [ ! -f "$script_name" ]; then
  echo "Error: $script_name not found in $(pwd)."
  exit 1
fi

# prefer system location if writable
if [ -w /usr/local/bin ] || [ "$(id -u)" = "0" ]; then
  target="/usr/local/bin/$script_name"
  echo "Installing to $target"
  cp "$script_name" "$target"
  chmod +x "$target"
  echo "Installed to $target"
  exit 0
fi

# otherwise install to ~/bin
mkdir -p "$HOME/bin"
target="$HOME/bin/$script_name"
cp "$script_name" "$target"
chmod +x "$target"
echo "Installed to $target"

# ensure PATH contains ~/bin for interactive shells (add to ~/.profile if missing)
case ":$PATH:" in
  *":$HOME/bin:"*) echo "PATH already contains \$HOME/bin" ;;
  *)
    echo "Adding \$HOME/bin to PATH in ~/.profile"
    printf "\n# added by phonefetch install\nexport PATH=\"\$HOME/bin:\$PATH\"\n" >> "$HOME/.profile"
    echo "You may need to start a new shell or run: . ~/.profile"
    ;;
esac

echo "Installation complete. Run 'phonefetch' to test."
