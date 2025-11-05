# Odoo Development Standards

## Security Implementation

### CSV + XML Security Pattern (CRITICAL)

**⚠️ NEVER mix CSV permissions with XML `perm_*` attributes - this causes problematic implementations!**

#### ✅ Correct Approach: Separation of Concerns

**CSV File (`security/ir.model.access.csv`)**: Controls ALL permissions
```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_model_system,model.system,model_my_model,base.group_system,1,1,1,1
access_model_manager,model.manager,model_my_model,group_my_manager,1,1,1,1
access_model_user,model.user,model_my_model,group_my_user,1,1,1,0
```

**XML File (`security/security.xml`)**: Groups definition and data filtering (record rules)
```xml
<!-- ✅ CORRECT: Groups definition -->
<record id="group_my_user" model="res.groups">
    <field name="name">My Module: User</field>
    <field name="category_id" ref="base.module_category_human_resources"/>
</record>

<!-- ✅ CORRECT: Record rules for data filtering, NO permission attributes -->
<record id="rule_my_model_user" model="ir.rule">
    <field name="name">My Model: User access</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('group_my_user'))]"/>
    <!-- NO perm_read, perm_write, perm_create, perm_unlink attributes -->
</record>
```

#### ❌ Problematic Approach: Mixing Systems

```xml
<!-- ❌ WRONG: Mixing permissions in XML causes access conflicts -->
<record id="rule_my_model_user" model="ir.rule">
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="False"/>  <!-- ❌ Conflicts with CSV -->
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="False"/>
</record>
```

#### Security Architecture

```
┌─────────────────┐    ┌──────────────────┐
│   CSV File      │    │   XML File       │
│                 │    │                  │
│ ✅ Permissions  │    │ ✅ Groups        │
│ - Read: 1/0     │    │ - Definition     │
│ - Write: 1/0    │    │ - Hierarchy      │
│ - Create: 1/0   │    │                  │
│ - Delete: 1/0   │    │ ✅ Record Rules  │
│                 │    │ - Domain: [...]  │
│                 │    │ - Groups: [...]  │
│                 │    │ NO perm_* attrs  │
└─────────────────┘    └──────────────────┘
```

#### Benefits of Proper Separation

1. **✅ No Access Conflicts**: Clear separation prevents permission conflicts
2. **✅ Maintainable**: Single source of truth for each concern
3. **✅ Scalable**: Easy to modify permissions without touching record rules
4. **✅ Standard**: Follows Odoo recommended practices
5. **✅ Clean Code**: No sudo() workarounds needed

#### Common Issues with Mixed Approach

- "Due to security restrictions" errors during workflow actions
- Complex sudo() workarounds cluttering business logic
- Inconsistent permission behavior across different operations
- Difficult debugging and maintenance

### Group Hierarchy

Use proper group inheritance for clean security:

```xml
<record id="group_my_user" model="res.groups">
    <field name="name">My Module: User</field>
    <field name="category_id" ref="base.module_category_human_resources"/>
</record>

<record id="group_my_manager" model="res.groups">
    <field name="name">My Module: Manager</field>
    <field name="category_id" ref="base.module_category_human_resources"/>
    <field name="implied_ids" eval="[(4, ref('group_my_user'))]"/>
</record>
```

### Record Rules Best Practices

1. **Use OR logic for multiple conditions**:
```xml
<field name="domain_force">['|', ('state', 'in', ['approved', 'done']), ('user_id', '=', user.id)]</field>
```

2. **Avoid complex Python expressions in domains**
3. **Test record rules with different user roles**
4. **Document the business logic behind each rule**

## Code Organization

- Organize code into logical segments:
  - Field definitions
  - API methods (create, write, onchange, compute)
  - Action methods
  - Public functions
  - Private methods
- Include proper docstrings and maintain consistent indentation (4 spaces)
- When extending Odoo methods, prefer using super().with_context() instead of duplicating code
- Prefer Odoo's ORM methods over raw SQL queries when possible
- **CRITICAL**: Place ALL imports at the top of the file, never within methods, functions, or exception handlers
- Inline imports (e.g., `import traceback` inside try/except blocks) are strictly prohibited
- All required modules must be imported at the file header, even if only used in error handling
- All module files should include consistent author and company details with copyright information

## Model Method Standards

### Create Method Implementation

**Standard Pattern for Odoo 15.0+:**
```python
@api.model_create_multi
def create(self, vals_list):
    """Create method with multi-record support."""
    # Pre-processing logic
    for vals in vals_list:
        # Process individual vals dict
        pass

    # Call super with vals_list
    records = super().create(vals_list)

    # Post-processing logic
    for record in records:
        # Process individual created record
        pass

    return records
```

**Key Requirements:**
- Always use `@api.model_create_multi` decorator for new models in Odoo 15.0+
- Method signature must be `create(self, vals_list)` not `create(self, vals)`
- Handle both single dict and list of dicts in vals_list parameter
- Use `super().create(vals_list)` to call parent method
- This pattern provides better performance and consistency with Odoo core

## Naming Conventions

- State-tracking fields should follow the standard naming convention of 'state'
- Avoid using 'default_' prefix for field names as it is reserved for Odoo internals
- Use clear, descriptive names for methods and variables

## Computed Fields with Search

For computed fields that need to be searchable but cannot/should not be stored:

```python
# Field definition
is_expiring_soon = fields.Boolean(
    string='Expiring Soon',
    compute='_compute_expiry_info',
    search='_search_is_expiring_soon'  # Enable search without storing
)

# Search method
@api.model
def _search_is_expiring_soon(self, operator, value):
    """Search method for computed field"""
    # Get candidates with basic domain
    candidates = self.search([('basic_field', '=', 'criteria')])

    # Apply computed logic to filter results
    matching_ids = []
    for record in candidates:
        if record.computed_condition:
            matching_ids.append(record.id)

    return [('id', 'in', matching_ids)]
```

**Use cases:**
- Fields depending on current date/time (never store these)
- Complex calculations without clear dependency triggers
- Fields that need search capability in XML filters and Python domains

**Benefits:**
- Always current values (no stale stored data)
- Searchable in domains and XML filters
- Follows Odoo standard patterns

## Time-Based Computed Fields (CRITICAL)

**⚠️ NEVER store computed fields that depend on current date/time!**

### The Problem

Time-based computed fields that compare with `date.today()`, `datetime.now()`, or similar time functions should **NEVER** be stored. They only recompute when their declared dependencies change, not when the date/time changes.

```python
# ❌ WRONG - Stored time-based field
license_status = fields.Selection([
    ('valid', 'Valid'),
    ('expired', 'Expired'),
], compute='_compute_license_status',
   store=True)  # ❌ WRONG! Will become stale

@api.depends('license_expiry_date')
def _compute_license_status(self):
    """This only runs when license_expiry_date changes!"""
    for record in self:
        today = date.today()  # This changes every day!
        if record.license_expiry_date < today:
            record.license_status = 'expired'
        else:
            record.license_status = 'valid'
```

**Issue:** A license that's "valid" today won't automatically become "expired" tomorrow because the field only recomputes when `license_expiry_date` changes, not when the date changes. Days and nights happen outside Odoo - there's no trigger to recompute!

### ✅ Correct Implementation

```python
# ✅ CORRECT - Not stored, recomputes on every access
license_status = fields.Selection([
    ('valid', 'Valid'),
    ('expired', 'Expired'),
], compute='_compute_license_status')  # No store=True!

@api.depends('license_expiry_date')
def _compute_license_status(self):
    """Computes fresh on every access"""
    for record in self:
        today = date.today()
        if record.license_expiry_date < today:
            record.license_status = 'expired'
        else:
            record.license_status = 'valid'
```

### Common Time-Based Fields (Never Store)

- **License/Certificate status** (valid/expired based on expiry date)
- **Days until expiry** (calculated from today)
- **Age calculations** (years/months from birth date)
- **Overdue status** (based on due date vs today)
- **Time remaining** (deadline - now)
- **Business hours status** (open/closed based on current time)
- **Seasonal flags** (based on current month/season)

### If You Need to Search Time-Based Fields

Use the `search` parameter to enable searching without storing:

```python
is_expired = fields.Boolean(
    compute='_compute_is_expired',
    search='_search_is_expired'  # Enable search without storing
)

@api.model
def _search_is_expired(self, operator, value):
    """Search for expired records"""
    today = date.today()
    if (operator == '=' and value) or (operator == '!=' and not value):
        return [('expiry_date', '<', today)]
    else:
        return [('expiry_date', '>=', today)]
```

### Performance Considerations

**Q: Won't non-stored fields be slow?**

**A:** Not significantly. Time-based computations are typically very fast (simple date comparisons). The benefit of always-correct data far outweighs the minimal performance cost.

**Q: What if I have thousands of records?**

**A:** Use proper indexing on the dependency fields (e.g., `expiry_date`) and implement efficient search methods. Odoo's ORM is optimized for this pattern.

### Summary

- ✅ **DO**: Leave time-based computed fields non-stored
- ✅ **DO**: Implement search methods if filtering is needed
- ✅ **DO**: Use proper indexing on dependency fields
- ❌ **DON'T**: Store fields that compare with `date.today()` or `datetime.now()`
- ❌ **DON'T**: Assume stored fields will update automatically over time

## Error Handling and Validation

- Error messages should be clear and specific about the exact problem encountered
- Implement field validation through onchange methods for immediate UI feedback
- Centralize validation logic in a single function
- Avoid raising UserError in write() methods as it may interfere with automated scripts
- Add proper logging (using _logger) for better debugging and monitoring
- Use % formatting for logging messages instead of f-strings for performance optimization (% formatting is only evaluated when the logging level is active, while f-strings are always evaluated regardless of logging level)

## Function Design

- User interaction functions should handle validation while calling separate internal functions for business logic
- Public functions should contain all required business logic checks internally
- Prefer moving domain definitions from Python model files to XML view files for greater flexibility

## Action Handling Patterns

### Getting Action Data for Smart Buttons and Redirects

When returning action data from model methods (e.g., smart buttons, wizard redirects), always use `_for_xml_id()` instead of `ref().read()` to avoid permission errors:

#### ✅ Correct Pattern
```python
def action_view_related_records(self):
    """Smart button to view related records."""
    # ✅ CORRECT: Use _for_xml_id() - works for all user groups
    action = self.env["ir.actions.act_window"]._for_xml_id('module.action_related_records')
    action['domain'] = [('parent_id', '=', self.id)]
    action['context'] = {'default_parent_id': self.id}
    return action
```

#### ❌ Problematic Pattern
```python
def action_view_related_records(self):
    """Smart button to view related records."""
    # ❌ WRONG: Causes "Access Error" for non-admin users
    action = self.env.ref('module.action_related_records').read()[0]
    action['domain'] = [('parent_id', '=', self.id)]
    return action
```

#### Why This Matters
- `ref().read()[0]` requires "Administration/Settings" group permissions
- `_for_xml_id()` is designed for this use case and handles permissions internally
- Smart buttons and wizard redirects should work for all authorized users, not just admins

#### Common Use Cases
- **Smart buttons**: Opening related records (bills, payments, moves)
- **Wizard redirects**: Returning to list views after operations
- **Menu actions**: Programmatically opening specific views
- **Report actions**: Triggering report generation

### Settings Actions

When creating settings actions that inherit `res.config.settings`, **do NOT include a `name` field** in the action definition. The standard settings view will automatically use "Settings" as the title, preventing breadcrumb navigation issues.

#### ✅ Correct Settings Action
```xml
<record id="action_module_settings" model="ir.actions.act_window">
    <!-- NO name field here -->
    <field name="type">ir.actions.act_window</field>
    <field name="res_model">res.config.settings</field>
    <field name="view_mode">form</field>
    <field name="target">inline</field>
    <field name="context">{'module': 'module_name'}</field>
</record>
```

#### ❌ Problematic Settings Action
```xml
<record id="action_module_settings" model="ir.actions.act_window">
    <field name="name">Module Settings</field>  <!-- REMOVE THIS -->
    <field name="type">ir.actions.act_window</field>
    <field name="res_model">res.config.settings</field>
    <field name="view_mode">form</field>
    <field name="target">inline</field>
    <field name="context">{'module': 'module_name'}</field>
</record>
```

#### Why This Matters
- Including a `name` field causes breadcrumb navigation to show "Module Settings / Users" instead of "Settings / Users"
- The standard settings view is designed to use "Settings" as the default title
- This ensures consistent navigation experience across all Odoo settings pages
- Prevents user confusion when navigating between different settings sections

## Save Before Add Line Pattern

### Forcing Parent Record Save Before Adding Child Records

When working with One2many fields, it's often necessary to save the parent record before allowing users to add child records. This prevents issues with unsaved records and ensures proper data integrity.

#### ✅ Implementation Pattern

**1. Add Save Action to Parent Model:**
```python
def action_save_record(self):
    """Save the current record and return to form view."""
    self.ensure_one()
    # No additional logic needed - just trigger save
    return {
        'type': 'ir.actions.act_window',
        'res_model': self._name,
        'res_id': self.id,
        'view_mode': 'form',
        'target': 'current',
    }
```

**2. Add Save Button in Form View:**
```xml
<header>
    <!-- Other buttons -->
    <button name="action_save_record" type="object" string="Save"
            class="oe_highlight"
            attrs="{'invisible': [('id', '!=', False)]}"/>
</header>
```

**3. Configure One2many Field with Context:**
```xml
<field name="line_ids"
       context="{'default_parent_id': id}"
       attrs="{'readonly': [('id', '=', False)]}">
    <tree editable="bottom">
        <!-- Tree view fields -->
    </tree>
</field>
```

**4. Add Helper Text for User Guidance:**
```xml
<div class="alert alert-info" attrs="{'invisible': [('id', '!=', False)]}">
    <strong>Save Required:</strong> Please save this record before adding lines.
</div>
```

#### ✅ Complete Example
```xml
<form string="Parent Record">
    <header>
        <button name="action_save_record" type="object" string="Save"
                class="oe_highlight"
                attrs="{'invisible': [('id', '!=', False)]}"/>
        <field name="state" widget="statusbar"/>
    </header>
    <sheet>
        <group>
            <field name="name"/>
            <field name="date"/>
        </group>

        <div class="alert alert-info" attrs="{'invisible': [('id', '!=', False)]}">
            <strong>Save Required:</strong> Please save this record before adding lines.
        </div>

        <notebook>
            <page string="Lines">
                <field name="line_ids"
                       context="{'default_parent_id': id}"
                       attrs="{'readonly': [('id', '=', False)]}">
                    <tree editable="bottom">
                        <field name="description"/>
                        <field name="amount"/>
                    </tree>
                </field>
            </page>
        </notebook>
    </sheet>
</form>
```

#### Key Benefits
- **Data Integrity**: Ensures parent record exists before creating child records
- **User Experience**: Clear guidance on required actions
- **Error Prevention**: Avoids "record not found" errors when adding lines
- **Standard Pattern**: Follows Odoo's recommended approach for parent-child relationships

#### When to Use
- **One2many fields** where child records reference parent ID
- **Complex forms** with multiple related record types
- **Workflow-dependent records** where parent state affects child creation
- **Any scenario** where unsaved parent records cause child record issues

## XML and Data Files

- In XML data files, use noupdate="0" for master data to ensure changes are picked up when updating modules
- Use noupdate="1" for initial values that should not be overwritten on module update
- Use format_html() with _get_html_link() helper to create clickable record links in chatter messages

### Binary Field Widget Usage

**Binary fields with `attachment=True` do NOT need explicit `widget="binary"` in form views.**

Odoo automatically applies the correct widget based on the field type. Explicitly specifying `widget="binary"` is redundant and can be omitted.

#### ✅ Correct Pattern (Odoo Standard)

```python
# Model definition
class DocumentVersion(models.Model):
    attachment_datas = fields.Binary(
        string='File',
        attachment=True  # Stores in ir.attachment
    )
    attachment_name = fields.Char('Filename')
```

```xml
<!-- Form view - NO widget attribute needed -->
<field name="attachment_datas" filename="attachment_name"/>
```

#### ❌ Redundant Pattern (Works but unnecessary)

```xml
<!-- Form view - widget="binary" is redundant -->
<field name="attachment_datas" widget="binary" filename="attachment_name"/>
```

#### Reference from Odoo Core

From `/usr/lib/python3/dist-packages/odoo/addons/base/views/ir_attachment_views.xml`:
```xml
<field name="datas" nolabel="1" class="w-100" filename="name" invisible="type == 'url'"/>
```

The `datas` field in `ir.attachment` is a Binary field, and Odoo's standard view does NOT use `widget="binary"`.

#### When to Use `widget="binary"`

The `widget="binary"` attribute is only needed in **list views** when you want to display binary fields in a specific way:

```xml
<!-- List view - widget may be needed for specific display -->
<list>
    <field name="datas" widget="binary" filename="name" string="File"/>
</list>
```

However, for **form views**, omit the widget attribute and let Odoo handle it automatically.

#### Applies To

- **Odoo 15.0+**: All modern Odoo versions
- **Binary fields with `attachment=True`**: Standard file upload fields
- **Form views**: Widget is automatically applied
- **List views**: Widget may be specified for custom display behavior

### One2many List View Field Loading (CRITICAL)

**⚠️ Fields Referenced in Button Attributes Must Be Loaded in List View**

When using buttons in one2many list views with `invisible`, `readonly`, or other attributes that reference fields, those fields **MUST be included in the list view** or they will cause data save failures and UI interference.

#### ❌ Problematic Pattern (Causes Binary Field Save Failure)

```xml
<field name="version_ids">
    <list>
        <field name="issue_date"/>
        <field name="expiry_date"/>
        <field name="state"/>
        <!-- ❌ attachment_datas NOT in list but referenced by button -->
        <button name="action_download" type="object" string="Download"
                icon="fa-download"
                invisible="not attachment_datas"/>  <!-- ❌ Field not loaded! -->
    </list>
</field>
```

**Symptoms:**
- Binary fields fail to save when editing records through popup forms
- Only text fields are saved, binary data is lost
- Logs show binary field missing from `write()` vals despite being uploaded in UI
- Extra RPC calls or field loading issues during invisible evaluation
- Interference with form opening/saving process

#### ✅ Correct Pattern (Field Loaded but Hidden)

```xml
<field name="version_ids">
    <list>
        <field name="issue_date"/>
        <field name="expiry_date"/>
        <field name="attachment_datas" column_invisible="1"/>  <!-- ✅ REQUIRED -->
        <field name="state"/>
        <button name="action_download" type="object" string="Download"
                icon="fa-download"
                invisible="not attachment_datas"/>  <!-- ✅ Field is loaded -->
    </list>
</field>
```

**Key Points:**
- Use `column_invisible="1"` to hide the field from display while keeping it loaded
- This ensures the field is available for attribute evaluation
- Prevents interference with form dialog opening and saving
- Binary fields will save correctly when editing through popup forms

#### Applies To

- **Odoo 15.0+**: All modern Odoo versions
- **All field types**: Binary, Many2one, Boolean, Char, etc.
- **All attributes**: `invisible`, `readonly`, `required`, `attrs`
- **All button types**: `type="object"`, `type="action"`

#### Technical Explanation

When a button's attribute references a field (e.g., `invisible="not attachment_datas"`):
1. Odoo needs to evaluate that field's value to determine button visibility
2. If the field is not in the list view, Odoo attempts to load it dynamically
3. This dynamic loading can interfere with form dialog operations
4. Binary field uploads in popup forms fail to save because the field loading mechanism conflicts with the save process
5. The `write()` operation receives incomplete `vals` dictionary missing the binary field data

#### Related Issues

- Binary fields not saving in one2many popup forms
- Button visibility not updating correctly
- "Field not found" errors in browser console
- Unexpected RPC calls when opening records
- Form dialog save operations failing silently

### Chatter Implementation

- **Odoo 15.0**: Use the traditional `<div class="oe_chatter">` structure with individual field widgets
- **Odoo 17.0**: Use the complex div structure with individual field widgets
- **Odoo 18.0**: Use the simple `<chatter/>` tag instead of the old `<div class="oe_chatter">` structure

```xml
<!-- Odoo 15.0 and 17.0 - Traditional Structure -->
</sheet>
<div class="oe_chatter">
    <field name="message_follower_ids" widget="mail_followers"/>
    <field name="activity_ids" widget="mail_activity"/>
    <field name="message_ids" widget="mail_thread"/>
</div>
</form>

<!-- Odoo 18.0 - Simplified -->
</sheet>
<chatter/>
</form>
```

The new `<chatter/>` tag (Odoo 18.0+) automatically provides all chatter functionality including message followers, activities, message thread, attachments, and email integration.

## Module Structure and Assets

- All new modules should include a module icon at `static/description/icon.png`
- If no specific icon is requested, use the standard icon from `docs/module_icon.png`
- Create the `static/description/` directory structure for each new module
- Module icons help with visual identification in the Odoo Apps interface

## Odoo 15.0 Specifics

- Use 'attrs' attribute for conditional field visibility, readonly, and required states
- Field widget registration uses field_registry.add() instead of registry.category()
- OWL components use older syntax with different import patterns
- Models should use @api.model_create_multi with create(vals_list) as the standard approach (available in Odoo 15.0+)
- Use traditional JavaScript patterns for field widgets extending basic_fields
- In XML views, use invisible="1" or attrs="{'invisible': [...]}" for conditional visibility
- Use traditional jQuery and widget patterns for custom field implementations
- Asset management uses older patterns without the new 'assets' key structure
- QWeb templates are loaded differently in Odoo 15
- Field widgets extend from web.basic_fields classes with traditional inheritance

## Odoo 17.0 Specifics

- Replace 'attrs' and 'states' attributes with invisible, readonly, etc. with conditions inside them
- The field fiscalyear_lock_date in res.company model has been renamed to period_lock_date
- Hook functions use 'env' parameter instead of 'cr' and 'registry' parameters
- Models should override create_multi instead of create to avoid deprecation warnings
- Custom models with mail thread functionality must implement '_get_thread_with_access' method
- In OWL templates, use t-props syntax instead of curly braces which cause compilation errors
- Prefer using nextTick from @odoo/owl instead of setTimeout for deferred operations
- Fields with ir.model as comodel cannot use ondelete='restrict' mode

## Odoo 18.0 Specifics

- Use <list> views instead of deprecated <tree> views
- Replace 'attrs' and 'states' attributes with invisible, readonly, etc. with conditions inside them
- The field period_lock_date in res.company model has been renamed to hard_lock_date
- Hook functions use 'env' parameter instead of 'cr' and 'registry' parameters
- Models should override create_multi instead of create to avoid deprecation warnings
- Custom models with mail thread functionality must implement '_get_thread_with_access' method
- In OWL templates, use t-props syntax instead of curly braces which cause compilation errors
- Prefer using nextTick from @odoo/owl instead of setTimeout for deferred operations
- Fields with ir.model as comodel cannot use ondelete='restrict' mode
- JavaScript files should use the `.esm.js` extension for ES modules
- Some fields in res.company model have been removed: account_journal_payment_debit_account_id, account_journal_payment_credit_account_id

## Invoice-Payment Relations

### Getting Payments for Invoices

- **Use Odoo's built-in methods**: Always use `invoice._get_reconciled_payments()` to get payments for an invoice
- **Avoid manual reconciliation searches**: Do not manually search through `account.partial.reconcile` records
- **Never search computed fields**: Fields like `reconciled_invoice_ids` are computed and cannot be used in search domains
- **Payment states to consider**: When checking for payments, consider these states:
  - `'paid'` - Fully paid invoices
  - `'partial'` - Partially paid invoices
  - `'in_payment'` - Invoices currently being paid
- **Example usage**:
  ```python
  # Correct way to get payments for an invoice
  payments = invoice._get_reconciled_payments()

  # Check if invoice has any payments
  if invoice.payment_state in ['paid', 'partial', 'in_payment']:
      # Process payments
      pass
  ```

### Invoice-Payment Relationship Methods

- `invoice._get_reconciled_payments()` - Returns all payments reconciled with the invoice
- `invoice._get_reconciled_amls()` - Returns all reconciled account move lines
- `invoice._get_reconciled_invoices()` - Returns reconciled invoices (for payments)
- `payment.reconciled_invoice_ids` - Computed field showing reconciled invoices (read-only)

## General Best Practices

- When fixing issues, focus on addressing the root cause rather than implementing workarounds
- User prefers minimalistic, clean code with no unnecessary complexity
- Demo examples should demonstrate actual usage of modules without special tweaks
- User prefers concise code implementations, specifically wanting JavaScript files to be less than 100 lines when possible
- When implementing Odoo features, check the local codebase for valid examples to follow for consistency

## Module Versioning

### Version Format for Odoo 15.0

All modules should follow the standard Odoo version format:

```
'version': '15.0.x.x.x'
```

Where:
- `15.0` - Odoo major version
- `x.x.x` - Module version in semantic versioning format (major.minor.patch)

Examples:
- `'version': '15.0.1.0.0'` - First release of the module
- `'version': '15.0.1.1.0'` - Minor feature addition
- `'version': '15.0.1.0.1'` - Bug fix release
- `'version': '15.0.2.0.0'` - Major feature update with breaking changes

### Version Format for Odoo 17.0

All modules should follow the standard Odoo version format:

```
'version': '17.0.x.x.x'
```

Where:
- `17.0` - Odoo major version
- `x.x.x` - Module version in semantic versioning format (major.minor.patch)

Examples:
- `'version': '17.0.1.0.0'` - First release of the module
- `'version': '17.0.1.1.0'` - Minor feature addition
- `'version': '17.0.1.0.1'` - Bug fix release
- `'version': '17.0.2.0.0'` - Major feature update with breaking changes

### Version Format for Odoo 18.0

All modules should follow the standard Odoo version format:

```
'version': '18.0.x.x.x'
```

Where:
- `18.0` - Odoo major version
- `x.x.x` - Module version in semantic versioning format (major.minor.patch)

Examples:
- `'version': '18.0.1.0.0'` - First release of the module
- `'version': '18.0.1.1.0'` - Minor feature addition
- `'version': '18.0.1.0.1'` - Bug fix release
- `'version': '18.0.2.0.0'` - Major feature update with breaking changes

This format ensures compatibility tracking and proper module management within the Odoo ecosystem.

## Report Generation and PDF Rendering

### Portal-Style Report Generation

When generating PDF reports programmatically (e.g., in controllers or API endpoints), always follow Odoo's portal pattern for consistent formatting and proper company context:

```python
# Correct approach - matches portal behavior
ReportAction = request.env['ir.actions.report'].sudo()

# CRITICAL: Set company context for proper formatting
if hasattr(record, 'company_id'):
    ReportAction = ReportAction.with_company(record.company_id)

# Use simple data parameter like portal does
pdf_content, _ = ReportAction._render_qweb_pdf(
    'module.report_action_name',
    [record.id],
    data={'report_type': 'pdf'}
)
```

### Key Principles

1. **Company Context is Critical**: Always use `.with_company(record.company_id)` to ensure:
   - Proper paper format settings
   - Company-specific margins and layout
   - Correct CSS/styling rules
   - Consistent formatting with UI portal

2. **Simple Data Parameter**: Use `data={'report_type': 'pdf'}` instead of complex parameters
   - Avoid custom paperformat assignments
   - Don't override wkhtmltopdf parameters unless absolutely necessary
   - Let the company's report configuration handle formatting

3. **Report Reference Validation**:
   - Use correct report XML IDs (e.g., `'sale.action_report_saleorder'`)
   - Check if modules like `sale_pdf_quote_builder` modify standard reports
   - Verify report exists before calling `_render_qweb_pdf`

### Common Pitfalls to Avoid

❌ **Don't do this:**
```python
# Wrong - missing company context
pdf_content = request.env['ir.actions.report']._render_qweb_pdf(
    'sale.action_report_saleorder', [order_id]
)

# Wrong - complex data parameters
data = {
    'paperformat_id': some_format.id,
    'disable_smart_shrinking': True,
    'custom_margins': {...}
}
```

✅ **Do this instead:**
```python
# Correct - follows portal pattern
ReportAction = request.env['ir.actions.report'].sudo()
if hasattr(order, 'company_id'):
    ReportAction = ReportAction.with_company(order.company_id)

pdf_content, _ = ReportAction._render_qweb_pdf(
    'sale.action_report_saleorder',
    [order.id],
    data={'report_type': 'pdf'}
)
```

### Report Module Interactions

When working with report-modifying modules (e.g., `sale_pdf_quote_builder`):

1. **Check module modifications**: Some modules hijack standard reports and create new "clean" versions
2. **Use appropriate report reference**:
   - `sale.action_report_saleorder` might be modified to include prefix/suffix pages
   - `sale_pdf_quote_builder.action_report_saleorder_raw` might be the clean version
3. **Test both UI and API**: Ensure API generates identical output to portal UI

### Reference Implementation

Based on Odoo's portal controller (`/usr/lib/python3/dist-packages/odoo/addons/portal/controllers/portal.py`):

```python
def _show_report(self, model, report_type, report_ref, download=False):
    ReportAction = request.env['ir.actions.report'].sudo()

    if hasattr(model, 'company_id'):
        if len(model.company_id) > 1:
            raise UserError(_('Multi company reports are not supported.'))
        ReportAction = ReportAction.with_company(model.company_id)

    method_name = '_render_qweb_%s' % (report_type)
    report = getattr(ReportAction, method_name)(
        report_ref,
        list(model.ids),
        data={'report_type': report_type}
    )[0]

    return request.make_response(report, headers=headers)
```

This pattern ensures your API-generated PDFs match the portal UI exactly, preventing formatting issues, content overlap, and inconsistent layouts.

### Custom Paper Formats for Custom Reports

For **custom reports only** (not standard Odoo reports), you may define custom paper formats when specific formatting requirements are needed:

```xml
<!-- Custom paper format definition -->
<record id="paperformat_custom_report" model="report.paperformat">
    <field name="name">Custom Report Format</field>
    <field name="default" eval="False"/>
    <field name="format">A4</field>
    <field name="page_height">0</field>
    <field name="page_width">0</field>
    <field name="orientation">Portrait</field>
    <field name="margin_top">35</field>
    <field name="margin_bottom">20</field>
    <field name="margin_left">10</field>
    <field name="margin_right">10</field>
    <field name="header_line" eval="False"/>
    <field name="header_spacing">20</field>
    <field name="dpi">90</field>
</record>

<!-- Custom report with paper format -->
<record id="action_custom_report" model="ir.actions.report">
    <field name="name">Custom Report</field>
    <field name="model">custom.model</field>
    <field name="report_type">qweb-pdf</field>
    <field name="report_name">module.custom_report_template</field>
    <field name="report_file">module.custom_report_template</field>
    <field name="paperformat_id" ref="paperformat_custom_report"/>
    <field name="binding_model_id" ref="model_custom_model"/>
    <field name="binding_type">report</field>
</record>
```

#### When to Use Custom Paper Formats

✅ **Acceptable for custom reports:**
- Specialized business documents (certificates, labels, forms)
- Reports with unique layout requirements
- Integration with external systems requiring specific formats
- Custom modules with non-standard document types

❌ **Never modify standard reports:**
- Sale orders, invoices, purchase orders
- Standard Odoo business documents
- Reports that users expect to follow company settings

#### Custom Paper Format Guidelines

1. **Always set `default="False"`** - Never make custom formats the system default
2. **Use descriptive names** - Include module/purpose in the format name
3. **Test thoroughly** - Verify formatting across different content lengths
4. **Document requirements** - Explain why custom format is needed
5. **Consider company settings** - Allow companies to override if appropriate

#### Advanced Custom Parameters

For complex formatting needs, you can use wkhtmltopdf parameters:

```xml
<!-- Paper format with custom wkhtmltopdf parameters -->
<record id="paperformat_advanced_custom" model="report.paperformat">
    <field name="name">Advanced Custom Format</field>
    <field name="format">custom</field>
    <field name="page_height">297</field>
    <field name="page_width">210</field>
    <field name="margin_top">12</field>
    <field name="margin_bottom">8</field>
    <field name="margin_left">5</field>
    <field name="margin_right">5</field>
    <field name="dpi">110</field>
    <!-- Custom parameters for special requirements -->
    <field name="custom_params" eval="[
        (0, 0, {'name': '--disable-smart-shrinking'}),
        (0, 0, {'name': '--print-media-type'}),
    ]"/>
</record>
```

**Note**: Custom parameters require the `report_wkhtmltopdf_param` module.

#### Programmatic Usage with Custom Formats

When using custom reports programmatically, still follow the portal pattern but the custom paperformat will be automatically applied:

```python
# Custom report will use its assigned paperformat automatically
ReportAction = request.env['ir.actions.report'].sudo()
if hasattr(record, 'company_id'):
    ReportAction = ReportAction.with_company(record.company_id)

pdf_content, _ = ReportAction._render_qweb_pdf(
    'module.action_custom_report',  # Custom report with paperformat
    [record.id],
    data={'report_type': 'pdf'}
)
```

The custom paperformat defined in the report XML will be used automatically, while still maintaining proper company context for other settings.
