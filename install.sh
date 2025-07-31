#!/bin/bash
# Odoo Documentation Installer
# One-line setup for AI-powered Odoo development

set -e

# Default installation path
DEFAULT_DOCS_PATH="/opt/odoo-docs"
PROJECT_PATH="${1:-$(pwd)}"
DOCS_PATH="${2:-$DEFAULT_DOCS_PATH}"

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

if [ ! -f "dev-config.json" ]; then
    cp "$DOCS_PATH/templates/dev-config.json.template" "dev-config.json"
    echo "✅ Created dev-config.json from template"
else
    echo "⚠️  dev-config.json already exists, skipping"
fi

# Create symlinks
echo "🔗 Creating symlinks..."
ln -sf "$DOCS_PATH/docs" docs

# Update .gitignore
echo "📝 Updating .gitignore..."
{
    echo ""
    echo "# Odoo Documentation (symlinked)"
    echo "docs"
    echo ""
    echo "# Private configurations"
    echo ".augment-guidelines"
    echo "dev-config.json"
} >> .gitignore

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📚 Available documentation:"
echo "   ./docs/git.md              - Git standards"
echo "   ./docs/code_standard.md    - Coding standards"
echo "   ./docs/frontend.md         - Frontend guidelines"
echo "   ./docs/owl.md              - OWL component standards"
echo ""
echo "🤖 AI Configuration:"
echo "   ./.augment-guidelines      - Your private AI config"
echo ""
echo "🔄 Stay updated anytime:"
echo "   ./docs/sync.sh"
echo ""
echo "Happy AI-powered Odoo development! 🚀"
