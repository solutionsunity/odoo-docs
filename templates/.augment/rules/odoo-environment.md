---
type: "agent_requested"
description: "Load when user asks about environment setup, system configuration, installation paths, Odoo installation details, WSL2 setup, technology stack, or technical infrastructure questions."
---

# Odoo Development Environment

This rule defines the technical environment setup and configuration for Odoo/OWL development in WSL2. It specifies system paths, installation details, and technology stack.

## System Configuration

### Platform & Installation
- **Platform**: WSL2 development environment
- **Odoo Installation**: Odoo CE installed via apt package manager
- **Odoo Codebase Location**: `/usr/lib/python3/dist-packages/odoo`
- **Configuration File**: `/etc/odoo/odoo.conf` (use this when running Odoo commands)
- **User Context**: Use `sudo -u odoo` to run commands as the odoo user in WSL

### Repository Locations
- **Odoo Standard Codebase**: `/usr/lib/python3/dist-packages/odoo`
  - Contains core Odoo modules and framework
  - Source for examples and reference implementations
- **Project Repositories**: All under `/opt/odoo/`
  - `su-odoo` - Project repository
  - `uac-odoo` - Project repository
  - `workarea` - Project repository
  - Other project-specific repositories
- **Documentation Repository**: `/opt/odoo/odoo-docs/` (central docs repository)

## Technology Stack

### Backend
- **Framework**: Odoo (Python-based)
- **Language**: Python 3
- **ORM**: Odoo ORM

### Frontend
- **Framework**: OWL (Odoo Web Library)
- **Language**: JavaScript
- **Components**: OWL components for reactive UI

### Templates & Styling
- **Template Engine**: QWeb (XML-based)
- **Styling**: CSS/SCSS
- **Template Format**: XML

