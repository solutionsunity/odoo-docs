# Odoo 17.0 Migration Guidelines

This document provides a comprehensive guide for migrating modules to Odoo 17.0, based on our experience migrating custom and OCA modules. It highlights key changes, common challenges, and best practices to follow during the migration process.

## Key Changes in Odoo 17.0

### 1. Python Requirements

- Odoo 17.0 requires Python 3.10 or newer
- Some Python libraries may need to be updated to compatible versions

### 2. View Changes

#### Attrs and States Deprecation

One of the most significant changes in Odoo 17.0 is the deprecation of `attrs` and `states` attributes in view definitions:

- Replace `attrs` with direct attribute conditions (e.g., `invisible`, `readonly`, `required`)
- Replace `states` with direct attribute conditions
- Use domain expressions for conditional visibility and editability

Example:

```xml
<!-- Odoo 16.0 and earlier -->
<field name="field_name" attrs="{'invisible': [('state', '!=', 'draft')], 'readonly': [('state', '=', 'done')]}"/>

<!-- Odoo 17.0 -->
<field name="field_name"
       invisible="state != 'draft'"
       readonly="state == 'done'"/>
```

### 3. Field Name Changes

Some field names have changed in Odoo 17.0:

| Model | Old Field (16.0) | New Field (17.0) | Notes |
|-------|-----------------|-----------------|-------|
| res.company | fiscalyear_lock_date | period_lock_date | Used for accounting period locking |

### 4. Hook Function Changes

Hook functions now use different parameters:

- Use `env` parameter instead of `cr` and `registry` parameters
- Pre-install and post-install hooks have updated signatures

### 5. Asset Bundle Changes

Asset bundles work similarly in Odoo 17.0:

- The `assets_backend`, `assets_frontend`, and other asset bundles are still valid
- JavaScript files can use ES6 modules
- XML files for templates should be included in the appropriate asset bundle

### 6. API Changes

#### ORM Methods

- Models should override `create_multi` instead of `create` to avoid deprecation warnings
- Prefer using `read_group()` over `_read_group()` as the former is the public API method
- Methods prefixed with underscore are typically internal implementation details and should be avoided in custom code

#### Super Calls

Always use `super()` to call the original method instead of duplicating code:

```python
# Correct way to extend a method
def write(self, vals):
    # Custom code before super
    result = super().write(vals)
    # Custom code after super
    return result
```

### 7. Mail Thread Changes

- Custom models with mail thread functionality must implement `_get_thread_with_access` method
- This ensures proper access control for threaded discussions

## Common Migration Challenges

### 1. Database Schema Changes

When fields are renamed or removed, you may need to handle data migration:

```python
# Example of migrating data for renamed fields
def migrate(cr, version):
    if not version:
        return
    # Copy data from old field to new field
    cr.execute("""
        UPDATE res_company
        SET period_lock_date = fiscalyear_lock_date
        WHERE fiscalyear_lock_date IS NOT NULL
    """)
```

### 2. JavaScript Changes

- ES6 modules are becoming more standard in Odoo 17.0
- Component-based architecture is preferred over widget-based architecture
- Use of `owl` framework for UI components

### 3. Report Templates

- QWeb report templates generally remain compatible
- Check for changes in helper functions or context variables

## Migration Process Best Practices

### 1. Incremental Approach

1. Start by updating version numbers in manifest files
2. Fix basic compatibility issues (attrs/states, field names, view definitions)
3. Test the module installation
4. Address runtime errors
5. Perform functional testing

### 2. Testing Strategy

- Install the module on a clean Odoo 17.0 database
- Check for installation errors
- Test all functionality
- Verify reports and UI elements
- Test with realistic data

### 3. Common Fixes

#### Manifest Updates

```python
{
    'name': 'Module Name',
    'version': '17.0.1.0.0',  # Update version
    'depends': [
        'base',
        'other_module',  # Ensure dependencies are available in 17.0
    ],
    # Update assets section if needed
}
```

#### XML View Updates

```xml
<!-- Update attrs to direct attributes -->
<record id="view_model_form" model="ir.ui.view">
    <field name="name">model.form</field>
    <field name="model">model.name</field>
    <field name="arch" type="xml">
        <form>
            <!-- Old: attrs="{'invisible': [('state', '!=', 'draft')]}" -->
            <!-- New: invisible="state != 'draft'" -->
            <field name="field_name" invisible="state != 'draft'"/>
        </form>
    </field>
</record>
```

#### Python Code Updates

```python
# Update field references
def method(self):
    # Old: company.fiscalyear_lock_date
    # New: company.period_lock_date
    lock_date = self.company_id.period_lock_date

# Update create method to create_multi
@api.model_create_multi
def create_multi(self, vals_list):
    return super().create_multi(vals_list)
```

## Module-Specific Migration Notes

### Accounting Modules

- Check for field name changes in `res.company` model (fiscalyear_lock_date → period_lock_date)
- Update view definitions to remove attrs/states
- Verify account types and tax handling

### Sales Modules

- Update view definitions to remove attrs/states
- Check for changes in sale order workflow
- Verify report templates

### HR/Payroll Modules

- Update view definitions to remove attrs/states
- Check for changes in payroll computation
- Verify report templates

### Web/UI Modules

- Update JavaScript components to use OWL framework patterns
- Replace attrs/states in XML views with direct attributes
- Test widget functionality thoroughly

## Conclusion

Migrating modules to Odoo 17.0 requires attention to detail and a systematic approach. The most significant changes involve updating view definitions to remove deprecated attrs and states attributes, updating hook functions, and ensuring compatibility with the OWL framework.

By following these guidelines and best practices, you can ensure a smooth migration process with minimal disruption to functionality.

Remember to always test thoroughly after migration and address any issues before deploying to production.

---

# Odoo 18.0 Migration Guidelines

This document provides a comprehensive guide for migrating modules from Odoo 17.0 to Odoo 18.0, based on our experience migrating custom and OCA modules. It highlights key changes, common challenges, and best practices to follow during the migration process.

## Key Changes in Odoo 18.0

### 1. Python Requirements

- Odoo 18.0 requires Python 3.10 or newer
- Some Python libraries may need to be updated to compatible versions

### 2. View Changes

#### Tree to List View Conversion

One of the most significant changes in Odoo 18.0 is the renaming of "tree" views to "list" views:

- Change `<tree>` tags to `<list>` tags in XML view definitions
- Update `view_mode="tree,form"` to `view_mode="list,form"` in action definitions
- Update view IDs and names from "tree" to "list" (e.g., `view_model_tree` to `view_model_list`)
- Add explicit `type="list"` to list view definitions

Example:

```xml
<!-- Odoo 17.0 -->
<record id="view_partner_tree" model="ir.ui.view">
    <field name="name">res.partner.tree</field>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <tree>
            <field name="name"/>
        </tree>
    </field>
</record>

<!-- Odoo 18.0 -->
<record id="view_partner_list" model="ir.ui.view">
    <field name="name">res.partner.list</field>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <list>
            <field name="name"/>
        </list>
    </field>
</record>
```

### 3. Field Name Changes

Several field names have changed in Odoo 18.0:

| Model | Old Field (17.0) | New Field (18.0) | Notes |
|-------|-----------------|-----------------|-------|
| res.company | period_lock_date | hard_lock_date | Used for accounting period locking |
| res.company | account_journal_payment_debit_account_id | *Removed* | These fields were removed in 18.0 |
| res.company | account_journal_payment_credit_account_id | *Removed* | These fields were removed in 18.0 |

### 4. Menu Changes

Some menu IDs have changed in Odoo 18.0:

| Old Menu ID (17.0) | New Menu ID (18.0) | Notes |
|-------------------|-------------------|-------|
| account.menu_finance_entries_management | account.menu_finance_entries | Used in accounting modules |

### 5. Asset Bundle Changes

Asset bundles still work similarly in Odoo 18.0, but there are some changes to be aware of:

- The `assets_backend`, `assets_frontend`, and other asset bundles are still valid
- JavaScript files should use the `.esm.js` extension for ES modules
- XML files for templates should be included in the appropriate asset bundle

### 6. API Changes

#### ORM Methods

- Prefer using `read_group()` over `_read_group()` as the former is the public API method
- Methods prefixed with underscore are typically internal implementation details and should be avoided in custom code

#### Super Calls

Always use `super()` to call the original method instead of duplicating code:

```python
# Correct way to extend a method
def write(self, vals):
    # Custom code before super
    result = super().write(vals)
    # Custom code after super
    return result
```

## Common Migration Challenges (17.0 → 18.0)

### 1. Database Schema Changes

When fields are renamed or removed, you may need to handle data migration:

```python
# Example of migrating data for renamed fields
def migrate(cr, version):
    if not version:
        return
    # Copy data from old field to new field
    cr.execute("""
        UPDATE res_company
        SET hard_lock_date = period_lock_date
        WHERE period_lock_date IS NOT NULL
    """)
```

### 2. JavaScript Changes

- ES6 modules are now the standard in Odoo 18.0
- Component-based architecture is preferred over widget-based architecture
- Use of `owl` framework for UI components

### 3. Report Templates

- QWeb report templates generally remain compatible
- Check for changes in helper functions or context variables

## Migration Process Best Practices (17.0 → 18.0)

### 1. Incremental Approach

1. Start by updating version numbers in manifest files
2. Fix basic compatibility issues (field names, view definitions)
3. Test the module installation
4. Address runtime errors
5. Perform functional testing

### 2. Testing Strategy

- Install the module on a clean Odoo 18.0 database
- Check for installation errors
- Test all functionality
- Verify reports and UI elements
- Test with realistic data

### 3. Common Fixes

#### Manifest Updates

```python
{
    'name': 'Module Name',
    'version': '18.0.1.0.0',  # Update version
    'depends': [
        'base',
        'other_module',  # Ensure dependencies are available in 18.0
    ],
    # Update assets section if needed
}
```

#### XML View Updates

```xml
<!-- Update tree to list -->
<record id="view_model_list" model="ir.ui.view">
    <field name="name">model.list</field>
    <field name="model">model.name</field>
    <field name="arch" type="xml">
        <list>
            <!-- Fields -->
        </list>
    </field>
</record>

<!-- Update action view_mode -->
<record id="action_model" model="ir.actions.act_window">
    <field name="view_mode">list,form</field>
</record>
```

#### Python Code Updates

```python
# Update field references
def method(self):
    # Old: company.period_lock_date
    # New: company.hard_lock_date
    lock_date = self.company_id.hard_lock_date
```

## Module-Specific Migration Notes (17.0 → 18.0)

### Accounting Modules

- Check for field name changes in `res.company` model
- Update menu references
- Verify account types and tax handling

### Sales Modules

- Check for changes in sale order workflow
- Verify report templates

### HR/Payroll Modules

- Check for changes in payroll computation
- Verify report templates

## Conclusion (18.0 Migration)

Migrating modules from Odoo 17.0 to 18.0 requires attention to detail and a systematic approach. The most significant changes involve updating view definitions from tree to list, updating field references, and ensuring compatibility with the updated framework.

By following these guidelines and best practices, you can ensure a smooth migration process with minimal disruption to functionality.

Remember to always test thoroughly after migration and address any issues before deploying to production.
