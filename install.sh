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
echo "📋 Setting up Augment configuration..."
if [ ! -d ".augment" ]; then
    cp -r "$DOCS_PATH/templates/.augment" ".augment"
    # Rename template file to actual config file
    if [ -f ".augment/config/env-reference.json.template" ]; then
        mv ".augment/config/env-reference.json.template" ".augment/config/env-reference.json"
    fi
    echo "✅ Created .augment/ directory from templates"
    echo "   📁 .augment/config/env-reference.json - Update with your info"
    echo "   📁 .augment/rules/*.md - Augment AI rules"
else
    echo "⚠️  .augment/ directory already exists, skipping"
    echo "   Run migrate.sh if you need to migrate from old configuration"
fi



echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 Created configuration:"
echo "   ./.augment/                - Your Augment configuration"
echo "   ./.augment/config/         - Developer & branding info"
echo "   ./.augment/rules/          - AI agent rules"
echo ""
echo "⚙️  Next steps:"
echo "   1. Update .augment/config/env-reference.json with your info"
echo "   2. Run: $DOCS_PATH/link.sh to create documentation symlinks"
echo ""
echo "📝 Migration from old config:"
echo "   If you have .augment-guidelines or env-reference.json at root:"
echo "   Run: $DOCS_PATH/migrate.sh"
echo ""
echo "Happy AI-powered Odoo development! 🚀"
