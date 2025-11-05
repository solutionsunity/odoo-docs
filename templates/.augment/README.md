# Augment Configuration Template

This directory contains templates for setting up your personal Augment configuration.

## Quick Setup

Copy this template directory to create your personal `.augment/` configuration:

```bash
# From the repository root
cp -r templates/.augment .augment

# Customize your developer and branding information
nano .augment/config/env-reference.json

# Optional: Customize rules to your preferences
nano .augment/rules/*.md
```

## Structure

```
.augment/
├── config/
│   └── env-reference.json      # Your developer & branding info
└── rules/
    ├── meta-rule.md            # Core rule (ALWAYS loaded)
    ├── development-workflow.md # Development workflow (AUTO)
    ├── odoo-environment.md     # Environment details (AUTO)
    ├── repository-structure.md # Workspace structure (AUTO)
    └── agent-identity.md       # Communication style (AUTO)
```

## Configuration Files

### config/env-reference.json

Contains your personal developer and branding information:

- **developer**: Your name, email, company, website
- **odoo**: Odoo version, paths, configuration
- **branding**: Default author, license, versioning for modules

**Important:** Update this file with your actual information after copying!

### rules/*.md

Augment rule files that define how the AI agent behaves:

- **meta-rule.md** (ALWAYS): Core workflow, always loaded with every prompt
- **development-workflow.md** (AUTO): Loaded when doing development tasks
- **odoo-environment.md** (AUTO): Loaded for environment questions
- **repository-structure.md** (AUTO): Loaded for structure questions
- **agent-identity.md** (AUTO): Loaded for communication style discussions

## Rule Modes

Rules use YAML frontmatter to configure their behavior:

```yaml
---
type: "always_apply"        # Always loaded
---
```

```yaml
---
type: "agent_requested"     # Auto-loaded based on description
description: "Load when..."
---
```

## Customization

Feel free to customize the rules to match your preferences:

1. **Adjust descriptions** in frontmatter for better Auto-loading
2. **Modify workflow** to match your development process
3. **Add new rules** for project-specific guidelines
4. **Update config** with your personal information

## Git Ignore

The `.augment/` directory is ignored in git (see `.gitignore`), so your personal configuration stays private while the templates are version controlled.

## Updates

To get the latest template updates:

```bash
# Your .augment/ is preserved (it's in .gitignore)
git pull

# Manually merge any new template changes you want
diff -r templates/.augment .augment
```

