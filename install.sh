#!/bin/bash
# install.sh - Install gh-hooks to ~/.gh-hooks

set -e

INSTALL_DIR="${HOME}/.gh-hooks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing gh-hooks..."

# Create install directory
if [ ! -d "$INSTALL_DIR" ]; then
  echo "→ Creating ${INSTALL_DIR}"
  mkdir -p "$INSTALL_DIR"
fi

# Copy files
echo "→ Copying files to ${INSTALL_DIR}"
cp -r "${SCRIPT_DIR}/gh-hooks.sh" "$INSTALL_DIR/"
cp -r "${SCRIPT_DIR}/lib" "$INSTALL_DIR/"
cp -r "${SCRIPT_DIR}/examples" "$INSTALL_DIR/"

# Make scripts executable
chmod +x "${INSTALL_DIR}/gh-hooks.sh"

echo "✓ Files installed to ${INSTALL_DIR}"

# Detect shell
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
  SHELL_CONFIG="${HOME}/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
  if [ -f "${HOME}/.bashrc" ]; then
    SHELL_CONFIG="${HOME}/.bashrc"
  elif [ -f "${HOME}/.bash_profile" ]; then
    SHELL_CONFIG="${HOME}/.bash_profile"
  fi
fi

# Add source line to shell config
if [ -n "$SHELL_CONFIG" ]; then
  SOURCE_LINE="source ${INSTALL_DIR}/gh-hooks.sh"

  if ! grep -q "$SOURCE_LINE" "$SHELL_CONFIG" 2>/dev/null; then
    echo ""
    echo "→ Adding source line to ${SHELL_CONFIG}"
    echo "" >> "$SHELL_CONFIG"
    echo "# gh-hooks" >> "$SHELL_CONFIG"
    echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
    echo "✓ Added to ${SHELL_CONFIG}"
  else
    echo "✓ Already configured in ${SHELL_CONFIG}"
  fi
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ${SHELL_CONFIG}"
echo "  2. In your project, create .gh-hooks.sh with your hook functions"
echo "  3. See examples in ${INSTALL_DIR}/examples/"
echo ""
echo "For help, run: gh_hooks_help"
