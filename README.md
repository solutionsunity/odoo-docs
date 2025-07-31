# Odoo Development Documentation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Odoo](https://img.shields.io/badge/Odoo-17.0+-purple.svg)](https://www.odoo.com/)
[![AI Agent Ready](https://img.shields.io/badge/AI%20Agent-Ready-brightgreen.svg)](https://github.com/solutionsunity/odoo-docs)

Centralized documentation and development standards for **AI-powered Odoo development**. This repository provides consistent coding standards, guidelines, and AI assistant configurations that can be shared across multiple Odoo projects, designed primarily for AI agents with human developer support.

## ✨ Features

- 🤖 **AI Agent Optimized** - Pre-configured for AI assistants (Augment, Cursor, etc.)
- 📚 **Comprehensive Documentation** - Complete coding standards and guidelines
- 🔗 **One-Line Setup** - Instant integration with any Odoo project
- 🔄 **Auto-Update** - Keep standards current across all projects
- 🏗️ **Template System** - Ready-to-use AI and development configurations

## 🚀 One-Line Installation

### For AI Agents & Developers

**Install in current directory (default docs path: `/opt/odoo-docs`):**
```bash
curl -sSL https://raw.githubusercontent.com/solutionsunity/odoo-docs/main/install.sh | bash
```

**Install with custom paths:**
```bash
curl -sSL https://raw.githubusercontent.com/solutionsunity/odoo-docs/main/install.sh | bash -s /path/to/project /custom/docs/path
```

**What the installer does:**
1. 📥 Clones/updates the odoo-docs repository (default: `/opt/odoo-docs`)
2. 📋 Copies configuration templates (`.augment-guidelines`, `dev-config.json`)
3. 🔗 Creates symlinks to documentation (`docs/`)
4. 📝 Updates `.gitignore` to ignore symlinks and private configs
5. ✅ Ready for AI-powered development!

### Manual Installation

If you prefer manual setup:

```bash
# 1. Clone the repository
git clone https://github.com/solutionsunity/odoo-docs.git /opt/odoo-docs

# 2. Navigate to your project
cd /path/to/your/odoo-project

# 3. Copy templates for private configuration
cp /opt/odoo-docs/templates/.augment-guidelines.template .augment-guidelines
cp /opt/odoo-docs/templates/dev-config.json.template dev-config.json

# 4. Create documentation symlink
ln -sf /opt/odoo-docs/docs docs

# 5. Update .gitignore
echo -e "\n# Odoo Documentation\ndocs\n.augment-guidelines\ndev-config.json" >> .gitignore
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
│   └── dev-config.json.template
├── .augment-guidelines            # 🤖 AI assistant configuration (ignored)
├── dev-config.json               # ⚙️ Development configuration (ignored)
└── README.md                     # This file
```

## 📚 Documentation Standards

| Document | Description | Purpose |
|----------|-------------|---------|
| **[Git Standards](docs/git.md)** | Commit message format and workflow | Consistent git history |
| **[Code Standards](docs/code_standard.md)** | Backend development guidelines | Clean, maintainable code |
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
- **`dev-config.json.template`** - Development environment settings

Copy and customize these templates for your specific needs.

## 💡 Best Practices

1. **Always symlink** - Don't copy files, use symlinks to stay updated
2. **Sync regularly** - Run `./docs/sync.sh` before starting work
3. **Follow standards** - Check documentation before coding
4. **Contribute back** - Improve standards for everyone

## 🤝 Contributing

We welcome contributions to improve these standards:

1. Fork this repository
2. Create a feature branch
3. Make your improvements
4. Submit a pull request

## 📄 License

MIT License - Feel free to use and adapt for your projects.
