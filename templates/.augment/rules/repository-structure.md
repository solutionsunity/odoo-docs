---
type: "agent_requested"
description: "Load when user asks about workspace organization, repository structure, file locations, documentation access, project layout, or navigation questions."
---

# Repository Structure & Workspace Organization

This rule defines the workspace structure, repository organization, and how to access documentation and environment references across different Odoo projects.

## Workspace Structure

### Current Repository Context
- **Type**: Project repository containing Odoo modules (varies by project)
- **Location**: Varies by project (su-odoo, uac-odoo, workarea, etc.)
- **Base Path**: All Odoo project repos are under `/opt/odoo/` except for Odoo standard codebase

### Documentation Access
- **Central Repository**: `/opt/odoo/odoo-docs/` (public standards and templates)
- **Local Access**: `./docs/` (symlink to `/opt/odoo/odoo-docs/docs/`)
- **Sync Script**: `./docs/sync.sh` (synchronization script to get latest standards)
- **Environment Reference**: `./env-reference.json` (development environment settings)

## Key Paths Reference

```
/opt/odoo/
├── odoo-docs/              # Central documentation repository
│   └── docs/               # Standards and templates
├── su-odoo/                # Example project repository
│   ├── docs/               # Symlink to /opt/odoo/odoo-docs/docs/
│   ├── env-reference.json  # Environment settings
│   └── [modules]/          # Odoo modules
├── uac-odoo/               # Another project repository
└── workarea/               # Another project repository

/usr/lib/python3/dist-packages/odoo/  # Odoo standard codebase
└── addons/                           # Standard Odoo modules
```

## Documentation Synchronization

### Before Development Sessions
- **Always run**: `./docs/sync.sh` to get latest standards before starting any development
- **Availability**: Documentation is always available via `./docs/` symlink
- **Environment reference**: Available at `./env-reference.json`
- **Centralization**: All development standards are centralized and automatically updated

### Documentation Files
All documentation is centralized in `/opt/odoo/odoo-docs/` and accessed via symlinks in each project repository. This ensures consistency across all projects.

