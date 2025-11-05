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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"

# Target directory (where the user is calling from)
CURRENT_DIR="$(pwd)"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Augment Configuration Migration      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Update documentation first to get latest templates
echo -e "${CYAN}📥 Updating odoo-docs to get latest templates...${NC}"
if [[ -x "$SOURCE_DIR/docs/sync.sh" ]]; then
    cd "$SOURCE_DIR" && ./docs/sync.sh
    echo -e "${GREEN}✓${NC} Documentation updated"
else
    echo -e "${YELLOW}⚠️${NC}  Could not find docs/sync.sh, using existing templates"
fi
echo ""

# Function to check if directory has old configuration
has_old_config() {
    local dir="$1"
    # Check for files or symlinks (even broken ones)
    [[ -e "$dir/.augment-guidelines" ]] || [[ -L "$dir/.augment-guidelines" ]] || \
    [[ -e "$dir/env-reference.json" ]] || [[ -L "$dir/env-reference.json" ]]
}

# Function to scan for directories with old configuration
scan_odoo_directories() {
    local dirs=()

    # Scan /opt/odoo/* directories
    if [[ -d "/opt/odoo" ]]; then
        for dir in /opt/odoo/*/; do
            # Remove trailing slash
            dir="${dir%/}"

            # Skip odoo-docs itself
            if [[ "$dir" == "$SOURCE_DIR" ]] || [[ "$dir" == "/opt/odoo/odoo-docs" ]]; then
                continue
            fi

            # Check if directory has old config
            if has_old_config "$dir"; then
                dirs+=("$dir")
            fi
        done
    fi

    # Return array elements separated by newline (only if array is not empty)
    if [[ ${#dirs[@]} -gt 0 ]]; then
        printf '%s\n' "${dirs[@]}"
    fi
}

# Function to display directory info
display_dir_info() {
    local dir="$1"
    local index="$2"
    local has_guidelines=""
    local has_env=""

    # Check for files or symlinks (even broken ones)
    if [[ -e "$dir/.augment-guidelines" ]] || [[ -L "$dir/.augment-guidelines" ]]; then
        has_guidelines="📋"
    fi
    if [[ -e "$dir/env-reference.json" ]] || [[ -L "$dir/env-reference.json" ]]; then
        has_env="⚙️"
    fi

    echo -e "  ${YELLOW}[$index]${NC} $(basename "$dir")  $has_guidelines $has_env"
}

# Scan for directories
echo -e "${CYAN}🔍 Scanning /opt/odoo/ for projects with old configuration...${NC}"
echo ""

mapfile -t FOUND_DIRS < <(scan_odoo_directories)

if [[ ${#FOUND_DIRS[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No projects found with old configuration in /opt/odoo/${NC}"
    echo ""

    # Check if current directory has old config
    if has_old_config "$CURRENT_DIR"; then
        echo -e "${BLUE}Current directory has old configuration.${NC}"
        read -p "Migrate current directory? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Migration cancelled${NC}"
            exit 0
        fi
        DIRS_TO_MIGRATE=("$CURRENT_DIR")
    else
        echo -e "${GREEN}✓ No migration needed${NC}"
        exit 0
    fi
else
    # Check if current directory is in the list
    CURRENT_IN_LIST=false
    for dir in "${FOUND_DIRS[@]}"; do
        if [[ "$dir" == "$CURRENT_DIR" ]]; then
            CURRENT_IN_LIST=true
            break
        fi
    done

    # Build menu with found projects + special options
    echo -e "${BLUE}Select projects to migrate:${NC}"
    echo ""

    # Display found directories
    for i in "${!FOUND_DIRS[@]}"; do
        display_dir_info "${FOUND_DIRS[$i]}" "$((i+1))"
    done

    echo ""
    echo -e "${CYAN}Legend: 📋 = .augment-guidelines  ⚙️ = env-reference.json${NC}"
    echo ""

    # Add special options after the project list
    NEXT_NUM=$((${#FOUND_DIRS[@]} + 1))

    if [[ "$CURRENT_IN_LIST" == true ]]; then
        OPTION_CURRENT=$NEXT_NUM
        echo -e "  ${YELLOW}[$OPTION_CURRENT]${NC} Migrate current directory only ($(basename "$CURRENT_DIR"))"
        NEXT_NUM=$((NEXT_NUM + 1))
    fi

    OPTION_ALL=$NEXT_NUM
    echo -e "  ${YELLOW}[$OPTION_ALL]${NC} Migrate all found projects"

    OPTION_CANCEL=$((NEXT_NUM + 1))
    echo -e "  ${YELLOW}[$OPTION_CANCEL]${NC} Cancel"
    echo ""

    echo -e "${CYAN}Enter project numbers (space-separated, e.g., 1 3) or option number:${NC}"
    read -p "Selection: " -r SELECTION

    # Parse selection
    DIRS_TO_MIGRATE=()

    # Check if it's a single special option
    if [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
        # Single number - could be project or special option
        num=$SELECTION

        if [[ $num -eq $OPTION_CANCEL ]]; then
            echo -e "${YELLOW}Migration cancelled${NC}"
            exit 0
        elif [[ $num -eq $OPTION_ALL ]]; then
            DIRS_TO_MIGRATE=("${FOUND_DIRS[@]}")
        elif [[ "$CURRENT_IN_LIST" == true ]] && [[ $num -eq $OPTION_CURRENT ]]; then
            DIRS_TO_MIGRATE=("$CURRENT_DIR")
        elif [[ $num -ge 1 ]] && [[ $num -le ${#FOUND_DIRS[@]} ]]; then
            # It's a project number
            index=$((num-1))
            DIRS_TO_MIGRATE=("${FOUND_DIRS[$index]}")
        else
            echo -e "${RED}✗ Invalid selection: $num${NC}"
            exit 1
        fi
    else
        # Multiple numbers - must be project selections
        for num in $SELECTION; do
            if [[ $num -ge 1 ]] && [[ $num -le ${#FOUND_DIRS[@]} ]]; then
                index=$((num-1))
                DIRS_TO_MIGRATE+=("${FOUND_DIRS[$index]}")
            else
                echo -e "${YELLOW}⚠️  Invalid number: $num (skipped)${NC}"
            fi
        done

        if [[ ${#DIRS_TO_MIGRATE[@]} -eq 0 ]]; then
            echo -e "${RED}✗ No valid directories selected${NC}"
            exit 1
        fi
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Will migrate ${#DIRS_TO_MIGRATE[@]} project(s):${NC}"
for dir in "${DIRS_TO_MIGRATE[@]}"; do
    echo -e "  • $(basename "$dir")"
done
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

read -p "Proceed with migration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Migration cancelled${NC}"
    exit 0
fi

# Function to migrate a single directory
migrate_directory() {
    local TARGET_DIR="$1"
    local PROJECT_NAME=$(basename "$TARGET_DIR")

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Migrating: ${PROJECT_NAME}${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    # Check if .augment already exists
    if [[ -e "$TARGET_DIR/.augment" ]]; then
        echo -e "${YELLOW}⚠️  .augment/ directory already exists${NC}"
        read -p "   Overwrite existing .augment/ directory? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}   Skipped $PROJECT_NAME${NC}"
            return 1
        fi
        rm -rf "$TARGET_DIR/.augment"
    fi

    # Copy templates to create .augment directory
    echo -e "${BLUE}Step 1: Creating .augment/ directory from templates${NC}"
    if [[ ! -e "$SOURCE_DIR/templates/.augment" ]]; then
        echo -e "${RED}✗ Error: Template directory not found at $SOURCE_DIR/templates/.augment${NC}"
        return 1
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

    echo ""
    echo -e "${GREEN}✓ Migration completed for $PROJECT_NAME!${NC}"

    return 0
}

# Migrate all selected directories
echo ""
echo -e "${BLUE}Starting migration process...${NC}"

MIGRATED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

for dir in "${DIRS_TO_MIGRATE[@]}"; do
    if migrate_directory "$dir"; then
        ((MIGRATED_COUNT++))
    else
        if [[ $? -eq 1 ]]; then
            ((SKIPPED_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
    fi
done

# Final summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Migration Summary                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Successfully migrated: $MIGRATED_COUNT${NC}"
[[ $SKIPPED_COUNT -gt 0 ]] && echo -e "${YELLOW}⊘ Skipped: $SKIPPED_COUNT${NC}"
[[ $FAILED_COUNT -gt 0 ]] && echo -e "${RED}✗ Failed: $FAILED_COUNT${NC}"
echo ""
echo -e "${BLUE}New structure for migrated projects:${NC}"
echo -e "  📁 ${YELLOW}./.augment/${NC}"
echo -e "  📁 ${YELLOW}./.augment/config/env-reference.json${NC} - Developer & branding info"
echo -e "  📁 ${YELLOW}./.augment/rules/${NC} - AI agent rules"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Review and update: ${YELLOW}./.augment/config/env-reference.json${NC} in each project"
echo -e "  2. Customize rules if needed: ${YELLOW}./.augment/rules/*.md${NC}"
echo -e "  3. The .augment/ directory is in .gitignore (user-specific)"
echo ""
echo -e "${GREEN}Happy AI-powered Odoo development! 🚀${NC}"

