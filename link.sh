#!/bin/bash

# Odoo Documentation and Configuration Linker
# Creates symlinks to centralized documentation and configuration files
# Usage: /opt/odoo/odoo-docs/link.sh

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

echo -e "${BLUE}Odoo Documentation and Configuration Linker${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "Source directory: ${YELLOW}$SOURCE_DIR${NC}"
echo -e "Target directory: ${YELLOW}$TARGET_DIR${NC}"
echo ""

# Function to create symlink with checks
create_symlink() {
    local source_path="$1"
    local target_path="$2"
    local description="$3"

    # Check if source exists
    if [[ ! -e "$source_path" ]]; then
        echo -e "${YELLOW}⚠️  Skipping $description: Source not found at $source_path${NC}"
        return 0
    fi

    # Check if target already exists
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        if [[ -L "$target_path" ]]; then
            local current_target=$(readlink "$target_path")
            if [[ "$current_target" == "$source_path" ]]; then
                echo -e "${GREEN}✓${NC} $description: Symlink already exists and points to correct location"
                return 0
            else
                echo -e "${YELLOW}⚠️  $description: Symlink exists but points to different location${NC}"
                echo -e "   Current: $current_target"
                echo -e "   Expected: $source_path"
                read -p "   Replace existing symlink? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}   Skipped${NC}"
                    return 0
                fi
                rm "$target_path"
            fi
        else
            echo -e "${RED}✗${NC} $description: File/directory already exists at $target_path"
            echo -e "   Please remove or rename the existing file/directory first"
            return 1
        fi
    fi

    # Create the symlink
    ln -s "$source_path" "$target_path"
    echo -e "${GREEN}✓${NC} $description: Created symlink $target_path -> $source_path"
}

# Function to check if we're in a valid target directory
check_target_directory() {
    # Check if we're not in the source directory
    if [[ "$TARGET_DIR" == "$SOURCE_DIR" ]]; then
        echo -e "${RED}✗ Error: Cannot create symlinks in the source directory itself${NC}"
        echo -e "  Please run this script from your project repository directory"
        exit 1
    fi

    # Check if we're in a reasonable location (under /opt/odoo/ but not in odoo-docs)
    if [[ "$TARGET_DIR" == "/opt/odoo/odoo-docs"* ]]; then
        echo -e "${RED}✗ Error: Cannot create symlinks within the odoo-docs directory${NC}"
        echo -e "  Please run this script from your project repository directory"
        exit 1
    fi

    # Warn if not under /opt/odoo/
    if [[ "$TARGET_DIR" != "/opt/odoo/"* ]]; then
        echo -e "${YELLOW}⚠️  Warning: You're not in the standard /opt/odoo/ directory structure${NC}"
        echo -e "   Current directory: $TARGET_DIR"
        read -p "   Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Aborted${NC}"
            exit 0
        fi
    fi
}

# Function to ensure templates are copied to source directory
ensure_source_files() {
    echo "Ensuring source files exist..."

    # Copy .augment-guidelines from template if missing
    if [[ ! -e "$SOURCE_DIR/.augment-guidelines" ]]; then
        if [[ -e "$SOURCE_DIR/templates/.augment-guidelines.template" ]]; then
            cp "$SOURCE_DIR/templates/.augment-guidelines.template" "$SOURCE_DIR/.augment-guidelines"
            echo -e "${GREEN}✓${NC} Created .augment-guidelines from template"
        else
            echo -e "${YELLOW}⚠️  Template not found: .augment-guidelines.template${NC}"
        fi
    fi

    # Copy env-reference.json from template if missing
    if [[ ! -e "$SOURCE_DIR/env-reference.json" ]]; then
        if [[ -e "$SOURCE_DIR/templates/env-reference.json.template" ]]; then
            cp "$SOURCE_DIR/templates/env-reference.json.template" "$SOURCE_DIR/env-reference.json"
            echo -e "${GREEN}✓${NC} Created env-reference.json from template"
        else
            echo -e "${YELLOW}⚠️  Template not found: env-reference.json.template${NC}"
        fi
    fi
}

# Function to update .gitignore
update_gitignore() {
    local gitignore_file="$TARGET_DIR/.gitignore"

    # Check if we're in a git repository
    if ! git -C "$TARGET_DIR" rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Not a git repository - skipping .gitignore updates${NC}"
        echo -e "${BLUE}ℹ️${NC}  If you initialize git later, run this script again to update .gitignore"
        return 0
    fi

    echo "Updating .gitignore..."

    # Create .gitignore if it doesn't exist
    if [[ ! -f "$gitignore_file" ]]; then
        touch "$gitignore_file"
    fi

    # Check which entries are missing
    local missing_entries=()

    if ! grep -q "^/docs$" "$gitignore_file" 2>/dev/null; then
        missing_entries+=("/docs")
    fi

    if ! grep -q "^/\.augment-guidelines$" "$gitignore_file" 2>/dev/null; then
        missing_entries+=("/.augment-guidelines")
    fi

    if ! grep -q "^/env-reference\.json$" "$gitignore_file" 2>/dev/null; then
        missing_entries+=("/env-reference.json")
    fi

    if [[ ${#missing_entries[@]} -gt 0 ]]; then
        # Create temporary file with new entries at the top
        local temp_file=$(mktemp)

        # Add header and missing entries
        echo "# Odoo Documentation (symlinked - root-relative paths only)" > "$temp_file"
        for entry in "${missing_entries[@]}"; do
            echo "$entry" >> "$temp_file"
        done
        echo "" >> "$temp_file"

        # Append existing .gitignore content (if any)
        if [[ -s "$gitignore_file" ]]; then
            cat "$gitignore_file" >> "$temp_file"
        fi

        # Replace original with updated content
        mv "$temp_file" "$gitignore_file"

        echo -e "${GREEN}✓${NC} Updated .gitignore with missing entries: ${missing_entries[*]}"
        echo -e "${BLUE}ℹ️${NC}  Added entries at top of file using root-relative paths (/) to preserve module docs directories"
    else
        echo -e "${GREEN}✓${NC} .gitignore already contains all required symlink entries"
    fi
}

# Main execution
echo "Checking target directory..."
check_target_directory

echo ""
ensure_source_files

echo ""
echo "Creating symlinks..."

# Create symlinks for each file/directory
create_symlink "$SOURCE_DIR/docs" "$TARGET_DIR/docs" "Documentation directory"
create_symlink "$SOURCE_DIR/.augment-guidelines" "$TARGET_DIR/.augment-guidelines" "Augment guidelines"
create_symlink "$SOURCE_DIR/env-reference.json" "$TARGET_DIR/env-reference.json" "Environment reference"

echo ""
update_gitignore

echo ""
echo -e "${GREEN}✓ Linking process completed!${NC}"
echo ""
echo -e "${BLUE}Available resources:${NC}"
echo -e "  📁 ${YELLOW}./docs/${NC} - Documentation and standards"
echo -e "  📄 ${YELLOW}./.augment-guidelines${NC} - AI assistant guidelines"
echo -e "  📄 ${YELLOW}./env-reference.json${NC} - Environment reference"
echo ""
echo -e "${BLUE}Quick start:${NC}"
echo -e "  • Sync latest docs: ${YELLOW}./docs/sync.sh${NC}"
echo -e "  • Read coding standards: ${YELLOW}./docs/code_standard.md${NC}"
echo -e "  • Read git workflow: ${YELLOW}./docs/git.md${NC}"
