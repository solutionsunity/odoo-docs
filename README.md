# Odoo Development Documentation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Odoo](https://img.shields.io/badge/Odoo-15+-purple.svg)](https://www.odoo.com/)
[![AI Agent Ready](https://img.shields.io/badge/AI%20Agent-Ready-brightgreen.svg)](https://github.com/solutionsunity/odoo-docs)

Centralized documentation and development standards for **AI-powered Odoo development**. This repository provides consistent coding standards, guidelines, and AI assistant configurations that can be shared across multiple Odoo projects (15+), designed primarily for AI agents with human developer support.

## ✨ Features

- 🤖 **AI Agent Optimized** - Pre-configured for AI assistants (Augment, Cursor, etc.)
- 📚 **Comprehensive Documentation** - Complete coding standards and guidelines
- 🔗 **One-Line Setup** - Instant integration with any Odoo project
- 🔄 **Auto-Update** - Keep standards current across all projects
- 🏗️ **Template System** - Ready-to-use AI and development configurations

## 🚀 Quick Setup

### Step 1: One-Line Installation (Recommended)

**Install templates in current directory:**
```bash
curl -sSL https://raw.githubusercontent.com/solutionsunity/odoo-docs/main/install.sh | bash
```

**Install templates in specific project directory:**
```bash
# Syntax: bash -s [project_path]
curl -sSL https://raw.githubusercontent.com/solutionsunity/odoo-docs/main/install.sh | bash -s /path/to/project
```

**What the installer does:**
- 📥 Clones/updates the odoo-docs repository to `/opt/odoo/odoo-docs` (standardized location)
- 📋 Copies configuration templates to your project directory
- 📝 Guides you to run `link.sh` next

### Step 2: Link to Existing Installation

If you already have odoo-docs installed, simply create symlinks from your project:

```bash
# From your project directory (e.g., /opt/odoo/workarea)
/opt/odoo/odoo-docs/link.sh
```

**What the linker does:**
- 📋 Copies templates to odoo-docs root (if missing)
- 🔗 Creates symlink to `docs/` directory
- 🔗 Creates symlink to `.augment-guidelines`
- 🔗 Creates symlink to `env-reference.json`
- 📝 Updates `.gitignore` with proper root-relative paths (`/docs`, `/.augment-guidelines`, `/env-reference.json`)
- ✅ Validates target directory and prevents conflicts
- 🔄 Detects existing symlinks and avoids duplicates

### Manual Installation

If you prefer manual setup:

```bash
# 1. Clone the repository
git clone https://github.com/solutionsunity/odoo-docs.git /opt/odoo/odoo-docs

# 2. Navigate to your project
cd /path/to/your/odoo-project

# 3. Copy templates for private configuration
cp /opt/odoo/odoo-docs/templates/.augment-guidelines.template .augment-guidelines
cp /opt/odoo/odoo-docs/templates/env-reference.json.template env-reference.json

# 4. Create symlinks and update .gitignore
/opt/odoo/odoo-docs/link.sh
```

## 📁 Repository Structure

```
odoo-docs/
├── docs/                          # 📚 Development standards and guidelines
│   ├── git.md                     # Git commit standards
│   ├── code_standard.md           # Backend coding standards
│   ├── frontend.md                # Frontend/portal standards
│   ├── owl.md                     # OWL component guidelines
│   ├── migration_guideline.md     # Migration procedures
│   ├── email_standard.md          # Email template standards
│   ├── module_icon.png            # Standard module icon
│   └── sync.sh                    # Synchronization script
├── templates/                     # 🔧 Configuration templates
│   ├── .augment-guidelines.template
│   └── env-reference.json.template
├── .augment-guidelines            # 🤖 AI assistant configuration
├── env-reference.json            # 🔧 Environment reference configuration
├── link.sh                       # 🔗 Symlink creation script
└── README.md                     # This file
```

## 📚 Documentation Standards

| Document | Description | Purpose |
|----------|-------------|---------|
| **[Git Standards](docs/git.md)** | Commit message format and workflow | Consistent git history |
| **[Code Standards](docs/code_standard.md)** | Backend development guidelines (15+) | Clean, maintainable code |
| **[Frontend Standards](docs/frontend.md)** | Portal and frontend development | Consistent UI/UX |
| **[OWL Guidelines](docs/owl.md)** | OWL component development | Modern JS framework |
| **[Migration Guide](docs/migration_guideline.md)** | Version migration procedures | Smooth upgrades |
| **[Email Standards](docs/email_standard.md)** | Email template guidelines | Professional communication |

## 🤖 AI Agent Integration

This repository is **optimized for AI agents** like Augment, Cursor, GitHub Copilot, and others:

### For AI Agents
- **`.augment-guidelines`** - Contains AI-specific instructions and context
- **Comprehensive docs** - All standards in easily parseable markdown
- **Auto-sync** - AI can run `./docs/sync.sh` to get latest updates
- **Template system** - AI can copy and customize configurations

### Recommended AI Workflow
1. **Session start**: Run `./docs/sync.sh` to ensure latest updates
2. **Before coding**: Reference `./docs/` for current guidelines
3. **During development**: Follow standards in documentation
4. **Before commits**: Check `./docs/git.md` for commit format

## 🔄 Staying Updated

Keep your documentation and standards current:

```bash
# From any project with symlinked docs
./docs/sync.sh
```

This script automatically:
- Pulls the latest changes from this repository
- Updates all symlinked documentation across your projects
- Ensures you're always using the current standards

## 🛠️ Configuration Templates

Use the provided templates to set up your development environment:

- **`.augment-guidelines.template`** - AI assistant configuration
- **`env-reference.json.template`** - Development environment settings

Copy and customize these templates for your specific needs.

## 💡 Best Practices

1. **Always symlink** - Don't copy files, use symlinks to stay updated
2. **Sync regularly** - Run `./docs/sync.sh` before starting work
3. **Follow standards** - Check documentation before coding
4. **Contribute back** - Improve standards for everyone

## ❓ FAQ

### **Q: I ran `link.sh` before initializing git. How do I get the .gitignore entries?**
**A:** Simply run `link.sh` again after `git init`. The script detects git repositories and will create the .gitignore entries automatically.

```bash
git init
/opt/odoo/odoo-docs/link.sh
```

### **Q: Can I use this in a directory that's not a git repository?**
**A:** Yes! The `link.sh` script works in any directory. It will create symlinks but skip .gitignore updates if git isn't initialized. You'll see a helpful message about this.

### **Q: What's the difference between `install.sh` and `link.sh`?**
**A:**
- **`install.sh`** - Copies templates for customization (creates actual files you can edit)
- **`link.sh`** - Creates symlinks to shared files (always stays in sync with updates)

Use `install.sh` when you want to customize configurations, use `link.sh` when you want to share the central configurations.

### **Q: I accidentally deleted a symlinked file. How do I restore it?**
**A:** Just run `link.sh` again. It will recreate any missing symlinks automatically.

### **Q: How do I update to the latest documentation standards?**
**A:** Run `./docs/sync.sh` from any project with symlinked docs. This pulls the latest updates from the central repository.

### **Q: Will this interfere with my Odoo module `docs/` directories?**
**A:** No! The .gitignore uses root-relative paths (`/docs`) that only ignore the symlinked docs directory at your repository root, not module documentation directories.

## 🤝 Contributing

We welcome contributions to improve these standards:

1. Fork this repository
2. Create a feature branch
3. Make your improvements
4. Submit a pull request

## 📄 License

MIT License - Feel free to use and adapt for your projects.
