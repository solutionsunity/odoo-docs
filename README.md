# Odoo Development Workspace

Professional Odoo development workspace with standards, documentation, and development environment setup.

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/solutionsunity/odoo-workarea.git
   cd odoo-workarea
   ```

2. **Set up your private configuration:**
   ```bash
   # Copy and customize the Augment guidelines
   cp templates/.augment-guidelines.template .augment-guidelines
   
   # Copy and customize development configuration
   cp templates/dev-config.json.template dev-config.json
   ```

3. **Edit the configuration files** with your personal/company information

4. **Create your workarea directory** for private repositories:
   ```bash
   mkdir -p workarea
   cd workarea
   # Clone your private Odoo repositories here
   ```

## 📁 Structure

```
odoo-workarea/
├── docs/                          # Development standards and guidelines
│   ├── git.md                     # Git commit standards
│   ├── code_standard.md           # Backend coding standards
│   ├── frontend.md                # Frontend/portal standards
│   ├── owl.md                     # OWL component guidelines
│   └── migration_guideline.md     # Migration procedures
├── templates/                     # Configuration templates
│   ├── .augment-guidelines.template
│   ├── dev-config.json.template
│   └── odoo.conf.template
├── workarea/                      # Private repositories (ignored)
│   ├── your-private-repo-1/
│   ├── your-private-repo-2/
│   └── modules/
└── .gitignore                     # Ignores workarea and private configs
```

## 📚 Documentation

- **[Git Standards](docs/git.md)** - Commit message format and git workflow
- **[Code Standards](docs/code_standard.md)** - Backend development guidelines
- **[Frontend Standards](docs/frontend.md)** - Portal and frontend development
- **[OWL Guidelines](docs/owl.md)** - OWL component development (version-specific notes included)
- **[Migration Guide](docs/migration_guideline.md)** - Version migration procedures

## 🔧 Configuration

The `workarea/` directory is ignored by git and should contain your private repositories and sensitive configurations. Use the templates in `templates/` to set up your development environment.

## 🤝 Contributing

This repository contains shared development standards. Feel free to contribute improvements to documentation and standards that benefit the Odoo development community.

## 📄 License

MIT License - See LICENSE file for details.
