# Odoo Portal & Website Frontend Development Guide

This guide covers frontend development patterns in Odoo, focusing on portal extensions, form creation, validation, and adding new portal areas. All examples follow Odoo's standard patterns found in core modules.

**Scope**: This document covers portal development, form validation, and general website frontend patterns. For website snippet development, see `docs/snippet_javascript_standards.md`.

## Table of Contents

1. [JavaScript Implementation Standards](#javascript-implementation-standards)
2. [CSS Theming and Color Variables](#css-theming-and-color-variables)
3. [Portal Card Standards and Best Practices](#portal-card-standards-and-best-practices)
4. [Extending Existing Portal Forms/Pages/Templates](#extending-existing-portal-formspagstemplates)
5. [Creating New Forms with Validation and Control](#creating-new-forms-with-validation-and-control)
6. [Adding New Areas to User Portal (/my)](#adding-new-areas-to-user-portal-my)
7. [Portal Controller Patterns](#portal-controller-patterns)
8. [Form Validation Patterns](#form-validation-patterns)
9. [Template Inheritance Patterns](#template-inheritance-patterns)
10. [Signature Component Integration](#signature-component-integration)
11. [Internal User Access in Portal Modules](#internal-user-access-in-portal-modules)
12. [Portal URL Generation and PDF Handling](#portal-url-generation-and-pdf-handling)
13. [Portal Translation Issues with Loops](#portal-translation-issues-with-loops)
14. [Odoo Standard: Controller vs Record Rules Architecture](#odoo-standard-controller-vs-record-rules-architecture)

## ⚠️ **CRITICAL: Portal JavaScript Implementation Standards**

### **NO INLINE JAVASCRIPT ALLOWED**

**Rule**: All JavaScript functionality MUST be implemented in external `.js` files. Inline JavaScript in templates is strictly prohibited.

**Note**: This section covers portal and general website JavaScript. For website snippet JavaScript patterns, see `docs/snippet_javascript_standards.md`.

**❌ WRONG - Inline JavaScript:**
```xml
<template id="my_template">
    <script type="text/javascript">
        document.addEventListener("DOMContentLoaded", function() {
            // JavaScript code here - THIS IS FORBIDDEN
        });
    </script>
</template>
```

**✅ CORRECT - External JavaScript:**
```xml
<!-- Template file -->
<template id="my_template">
    <!-- No JavaScript here -->
</template>
```

```javascript
// static/src/js/my_functionality.js
odoo.define('module_name.my_functionality', [], function () {
    'use strict';

    document.addEventListener('DOMContentLoaded', function() {
        // JavaScript code here
    });
});
```

**Reasons for this rule:**
1. **Prevents Conflicts**: Inline scripts can conflict with external JavaScript files
2. **Better Maintainability**: Centralized JavaScript is easier to debug and maintain
3. **Performance**: External files can be cached and minified
4. **Security**: Reduces XSS risks and improves CSP compliance
5. **Testing**: External JavaScript can be properly unit tested

## JavaScript Implementation Standards

### **File Organization**

**Structure your JavaScript files properly:**
```
static/src/js/
├── module_main.js          # Main functionality
├── form_validation.js      # Form-specific features
├── upload_handler.js       # File upload functionality
└── utils.js               # Utility functions
```

### **Asset Declaration**

**Always declare JavaScript files in the manifest:**
```python
'assets': {
    'web.assets_frontend': [
        'module_name/static/src/js/module_main.js',
        'module_name/static/src/js/form_validation.js',
    ],
}
```

### **Asset Bundle Loading Considerations**

**For portal/website pages that may use lazy loading, declare JavaScript in both bundles:**
```python
'assets': {
    'web.assets_frontend': [
        'module_name/static/src/js/portal_functionality.js',
    ],
    'web.assets_frontend_lazy': [
        'module_name/static/src/js/portal_functionality.js',
    ],
}
```

**Key Points:**
- Portal pages may load `web.assets_frontend_lazy` instead of the main frontend bundle
- Declaring in both bundles ensures JavaScript loads regardless of page loading strategy
- This pattern is used by core Odoo modules for portal functionality
- Only duplicate JavaScript files that are essential for portal/website functionality

### **Odoo Module Pattern**

**Use Odoo's module definition pattern with robust initialization:**
```javascript
odoo.define('module_name.functionality_name', [], function () {
    'use strict';

    function initializeFunctionality() {
        // Your code here
    }

    // Robust initialization pattern for lazy-loaded scripts
    function init() {
        initializeFunctionality();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        // DOM is already ready (for lazy-loaded scripts)
        init();
    }

    // Return public API if needed
    return {
        initializeFunctionality: initializeFunctionality
    };
});
```

**Key Points:**
- Use `document.readyState` check for scripts that may load after DOM is ready
- This pattern works with both normal and lazy-loaded asset bundles
- Essential for portal/website functionality that uses `web.assets_frontend_lazy`

### **Event Handling Best Practices**

**Proper event delegation and cleanup:**
```javascript
function initializeEventHandlers() {
    const element = document.getElementById('my-element');
    if (!element) return; // Guard clause for missing elements

    // Add event listeners with proper cleanup
    element.addEventListener('click', handleClick);
    element.addEventListener('change', handleChange);
}

function handleClick(e) {
    e.preventDefault();
    e.stopPropagation();
    // Handle click
}
```

### **Console Logging Standards**

**Use appropriate console methods for different purposes:**
- `console.error()` - For errors and exceptions that need debugging
- `console.warn()` - For warnings about deprecated or problematic usage
- `console.info()` - For important information (sparingly in production)
- Avoid `console.log()` in production code - remove debug logs before deployment

**Example:**
```javascript
if (!uploadArea || !fileInput) {
    console.error("Upload area or file input not found");
    return false;
}
```

### **Common Violations to Avoid**

**❌ Don't use inline event handlers:**
```xml
<!-- WRONG -->
<button onclick="myFunction()">Click me</button>
```

**✅ Use proper event listeners:**
```xml
<!-- CORRECT -->
<button id="my-button">Click me</button>
```

```javascript
// In external JS file
document.getElementById('my-button').addEventListener('click', myFunction);
```

## CSS Theming and Color Variables

### **⚠️ CRITICAL: Odoo CSS Variables Reality Check**

**Important Discovery**: Many commonly assumed CSS variables **DO NOT EXIST** in Odoo 17.0. Always verify against the actual codebase before using CSS variables.

### **CSS Variables That Actually Exist in Odoo 17.0**

**✅ Odoo Website Variables (Available):**
```css
/* These are defined by Odoo website themes and available in website/portal context */
var(--primary)              /* Main primary color (follows website theme) */
var(--secondary)            /* Secondary color */
var(--success)              /* Success color (#28a745) */
var(--danger)               /* Danger/error color (#dc3545) */
var(--warning)              /* Warning color (#ffc107) */
var(--info)                 /* Info color (#17a2b8) */
var(--o-color-1)            /* Same as --primary */
var(--o-color-2)            /* Same as --secondary */
var(--o-color-3)            /* Light background color */
var(--o-color-4)            /* White (#FFFFFF) */
var(--o-color-5)            /* Dark text color */
```

**❌ Variables That DON'T EXIST in Website Context:**
```css
/* These DO NOT EXIST in Odoo website/portal context - DO NOT USE */
var(--bs-primary)           /* ❌ Bootstrap variables not available in website */
var(--bs-primary-rgb)       /* ❌ Bootstrap variables not available in website */
var(--bs-primary-light)     /* ❌ Does not exist */
var(--bs-primary-dark)      /* ❌ Does not exist */
var(--primary-light)        /* ❌ Does not exist */
var(--primary-dark)         /* ❌ Does not exist */
```

### **Correct Theme-Aware CSS Patterns**

**✅ CORRECT - Using Available Website Variables:**
```css
/* Main colors - use Odoo website variables */
.my-element {
    background-color: var(--primary, #875a7b);
    border-color: var(--primary, #875a7b);
}

/* Secondary colors */
.my-secondary-element {
    background-color: var(--secondary, #6c757d);
}

/* Status colors */
.error-message {
    color: var(--danger, #dc3545);
}

.success-message {
    color: var(--success, #28a745);
}

/* For darker/lighter variants, use color-mix() function */
.my-element:hover {
    background-color: color-mix(in srgb, var(--primary, #875a7b) 85%, black);
}

/* For semi-transparent effects */
.my-element-focus {
    box-shadow: 0 0 0 0.2rem color-mix(in srgb, var(--primary, #875a7b) 25%, transparent);
}
```

**❌ WRONG - Using Non-Existent Variables:**
```css
/* DON'T DO THIS - these variables don't exist in website context */
.my-element {
    background-color: var(--bs-primary, #875a7b);           /* ❌ Wrong context */
    border-color: var(--primary-dark, #734c68);             /* ❌ Doesn't exist */
}
```

### **Color Mixing Techniques**

**Use `color-mix()` for theme-aware color variations:**
```css
/* Darker variant (mix with black) */
background-color: color-mix(in srgb, var(--primary, #875a7b) 80%, black);

/* Lighter variant (mix with white) */
background-color: color-mix(in srgb, var(--primary, #875a7b) 80%, white);

/* Semi-transparent (mix with transparent) */
background-color: color-mix(in srgb, var(--primary, #875a7b) 25%, transparent);
```

### **Fallback Strategy**

**Always provide fallback colors:**
```css
/* Good fallback pattern for website/portal context */
.portal-sidebar .list-group-item.active {
    background-color: var(--primary, #875a7b);
    border-color: var(--primary, #875a7b);
}

/* Using Odoo color palette */
.my-card {
    background-color: var(--o-color-3, #f3f2f2);  /* Light background */
    color: var(--o-color-5, #111827);             /* Dark text */
    border: 1px solid var(--o-color-2, #8595a2);  /* Secondary border */
}
```

### **Browser Support Note**

The `color-mix()` function is supported in:
- Chrome 111+
- Firefox 113+
- Safari 16.2+

For older browsers, the fallback color will be used.

### **Verification Method**

**Before using any CSS variable, verify it exists:**

**Method 1: Browser Console (Recommended)**
```javascript
// Test in browser console on any Odoo website page
const rootStyles = getComputedStyle(document.documentElement);
console.log('--primary:', rootStyles.getPropertyValue('--primary'));
console.log('--o-color-1:', rootStyles.getPropertyValue('--o-color-1'));
```

**Method 2: Codebase Search**
```bash
# Check if a CSS variable exists in Odoo's website module
find /usr/lib/python3/dist-packages/odoo/addons/website -name "*.scss" -exec grep -l "primary" {} \;
```

**Method 3: Live Testing**
- Navigate to any Odoo website page
- Open browser developer tools
- Check computed styles on `:root` element
- Look for CSS custom properties starting with `--`

## Portal Card Standards and Best Practices

### 1. Entity Separation Principle

**CRITICAL**: Always treat different business entities as separate portal cards. Do not combine multiple entities into a single card.

#### ❌ Wrong: Single Card for Multiple Entities
```xml
<!-- DON'T DO THIS -->
<template id="portal_my_home_bad" inherit_id="portal.portal_my_home">
    <div id="portal_service_category" position="inside">
        <t t-call="portal.portal_docs_entry">
            <t t-set="title">Applications & Memberships</t>
            <t t-set="url" t-value="'/my/applications' if has_applications else '/my/memberships'"/>
            <t t-set="text">
                <span t-if="has_applications">View applications</span>
                <span t-elif="has_memberships">View memberships</span>
                <span t-else="">Apply now</span>
            </t>
        </t>
    </div>
</template>
```

#### ✅ Correct: Separate Cards for Each Entity
```xml
<!-- DO THIS -->
<template id="portal_my_home_good" inherit_id="portal.portal_my_home">
    <div id="portal_service_category" position="inside">

        <!-- Card 1: Applications (Always visible) -->
        <t t-call="portal.portal_docs_entry">
            <t t-set="title">Applications</t>
            <t t-set="url" t-value="'/my/applications'"/>
            <t t-set="placeholder_count" t-value="'application_count'"/>
            <t t-set="show_count" t-value="True"/>
            <t t-set="text">Manage your applications</t>
        </t>

        <!-- Card 2: Memberships (Conditional) -->
        <t t-set="total_memberships" t-value="request.env['membership.member'].search_count([('user_id', '=', request.env.user.id)])"/>
        <t t-if="total_memberships > 0">
            <t t-call="portal.portal_docs_entry">
                <t t-set="title">Memberships</t>
                <t t-set="url" t-value="'/my/memberships'"/>
                <t t-set="placeholder_count" t-value="'membership_count'"/>
                <t t-set="show_count" t-value="True"/>
                <t t-set="text">View your memberships</t>
            </t>
        </t>

    </div>
</template>
```

### 2. Counter Implementation Standards

#### ✅ Always Include All States in Counters
```python
# controllers/portal.py
def _prepare_home_portal_values(self, counters):
    values = super()._prepare_home_portal_values(counters)

    if 'application_count' in counters:
        # Count ALL applications (draft, under_review, approved, rejected)
        application_count = request.env['membership.application'].search_count([
            ('user_id', '=', request.env.user.id)
        ])
        values['application_count'] = application_count

    return values
```

#### ❌ Don't Exclude States from Counters
```python
# DON'T DO THIS - excludes approved applications
if 'application_count' in counters:
    application_count = request.env['membership.application'].search_count([
        ('user_id', '=', request.env.user.id),
        ('state', 'in', ['draft', 'under_review', 'rejected'])  # Missing 'approved'
    ])
```

#### ✅ Always Display Counters
```python
def _getCountersAlwaysDisplayed(self):
    """Return list of counters that should always be displayed"""
    counters = super()._getCountersAlwaysDisplayed() if hasattr(super(), '_getCountersAlwaysDisplayed') else []
    counters.extend(['application_count', 'membership_count'])
    return counters
```

### 3. Route Logic Standards

#### ✅ Independent Entity Access
```python
@http.route(['/my/applications/<int:application_id>'], type='http', auth="user", website=True)
def portal_my_application(self, application_id=None, **kw):
    """Display application details - independent of membership status"""
    try:
        if application_id:
            application = request.env['membership.application'].browse([application_id])
            # Verify ownership
            if not application.exists() or application.user_id.id != request.env.user.id:
                return request.redirect('/my/applications')
        else:
            # Find most recent application
            application = request.env['membership.application'].search([
                ('user_id', '=', request.env.user.id)
            ], limit=1, order='create_date desc')

            if not application:
                return request.redirect('/membership/apply')

        # Show application regardless of membership status
        return request.render("module.portal_my_application", {'application': application})
```

#### ❌ Don't Block Entity Access Based on Other Entities
```python
# DON'T DO THIS - blocks application access if user has membership
def portal_my_application(self, application_id=None, **kw):
    status_info = self._get_user_membership_status()

    # WRONG: Prevents users with memberships from viewing applications
    if status_info['status'] in ['active_member', 'inactive_member']:
        return request.redirect('/my/membership')
```

### 4. Navigation Standards

#### ✅ Use Standard Portal Breadcrumbs
```xml
<!-- Use portal.portal_record_layout for consistent navigation -->
<template id="portal_my_record" name="My Record">
    <t t-call="portal.portal_layout">
        <t t-call="portal.portal_record_layout">
            <t t-set="card_header">
                <div class="row no-gutters">
                    <div class="col-12">
                        <h5 class="mb-0">Record Title</h5>
                    </div>
                </div>
            </t>
            <t t-set="card_body">
                <!-- Content here -->
            </t>
        </t>
    </t>
</template>

<!-- Extend standard breadcrumbs -->
<template id="portal_breadcrumbs_extend" inherit_id="portal.portal_breadcrumbs">
    <xpath expr="//ol[hasclass('breadcrumb')]" position="inside">
        <li t-if="page_name == 'my_record'" class="breadcrumb-item">
            <a href="/my/records">Records</a>
        </li>
    </xpath>
</template>
```

#### ❌ Don't Create Custom Breadcrumbs
```xml
<!-- DON'T DO THIS - creates duplicate navigation -->
<template id="portal_my_record_bad" name="My Record">
    <t t-call="portal.portal_layout">
        <div class="container">
            <!-- WRONG: Custom breadcrumbs conflict with standard ones -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="/my/home">Home</a></li>
                    <li class="breadcrumb-item"><a href="/my/records">Records</a></li>
                    <li class="breadcrumb-item active">Record Detail</li>
                </ol>
            </nav>
            <!-- Content -->
        </div>
    </t>
</template>
```

### 5. Portal Card Visibility Rules

#### ✅ Applications Card: Always Visible
```xml
<!-- Applications should always be visible, even with 0 count -->
<t t-call="portal.portal_docs_entry">
    <t t-set="title">Applications</t>
    <t t-set="url" t-value="'/my/applications'"/>
    <t t-set="placeholder_count" t-value="'application_count'"/>
    <t t-set="show_count" t-value="True"/>
    <t t-set="text">
        <span t-if="draft_apps">X draft applications</span>
        <span t-elif="review_apps">X under review</span>
        <span t-elif="approved_apps">X approved applications</span>
        <span t-elif="rejected_apps">X rejected applications</span>
        <span t-else="">Apply for membership</span>
    </t>
</t>
```

#### ✅ Entity Records Card: Conditional Visibility
```xml
<!-- Memberships only visible if user has/had memberships -->
<t t-set="total_memberships" t-value="request.env['membership.member'].search_count([('user_id', '=', request.env.user.id)])"/>
<t t-if="total_memberships > 0">
    <t t-call="portal.portal_docs_entry">
        <t t-set="title">Memberships</t>
        <t t-set="url" t-value="'/my/memberships'"/>
        <t t-set="placeholder_count" t-value="'membership_count'"/>
        <t t-set="show_count" t-value="True"/>
        <t t-set="text">View your memberships</t>
    </t>
</t>
```

### 6. JavaScript Error Prevention

#### ✅ Proper Portal Counter Handling
```python
# Always check for counters in the list
def _prepare_home_portal_values(self, counters):
    values = super()._prepare_home_portal_values(counters)

    if 'application_count' in counters:
        values['application_count'] = request.env['model'].search_count(domain)

    return values
```

#### ✅ Enable Portal Service Category
```xml
<template id="portal_my_home_extend" inherit_id="portal.portal_my_home">
    <!-- REQUIRED: Enable service category -->
    <xpath expr="//div[hasclass('o_portal_docs')]" position="before">
        <t t-set="portal_service_category_enable" t-value="True"/>
    </xpath>

    <div id="portal_service_category" position="inside">
        <t t-call="portal.portal_docs_entry">
            <t t-set="show_count" t-value="True"/>
            <!-- Other attributes -->
        </t>
    </div>
</template>
```

### 7. Common Pitfalls to Avoid

#### ❌ Pitfall 1: Conflating Entities
- **Problem**: Mixing applications and memberships in one card
- **Solution**: Create separate cards for each business entity

#### ❌ Pitfall 2: Incomplete Counters
- **Problem**: Excluding certain states from counters (e.g., approved applications)
- **Solution**: Always count ALL records for complete visibility

#### ❌ Pitfall 3: Blocking Entity Access
- **Problem**: Preventing users from viewing applications if they have memberships
- **Solution**: Allow independent access to all entities

#### ❌ Pitfall 4: Duplicate Navigation
- **Problem**: Creating custom breadcrumbs alongside standard portal breadcrumbs
- **Solution**: Use only standard portal breadcrumb extensions

#### ❌ Pitfall 5: JavaScript Counter Errors
- **Problem**: Portal JavaScript fails when counter elements are null
- **Solution**: Always use `show_count="True"` and proper counter checking

### 8. Portal Card Sizing and Icon Standards

#### ✅ Standard Icon Dimensions
Portal card icons must follow Odoo's standard sizing:

- **Standard Size**: 64×64 pixels (same as Odoo core portal icons)
- **Format**: SVG preferred for scalability and consistency
- **Color Scheme**: Use `#6c757d` for main elements, `#f8f9fa` for backgrounds, `#dee2e6` for borders

```xml
<!-- Example: Standard 64x64 SVG icon -->
<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Background circle for consistency -->
  <circle cx="32" cy="32" r="30" fill="#f8f9fa" stroke="#dee2e6" stroke-width="2"/>

  <!-- Main icon content -->
  <path d="..." fill="#6c757d" stroke="#495057" stroke-width="1.5"/>
</svg>
```

#### ✅ Card Width Control
Portal cards support different width configurations:

**Full Width Cards (Default)**:
```xml
<t t-call="portal.portal_docs_entry">
    <t t-set="title">My Records</t>
    <!-- Results in: col-12 (full width) -->
</t>
```

**Half Width Cards (Config Cards)**:
```xml
<t t-call="portal.portal_docs_entry">
    <t t-set="title">Connection & Security</t>
    <t t-set="config_card" t-value="True"/>
    <!-- Results in: col-md-6 (half width on medium+ screens) -->
</t>
```

#### ❌ Common Icon Issues
- **Wrong Size**: Using 24×24 or 512×512 instead of 64×64 causes spacing issues
- **Wrong Format**: PNG icons may render inconsistently compared to SVG
- **Wrong Colors**: Using custom colors breaks visual consistency

#### ✅ Icon Size Verification
Check existing Odoo core icons for reference:
```bash
# Check Odoo core portal icon dimensions
head -5 /usr/lib/python3/dist-packages/odoo/addons/portal/static/src/img/portal-connection.svg
# Should show: <svg width="64" height="64" viewBox="0 0 64 64"...
```

### 9. Portal Card Checklist

Before implementing portal cards, verify:

- [ ] **Entity Separation**: Each business entity has its own card
- [ ] **Complete Counters**: All record states are included in counts
- [ ] **Independent Access**: Users can access entities regardless of other entity states
- [ ] **Standard Navigation**: Using portal breadcrumb extensions, not custom breadcrumbs
- [ ] **Proper Visibility**: Applications always visible, records conditional
- [ ] **JavaScript Safety**: Counters properly handled with `show_count="True"`
- [ ] **Service Category**: `portal_service_category_enable` is set to True
- [ ] **Always Displayed**: Counters added to `_getCountersAlwaysDisplayed()`
- [ ] **Icon Standards**: 64×64 SVG icons with standard Odoo colors
- [ ] **Card Width**: Use `config_card="True"` for half-width cards when appropriate

## Extending Existing Portal Forms/Pages/Templates

### 1. Extending Portal Templates

Use template inheritance to extend existing portal templates. Follow Odoo's xpath patterns:

```xml
<!-- views/portal_templates.xml -->
<odoo>
    <template id="portal_my_home_extend" name="Portal My Home Extension" inherit_id="portal.portal_my_home">
        <!-- Add new section to portal home -->
        <xpath expr="//div[hasclass('o_portal_docs')]" position="inside">
            <t t-call="your_module.portal_docs_entry">
                <t t-set="title">My Custom Area</t>
                <t t-set="url">/my/custom</t>
                <t t-set="placeholder_count">custom_count</t>
            </t>
        </xpath>
    </template>

    <!-- Extend specific portal page -->
    <template id="portal_my_invoices_extend" name="Portal Invoices Extension" inherit_id="account.portal_my_invoices">
        <!-- Add custom filters -->
        <xpath expr="//div[hasclass('o_portal_search_panel')]" position="inside">
            <div class="form-group">
                <label for="custom_filter">Custom Filter</label>
                <select name="custom_filter" class="form-control">
                    <option value="">All</option>
                    <option value="custom">Custom Value</option>
                </select>
            </div>
        </xpath>
    </template>
</odoo>
```

### 2. Extending Portal Forms

Extend existing portal forms by inheriting the template and adding new fields:

```xml
<!-- Extend partner details form -->
<template id="portal_my_details_extend" name="Portal Details Extension" inherit_id="portal.portal_my_details">
    <xpath expr="//div[@class='row']//div[last()]" position="after">
        <div class="col-lg-6">
            <div class="form-group">
                <label for="custom_field">Custom Field</label>
                <input type="text" name="custom_field" class="form-control"
                       t-att-value="partner.custom_field or ''" required=""/>
            </div>
        </div>
    </xpath>
</template>
```

### 3. Extending Portal Controllers

Extend portal controllers to handle additional data and validation:

```python
# controllers/portal.py
from odoo import http, _
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal
from odoo.exceptions import ValidationError

class CustomPortal(CustomerPortal):

    @http.route()
    def account(self, redirect=None, **post):
        """Extend account method to handle custom fields"""
        response = super().account(redirect=redirect, **post)

        if post and request.httprequest.method == 'POST':
            # Handle custom field validation
            if 'custom_field' in post:
                self._validate_custom_field(post['custom_field'])
                # Update partner with custom field
                request.env.user.partner_id.sudo().write({
                    'custom_field': post['custom_field']
                })

        return response

    def _validate_custom_field(self, value):
        """Custom validation for custom field"""
        if not value or len(value) < 3:
            raise ValidationError(_("Custom field must be at least 3 characters"))
```

## Creating New Forms with Validation and Control

### 1. Frontend Form with Validation

Create a complete form with frontend and backend validation:

```xml
<!-- views/portal_templates.xml -->
<template id="portal_custom_form" name="Custom Form">
    <t t-call="website.layout">
        <div class="o_portal">
            <div class="container py-5">
                <div class="row">
                    <div class="col-lg-8 offset-lg-2">
                        <h1>Custom Form</h1>

                        <!-- Display errors -->
                        <div t-if="error_message" class="alert alert-danger">
                            <t t-out="error_message"/>
                        </div>

                        <!-- Display success -->
                        <div t-if="success_message" class="alert alert-success">
                            <t t-out="success_message"/>
                        </div>

                        <form method="post" enctype="multipart/form-data" class="needs-validation" novalidate="">
                            <input type="hidden" name="csrf_token" t-att-value="request.csrf_token()"/>

                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="name" class="form-label">Name *</label>
                                        <input type="text" name="name" id="name" class="form-control"
                                               t-att-value="form_data.get('name', '')" required=""/>
                                        <div class="invalid-feedback">
                                            Please provide a valid name.
                                        </div>
                                    </div>
                                </div>

                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="email" class="form-label">Email *</label>
                                        <input type="email" name="email" id="email" class="form-control"
                                               t-att-value="form_data.get('email', '')" required=""/>
                                        <div class="invalid-feedback">
                                            Please provide a valid email.
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="description" class="form-label">Description</label>
                                <textarea name="description" id="description" class="form-control" rows="4">
                                    <t t-out="form_data.get('description', '')"/>
                                </textarea>
                            </div>

                            <div class="form-group">
                                <label for="attachment" class="form-label">Attachment</label>
                                <input type="file" name="attachment" id="attachment" class="form-control"
                                       accept=".pdf,.doc,.docx,.jpg,.png"/>
                            </div>

                            <div class="form-group">
                                <label for="category" class="form-label">Category *</label>
                                <select name="category" id="category" class="form-control" required="">
                                    <option value="">Select Category</option>
                                    <t t-foreach="categories" t-as="category">
                                        <option t-att-value="category.id"
                                                t-att-selected="form_data.get('category') == str(category.id)">
                                            <t t-out="category.name"/>
                                        </option>
                                    </t>
                                </select>
                                <div class="invalid-feedback">
                                    Please select a category.
                                </div>
                            </div>

                            <div class="form-check">
                                <input type="checkbox" name="terms" id="terms" class="form-check-input"
                                       value="1" required=""/>
                                <label for="terms" class="form-check-label">
                                    I agree to the <a href="/terms" target="_blank">terms and conditions</a> *
                                </label>
                                <div class="invalid-feedback">
                                    You must agree to the terms and conditions.
                                </div>
                            </div>

                            <div class="form-group mt-4">
                                <button type="submit" class="btn btn-primary">Submit</button>
                                <a href="/my" class="btn btn-secondary">Cancel</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </t>
</template>
```

### 2. Controller with Form Processing

```python
# controllers/portal.py
import base64
import logging
from odoo import http, _
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal
from odoo.exceptions import ValidationError, UserError

_logger = logging.getLogger(__name__)

class CustomFormPortal(CustomerPortal):

    @http.route(['/my/custom-form'], type='http', auth='user', website=True)
    def custom_form(self, **kw):
        """Display custom form"""
        values = self._prepare_custom_form_values(**kw)

        if request.httprequest.method == 'POST':
            return self._process_custom_form(**kw)

        return request.render("your_module.portal_custom_form", values)

    def _prepare_custom_form_values(self, **kw):
        """Prepare values for custom form"""
        values = {
            'categories': request.env['your.category'].search([]),
            'form_data': kw,
            'page_name': 'custom_form',
        }
        return values

    def _process_custom_form(self, **post):
        """Process custom form submission"""
        try:
            # Validate form data
            self._validate_custom_form(post)

            # Process file upload
            attachment_data = None
            if post.get('attachment'):
                attachment_data = self._process_file_upload(post['attachment'])

            # Create record
            record_data = {
                'name': post.get('name'),
                'email': post.get('email'),
                'description': post.get('description'),
                'category_id': int(post.get('category')),
                'partner_id': request.env.user.partner_id.id,
            }

            record = request.env['your.model'].create(record_data)

            # Attach file if uploaded
            if attachment_data:
                request.env['ir.attachment'].create({
                    'name': attachment_data['filename'],
                    'datas': attachment_data['content'],
                    'res_model': 'your.model',
                    'res_id': record.id,
                })

            # Success message
            values = self._prepare_custom_form_values()
            values.update({
                'success_message': _('Form submitted successfully!'),
                'form_data': {},  # Clear form
            })

            return request.render("your_module.portal_custom_form", values)

        except ValidationError as e:
            values = self._prepare_custom_form_values(**post)
            values['error_message'] = str(e)
            return request.render("your_module.portal_custom_form", values)

        except Exception as e:
            _logger.error("Error processing custom form: %s", e)
            values = self._prepare_custom_form_values(**post)
            values['error_message'] = _('An error occurred. Please try again.')
            return request.render("your_module.portal_custom_form", values)

    def _validate_custom_form(self, post):
        """Validate custom form data"""
        errors = []

        # Required fields validation
        if not post.get('name'):
            errors.append(_('Name is required'))
        elif len(post.get('name', '')) < 3:
            errors.append(_('Name must be at least 3 characters'))

        if not post.get('email'):
            errors.append(_('Email is required'))
        elif '@' not in post.get('email', ''):
            errors.append(_('Please provide a valid email'))

        if not post.get('category'):
            errors.append(_('Category is required'))

        if not post.get('terms'):
            errors.append(_('You must agree to the terms and conditions'))

        # Custom business logic validation
        if post.get('email'):
            existing = request.env['your.model'].search([
                ('email', '=', post.get('email'))
            ])
            if existing:
                errors.append(_('Email already exists'))

        if errors:
            raise ValidationError('\n'.join(errors))

    def _process_file_upload(self, file_upload):
        """Process file upload with validation"""
        if not file_upload:
            return None

        # Validate file size (5MB limit)
        max_size = 5 * 1024 * 1024  # 5MB
        if len(file_upload.read()) > max_size:
            file_upload.seek(0)  # Reset file pointer
            raise ValidationError(_('File size must be less than 5MB'))

        file_upload.seek(0)  # Reset file pointer

        # Validate file type
        allowed_extensions = ['.pdf', '.doc', '.docx', '.jpg', '.png']
        filename = file_upload.filename
        if not any(filename.lower().endswith(ext) for ext in allowed_extensions):
            raise ValidationError(_('File type not allowed'))

        # Read and encode file content
        content = base64.b64encode(file_upload.read())

        return {
            'filename': filename,
            'content': content,
        }
```

### 3. Mobile Camera Access for File Uploads

#### **Enabling Camera Access on Mobile Devices**

For image file uploads, enable direct camera access on mobile devices by using proper HTML5 attributes:

**✅ CORRECT - Mobile Camera + Gallery Access:**
```xml
<input type="file" class="form-control-file" name="file"
       id="file_field" required="required"
       accept="image/jpeg,image/png" autocomplete="off" />
```

**❌ WRONG - Gallery Only:**
```xml
<input type="file" accept=".jpg,.jpeg,.png" />
```

#### **Mobile Behavior Comparison**

| **Configuration** | **iOS Safari** | **Android Chrome** | **User Experience** |
|-------------------|----------------|-------------------|---------------------|
| `accept=".jpg,.jpeg,.png"` | Photo Library only | Gallery only | ❌ No camera access |
| `accept="image/jpeg,image/png"` | Camera + Photo Library | Camera + Gallery | ✅ Full camera + gallery access |
| `accept="image/*" capture="environment"` | Camera (rear) first | Camera (rear) first | ⚠️ Camera forced, limited choice |

#### **Key Attributes**

- **`accept="image/jpeg,image/png"`**: Use MIME types instead of file extensions for better mobile support
- **No `capture` attribute**: Allows users to choose between camera and gallery (recommended)
- **`capture="environment"`**: Forces rear camera first (limits user choice)
- **`capture="user"`**: Forces front camera first (limits user choice)

#### **Use Cases**

**✅ RECOMMENDED - No `capture` attribute for:**
- General file uploads with flexible user choice
- Artwork/calligraphy submissions (camera OR gallery)
- Document uploads where users may have existing files
- Better overall user experience

**⚠️ Use `capture="environment"` only when:**
- Camera is the primary/only expected input method
- Document scanning apps where camera quality is critical
- Specific workflows requiring fresh captures

**⚠️ Use `capture="user"` only when:**
- Profile pictures where selfies are expected
- Identity verification requiring live capture

#### **JavaScript Validation**

Ensure your JavaScript validation handles camera-captured files properly:

```javascript
// Validate file type (including camera captures)
var validTypes = ['image/jpeg', 'image/png'];
if (!validTypes.includes(file.type)) {
    var extension = file.name.split('.').pop().toLowerCase();
    if (!['jpg', 'jpeg', 'png'].includes(extension)) {
        console.warn('Invalid file type:', file.type);
        alert('Only JPEG and PNG image files are allowed');
        return false;
    }
}
```

#### **Benefits**

- **📱 Better Mobile UX**: Users can choose camera OR gallery based on their needs
- **🔄 Flexible Workflow**: Supports both new captures and existing files
- **📷 User Choice**: Camera available when needed, gallery when files exist
- **⚡ Optimal Experience**: No forced camera opening, respects user preference

### 4. Frontend JavaScript Validation

Add client-side validation for better user experience:

```javascript
// static/src/js/portal_form.js
/** @odoo-module **/

import { Component, onMounted } from "@odoo/owl";

export class PortalFormValidation {
    constructor() {
        this.init();
    }

    init() {
        // Initialize Bootstrap validation
        const forms = document.querySelectorAll('.needs-validation');

        Array.from(forms).forEach(form => {
            form.addEventListener('submit', (event) => {
                if (!form.checkValidity()) {
                    event.preventDefault();
                    event.stopPropagation();
                }

                // Custom validation
                this.validateCustomFields(form);

                form.classList.add('was-validated');
            }, false);
        });

        // Real-time validation
        this.setupRealTimeValidation();
    }

    setupRealTimeValidation() {
        // Email validation
        const emailField = document.getElementById('email');
        if (emailField) {
            emailField.addEventListener('blur', () => {
                this.validateEmail(emailField);
            });
        }

        // File upload validation
        const fileField = document.getElementById('attachment');
        if (fileField) {
            fileField.addEventListener('change', () => {
                this.validateFile(fileField);
            });
        }
    }

    validateEmail(field) {
        const email = field.value;
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (email && !emailRegex.test(email)) {
            field.setCustomValidity('Please enter a valid email address');
        } else {
            field.setCustomValidity('');
        }
    }

    validateFile(field) {
        const file = field.files[0];
        if (!file) return;

        // Check file size (5MB)
        const maxSize = 5 * 1024 * 1024;
        if (file.size > maxSize) {
            field.setCustomValidity('File size must be less than 5MB');
            return;
        }

        // Check file type
        const allowedTypes = [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'image/jpeg',
            'image/png'
        ];

        if (!allowedTypes.includes(file.type)) {
            field.setCustomValidity('File type not allowed');
            return;
        }

        field.setCustomValidity('');
    }

    validateCustomFields(form) {
        // Add any custom validation logic here
        const nameField = form.querySelector('#name');
        if (nameField && nameField.value.length < 3) {
            nameField.setCustomValidity('Name must be at least 3 characters');
        }
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new PortalFormValidation();
});
```

## Adding New Areas to User Portal (/my)

### 1. Extending Portal Home Page

Add new sections to the portal home page by extending the portal layout:

```python
# controllers/portal.py
from odoo import http
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal

class CustomPortalHome(CustomerPortal):

    def _prepare_home_portal_values(self, counters):
        """Add custom counters to portal home"""
        values = super()._prepare_home_portal_values(counters)

        # Add custom counters
        if 'custom_requests_count' in counters:
            values['custom_requests_count'] = request.env['your.model'].search_count([
                ('partner_id', '=', request.env.user.partner_id.id)
            ])

        if 'custom_documents_count' in counters:
            values['custom_documents_count'] = request.env['your.document'].search_count([
                ('partner_id', '=', request.env.user.partner_id.id),
                ('state', '!=', 'cancelled')
            ])

        return values

    @http.route(['/my/custom-requests', '/my/custom-requests/page/<int:page>'],
                type='http', auth="user", website=True)
    def portal_my_custom_requests(self, page=1, date_begin=None, date_end=None,
                                  sortby=None, filterby=None, search=None,
                                  search_in='content', groupby='none', **kw):
        """Display custom requests in portal"""
        values = self._prepare_portal_layout_values()

        # Define searchbar
        searchbar_sortings = {
            'date': {'label': _('Date'), 'order': 'create_date desc'},
            'name': {'label': _('Name'), 'order': 'name'},
            'status': {'label': _('Status'), 'order': 'state'},
        }

        searchbar_filters = {
            'all': {'label': _('All'), 'domain': []},
            'draft': {'label': _('Draft'), 'domain': [('state', '=', 'draft')]},
            'submitted': {'label': _('Submitted'), 'domain': [('state', '=', 'submitted')]},
            'approved': {'label': _('Approved'), 'domain': [('state', '=', 'approved')]},
        }

        searchbar_inputs = {
            'content': {'input': 'content', 'label': _('Search in Content')},
            'name': {'input': 'name', 'label': _('Search in Name')},
        }

        searchbar_groupby = {
            'none': {'input': 'none', 'label': _('None')},
            'status': {'input': 'state', 'label': _('Status')},
            'date': {'input': 'create_date', 'label': _('Date')},
        }

        # Default values
        if not sortby:
            sortby = 'date'
        if not filterby:
            filterby = 'all'

        order = searchbar_sortings[sortby]['order']
        domain = searchbar_filters[filterby]['domain']

        # Add partner domain
        domain += [('partner_id', '=', request.env.user.partner_id.id)]

        # Search
        if search and search_in:
            search_domain = []
            if search_in in ('content', 'all'):
                search_domain = ['|', ('name', 'ilike', search), ('description', 'ilike', search)]
            elif search_in == 'name':
                search_domain = [('name', 'ilike', search)]
            domain += search_domain

        # Date filter
        if date_begin and date_end:
            domain += [('create_date', '>', date_begin), ('create_date', '<=', date_end)]

        # Count records
        request_count = request.env['your.model'].search_count(domain)

        # Pagination
        pager = request.website.pager(
            url="/my/custom-requests",
            url_args={'date_begin': date_begin, 'date_end': date_end, 'sortby': sortby,
                     'filterby': filterby, 'search': search, 'search_in': search_in},
            total=request_count,
            page=page,
            step=self._items_per_page
        )

        # Get records
        requests = request.env['your.model'].search(domain, order=order,
                                                   limit=self._items_per_page,
                                                   offset=pager['offset'])

        # Group by if needed
        if groupby == 'status':
            grouped_requests = {}
            for req in requests:
                status = req.state
                if status not in grouped_requests:
                    grouped_requests[status] = request.env['your.model']
                grouped_requests[status] += req
            requests = grouped_requests

        values.update({
            'date': date_begin,
            'date_end': date_end,
            'requests': requests,
            'page_name': 'custom_requests',
            'archive_groups': [],
            'default_url': '/my/custom-requests',
            'pager': pager,
            'searchbar_sortings': searchbar_sortings,
            'searchbar_groupby': searchbar_groupby,
            'searchbar_inputs': searchbar_inputs,
            'search_in': search_in,
            'search': search,
            'sortby': sortby,
            'groupby': groupby,
            'searchbar_filters': searchbar_filters,
            'filterby': filterby,
        })

        return request.render("your_module.portal_my_custom_requests", values)
```

### 2. Portal Home Template Extension

Add new sections to the portal home page template:

```xml
<!-- views/portal_templates.xml -->
<template id="portal_my_home_custom" name="Portal My Home Custom" inherit_id="portal.portal_my_home">
    <!-- Add custom section to portal home -->
    <xpath expr="//div[hasclass('o_portal_docs')]" position="inside">
        <t t-call="portal.portal_docs_entry">
            <t t-set="title">Custom Requests</t>
            <t t-set="url">/my/custom-requests</t>
            <t t-set="placeholder_count">custom_requests_count</t>
        </t>

        <t t-call="portal.portal_docs_entry">
            <t t-set="title">Custom Documents</t>
            <t t-set="url">/my/custom-documents</t>
            <t t-set="placeholder_count">custom_documents_count</t>
        </t>
    </xpath>
</template>

<!-- Custom requests list template -->
<template id="portal_my_custom_requests" name="My Custom Requests">
    <t t-call="portal.portal_layout">
        <t t-set="breadcrumbs_searchbar" t-value="True"/>

        <t t-call="portal.portal_searchbar">
            <t t-set="title">Custom Requests</t>
        </t>

        <t t-if="not requests">
            <div class="alert alert-warning mt-3" role="alert">
                There are no custom requests to display.
                <a href="/my/custom-form" class="btn btn-primary btn-sm ms-2">
                    <i class="fa fa-plus"></i> Create New Request
                </a>
            </div>
        </t>
        <t t-else="">
            <div class="card mt-3">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">Custom Requests</h5>
                    <a href="/my/custom-form" class="btn btn-primary btn-sm">
                        <i class="fa fa-plus"></i> New Request
                    </a>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover o_portal_my_doc_table">
                        <thead>
                            <tr class="active">
                                <th>
                                    <span role="img" aria-label="Reference" title="Reference">#</span>
                                </th>
                                <th>Name</th>
                                <th class="text-center">Status</th>
                                <th class="text-center">Date</th>
                                <th class="text-center">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <t t-foreach="requests" t-as="request_item">
                                <tr>
                                    <td>
                                        <a t-attf-href="/my/custom-requests/#{request_item.id}">
                                            <t t-out="request_item.name"/>
                                        </a>
                                    </td>
                                    <td>
                                        <t t-out="request_item.description[:50]"/>
                                        <t t-if="len(request_item.description) > 50">...</t>
                                    </td>
                                    <td class="text-center">
                                        <span t-attf-class="badge badge-#{request_item.state == 'approved' and 'success' or request_item.state == 'submitted' and 'warning' or 'secondary'}">
                                            <t t-out="request_item.state.title()"/>
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <span t-field="request_item.create_date" t-options="{'widget': 'date'}"/>
                                    </td>
                                    <td class="text-center">
                                        <a t-attf-href="/my/custom-requests/#{request_item.id}"
                                           class="btn btn-sm btn-outline-primary">
                                            <i class="fa fa-eye"></i> View
                                        </a>
                                        <t t-if="request_item.state == 'draft'">
                                            <a t-attf-href="/my/custom-requests/#{request_item.id}/edit"
                                               class="btn btn-sm btn-outline-secondary">
                                                <i class="fa fa-edit"></i> Edit
                                            </a>
                                        </t>
                                    </td>
                                </tr>
                            </t>
                        </tbody>
                    </table>
                </div>
            </div>
        </t>

        <div t-if="pager" class="o_portal_pager text-center">
            <t t-call="portal.pager"/>
        </div>
    </t>
</template>

<!-- Individual request detail template -->
<template id="portal_my_custom_request_detail" name="Custom Request Detail">
    <t t-call="portal.portal_layout">
        <t t-call="portal.portal_record_layout">
            <t t-set="card_header">
                <div class="row no-gutters">
                    <div class="col-12">
                        <h5 class="mb-0">
                            <span t-field="request.name"/>
                            <small class="text-muted"> (#<span t-field="request.id"/>)</small>
                        </h5>
                    </div>
                </div>
            </t>

            <t t-set="card_body">
                <div class="row mb-4">
                    <div class="col-12 col-md-6">
                        <strong>Status:</strong>
                        <span t-attf-class="badge badge-#{request.state == 'approved' and 'success' or request.state == 'submitted' and 'warning' or 'secondary'}">
                            <t t-out="request.state.title()"/>
                        </span>
                    </div>
                    <div class="col-12 col-md-6">
                        <strong>Date:</strong>
                        <span t-field="request.create_date" t-options="{'widget': 'datetime'}"/>
                    </div>
                </div>

                <div class="row mb-4">
                    <div class="col-12">
                        <strong>Description:</strong>
                        <div class="mt-2">
                            <t t-out="request.description"/>
                        </div>
                    </div>
                </div>

                <!-- Attachments -->
                <t t-if="request.attachment_ids">
                    <div class="row mb-4">
                        <div class="col-12">
                            <strong>Attachments:</strong>
                            <div class="mt-2">
                                <t t-foreach="request.attachment_ids" t-as="attachment">
                                    <div class="d-flex align-items-center mb-2">
                                        <i class="fa fa-file-o me-2"></i>
                                        <a t-attf-href="/web/content/#{attachment.id}?download=true"
                                           target="_blank">
                                            <t t-out="attachment.name"/>
                                        </a>
                                        <small class="text-muted ms-2">
                                            (<t t-out="attachment.file_size"/> bytes)
                                        </small>
                                    </div>
                                </t>
                            </div>
                        </div>
                    </div>
                </t>

                <!-- Actions -->
                <div class="row">
                    <div class="col-12">
                        <a href="/my/custom-requests" class="btn btn-secondary">
                            <i class="fa fa-arrow-left"></i> Back to List
                        </a>
                        <t t-if="request.state == 'draft'">
                            <a t-attf-href="/my/custom-requests/#{request.id}/edit"
                               class="btn btn-primary">
                                <i class="fa fa-edit"></i> Edit
                            </a>
                        </t>
                    </div>
                </div>
            </t>
        </t>
    </t>
</template>
```

## Portal Controller Patterns

### 1. Standard Portal Controller Structure

Follow Odoo's standard patterns for portal controllers:

```python
# controllers/portal.py
from odoo import http, _
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal, pager as portal_pager
from odoo.exceptions import AccessError, MissingError

class YourModulePortal(CustomerPortal):

    def _prepare_home_portal_values(self, counters):
        """Override to add custom counters"""
        values = super()._prepare_home_portal_values(counters)

        partner = request.env.user.partner_id

        # Add your custom counters
        YourModel = request.env['your.model']
        if 'your_model_count' in counters:
            values['your_model_count'] = YourModel.search_count(
                self._get_your_model_domain(partner)
            )

        return values

    def _get_your_model_domain(self, partner):
        """Get domain for your model records"""
        return [
            ('partner_id', '=', partner.id),
            ('state', '!=', 'cancelled')
        ]

    def _your_model_get_page_view_values(self, your_model, access_token, **kwargs):
        """Prepare values for individual record view"""
        values = {
            'page_name': 'your_model',
            'your_model': your_model,
        }
        return self._get_page_view_values(
            your_model, access_token, values, 'my_your_models_history', False, **kwargs
        )

    @http.route(['/my/your-models', '/my/your-models/page/<int:page>'],
                type='http', auth="user", website=True)
    def portal_my_your_models(self, page=1, date_begin=None, date_end=None,
                              sortby=None, **kw):
        """List view for your models"""
        values = self._prepare_portal_layout_values()
        partner = request.env.user.partner_id
        YourModel = request.env['your.model']

        domain = self._get_your_model_domain(partner)

        # Sorting
        searchbar_sortings = {
            'date': {'label': _('Newest'), 'order': 'create_date desc'},
            'name': {'label': _('Name'), 'order': 'name'},
        }

        if not sortby:
            sortby = 'date'
        order = searchbar_sortings[sortby]['order']

        # Date filtering
        if date_begin and date_end:
            domain += [('create_date', '>', date_begin), ('create_date', '<=', date_end)]

        # Count for pager
        your_model_count = YourModel.search_count(domain)

        # Pager
        pager = portal_pager(
            url="/my/your-models",
            url_args={'date_begin': date_begin, 'date_end': date_end, 'sortby': sortby},
            total=your_model_count,
            page=page,
            step=self._items_per_page
        )

        # Content
        your_models = YourModel.search(domain, order=order, limit=self._items_per_page,
                                       offset=pager['offset'])

        values.update({
            'date': date_begin,
            'date_end': date_end,
            'your_models': your_models,
            'page_name': 'your_model',
            'archive_groups': [],
            'default_url': '/my/your-models',
            'pager': pager,
            'searchbar_sortings': searchbar_sortings,
            'sortby': sortby,
        })

        return request.render("your_module.portal_my_your_models", values)

    @http.route(['/my/your-models/<int:your_model_id>'], type='http', auth="user", website=True)
    def portal_my_your_model(self, your_model_id=None, access_token=None, **kw):
        """Detail view for individual record"""
        try:
            your_model_sudo = self._document_check_access('your.model', your_model_id, access_token)
        except (AccessError, MissingError):
            return request.redirect('/my')

        values = self._your_model_get_page_view_values(your_model_sudo, access_token, **kw)
        return request.render("your_module.portal_my_your_model", values)
```

### 2. Access Control Patterns

#### ⚠️ **CRITICAL: `_document_check_access` Override Pattern**

**DANGER**: Overriding `_document_check_access` without model-specific checks will break ALL portal document access, including sale orders, invoices, and other core Odoo models!

**The Problem:**
When you override `_document_check_access` in a `CustomerPortal` subclass, it applies to **ALL models** accessed through that controller, not just your custom models. Many Odoo models have a `user_id` field that means different things:
- `sale.order.user_id` = **Salesperson** (internal user)
- `account.move.user_id` = **Responsible user** (internal user)
- `project.task.user_id` = **Assigned user**
- Your custom model's `user_id` = **Portal user/owner**

**❌ WRONG - Breaks All Portal Access:**
```python
def _document_check_access(self, model_name, document_id, access_token=None):
    """DANGEROUS: This breaks sale orders, invoices, and other core models!"""
    document = request.env[model_name].browse([document_id])
    document_sudo = document.sudo()

    try:
        document.check_access_rights('read')
        document.check_access_rule('read')
    except AccessError:
        if access_token and document_sudo.access_token and \
           consteq(document_sudo.access_token, access_token):
            return document_sudo
        else:
            raise

    # ❌ CRITICAL BUG: This breaks sale orders and other core models!
    # sale.order.user_id is the SALESPERSON, not the customer!
    if hasattr(document_sudo, 'user_id'):
        if document_sudo.user_id.id != request.env.user.id:
            raise AccessError(_("You don't have access to this document."))

    return document_sudo
```

**Why This Breaks:**
1. User clicks "Preview" on sale order → Opens `/my/orders/123?access_token=...`
2. Your override checks `sale_order.user_id` (salesperson) != portal user
3. Access denied → Redirects to `/my`
4. **Result**: Portal users cannot view their own orders!

**✅ CORRECT - Model-Specific Access Checks:**
```python
def _document_check_access(self, model_name, document_id, access_token=None):
    """
    Check access rights for portal documents.

    IMPORTANT: Only apply custom ownership checks to YOUR models.
    Let parent class handle core Odoo models (sale.order, account.move, etc.)
    """
    document = request.env[model_name].browse([document_id])
    document_sudo = document.sudo()

    try:
        document.check_access_rights('read')
        document.check_access_rule('read')
    except AccessError:
        if access_token and document_sudo.access_token and \
           consteq(document_sudo.access_token, access_token):
            return document_sudo
        else:
            raise

    # ✅ CORRECT: Only check user_id ownership for YOUR specific models
    # List all models where user_id represents the portal user/owner
    if model_name in ['your.custom.model', 'your.application', 'your.membership']:
        if hasattr(document_sudo, 'user_id') and document_sudo.user_id.id != request.env.user.id:
            raise AccessError(_("You don't have access to this document."))

    return document_sudo
```

**✅ BETTER - Use partner_id for Core Model Compatibility:**
```python
def _document_check_access(self, model_name, document_id, access_token=None):
    """
    Check access rights for portal documents.

    Use partner_id for ownership checks - it's consistent across Odoo models.
    """
    document = request.env[model_name].browse([document_id])
    document_sudo = document.sudo()

    try:
        document.check_access_rights('read')
        document.check_access_rule('read')
    except AccessError:
        if access_token and document_sudo.access_token and \
           consteq(document_sudo.access_token, access_token):
            return document_sudo
        else:
            raise

    # ✅ BEST: Use partner_id which is consistent across models
    # Only check for YOUR specific models
    if model_name in ['your.custom.model', 'your.application']:
        if hasattr(document_sudo, 'partner_id'):
            if document_sudo.partner_id != request.env.user.partner_id:
                raise AccessError(_("You don't have access to this document."))

    return document_sudo
```

**✅ BEST - Don't Override Unless Necessary:**
```python
# If you only need standard portal access control, DON'T override _document_check_access!
# The parent CustomerPortal class already handles it correctly.

# Only override if you need ADDITIONAL checks for YOUR models:
@http.route(['/my/custom-model/<int:model_id>'], type='http', auth="user", website=True)
def portal_my_custom_model(self, model_id=None, access_token=None, **kw):
    """Detail view with standard access control"""
    try:
        # Use parent's _document_check_access - it works correctly!
        model_sudo = self._document_check_access('your.custom.model', model_id, access_token)
    except (AccessError, MissingError):
        return request.redirect('/my')

    # Additional custom checks AFTER standard access control
    if model_sudo.state == 'cancelled':
        return request.redirect('/my/custom-models?error=cancelled')

    values = {'model': model_sudo}
    return request.render("your_module.portal_my_custom_model", values)
```

**Testing Checklist:**
After overriding `_document_check_access`, test these core Odoo features:
- [ ] Sale Order Preview button (backend → portal view)
- [ ] Invoice portal access
- [ ] Purchase Order portal access (if applicable)
- [ ] Project/Task portal access (if applicable)
- [ ] Any other portal documents your users access

**Key Takeaways:**
1. **Don't override `_document_check_access` unless absolutely necessary**
2. **If you must override, use model-specific checks with explicit model names**
3. **Never use `user_id` for ownership checks without model filtering**
4. **Prefer `partner_id` for ownership - it's consistent across Odoo**
5. **Test all portal document types after overriding**

### 3. Portal Counter Debugging and Troubleshooting

#### Common JavaScript Errors and Solutions

**Error**: `TypeError: Cannot set properties of null (setting 'textContent')`

**Cause**: Portal JavaScript tries to update counter elements that don't exist or are null.

**Solutions**:

1. **Always use `show_count="True"`**:
```xml
<t t-call="portal.portal_docs_entry">
    <t t-set="show_count" t-value="True"/>  <!-- REQUIRED -->
    <t t-set="placeholder_count" t-value="'your_count'"/>
</t>
```

2. **Check counters in controller**:
```python
def _prepare_home_portal_values(self, counters):
    values = super()._prepare_home_portal_values(counters)

    # ALWAYS check if counter is in the list
    if 'your_count' in counters:
        values['your_count'] = request.env['your.model'].search_count(domain)

    return values
```

3. **Add counters to always displayed**:
```python
def _getCountersAlwaysDisplayed(self):
    counters = super()._getCountersAlwaysDisplayed() if hasattr(super(), '_getCountersAlwaysDisplayed') else []
    counters.extend(['your_count'])
    return counters
```

4. **Enable portal service category**:
```xml
<xpath expr="//div[hasclass('o_portal_docs')]" position="before">
    <t t-set="portal_service_category_enable" t-value="True"/>
</xpath>
```

#### Debugging Portal Counter Issues

1. **Check browser console** for JavaScript errors
2. **Verify counter elements** exist in DOM:
```javascript
// In browser console
document.querySelectorAll('[data-placeholder_count]')
```

3. **Check RPC calls** to `/my/counters` in Network tab
4. **Verify controller response** includes your counter
5. **Test with different user states** (new user, existing user, etc.)

#### Portal Counter Flow Debugging

```python
# Add logging to debug counter flow
import logging
_logger = logging.getLogger(__name__)

def _prepare_home_portal_values(self, counters):
    _logger.info("Portal counters requested: %s", counters)
    values = super()._prepare_home_portal_values(counters)

    if 'your_count' in counters:
        count = request.env['your.model'].search_count(domain)
        values['your_count'] = count
        _logger.info("Your count: %s", count)

    _logger.info("Portal values: %s", values)
    return values
```

## Form Validation Patterns

### 1. Server-Side Validation

Implement comprehensive server-side validation:

```python
def _validate_form_data(self, data, required_fields=None):
    """Validate form data with custom rules"""
    errors = {}

    # Required fields validation
    if required_fields:
        for field in required_fields:
            if not data.get(field):
                errors[field] = _('This field is required')

    # Email validation
    if data.get('email'):
        import re
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, data['email']):
            errors['email'] = _('Please enter a valid email address')

    # Phone validation
    if data.get('phone'):
        phone = re.sub(r'[^\d+]', '', data['phone'])
        if len(phone) < 10:
            errors['phone'] = _('Phone number must be at least 10 digits')

    # Custom business logic validation
    if data.get('start_date') and data.get('end_date'):
        from datetime import datetime
        try:
            start = datetime.strptime(data['start_date'], '%Y-%m-%d')
            end = datetime.strptime(data['end_date'], '%Y-%m-%d')
            if start >= end:
                errors['end_date'] = _('End date must be after start date')
        except ValueError:
            errors['date'] = _('Invalid date format')

    # File validation
    if data.get('attachment'):
        file_obj = data['attachment']
        max_size = 5 * 1024 * 1024  # 5MB
        allowed_types = ['pdf', 'doc', 'docx', 'jpg', 'png']

        if hasattr(file_obj, 'read'):
            content = file_obj.read()
            file_obj.seek(0)  # Reset file pointer

            if len(content) > max_size:
                errors['attachment'] = _('File size must be less than 5MB')

            filename = getattr(file_obj, 'filename', '')
            if filename:
                ext = filename.split('.')[-1].lower()
                if ext not in allowed_types:
                    errors['attachment'] = _('File type not allowed')

    return errors
```

### 2. Client-Side Validation Integration

Integrate client-side validation with server-side validation:

```javascript
// static/src/js/portal_validation.js
/** @odoo-module **/

export class PortalValidation {
    constructor() {
        this.setupValidation();
    }

    setupValidation() {
        // Form submission handling
        document.addEventListener('submit', (e) => {
            if (e.target.classList.contains('portal-form')) {
                this.handleFormSubmit(e);
            }
        });

        // Real-time field validation
        document.addEventListener('blur', (e) => {
            if (e.target.classList.contains('validate-field')) {
                this.validateField(e.target);
            }
        }, true);
    }

    handleFormSubmit(event) {
        const form = event.target;
        const isValid = this.validateForm(form);

        if (!isValid) {
            event.preventDefault();
            this.showValidationErrors(form);
        }
    }

    validateForm(form) {
        let isValid = true;
        const fields = form.querySelectorAll('.validate-field');

        fields.forEach(field => {
            if (!this.validateField(field)) {
                isValid = false;
            }
        });

        return isValid;
    }

    validateField(field) {
        const value = field.value.trim();
        const rules = this.getValidationRules(field);
        let isValid = true;
        let errorMessage = '';

        // Required validation
        if (rules.required && !value) {
            isValid = false;
            errorMessage = 'This field is required';
        }

        // Email validation
        if (value && rules.email) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(value)) {
                isValid = false;
                errorMessage = 'Please enter a valid email address';
            }
        }

        // Length validation
        if (value && rules.minLength && value.length < rules.minLength) {
            isValid = false;
            errorMessage = `Minimum length is ${rules.minLength} characters`;
        }

        this.setFieldValidation(field, isValid, errorMessage);
        return isValid;
    }

    getValidationRules(field) {
        return {
            required: field.hasAttribute('required'),
            email: field.type === 'email',
            minLength: field.getAttribute('data-min-length'),
        };
    }

    setFieldValidation(field, isValid, errorMessage) {
        const errorElement = field.parentNode.querySelector('.field-error');

        if (isValid) {
            field.classList.remove('is-invalid');
            if (errorElement) {
                errorElement.remove();
            }
        } else {
            field.classList.add('is-invalid');
            if (!errorElement) {
                const error = document.createElement('div');
                error.className = 'field-error text-danger small mt-1';
                error.textContent = errorMessage;
                field.parentNode.appendChild(error);
            } else {
                errorElement.textContent = errorMessage;
            }
        }
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new PortalValidation();
});
```

## Template Inheritance Patterns

### 1. Standard Template Inheritance

Follow Odoo's template inheritance patterns for consistent portal integration:

```xml
<!-- Extend portal layout -->
<template id="portal_layout_extend" name="Portal Layout Extension" inherit_id="portal.portal_layout">
    <!-- Add custom CSS -->
    <xpath expr="//head" position="inside">
        <link rel="stylesheet" type="text/css" href="/your_module/static/src/css/portal.css"/>
    </xpath>

    <!-- Add custom JavaScript -->
    <xpath expr="//body" position="inside">
        <script type="text/javascript" src="/your_module/static/src/js/portal.js"></script>
    </xpath>
</template>

<!-- Extend portal breadcrumbs -->
<template id="portal_breadcrumbs_extend" name="Portal Breadcrumbs Extension" inherit_id="portal.portal_breadcrumbs">
    <xpath expr="//ol[hasclass('breadcrumb')]" position="inside">
        <li t-if="page_name == 'your_model'" class="breadcrumb-item">
            <a href="/my/your-models">Your Models</a>
        </li>
    </xpath>
</template>

<!-- Extend portal searchbar -->
<template id="portal_searchbar_extend" name="Portal Searchbar Extension" inherit_id="portal.portal_searchbar">
    <!-- Add custom search options -->
    <xpath expr="//div[hasclass('o_portal_search_panel')]" position="inside">
        <t t-if="page_name == 'your_model'">
            <div class="form-group">
                <label for="custom_filter">Custom Filter</label>
                <select name="custom_filter" class="form-control">
                    <option value="">All</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                </select>
            </div>
        </t>
    </xpath>
</template>
```

### 2. Portal Record Layout Pattern

Use Odoo's portal record layout for consistent styling:

```xml
<template id="portal_my_record" name="My Record">
    <t t-call="portal.portal_layout">
        <t t-call="portal.portal_record_layout">
            <t t-set="card_header">
                <div class="row no-gutters">
                    <div class="col-12">
                        <h5 class="mb-0">
                            <span t-field="record.name"/>
                            <small class="text-muted"> (#<span t-field="record.id"/>)</small>
                        </h5>
                    </div>
                </div>
            </t>

            <t t-set="card_body">
                <!-- Record content goes here -->
                <div class="row">
                    <div class="col-12 col-md-6">
                        <strong>Field Label:</strong>
                        <span t-field="record.field_name"/>
                    </div>
                </div>
            </t>
        </t>
    </t>
</template>
```

### 3. Portal Table Pattern

Use consistent table patterns for list views:

```xml
<template id="portal_my_records_table" name="My Records Table">
    <div class="table-responsive">
        <table class="table table-hover o_portal_my_doc_table">
            <thead>
                <tr class="active">
                    <th>Reference</th>
                    <th>Name</th>
                    <th class="text-center">Status</th>
                    <th class="text-center">Date</th>
                    <th class="text-center">Actions</th>
                </tr>
            </thead>
            <tbody>
                <t t-foreach="records" t-as="record">
                    <tr>
                        <td>
                            <a t-attf-href="/my/records/#{record.id}">
                                <t t-out="record.name"/>
                            </a>
                        </td>
                        <td>
                            <span t-field="record.description"/>
                        </td>
                        <td class="text-center">
                            <span t-attf-class="badge badge-#{record.state == 'done' and 'success' or 'secondary'}">
                                <t t-out="record.state.title()"/>
                            </span>
                        </td>
                        <td class="text-center">
                            <span t-field="record.create_date" t-options="{'widget': 'date'}"/>
                        </td>
                        <td class="text-center">
                            <a t-attf-href="/my/records/#{record.id}"
                               class="btn btn-sm btn-outline-primary">
                                <i class="fa fa-eye"></i> View
                            </a>
                        </td>
                    </tr>
                </t>
            </tbody>
        </table>
    </div>
</template>
```

### 4. Responsive Design Patterns

Ensure portal templates are mobile-friendly:

```xml
<template id="portal_responsive_form" name="Responsive Portal Form">
    <div class="container-fluid">
        <div class="row">
            <div class="col-12 col-lg-8 offset-lg-2">
                <form class="portal-form">
                    <div class="row">
                        <!-- Use Bootstrap grid for responsive layout -->
                        <div class="col-12 col-md-6">
                            <div class="form-group">
                                <label for="field1">Field 1</label>
                                <input type="text" name="field1" class="form-control"/>
                            </div>
                        </div>
                        <div class="col-12 col-md-6">
                            <div class="form-group">
                                <label for="field2">Field 2</label>
                                <input type="text" name="field2" class="form-control"/>
                            </div>
                        </div>
                    </div>

                    <!-- Mobile-friendly button layout -->
                    <div class="row">
                        <div class="col-12">
                            <div class="d-flex flex-column flex-md-row justify-content-between">
                                <button type="submit" class="btn btn-primary mb-2 mb-md-0">
                                    Submit
                                </button>
                                <a href="/my" class="btn btn-secondary">
                                    Cancel
                                </a>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>
```

## Portal URL Generation and PDF Handling

### 1. Portal URL Generation Patterns

When creating portal functionality that involves downloading PDFs or accessing specific documents, follow Odoo's standard URL generation patterns.

#### ✅ Standard Portal URL Method Pattern

```python
# models/your_model.py
from odoo import models

class YourModel(models.Model):
    _inherit = 'your.model'

    def get_portal_url(self, suffix=None, report_type=None, download=None, query_string=None, anchor=None):
        """
        Generate portal URL for this record
        Similar to account.move.get_portal_url pattern
        """
        self.ensure_one()

        # Build the portal URL following Odoo's standard pattern
        url = '/my/records/%s?access_token=%s%s%s%s%s' % (
            self.id,
            self._portal_ensure_token(),
            '&report_type=%s' % report_type if report_type else '',
            '&download=true' if download else '',
            query_string if query_string else '',
            '#%s' % anchor if anchor else ''
        )
        return url

    def get_custom_report_portal_url(self, suffix=None, report_type=None, download=None, query_string=None, anchor=None):
        """
        Generate portal URL for custom report download
        Follow the same pattern as get_portal_url but for different endpoints
        """
        self.ensure_one()

        # Build the custom report URL
        url = '/my/records/%s/custom_report?access_token=%s%s%s%s%s' % (
            self.id,
            self._portal_ensure_token(),
            '&report_type=%s' % report_type if report_type else '',
            '&download=true' if download else '',
            query_string if query_string else '',
            '#%s' % anchor if anchor else ''
        )
        return url
```

#### ✅ Template Usage for Portal URLs

```xml
<!-- views/portal_templates.xml -->
<template id="portal_record_page" name="Portal Record">
    <t t-call="portal.portal_layout">
        <div class="container">
            <!-- Standard download buttons -->
            <div class="d-flex gap-1 flex-lg-column flex-xl-row">
                <div class="flex-grow-1">
                    <a t-att-href="record.get_portal_url(report_type='pdf', download=True)"
                       class="btn btn-primary d-block o_download_btn" title="Download PDF">
                        <i class="fa fa-download"/> Download PDF
                    </a>
                </div>
            </div>

            <!-- Custom report download (conditional) -->
            <t t-if="record.state in ['confirmed', 'done']">
                <div class="d-flex gap-1 flex-lg-column flex-xl-row mt-2">
                    <div class="flex-grow-1">
                        <a t-att-href="record.get_custom_report_portal_url(report_type='pdf', download=True)"
                           class="btn btn-secondary d-block o_download_btn" title="Download Custom Report">
                            <i class="fa fa-download"/> Custom Report
                        </a>
                    </div>
                </div>
            </t>
        </div>
    </t>
</template>
```

### 2. PDF Report Generation in Portal Controllers

#### ✅ Correct PDF Generation Pattern

```python
# controllers/portal.py
from odoo import http, _
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal
from odoo.exceptions import AccessError, MissingError

class YourPortal(CustomerPortal):

    @http.route(['/my/records/<int:record_id>/custom_report'], type='http', auth="public", website=True)
    def portal_record_custom_report(self, record_id, access_token=None, report_type=None, download=None, **kwargs):
        """Download custom report PDF for a record"""
        try:
            # Check access to the record
            record_sudo = self._document_check_access('your.model', record_id, access_token)
        except (AccessError, MissingError):
            return request.redirect('/my')

        # Verify the record state allows report generation
        if record_sudo.state not in ['confirmed', 'done']:
            return request.not_found()

        try:
            # Generate PDF using the correct method signature
            pdf_content, _ = request.env['ir.actions.report'].sudo()._render_qweb_pdf(
                'your_module.action_report_custom', res_ids=record_sudo.ids
            )

            # Set appropriate filename
            filename = f"Custom_Report_{record_sudo.name.replace('/', '-')}.pdf"

            # Return PDF response with proper headers
            pdfhttpheaders = [
                ('Content-Type', 'application/pdf'),
                ('Content-Length', len(pdf_content)),
                ('Content-Disposition', f'attachment; filename="{filename}"')
            ]
            return request.make_response(pdf_content, headers=pdfhttpheaders)

        except Exception as e:
            _logger.error("Error generating custom report PDF: %s", str(e))
            return request.not_found()
```

#### ❌ Common PDF Generation Mistakes

```python
# DON'T DO THIS - Wrong method signature
report = request.env.ref('your_module.action_report_custom')
pdf_content, _ = report.sudo()._render_qweb_pdf(record_sudo.ids)  # WRONG

# DON'T DO THIS - Passing list as first parameter
pdf_content, _ = report.sudo()._render_qweb_pdf([record_sudo.id])  # WRONG

# DO THIS - Correct method signature
pdf_content, _ = request.env['ir.actions.report'].sudo()._render_qweb_pdf(
    'your_module.action_report_custom', res_ids=record_sudo.ids
)  # CORRECT
```

### 3. Multiple Records PDF Generation

#### ✅ Handling Multiple Records in Single PDF

```python
@http.route(['/my/records/<int:record_id>/all_payments_report'], type='http', auth="public", website=True)
def portal_all_payments_report(self, record_id, access_token=None, **kwargs):
    """Generate PDF containing all related payments"""
    try:
        # Check access to the main record
        record_sudo = self._document_check_access('your.model', record_id, access_token)
    except (AccessError, MissingError):
        return request.redirect('/my')

    # Get all related records (e.g., payments)
    related_records = record_sudo._get_related_payments()  # Use Odoo's built-in methods

    if not related_records:
        return request.not_found()

    try:
        # Generate PDF for all related records
        pdf_content, _ = request.env['ir.actions.report'].sudo()._render_qweb_pdf(
            'account.action_report_payment_receipt', res_ids=related_records.ids
        )

        # Set filename based on number of records
        if len(related_records) == 1:
            filename = f"Payment_Receipt_{record_sudo.name.replace('/', '-')}_{related_records[0].name.replace('/', '-')}.pdf"
        else:
            filename = f"Payment_Receipts_{record_sudo.name.replace('/', '-')}.pdf"

        pdfhttpheaders = [
            ('Content-Type', 'application/pdf'),
            ('Content-Length', len(pdf_content)),
            ('Content-Disposition', f'attachment; filename="{filename}"')
        ]
        return request.make_response(pdf_content, headers=pdfhttpheaders)

    except Exception as e:
        _logger.error("Error generating payments report PDF: %s", str(e))
        return request.not_found()
```

### 4. Portal Button Layout Standards

#### ✅ Stacked Button Layout (Recommended)

```xml
<!-- Use stacked layout for better mobile experience -->
<xpath expr="//a[@t-att-href='record.get_portal_url(report_type=\"pdf\", download=True)']/parent::*/parent::*" position="after">
    <t t-if="record.state in ['paid', 'partial', 'in_payment']">
        <div class="flex-basis-100 flex-basis-sm-50 flex-basis-lg-100 order-1 order-lg-1 mt-2 mb-2">
            <div class="d-flex gap-1 flex-lg-column flex-xl-row">
                <div class="flex-grow-1">
                    <a t-att-href="record.get_custom_report_portal_url(report_type='pdf', download=True)"
                       class="btn btn-secondary d-block o_download_btn" title="Download Custom Report">
                        <i class="fa fa-download"/> Custom Report
                    </a>
                </div>
            </div>
        </div>
    </t>
</xpath>
```

#### ✅ XPath Targeting Best Practices

```xml
<!-- Target specific elements using proper XPath -->
<!-- Method 1: Target by href attribute -->
<xpath expr="//a[@t-att-href='invoice.get_portal_url(report_type=\"pdf\", download=True)']" position="after">
    <!-- New button here -->
</xpath>

<!-- Method 2: Navigate to parent container -->
<xpath expr="//a[@t-att-href='invoice.get_portal_url(report_type=\"pdf\", download=True)']/parent::*/parent::*" position="after">
    <!-- New section here -->
</xpath>

<!-- Method 3: Use ::parent for cleaner navigation -->
<xpath expr="//a[@t-att-href='invoice.get_portal_url(report_type=\"pdf\", download=True)']::parent::parent" position="after">
    <!-- New section here -->
</xpath>
```

### 5. Access Token Security

#### ✅ Proper Access Token Usage

```python
def _document_check_access(self, model_name, document_id, access_token=None):
    """Check access rights for portal documents with proper token validation"""
    document = request.env[model_name].browse([document_id])
    document_sudo = document.sudo()

    try:
        # Try normal access first
        document.check_access_rights('read')
        document.check_access_rule('read')
    except AccessError:
        # Fall back to access token validation
        if access_token and document_sudo.access_token and \
           consteq(document_sudo.access_token, access_token):
            return document_sudo
        else:
            raise

    # Additional custom access checks
    if hasattr(document_sudo, 'partner_id'):
        if document_sudo.partner_id != request.env.user.partner_id:
            raise AccessError(_("You don't have access to this document."))

    return document_sudo
```

### 6. Error Handling and Logging

#### ✅ Comprehensive Error Handling

```python
import logging
_logger = logging.getLogger(__name__)

@http.route(['/my/records/<int:record_id>/report'], type='http', auth="public", website=True)
def portal_record_report(self, record_id, access_token=None, **kwargs):
    """Generate record report with proper error handling"""
    try:
        # Access validation
        record_sudo = self._document_check_access('your.model', record_id, access_token)
    except (AccessError, MissingError):
        _logger.warning("Access denied for record %s with token %s", record_id, access_token)
        return request.redirect('/my')

    # State validation
    if record_sudo.state not in ['confirmed', 'done']:
        _logger.warning("Invalid state %s for record %s report generation", record_sudo.state, record_id)
        return request.not_found()

    try:
        # Get related data using Odoo's built-in methods
        related_data = record_sudo._get_related_data()

        if not related_data:
            _logger.warning("No related data found for record %s", record_sudo.name)
            return request.not_found()

        _logger.info("Generating report for record %s with %d related items",
                    record_sudo.name, len(related_data))

        # Generate PDF
        pdf_content, _ = request.env['ir.actions.report'].sudo()._render_qweb_pdf(
            'your_module.action_report_template', res_ids=related_data.ids
        )

        # Success response
        filename = f"Report_{record_sudo.name.replace('/', '-')}.pdf"
        pdfhttpheaders = [
            ('Content-Type', 'application/pdf'),
            ('Content-Length', len(pdf_content)),
            ('Content-Disposition', f'attachment; filename="{filename}"')
        ]
        return request.make_response(pdf_content, headers=pdfhttpheaders)

    except Exception as e:
        _logger.error("Error generating report PDF for record %s: %s", record_id, str(e))
        _logger.error("Full traceback: %s", traceback.format_exc())
        return request.not_found()
```

### 7. Portal URL and PDF Best Practices Summary

#### ✅ Do's
- **Use Odoo's built-in methods** like `_get_reconciled_payments()` instead of manual searches
- **Follow standard URL patterns** similar to `account.move.get_portal_url()`
- **Use correct PDF generation syntax**: `request.env['ir.actions.report']._render_qweb_pdf(report_xml_id, res_ids=record_ids)`
- **Handle multiple records properly** in single PDF generation
- **Use stacked button layouts** for better mobile experience
- **Implement proper access token validation** for security
- **Add comprehensive error handling** and logging
- **Use XPath targeting with ::parent** for cleaner template inheritance

#### ❌ Don'ts
- **Don't search computed fields** like `reconciled_invoice_ids` in domains
- **Don't pass lists as first parameter** to `_render_qweb_pdf()`
- **Don't use single-line button layouts** in portal templates
- **Don't skip access token validation** in public routes
- **Don't ignore error handling** in PDF generation
- **Don't create custom reconciliation logic** when Odoo provides built-in methods

## Best Practices Summary

### Portal Card Standards (CRITICAL)
1. **Entity Separation**: Always create separate portal cards for different business entities
2. **Complete Counters**: Include ALL record states in counters (don't exclude approved, etc.)
3. **Independent Access**: Allow users to access entities regardless of other entity states
4. **Standard Navigation**: Use portal breadcrumb extensions, never custom breadcrumbs
5. **JavaScript Safety**: Always use `show_count="True"` and check counters in controller
6. **Service Category**: Set `portal_service_category_enable="True"` when adding cards
7. **Always Displayed**: Add counters to `_getCountersAlwaysDisplayed()` method

### General Portal Development
8. **Always extend existing portal controllers** rather than creating new ones from scratch
9. **Use Odoo's standard portal templates** (`portal.portal_layout`, `portal.portal_record_layout`) for consistency
10. **Implement proper access control** using `_document_check_access` patterns
11. **Follow Odoo's searchbar and pager patterns** for list views
12. **Use Bootstrap classes** for responsive design
13. **Implement both client-side and server-side validation** for better user experience and security
14. **Follow Odoo's naming conventions** for routes, templates, and methods
15. **Use proper error handling** and user feedback patterns
16. **Implement CSRF protection** for all forms
17. **Test portal functionality** with different user types (portal, internal, public)

### Portal Card Checklist
Before implementing portal functionality, verify:
- [ ] Each business entity has its own portal card
- [ ] All record states are included in counters
- [ ] Users can access entities independently
- [ ] Standard portal navigation is used
- [ ] JavaScript counter errors are prevented
- [ ] Portal service category is enabled
- [ ] Counters are added to always displayed list

## Signature Component Integration

The Odoo portal module provides a standard signature component (`portal.signature_form`) that can be integrated into portal pages for capturing user signatures. This component is used throughout Odoo (quotations, contracts, etc.) and provides a consistent signature experience.

### 1. Understanding the Signature Component

#### Available Signature Modes

The signature widget supports three modes:

- **🎨 Auto**: Generates signature from name using fonts (default in standard Odoo)
- **✏️ Draw**: Manual drawing with mouse/touch (recommended default for custom implementations)
- **📁 Load**: Upload signature image file

#### Component Architecture

```javascript
// Core component: /web/static/src/core/signature/name_and_signature.js
// Portal wrapper: /portal/static/src/signature_form/signature_form.js
// Template: portal.signature_form (calls portal.SignatureForm OWL component)
```

### 2. Basic Integration Patterns

#### ✅ Inline Integration (Simple)

```xml
<!-- Direct integration in portal page -->
<template id="portal_page_with_signature" inherit_id="portal.portal_my_details">
    <xpath expr="//div[@class='clearfix text-end mb-5']" position="before">
        <div class="row">
            <div class="col-12">
                <hr class="my-4"/>
                <h5 class="mb-3">Digital Signature</h5>

                <!-- Current signature display -->
                <div t-if="request.env.user.partner_id.signature" class="form-group mb-3">
                    <label class="form-label">Current Signature</label>
                    <div class="current-signature mb-3">
                        <img t-att-src="'/web/image/res.partner/%s/signature' % request.env.user.partner_id.id"
                             style="max-height: 100px; border: 1px solid #ddd; padding: 10px;"/>
                    </div>
                </div>

                <!-- Signature widget -->
                <div class="form-group mb-3">
                    <t t-call="portal.signature_form">
                        <t t-set="call_url" t-value="'/my/account/signature/save'"/>
                        <t t-set="default_name" t-value="request.env.user.name"/>
                        <t t-set="mode" t-value="'draw'"/>  <!-- Set default mode -->
                    </t>
                </div>
            </div>
        </div>
    </xpath>
</template>
```

#### ✅ Modal Integration (Recommended)

```xml
<!-- Modal approach for better UX -->
<template id="portal_signature_modal" inherit_id="portal.portal_my_details">
    <xpath expr="//div[@class='clearfix text-end mb-5']" position="before">
        <div class="row">
            <div class="col-12">
                <hr class="my-4"/>
                <h5 class="mb-3">Digital Signature</h5>

                <!-- Current signature display -->
                <div t-if="request.env.user.partner_id.signature" class="form-group mb-3">
                    <label class="form-label">Current Signature</label>
                    <div class="current-signature mb-3">
                        <img t-att-src="'/web/image/res.partner/%s/signature' % request.env.user.partner_id.id"
                             style="max-height: 100px; border: 1px solid #ddd; padding: 10px;"/>
                    </div>
                </div>

                <!-- Signature button -->
                <div class="form-group mb-3">
                    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#signatureModal">
                        <i class="fa fa-edit me-1"/>
                        <t t-if="request.env.user.partner_id.signature">Update Signature</t>
                        <t t-else="">Add Signature</t>
                    </button>
                </div>

                <!-- Modal with signature widget -->
                <div class="modal fade" id="signatureModal" tabindex="-1" aria-labelledby="signatureModalLabel" aria-hidden="true">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title" id="signatureModalLabel">
                                    <i class="fa fa-edit me-2"/>Digital Signature
                                </h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>
                            <div class="modal-body">
                                <t t-call="portal.signature_form">
                                    <t t-set="call_url" t-value="'/my/account/signature/save'"/>
                                    <t t-set="default_name" t-value="request.env.user.name"/>
                                    <t t-set="mode" t-value="'draw'"/>
                                </t>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xpath>
</template>
```

### 3. Controller Implementation

#### JSON RPC Endpoint (Required)

The signature component expects a JSON RPC endpoint to save signature data:

```python
# controllers/signature.py
from odoo import http
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal

class SignaturePortal(CustomerPortal):

    @http.route(['/my/account/signature/save'], type='json', auth='user', website=True)
    def portal_signature_save_json(self, name, signature):
        """Save user signature via JSON RPC (used by standard signature widget)

        Args:
            name: Signer name (required by widget but not used here)
            signature: Base64 encoded signature image
        """
        try:
            partner = request.env.user.partner_id
            if not partner:
                return {'error': 'No partner found for current user'}

            if not signature:
                return {'error': 'No signature provided'}

            # Update partner signature
            partner.sudo().write({
                'signature': signature,
            })

            return {
                'force_refresh': True,
                'message': 'Signature updated successfully!',
            }

        except Exception as e:
            return {'error': str(e)}
```

#### HTTP Endpoint (Alternative)

For custom implementations, you can also use HTTP endpoints:

```python
@http.route(['/my/signature/save'], type='http', auth='user', website=True, methods=['POST'])
def portal_signature_save_http(self, **post):
    """HTTP endpoint for signature saving"""
    try:
        signature_data = post.get('signature_data')
        if not signature_data:
            return request.redirect('/my/account?error=no_signature')

        partner = request.env.user.partner_id
        partner.sudo().write({'signature': signature_data})

        return request.redirect('/my/account?success=signature_saved')

    except Exception as e:
        return request.redirect('/my/account?error=save_error')
```

### 4. Configuration Options

#### Available Template Variables

```xml
<t t-call="portal.signature_form">
    <!-- Required -->
    <t t-set="call_url" t-value="'/my/signature/save'"/>           <!-- Save endpoint -->
    <t t-set="default_name" t-value="request.env.user.name"/>     <!-- Default signer name -->

    <!-- Optional -->
    <t t-set="mode" t-value="'draw'"/>                            <!-- Default mode: auto|draw|load -->
    <t t-set="send_label" t-value="'Update Signature'"/>         <!-- Button text -->
    <t t-set="signature_ratio" t-value="3"/>                     <!-- Width/height ratio -->
    <t t-set="signature_type" t-value="'signature'"/>            <!-- Type: signature|initial -->
    <t t-set="font_color" t-value="'blue'"/>                     <!-- Signature color -->
</t>
```

#### Mode Selection Logic

The component automatically selects the default mode based on this logic:

```javascript
// From name_and_signature.js
signMode: this.props.mode || (this.props.noInputName && !this.defaultName ? "draw" : "auto")
```

**Recommendation**: Always explicitly set `mode="draw"` for better UX.

### 5. Integration Best Practices

#### ✅ Do: Modal Approach

**Benefits**:
- Better UX on mobile devices
- Doesn't clutter the main page
- Ensures proper component initialization
- Consistent with Odoo patterns (quotations, contracts)

#### ✅ Do: Set Draw as Default

```xml
<t t-set="mode" t-value="'draw'"/>
```

**Reason**: Drawing is more intuitive for most users than auto-generated text signatures.

#### ✅ Do: Show Current Signature

Always display the current signature if it exists:

```xml
<div t-if="request.env.user.partner_id.signature" class="form-group mb-3">
    <label class="form-label">Current Signature</label>
    <div class="current-signature mb-3">
        <img t-att-src="'/web/image/res.partner/%s/signature' % request.env.user.partner_id.id"
             style="max-height: 100px; border: 1px solid #ddd; padding: 10px;"/>
    </div>
</div>
```

#### ✅ Do: Use JSON RPC Endpoints

The standard signature widget expects JSON RPC responses:

```python
return {
    'force_refresh': True,        # Refresh page after save
    'message': 'Success message', # Optional success message
    'error': 'Error message',     # Optional error message
}
```

#### ❌ Don't: Try to Remove Auto Mode

The Auto/Draw/Load modes are part of the standard Odoo signature widget. Removing them requires:
- Custom widget development (complex)
- Template overrides (maintenance risk)
- Breaking standard Odoo patterns

**Solution**: Set `mode="draw"` as default instead.

#### ❌ Don't: Use Custom JavaScript

The standard signature widget handles all JavaScript interactions. Don't create custom signature JavaScript unless absolutely necessary.

### 6. Common Issues and Solutions

#### Issue: "setSignMode is not defined" Error

**Cause**: Trying to use custom JavaScript with standard widget.

**Solution**: Remove custom JavaScript and use standard widget:

```xml
<!-- WRONG: Custom onclick handlers -->
<a onclick="setSignMode('draw')">Draw</a>

<!-- RIGHT: Use standard widget -->
<t t-call="portal.signature_form">
    <t t-set="mode" t-value="'draw'"/>
</t>
```

#### Issue: Modal Not Loading Widget

**Cause**: OWL component not initializing properly in modal.

**Solution**: The standard widget handles modal initialization automatically. Ensure proper modal structure:

```xml
<div class="modal fade" id="signatureModal">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-body">
                <t t-call="portal.signature_form">
                    <!-- Configuration -->
                </t>
            </div>
        </div>
    </div>
</div>
```

#### Issue: XPath Error "Cannot locate //body"

**Cause**: Trying to append modal to body in inherited template.

**Solution**: Add modal inside the same container:

```xml
<!-- WRONG -->
<xpath expr="//body" position="inside">
    <div class="modal">...</div>
</xpath>

<!-- RIGHT -->
<xpath expr="//div[@class='clearfix text-end mb-5']" position="before">
    <!-- Content and modal here -->
    <div class="modal">...</div>
</xpath>
```

### 7. Testing Signature Integration

#### Test Checklist

- [ ] **Modal opens correctly** when button is clicked
- [ ] **Default mode is Draw** (canvas visible, not auto text)
- [ ] **All three modes work**: Auto, Draw, Load
- [ ] **Signature saves successfully** via JSON RPC
- [ ] **Page refreshes** after successful save
- [ ] **Current signature displays** if exists
- [ ] **Error handling works** for invalid signatures
- [ ] **Mobile compatibility** - touch drawing works
- [ ] **No JavaScript errors** in browser console

#### Manual Testing Steps

1. **Open portal page** with signature integration
2. **Click signature button** → Modal should open
3. **Test Draw mode**: Draw signature with mouse/touch
4. **Test Auto mode**: Type name, select font
5. **Test Load mode**: Upload image file
6. **Submit signature** → Should save and refresh page
7. **Verify signature appears** in current signature section
8. **Test on mobile device** for touch compatibility

### 8. Advanced Integration Examples

#### Certificate Generation with Signature

```xml
<!-- Certificate template with signature -->
<template id="certificate_with_signature">
    <div class="certificate">
        <div class="certificate-content">
            <h1>Certificate of Completion</h1>
            <p>This certifies that <strong t-field="certificate.student_name"/> has completed...</p>
        </div>

        <!-- Signature area (bottom-aligned to prevent layout shifts) -->
        <div class="signature-area" style="position: absolute; bottom: 50px; right: 50px;">
            <div t-if="certificate.signature" class="signature-container">
                <img t-att-src="'/web/image/certificate/%s/signature' % certificate.id"
                     style="max-height: 80px; max-width: 200px;"/>
                <div class="signature-line" style="border-top: 1px solid #000; margin-top: 5px; text-align: center;">
                    <small>Digital Signature</small>
                </div>
            </div>
            <div t-else="" class="signature-placeholder" style="height: 80px; width: 200px; border: 1px dashed #ccc;">
                <small class="text-muted">Signature will appear here</small>
            </div>
        </div>
    </div>
</template>
```

#### Multi-Step Form with Signature

```xml
<!-- Final step of multi-step form -->
<template id="application_final_step">
    <div class="step-content">
        <h3>Step 4: Digital Signature</h3>
        <p>Please provide your digital signature to complete the application.</p>

        <div class="signature-section">
            <t t-call="portal.signature_form">
                <t t-set="call_url" t-value="'/my/application/sign'"/>
                <t t-set="default_name" t-value="application.applicant_name"/>
                <t t-set="mode" t-value="'draw'"/>
                <t t-set="send_label" t-value="'Complete Application'"/>
            </t>
        </div>

        <div class="form-actions mt-4">
            <a href="/my/application/step/3" class="btn btn-secondary">Previous</a>
            <!-- Submit handled by signature widget -->
        </div>
    </div>
</template>
```

### 9. Signature Component Summary

The Odoo signature component provides a robust, tested solution for capturing digital signatures in portal applications. Key takeaways:

- **✅ Use standard `portal.signature_form` template** - Don't reinvent the wheel
- **✅ Implement JSON RPC endpoints** - Required for proper widget function
- **✅ Set Draw as default mode** - Better user experience
- **✅ Use modal approach** - Better UX and mobile compatibility
- **✅ Show current signatures** - Users need to see existing signatures
- **❌ Don't customize core widget** - Maintenance nightmare
- **❌ Don't remove standard modes** - Keep Auto/Draw/Load available

This approach ensures consistency with Odoo standards, reduces maintenance overhead, and provides users with a familiar signature experience across all Odoo applications.

## Internal User Access in Portal Modules

### 10. Portal Access for Internal Users (Employees)

When developing portal modules, it's crucial to consider whether internal users (employees with `base.group_user`) should have access to portal functionality. By default, portal modules are designed for external users (`base.group_portal`), but internal users may also need submission capabilities.

#### ✅ Security Configuration for Internal Users

**Problem**: Internal users cannot access portal submission forms due to missing security rules.

**Solution**: Add explicit access rights for `base.group_user` in both model access and record rules.

#### Model Access Rights (`security/ir.model.access.csv`)
```csv
# Add internal user access alongside portal access
access_model_portal,model.portal,model_your_model,base.group_portal,1,0,1,0
access_model_user,model.user,model_your_model,base.group_user,1,0,1,0
```

#### Record Rules (`security/security.xml`)
```xml
<!-- Portal User: Own submissions only -->
<record id="rule_model_portal" model="ir.rule">
    <field name="name">Model Portal: Own Submissions</field>
    <field name="model_id" ref="model_your_model"/>
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('base.group_portal'))]"/>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="False"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="False"/>
</record>

<!-- Internal User: Own submissions only -->
<record id="rule_model_user" model="ir.rule">
    <field name="name">Model User: Own Submissions</field>
    <field name="model_id" ref="model_your_model"/>
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('base.group_user'))]"/>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="False"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="False"/>
</record>
```

#### ✅ Related Model Access
Don't forget to add access for related models (styles, categories, etc.):

```csv
# Related models access for internal users
access_style_user,style.user,model_your_style,base.group_user,1,0,0,0
access_category_user,category.user,model_your_category,base.group_user,1,0,0,0
```

#### ✅ Controller Considerations
Portal controllers with `auth="user"` work for both portal and internal users, but ensure proper access validation:

```python
@http.route(['/my/submit-form'], type='http', auth="user", website=True)
def submit_form(self, **kw):
    """Accessible by both portal and internal users"""
    # Controller logic works for both user types
    # Model-level security handles access control
    pass
```

## Portal Translation Issues with Loops

### 1. The Problem: t-foreach Loops Don't Work with Translations

When creating portal templates with selection fields or dynamic content, using `t-foreach` loops can break the translation system. This is a **known Odoo limitation** where dynamic content generation prevents the translation engine from properly identifying and translating strings.

#### ❌ Problematic Pattern: Using t-foreach for Selection Fields

```xml
<!-- DON'T DO THIS - Translations won't work -->
<template id="portal_rating_form_bad" name="Rating Form">
    <div class="rating-options">
        <t t-foreach="[('5', '5 - Excellent'), ('4', '4 - Good'), ('3', '3 - Average')]" t-as="rating_option">
            <div class="form-check">
                <input class="form-check-input" type="radio"
                       name="rating"
                       t-att-value="rating_option[0]"/>
                <label class="form-check-label">
                    <t t-out="rating_option[1]"/>  <!-- This won't be translated -->
                </label>
            </div>
        </t>
    </div>
</template>
```

**Why this fails:**
- The translation system can't detect strings inside dynamic loops
- `t-out` with dynamic content bypasses translation context
- Even with proper `.po` file entries, translations won't appear in portal

#### ❌ Also Problematic: Controller-Passed Selection Options

```python
# DON'T DO THIS - Still won't work with translations
def portal_form(self, **kw):
    rating_model = request.env['your.model']
    rating_options = dict(rating_model._fields['rating'].selection)

    values = {
        'rating_options': rating_options,  # Won't be translated in portal
    }
    return request.render("template", values)
```

```xml
<!-- This also fails -->
<t t-foreach="rating_options.items()" t-as="option">
    <label><t t-out="option[1]"/></label>  <!-- Not translated -->
</t>
```

### 2. The Solution: Hardcode Selection Values in Templates

The recommended approach is to **hardcode selection values directly in the template** and let Odoo's translation system handle them naturally.

#### ✅ Correct Pattern: Hardcoded Selection Values

```xml
<!-- DO THIS - Translations work properly -->
<template id="portal_rating_form_good" name="Rating Form">
    <div class="rating-options">
        <div class="form-check">
            <input class="form-check-input" type="radio"
                   name="rating"
                   value="5"/>
            <label class="form-check-label">
                5 - Excellent  <!-- This gets translated -->
            </label>
        </div>
        <div class="form-check">
            <input class="form-check-input" type="radio"
                   name="rating"
                   value="4"/>
            <label class="form-check-label">
                4 - Good  <!-- This gets translated -->
            </label>
        </div>
        <div class="form-check">
            <input class="form-check-input" type="radio"
                   name="rating"
                   value="3"/>
            <label class="form-check-label">
                3 - Average  <!-- This gets translated -->
            </label>
        </div>
    </div>
</template>
```

### 3. Translation Workflow for Hardcoded Values

#### Step 1: Update Module and Regenerate Translations

```bash
# Update module to include template changes
sudo -u odoo /usr/bin/odoo -c /etc/odoo/odoo.conf -d your_db --stop-after-init -u your_module

# Regenerate translation file to include template strings
sudo -u odoo /usr/bin/odoo -c /etc/odoo/odoo.conf -d your_db --stop-after-init \
    --i18n-export=your_module/i18n/ar.po --language=ar_001 --modules=your_module
```

#### Step 2: Verify Translation Entries

Check that your `.po` file contains the template strings:

```po
# your_module/i18n/ar.po
msgid "5 - Excellent"
msgstr "5 - ممتاز"

msgid "4 - Good"
msgstr "4 - جيد"

msgid "3 - Average"
msgstr "3 - متوسط"
```

#### Step 3: Import Translations

```bash
# Import updated translations
sudo -u odoo /usr/bin/odoo -c /etc/odoo/odoo.conf -d your_db --stop-after-init \
    --i18n-import=your_module/i18n/ar.po --language=ar_001 --modules=your_module
```

### 4. When to Use Each Approach

#### ✅ Use Hardcoded Values For:
- **Portal selection fields** (ratings, categories, status options)
- **Portal forms with predefined choices**
- **Any portal content that needs translation**
- **Small, fixed sets of options** (< 10 items)

#### ✅ Use Dynamic Loops For:
- **Backend forms** (translations work normally)
- **Large dynamic datasets** (database records)
- **Content that changes frequently**
- **Non-translatable dynamic content**

### 5. Best Practices for Portal Translations

#### ✅ Template Organization

```xml
<!-- Group related options together -->
<div class="rating-section">
    <h5>Service Rating</h5>
    <div class="rating-options">
        <!-- Hardcoded options here -->
    </div>
</div>

<div class="rating-section">
    <h5>Delivery Rating</h5>
    <div class="rating-options">
        <!-- Hardcoded options here -->
    </div>
</div>
```

#### ✅ Consistent Value Mapping

Ensure your hardcoded template values match your model selection values:

```python
# models/your_model.py
class YourModel(models.Model):
    _name = 'your.model'

    rating = fields.Selection([
        ('5', _('5 - Excellent')),  # Must match template text
        ('4', _('4 - Good')),       # Must match template text
        ('3', _('3 - Average')),    # Must match template text
    ])
```

#### ✅ Translation File Maintenance

- **Keep translations consistent** between model and template
- **Use the same translation keys** for both contexts
- **Test translations** in both backend and portal
- **Document translation requirements** for future developers

### 6. Common Pitfalls and Solutions

#### ❌ Pitfall: Mixed Approaches
```xml
<!-- DON'T MIX - Inconsistent behavior -->
<t t-foreach="some_options" t-as="option">
    <label><t t-out="option[1]"/></label>  <!-- Not translated -->
</t>
<label>Hardcoded Option</label>  <!-- Translated -->
```

#### ✅ Solution: Consistent Approach
```xml
<!-- Use one approach consistently -->
<label>Option 1</label>  <!-- All translated -->
<label>Option 2</label>  <!-- All translated -->
<label>Option 3</label>  <!-- All translated -->
```

#### ❌ Pitfall: Forgetting to Regenerate Translations
- **Problem**: New template strings not in `.po` file
- **Solution**: Always regenerate translations after template changes

#### ❌ Pitfall: Mismatched Values
- **Problem**: Template text doesn't match model selection values
- **Solution**: Keep model and template values synchronized

### 7. Portal Translation Checklist

Before implementing portal forms with selections:

- [ ] **Avoid `t-foreach` loops** for selection fields in portal templates
- [ ] **Hardcode selection values** directly in template
- [ ] **Match template text** with model selection values
- [ ] **Regenerate translation files** after template changes
- [ ] **Test translations** in portal (not just backend)
- [ ] **Document translation approach** for future maintenance
- [ ] **Use consistent translation keys** across model and template

### 11. Odoo Standard: Controller vs Record Rules Architecture

Based on analysis of Odoo's core codebase (sale, account, portal modules), the standard pattern is a **hybrid approach** combining controller domain filtering with record rules for security.

#### ✅ Odoo's Three-Layer Architecture

**Layer 1: Controller Domain Filtering** (Performance + Business Logic)
```python
# From Odoo core: sale/controllers/portal.py
def _prepare_orders_domain(self, partner):
    return [
        ('message_partner_ids', 'child_of', [partner.commercial_partner_id.id]),
        ('state', '=', 'sale'),
    ]
```

**Layer 2: Record Rules** (Security Enforcement)
```xml
<!-- From Odoo core: sale/security/ir_rules.xml -->
<record id="sale_order_rule_portal" model="ir.rule">
    <field name="name">Portal Personal Quotations/Sales Orders</field>
    <field name="domain_force">[('message_partner_ids','child_of',[user.commercial_partner_id.id])]</field>
    <field name="groups" eval="[(4, ref('base.group_portal'))]"/>
</record>
```

**Layer 3: Individual Access Check** (Document-level Security)
```python
# From Odoo core: portal/controllers/portal.py
def _document_check_access(self, model_name, document_id, access_token=None):
    document = request.env[model_name].browse([document_id])
    try:
        document.check_access_rights('read')
        document.check_access_rule('read')  # ← Relies on record rules!
    except AccessError:
        # Handle access token fallback
        raise
```

#### ✅ Cross-User Access Patterns (Odoo Standard)

Odoo supports complex business scenarios through proper domain construction:

**Scenario 1: Team Lead Access**
```python
def _get_domain(self, partner):
    domain = [('user_id', '=', request.env.user.id)]  # Base access

    # Business extension: Team lead can access team submissions
    if request.env.user.has_group('your_module.group_team_lead'):
        domain = [
            '|',
            ('user_id', '=', request.env.user.id),
            ('team_lead_id', '=', request.env.user.id)
        ]
    return domain
```

**Scenario 2: Commercial Partner Access (Odoo Sale Pattern)**
```python
# Odoo's approach: child_of for hierarchical access
domain = [('message_partner_ids', 'child_of', [partner.commercial_partner_id.id])]
```

**Scenario 3: Delegate/Shared Access**
```python
def _get_domain(self, partner):
    return [
        '|',
        ('user_id', '=', request.env.user.id),  # Own records
        ('delegate_user_ids', 'in', request.env.user.id)  # Delegated access
    ]
```

#### ✅ When to Use Each Layer

**Controller Domain Filtering**: Use for
- Performance optimization (avoid loading unnecessary records)
- Business logic filtering (status, date ranges, categories)
- User experience (showing relevant subsets)
- List views and counters

**Record Rules**: Use for
- Security boundaries (final access control layer)
- Cross-module consistency (same rules apply everywhere)
- API access (automatic enforcement)
- Individual record protection

**Document Check Access**: Use for
- Detail views and downloads
- Access token support
- Single record operations
- Portal sharing scenarios

#### ❌ Common Pitfalls
1. **Missing `base.group_user` access**: Internal users get access denied errors
2. **Incomplete related model access**: Form dropdowns fail to load
3. **Assuming portal-only usage**: Not considering internal user workflows
4. **Controller-only filtering**: Bypassing security through API access
5. **Record-rules-only approach**: Poor performance on large datasets

#### ✅ Testing Internal User Access
Always test with both user types:

1. **Portal User Test**: External user with `base.group_portal`
2. **Internal User Test**: Employee with `base.group_user`
3. **Reviewer Test**: User with module-specific reviewer groups

#### ✅ Access Validation Checklist
- [ ] Model access rights include `base.group_user`
- [ ] Record rules defined for `base.group_user`
- [ ] Related models accessible to `base.group_user`
- [ ] Controllers handle both user types properly
- [ ] Testing completed with different user types
- [ ] Cross-user scenarios properly implemented
- [ ] Performance tested with large datasets

#### Example: Calligraphy Correction Module
The calligraphy correction module initially only supported portal users. The fix required:

```csv
# Added to ir.model.access.csv
access_calligraphy_correction_user,uac.calligraphy.correction.user,model_uac_calligraphy_correction,base.group_user,1,0,1,0
access_calligraphy_style_user,uac.calligraphy.style.user,model_uac_calligraphy_style,base.group_user,1,0,0,0
access_calligraphy_purpose_user,uac.calligraphy.purpose.user,model_uac_calligraphy_purpose,base.group_user,1,0,0,0
```

```xml
<!-- Added to security.xml -->
<record id="rule_calligraphy_user" model="ir.rule">
    <field name="name">Calligraphy User: Own Submissions</field>
    <field name="model_id" ref="model_uac_calligraphy_correction"/>
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('base.group_user'))]"/>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="False"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="False"/>
</record>
```

This follows Odoo's standard hybrid approach: controller filtering for performance, record rules for security, and `_document_check_access` for individual records.
