#!/bin/bash
# Odoo Documentation Installer
# One-line setup for AI-powered Odoo development

set -e

# Standard installation path (centralized for all projects)
DOCS_PATH="/opt/odoo/odoo-docs"
PROJECT_PATH="${1:-$(pwd)}"

echo "🤖 Installing Odoo Development Documentation for AI Agents..."
echo "📁 Project: $PROJECT_PATH"
echo "📚 Docs: $DOCS_PATH"

# Clone or update documentation repository
if [ ! -d "$DOCS_PATH" ]; then
    echo "📥 Cloning odoo-docs repository..."
    git clone https://github.com/solutionsunity/odoo-docs.git "$DOCS_PATH"
else
    echo "🔄 Updating existing odoo-docs repository..."
    cd "$DOCS_PATH" && git pull origin main
fi

# Navigate to project directory
cd "$PROJECT_PATH"

# Copy templates to create private configurations
echo "📋 Setting up private configurations..."
if [ ! -f ".augment-guidelines" ]; then
    cp "$DOCS_PATH/templates/.augment-guidelines.template" ".augment-guidelines"
    echo "✅ Created .augment-guidelines from template"
else
    echo "⚠️  .augment-guidelines already exists, skipping"
fi

if [ ! -f "env-reference.json" ]; then
    cp "$DOCS_PATH/templates/env-reference.json.template" "env-reference.json"
    echo "✅ Created env-reference.json from template"
else
    echo "⚠️  env-reference.json already exists, skipping"
fi



echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 Created configuration files:"
echo "   ./.augment-guidelines      - Your private AI config"
echo "   ./env-reference.json       - Environment reference"
echo ""
echo "🔗 Next step: Create symlinks to documentation"
echo "   Run: $DOCS_PATH/link.sh in your repo!"
echo ""
echo "Happy AI-powered Odoo development! 🚀"
