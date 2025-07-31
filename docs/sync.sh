#!/bin/bash
# Sync development standards from central repository
# This script can be run from any repository via symlink

echo "🔄 Syncing Odoo development standards..."

# Navigate to the actual docs directory (resolve symlink if needed)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
cd "$SCRIPT_DIR"

# Pull the latest changes
echo "⬇️  Pulling latest standards updates..."
git pull origin main

if [ $? -eq 0 ]; then
    echo "✅ Development standards successfully synced!"
    echo "📚 Latest standards are now available via symlinks in all repositories"
else
    echo "❌ Error syncing standards"
    exit 1
fi
