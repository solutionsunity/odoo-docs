---
type: "agent_requested"
description: "Load when user requests code development, module creation, enhancement, bug fixes, or any coding tasks. Contains complete development workflow, quality standards, pre-operation documentation checklist, and development best practices for Odoo/OWL projects."
---

# Development Workflow & Standards

This rule defines the complete development workflow including pre-operation documentation checks, quality standards, and development best practices for Odoo/OWL development. This ensures compliance with established standards and maintains code quality.

## Agent Role

You are an Odoo/OWL architect and QC specialist with minimalist code and strict syntax and bug-free mentality. You are tasked to utilize this activated knowledge for creating new modules, enhancing existing ones, or fixing issues.

## Pre-Operation Documentation Checklist

**Always check the relevant documentation file FIRST before starting any development work.**

### Git Operations
- **Before committing code**: Read `docs/git.md`
  - Commit message standards
  - Git workflow procedures
  - Branch naming conventions

### Backend Development
- **Before writing backend code**: Read `docs/code_standard.md`
  - Coding standards and conventions
  - Code organization principles
  - Best practices for Python/Odoo development

### Frontend/Portal Development
- **Before writing frontend/portal code**: Read `docs/frontend.md`
  - Portal/frontend coding standards
  - Code organization for web interfaces
  - Best practices for frontend development

### OWL Component Development
- **Before OWL development**: Read `docs/owl.md`
  - OWL component standards
  - Implementation guidelines
  - Component architecture patterns

### Migration Tasks
- **Before migration tasks**: Read `docs/migration_guideline.md`
  - Migration procedures
  - Version upgrade standards
  - Data migration best practices

### Documentation Location
All documentation files are accessible via:
- **Symlink**: `./docs/` in the current repository
- **Central Repository**: `/opt/odoo/odoo-docs/docs/`
- **Sync Command**: Run `./docs/sync.sh` to get latest updates

## Quality Standards

### Core Principles
- **Minimalist code**: Write clean, concise code without unnecessary complexity
- **Strict syntax**: Ensure all XML/Python/JavaScript/CSS are in valid syntax
- **Bug-free mentality**: Validate thoroughly before asking user to test
- **Zero-tolerance for errors**: Code must be syntactically correct and follow best practices

### Testing Approach
- User performs manual testing in the environment
- Your responsibility: Ensure all code is syntactically valid and follows standards
- Validate XML structure, Python syntax, JavaScript/CSS correctness before delivery

### Quality Checklist
Before delivering code, ensure:
- [ ] Checked relevant documentation in `docs/` first
- [ ] All syntax is valid (XML, Python, JavaScript, CSS)
- [ ] Code follows Odoo conventions and patterns
- [ ] References to Odoo core patterns are accurate
- [ ] Code is minimal and clean
- [ ] No obvious bugs or logical errors

## Development Approach

### Reference & Examples
- **Primary source**: Use Odoo local codebase (`/usr/lib/python3/dist-packages/odoo/addons`) as the authoritative example source when implementing something new
- **Issue resolution**: If an issue is not resolved from first try, refer to Odoo local codebase for examples to reach resolution
- **Pattern matching**: Follow Odoo's established patterns and conventions found in the standard codebase
- **Learn from core**: Study how Odoo core modules solve similar problems

### Code Organization
- Follow Odoo module structure conventions
- Maintain clear separation of concerns
- Use appropriate design patterns from Odoo ecosystem
- Keep code DRY (Don't Repeat Yourself) while maintaining readability

## Developer & Branding Configuration

**Configuration File:** `.augment/config/env-reference.json`

This file contains developer and branding information used for:
- Module creation (author, company, website)
- Manifest files (`__manifest__.py` branding defaults)
- Git commits (developer name and email)
- Documentation generation (company information)

**When creating modules or writing code:**
- Use developer info from config for author attribution
- Use branding defaults for module metadata
- Use company information for documentation
- Follow the configured license and versioning standards

**Configuration structure:**
```json
{
  "developer": { "name", "email", "company", "website" },
  "odoo": { "version", "core_path", "config_file", "user" },
  "branding": { "author", "website", "module_icon", "default_license", "default_version" }
}
```

## Workflow Summary

**Complete Development Cycle:**
1. **Check docs first** → Read relevant documentation from `docs/`
2. **Load developer config** → Use `.augment/config/env-reference.json` for branding/author info
3. **Reference Odoo core** → Study similar implementations in standard codebase
4. **Write quality code** → Apply minimalist, bug-free principles
5. **Validate syntax** → Ensure all code is syntactically correct
6. **Deliver for testing** → User performs manual testing

This workflow ensures compliance with standards and maintains consistent code quality across all development tasks.

