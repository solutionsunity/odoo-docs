#!/bin/bash

# Augment Configuration Migration Script
# Migrates from old .augment-guidelines and env-reference.json to new .augment/ structure
# Usage: /opt/odoo/odoo-docs/migrate.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"

# Target directory (where the user is calling from)
TARGET_DIR="$(pwd)"

echo -e "${BLUE}Augment Configuration Migration${NC}"
echo -e "${BLUE}===============================${NC}"
echo ""
echo -e "Source directory: ${YELLOW}$SOURCE_DIR${NC}"
echo -e "Target directory: ${YELLOW}$TARGET_DIR${NC}"
echo ""

# Check if we're in the source directory
if [[ "$TARGET_DIR" == "$SOURCE_DIR" ]]; then
    echo -e "${RED}✗ Error: Cannot migrate in the source directory itself${NC}"
    echo -e "  Please run this script from your project repository directory"
    exit 1
fi

# Check if .augment already exists
if [[ -e "$TARGET_DIR/.augment" ]]; then
    echo -e "${YELLOW}⚠️  .augment/ directory already exists${NC}"
    read -p "   Overwrite existing .augment/ directory? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Migration aborted${NC}"
        exit 0
    fi
    rm -rf "$TARGET_DIR/.augment"
fi

# Copy templates to create .augment directory
echo -e "${BLUE}Step 1: Creating .augment/ directory from templates${NC}"
if [[ ! -e "$SOURCE_DIR/templates/.augment" ]]; then
    echo -e "${RED}✗ Error: Template directory not found at $SOURCE_DIR/templates/.augment${NC}"
    exit 1
fi

cp -r "$SOURCE_DIR/templates/.augment" "$TARGET_DIR/.augment"
echo -e "${GREEN}✓${NC} Created .augment/ directory structure"

# Handle env-reference.json migration
echo ""
echo -e "${BLUE}Step 2: Migrating environment configuration${NC}"

# Check if user has existing env-reference.json at root
if [[ -f "$TARGET_DIR/env-reference.json" ]]; then
    echo -e "${GREEN}✓${NC} Found existing env-reference.json at root"
    
    # Copy user's existing config to new location
    cp "$TARGET_DIR/env-reference.json" "$TARGET_DIR/.augment/config/env-reference.json"
    echo -e "${GREEN}✓${NC} Migrated env-reference.json to .augment/config/"
    
    # Remove template file if it exists
    if [[ -f "$TARGET_DIR/.augment/config/env-reference.json.template" ]]; then
        rm "$TARGET_DIR/.augment/config/env-reference.json.template"
    fi
else
    # No existing config, use template
    if [[ -f "$TARGET_DIR/.augment/config/env-reference.json.template" ]]; then
        mv "$TARGET_DIR/.augment/config/env-reference.json.template" "$TARGET_DIR/.augment/config/env-reference.json"
        echo -e "${YELLOW}⚠️${NC}  No existing env-reference.json found"
        echo -e "   Created from template - ${YELLOW}please update with your information${NC}"
    fi
fi

# Check for old .augment-guidelines
echo ""
echo -e "${BLUE}Step 3: Checking for old configuration files${NC}"

OLD_FILES_FOUND=false

if [[ -f "$TARGET_DIR/.augment-guidelines" ]]; then
    echo -e "${YELLOW}⚠️${NC}  Found old .augment-guidelines file"
    OLD_FILES_FOUND=true
fi

if [[ -f "$TARGET_DIR/env-reference.json" ]]; then
    echo -e "${YELLOW}⚠️${NC}  Found old env-reference.json file at root"
    OLD_FILES_FOUND=true
fi

# Ask user if they want to delete old files
if [[ "$OLD_FILES_FOUND" == true ]]; then
    echo ""
    echo -e "${YELLOW}Old configuration files detected:${NC}"
    [[ -f "$TARGET_DIR/.augment-guidelines" ]] && echo -e "  • .augment-guidelines"
    [[ -f "$TARGET_DIR/env-reference.json" ]] && echo -e "  • env-reference.json"
    echo ""
    echo -e "${BLUE}These files are no longer needed with the new .augment/ structure.${NC}"
    read -p "Delete old configuration files? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        [[ -f "$TARGET_DIR/.augment-guidelines" ]] && rm "$TARGET_DIR/.augment-guidelines" && echo -e "${GREEN}✓${NC} Deleted .augment-guidelines"
        [[ -f "$TARGET_DIR/env-reference.json" ]] && rm "$TARGET_DIR/env-reference.json" && echo -e "${GREEN}✓${NC} Deleted env-reference.json"
    else
        echo -e "${YELLOW}⚠️${NC}  Old files kept - you can delete them manually later"
    fi
else
    echo -e "${GREEN}✓${NC} No old configuration files found"
fi

# Summary
echo ""
echo -e "${GREEN}✓ Migration completed successfully!${NC}"
echo ""
echo -e "${BLUE}New structure:${NC}"
echo -e "  📁 ${YELLOW}./.augment/${NC}"
echo -e "  📁 ${YELLOW}./.augment/config/env-reference.json${NC} - Developer & branding info"
echo -e "  📁 ${YELLOW}./.augment/rules/${NC} - AI agent rules"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Review and update: ${YELLOW}./.augment/config/env-reference.json${NC}"
echo -e "  2. Customize rules if needed: ${YELLOW}./.augment/rules/*.md${NC}"
echo -e "  3. The .augment/ directory is in .gitignore (user-specific)"
echo ""
echo -e "${GREEN}Happy AI-powered Odoo development! 🚀${NC}"

