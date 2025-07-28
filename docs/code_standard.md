# Odoo Development Standards

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

## Naming Conventions

- State-tracking fields should follow the standard naming convention of 'state'
- Avoid using 'default_' prefix for field names as it is reserved for Odoo internals
- Use clear, descriptive names for methods and variables

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

## XML and Data Files

- In XML data files, use noupdate="0" for master data to ensure changes are picked up when updating modules
- Use noupdate="1" for initial values that should not be overwritten on module update
- Use format_html() with _get_html_link() helper to create clickable record links in chatter messages

## Module Structure and Assets

- All new modules should include a module icon at `static/description/icon.png`
- If no specific icon is requested, use the standard icon from `docs/module_icon.png`
- Create the `static/description/` directory structure for each new module
- Module icons help with visual identification in the Odoo Apps interface

## Odoo 17.0 Specifics

- Replace 'attrs' and 'states' attributes with invisible, readonly, etc. with conditions inside them
- The field fiscalyear_lock_date in res.company model has been renamed to period_lock_date
- Hook functions use 'env' parameter instead of 'cr' and 'registry' parameters
- Models should override create_multi instead of create to avoid deprecation warnings
- Custom models with mail thread functionality must implement '_get_thread_with_access' method
- In OWL templates, use t-props syntax instead of curly braces which cause compilation errors
- Prefer using nextTick from @odoo/owl instead of setTimeout for deferred operations
- Fields with ir.model as comodel cannot use ondelete='restrict' mode

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

This format ensures compatibility tracking and proper module management within the Odoo ecosystem.
