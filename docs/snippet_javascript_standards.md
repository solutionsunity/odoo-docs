# Website Snippet JavaScript Standards for Odoo 17+

## Overview

This document outlines the JavaScript coding standards for **website snippets** in Odoo 17+. This is specifically for snippet development and complements `docs/frontend.md` which covers portal/website development patterns.

**Scope**: This document covers website snippets only. For portal development, form validation, and general frontend patterns, see `docs/frontend.md`.

## 🚨 **CRITICAL WARNING: Data Processing Preservation**

**THE MOST CRITICAL ISSUE** when refactoring snippet JavaScript is **preserving complex data processing logic**.

### **Common Refactoring Mistake**

When converting from `DOMContentLoaded` to `publicWidget` pattern, developers often:

1. ✅ **Successfully convert** initialization and event handling
2. ✅ **Successfully convert** UI/UX and styling patterns
3. ❌ **LOSE CRITICAL DATA PROCESSING LOGIC** that makes tools functional

### **Example: QR Code Studio Regression**

**Before Refactoring (Working):**
```javascript
function generateQR(type) {
    switch(type) {
        case 'contact': value = generateContactVCard(); break;  // ✅ Proper vCard format
        case 'wifi': value = generateWiFi(); break;             // ✅ Proper WiFi string
        case 'sms': value = generateSMS(); break;               // ✅ Proper SMS format
        // ... 15+ different QR types with proper formatting
    }
}

function generateContactVCard() {
    // Collects 14+ fields and formats as proper vCard
    return `BEGIN:VCARD\nVERSION:3.0\nN:${lastName};${firstName}...`;
}
```

**After Refactoring (Broken):**
```javascript
_getQRDataFromActiveTab: function () {
    const urlInput = activeTab.querySelector('#url-input');
    if (urlInput && urlInput.value.trim()) {
        return urlInput.value.trim(); // ❌ Just returns raw text!
    }
}
```

**Result**: QR codes contain incomplete/incorrect data instead of properly formatted structures.

### **Prevention Checklist**

When refactoring snippet JavaScript:

1. ✅ **Inventory all data processing functions** before starting
2. ✅ **Document complex formatting logic** (vCard, WiFi, SMS, etc.)
3. ✅ **Test all tool functionality** after conversion
4. ✅ **Verify data output formats** match original implementation
5. ✅ **Check tab-specific processing** for multi-tab tools

## 🎯 **Website Snippet JavaScript Patterns**

Odoo 17+ has **specific patterns** for website snippet JavaScript:

### **✅ FOR WEBSITE SNIPPETS (REQUIRED - Odoo Standard)**

**ALL snippet JavaScript files MUST use the `publicWidget` pattern**. This is how Odoo core handles snippet JavaScript:

```javascript
/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";

const ToolNameWidget = publicWidget.Widget.extend({
    selector: '.s_tool_name, #tool-container',  // CRITICAL: Must match snippet selectors
    disabledInEditableMode: false,

    /**
     * @override
     */
    start: function () {
        // Tool initialization code here
        // Widget only initializes when selector is found on page
        this._initializeTool();
        return this._super(...arguments);
    },

    /**
     * @override
     */
    destroy: function () {
        // Cleanup code here
        this._cleanup();
        this._super(...arguments);
    },

    //--------------------------------------------------------------------------
    // Private
    //--------------------------------------------------------------------------

    _initializeTool: function () {
        // Your tool logic here
        // No need to check if container exists - widget handles this
    },

    _cleanup: function () {
        // Cleanup intervals, event listeners, etc.
    },
});

// Register the widget (REQUIRED)
publicWidget.registry.toolName = ToolNameWidget;
export default ToolNameWidget;
```

**Key Benefits of `publicWidget` Pattern:**
- ✅ **Conditional Initialization**: Only runs when selector is found on page
- ✅ **No Console Errors**: Gracefully handles missing containers
- ✅ **Odoo Standard**: Follows exact pattern used by core snippets
- ✅ **Automatic Cleanup**: Proper widget lifecycle management
- ✅ **Editor Compatible**: Works seamlessly with website editor

### **✅ FOR UTILITY/COMMON SCRIPTS ONLY (Non-Snippets)**

**ONLY for truly global utilities** (not snippet-specific code):

```javascript
/** @odoo-module **/

document.addEventListener('DOMContentLoaded', () => {
    'use strict';

    // ONLY for global utilities like tool_usage_tracker.js
    window.UACTools = window.UACTools || {};

    UACTools.Utils = {
        // Global utility functions
    };
});
```

## 📊 **Centralized Logging System (RECOMMENDED)**

### **✅ Preferred Logging Mechanism**

All JavaScript files should implement a centralized logging system that respects debug mode:

```javascript
/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";

const ToolWidget = publicWidget.Widget.extend({
    selector: ".s_uac_tool",

    // Debug mode detection
    debugMode: false,

    /**
     * Centralized logging system that respects debug parameter
     * @param {string} level - Log level: 'info', 'warn', 'error'
     * @param {string} message - Log message
     * @param {...any} args - Additional arguments
     */
    log: function(level, message, ...args) {
        const prefix = '[ToolName]';

        switch(level) {
            case 'info':
                // Only show info logs when debug mode is enabled
                if (this.debugMode) {
                    console.log(`${prefix} ${message}`, ...args);
                }
                break;
            case 'warn':
                // Always show warnings
                console.warn(`${prefix} WARNING: ${message}`, ...args);
                break;
            case 'error':
                // Always show errors
                console.error(`${prefix} ERROR: ${message}`, ...args);
                break;
            default:
                // Default to info level
                if (this.debugMode) {
                    console.log(`${prefix} ${message}`, ...args);
                }
        }
    },

    start: function () {
        // Detect debug mode from URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        const debugParam = urlParams.get('debug');
        this.debugMode = debugParam && debugParam !== '0';

        this.log('info', 'Tool initialization started', { debugMode: this.debugMode });

        // Tool initialization logic
        this._initializeTool();

        this.log('info', 'Tool initialization completed');
        return this._super.apply(this, arguments);
    },

    _initializeTool: function() {
        this.log('info', 'Setting up tool components...');
        // Tool setup logic
    },

    _handleError: function(error, context) {
        this.log('error', 'Tool error occurred', { error, context });
        // Error handling logic
    }
});

publicWidget.registry.ToolWidget = ToolWidget;
export default ToolWidget;
```

### **🎯 Logging Benefits**

1. **✅ Production Clean**: No console output in production (only warnings/errors)
2. **✅ Debug Mode**: Detailed logs when `?debug=1` or `?debug=assets` in URL
3. **✅ Consistent Format**: All logs have `[ToolName]` prefix for easy filtering
4. **✅ Smart Filtering**: Info logs only shown when debugging needed
5. **✅ Error Visibility**: Critical errors always visible for troubleshooting

### **📝 Usage Examples**

```javascript
// Info logging (only shown in debug mode)
this.log('info', 'Canvas setup complete', { width: 800, height: 600 });

// Warning logging (always shown)
this.log('warn', 'Failed to load background image for export');

// Error logging (always shown)
this.log('error', 'Canvas element not found');
```

### **🔧 Debug Mode Activation**

- **Normal mode**: `http://localhost:8069/page` - Only warnings and errors
- **Debug mode**: `http://localhost:8069/page?debug=1` - All logs including info
- **Assets debug**: `http://localhost:8069/page?debug=assets` - All logs including info

## 🛠️ **Centralized Logger Utility (ADVANCED)**

### **✅ Module-Wide Logging Utility**

For modules with multiple tools, use the centralized logger utility:

```javascript
/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";
import { createLogger } from "@uac_website_tools/js/utils/logger";

const ToolWidget = publicWidget.Widget.extend({
    selector: ".s_uac_tool",

    start: function () {
        // Create logger instance for this tool
        this.logger = createLogger('ToolName');

        this.logger.info('Tool initialization started');
        this._initializeTool();
        this.logger.info('Tool initialization completed');

        return this._super.apply(this, arguments);
    },

    _initializeTool: function() {
        this.logger.info('Setting up tool components...');
        // Tool setup logic
    },

    _handleError: function(error, context) {
        this.logger.error('Tool error occurred', { error, context });
        // Error handling logic
    }
});

publicWidget.registry.ToolWidget = ToolWidget;
export default ToolWidget;
```

### **🎯 Centralized Logger Benefits**

1. **✅ Consistent Interface**: Same logging API across all tools
2. **✅ Shared Configuration**: Debug mode detection handled centrally
3. **✅ Performance**: Single logger instance per tool
4. **✅ Advanced Features**: Child loggers, timing, grouping, data logging
5. **✅ Maintainability**: Easy to update logging behavior module-wide

### **📝 Advanced Logger Features**

```javascript
// Create child logger for specific component
const canvasLogger = this.logger.child('Canvas');
canvasLogger.info('Canvas setup started');

// Performance timing
const startTime = performance.now();
// ... operation ...
const endTime = performance.now();
this.logger.timing('Canvas initialization', startTime, endTime);

// Data logging with pretty formatting
this.logger.data('Canvas configuration', { width: 800, height: 600 });

// Grouped logging
this.logger.group('Touch Event Processing', () => {
    this.logger.info('Processing touch start');
    this.logger.info('Calculating touch positions');
    this.logger.info('Touch processing complete');
});
```

### **🔧 Logger Asset Loading**

The logger utility is automatically loaded via `ir.asset` record:

```xml
<record id="uac_website_tools.logger_utility_js" model="ir.asset">
    <field name="name">UAC Logger Utility</field>
    <field name="bundle">web.assets_frontend</field>
    <field name="path">uac_website_tools/static/src/js/utils/logger.js</field>
</record>
```

## 📋 **Logging Best Practices Summary**

### **✅ Recommended Approaches**

1. **For New Modules**: Use centralized logger utility (`createLogger`)
2. **For Single Tools**: Use widget-based logging (inline `log` method)
3. **For Module Refactoring**: Migrate to centralized logger utility

### **🎯 Implementation Decision Matrix**

| Scenario | Recommended Approach | Reason |
|----------|---------------------|---------|
| **New module with multiple tools** | Centralized Logger Utility | Consistency, maintainability |
| **Single tool/widget** | Widget-based logging | Simplicity, self-contained |
| **Existing module refactoring** | Centralized Logger Utility | Standardization, advanced features |
| **Quick prototyping** | Widget-based logging | Faster implementation |

### **🔄 Migration Path**

To migrate from widget-based to centralized logging:

```javascript
// 1. Add import
import { createLogger } from "@uac_website_tools/js/utils/logger";

// 2. Replace debugMode and log method with logger instance
// OLD:
debugMode: false,
log: function(level, message, ...args) { /* ... */ }

// NEW:
logger: null,

// 3. Initialize logger in start() or _initialize()
start: function() {
    this.logger = createLogger('ToolName');
    // ...
}

// 4. Replace all log calls
// OLD: this.log('info', 'message');
// NEW: this.logger.info('message');
```

## 🖥️ **Fullscreen API Implementation**

### **✅ Proper Fullscreen Handling**

Fullscreen functionality requires careful handling due to browser security restrictions and promise behavior quirks.

```javascript
/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";

const FullscreenWidget = publicWidget.Widget.extend({
    selector: ".s_uac_tool",

    /**
     * Robust fullscreen toggle that handles browser security quirks
     */
    _toggleFullscreen: function() {
        const container = this.el || document.getElementById("container-id");
        if (!container) {
            this.logger && this.logger.info('Container not found for fullscreen');
            return;
        }

        const isFullscreen = !!(document.fullscreenElement || document.webkitFullscreenElement ||
                               document.mozFullScreenElement || document.msFullscreenElement);

        if (isFullscreen) {
            // Exit fullscreen
            const exitFullscreen = document.exitFullscreen || document.webkitExitFullscreen ||
                                  document.mozCancelFullScreen || document.msExitFullscreen;
            if (exitFullscreen) {
                this.logger && this.logger.info('Exiting fullscreen mode');
                exitFullscreen.call(document);
            }
        } else {
            // Enter fullscreen
            const requestFullscreen = container.requestFullscreen || container.webkitRequestFullscreen ||
                                     container.mozRequestFullScreen || container.msRequestFullscreen;
            if (requestFullscreen) {
                this.logger && this.logger.info('Entering fullscreen mode');

                requestFullscreen.call(container).then(() => {
                    // Promise resolved - fullscreen worked normally
                    container.classList.add("fullscreen");
                    this.logger && this.logger.info('Fullscreen entered successfully');
                }).catch(() => {
                    // Browser quirk: promise may reject even when fullscreen works
                    // Check actual fullscreen state after a brief delay
                    setTimeout(() => {
                        const isActuallyFullscreen = !!(document.fullscreenElement || document.webkitFullscreenElement ||
                                                       document.mozFullScreenElement || document.msFullscreenElement);
                        if (isActuallyFullscreen) {
                            container.classList.add("fullscreen");
                            this.logger && this.logger.info('Fullscreen entered successfully');
                        } else {
                            this.logger && this.logger.warn('Fullscreen request failed');
                        }
                    }, 100);
                });
            }
        }
    },

    _setupFullscreenHandlers: function() {
        const self = this;

        // Use direct onclick for maximum browser compatibility with user gestures
        const fullscreenBtn = document.querySelector("#fullscreen-btn");
        if (fullscreenBtn) {
            fullscreenBtn.onclick = () => self._toggleFullscreen();
        }

        // Sync CSS classes with browser fullscreen state (ESC key exits are handled by browser)
        const fullscreenEvents = ["fullscreenchange", "webkitfullscreenchange", "mozfullscreenchange", "MSFullscreenChange"];

        fullscreenEvents.forEach(event => {
            document.addEventListener(event, () => {
                const container = self.el || document.getElementById("container-id");
                if (!container) return;

                const isFullscreen = !!(document.fullscreenElement || document.webkitFullscreenElement ||
                                       document.mozFullScreenElement || document.msFullscreenElement);

                // Keep CSS classes in sync with browser fullscreen state
                if (isFullscreen) {
                    container.classList.add("fullscreen");
                } else {
                    container.classList.remove("fullscreen");
                }
            });
        });
    }
});
```

### **🎯 Fullscreen Best Practices**

#### **1. User Gesture Requirement**
```javascript
// ✅ CORRECT: Direct onclick handler preserves user gesture
fullscreenBtn.onclick = () => this._toggleFullscreen();

// ❌ WRONG: Complex event handling may break user gesture chain
fullscreenBtn.addEventListener("click", function(event) {
    event.preventDefault();
    event.stopPropagation();
    // Complex logic here breaks gesture context
    this._toggleFullscreen();
});
```

#### **2. Promise Handling (Critical)**
```javascript
// ✅ CORRECT: Handle browser quirks where promise rejects but fullscreen works
requestFullscreen.call(container).then(() => {
    container.classList.add("fullscreen");
}).catch(() => {
    // Check if fullscreen actually worked despite promise rejection
    setTimeout(() => {
        const isActuallyFullscreen = !!(document.fullscreenElement || /* vendor prefixes */);
        if (isActuallyFullscreen) {
            container.classList.add("fullscreen");
        }
    }, 100);
});

// ❌ WRONG: Immediate CSS class addition without waiting for promise
requestFullscreen.call(container);
container.classList.add("fullscreen"); // Timing issues
```

#### **3. ESC Key Handling**
```javascript
// ✅ CORRECT: Browser handles ESC automatically, we just sync CSS classes
const fullscreenEvents = ["fullscreenchange", "webkitfullscreenchange", "mozfullscreenchange", "MSFullscreenChange"];
fullscreenEvents.forEach(event => {
    document.addEventListener(event, () => {
        // Sync CSS classes with browser state
        if (document.fullscreenElement) {
            container.classList.add("fullscreen");
        } else {
            container.classList.remove("fullscreen");
        }
    });
});

// ❌ WRONG: Trying to handle ESC key manually
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // Don't do this - browser handles ESC automatically
    }
});
```

### **🔧 Common Fullscreen Issues & Solutions**

| **Issue** | **Cause** | **Solution** |
|-----------|-----------|--------------|
| "User gesture required" error | Complex event handling | Use direct `onclick` assignment |
| Promise rejects but fullscreen works | Browser security quirk | Check actual state in `.catch()` |
| CSS classes out of sync | Not listening to fullscreen events | Use fullscreen change event listeners |
| Duplicate fullscreen requests | Multiple event handlers | Ensure single widget instance |
| ESC key not working | Custom ESC handling | Let browser handle ESC automatically |

### **⚠️ Fullscreen Security Notes**

1. **User Gesture Required**: Fullscreen API can only be called from direct user interactions
2. **Browser Differences**: Some browsers reject promises even when fullscreen works
3. **ESC Key**: Browser automatically handles ESC key - don't override this behavior
4. **CSS Synchronization**: Always sync CSS classes with actual fullscreen state
5. **Vendor Prefixes**: Still needed for cross-browser compatibility

### ❌ CRITICAL: Deprecated Patterns (DO NOT USE)

```javascript
// ❌ DOMContentLoaded for Snippets (WRONG - causes console errors)
document.addEventListener('DOMContentLoaded', () => {
    const container = document.getElementById('tool-container');
    if (!container) {
        console.warn('Container not found'); // ❌ Runs on every page!
        return;
    }
    // Tool initialization
});

// ❌ IIFE Pattern (Old approach)
(function() {
    'use strict';
    // code
})();

// ❌ Odoo 15 Pattern (Outdated)
odoo.define('module.name', function (require) {
    // code
});
```

**Why DOMContentLoaded is wrong for snippets:**
- ❌ **Runs on every page** (even when snippet isn't present)
- ❌ **Causes console errors** when containers don't exist
- ❌ **Not Odoo standard** for snippet JavaScript
- ❌ **Poor performance** (unnecessary initialization)

## 🚨 Critical Rules

### 1. Module Declaration
- **ALWAYS** start with `/** @odoo-module **/`
- **NO** IIFE patterns `(function() {})()`
- **NO** `odoo.define()` (Odoo 15 legacy)

### 2. Widget Pattern (For Snippets)
- **USE** `publicWidget.Widget.extend()` for website snippets
- **REGISTER** with `publicWidget.registry.toolName = Widget`
- **EXPORT** the widget: `export default Widget`
- **SELECTOR** should target snippet classes/IDs

### 3. Naming Conventions (Organization-Specific)
- **TEMPLATE IDs**: Use `s_<ORG>_<tool_name>` format
  - Examples: `s_uac_qr_code_studio`, `s_su_contact_form`, `s_company_calculator`
- **CSS CLASSES**: Use `s_<ORG>_<tool_name>_<element>` format
  - Examples: `.s_uac_qr_canvas`, `.s_su_form_container`, `.s_company_calc_result`
- **WIDGET SELECTORS**: Target organization-specific classes
  - Examples: `.s_uac_qr_code_studio`, `.s_su_contact_form`
- **ASSET IDs**: Use `<module_name>.<tool_name>_<type>` format
  - Examples: `uac_website_tools.qr_code_studio_js`, `su_tools.contact_form_css`

**Benefits of Organization Prefixes:**
- ✅ **Unique naming** prevents conflicts between modules
- ✅ **Clear ownership** of snippets and assets
- ✅ **Better organization** in large multi-organization deployments
- ✅ **Easier debugging** with clear naming patterns

### 3. Asset Loading (CRITICAL - UPDATED FINDINGS)
- **❌ NEVER** use `website_assets.xml` files
- **❌ NEVER** load JavaScript in templates with `<script src="..."/>`
- **❌ NEVER** use inline JavaScript in templates
- **❌ NEVER** load snippet-specific assets in `__manifest__.py` bundles
- **✅ ALWAYS** use `ir.asset` records for snippet-specific assets
- **✅ ONLY** use `__manifest__.py` bundles for truly global/common assets
- **✅ ALWAYS** register assets in `web.assets_frontend` bundle

### 4. DOM Ready Handling (Non-Snippets Only)
- **USE** `document.addEventListener('DOMContentLoaded', () => {})` for utilities
- **NO** multiple DOMContentLoaded listeners in same file
- **NO** immediate execution without DOM ready check

### 5. Strict Mode
- **ALWAYS** include `'use strict';` (for non-widget patterns)
- **CONSISTENT** indentation and formatting

## 📁 Asset Loading Patterns

### 🎯 **CRITICAL DISCOVERY: Odoo's Standard Practice**

**After analyzing Odoo core codebase**, we discovered that Odoo's standard practice is:

1. **✅ Snippet-specific assets**: Use `ir.asset` records in snippet XML files
2. **✅ Global/common assets**: Use `__manifest__.py` bundles
3. **❌ NEVER mix both**: Avoid duplicate loading of the same asset

**Evidence from Odoo core** (`/usr/lib/python3/dist-packages/odoo/addons/website/views/snippets/`):
- `s_badge.xml`, `s_alert.xml`, `s_instagram_page.xml` all use `ir.asset` records
- Both CSS and JavaScript files are loaded via `ir.asset` records
- No snippet assets are found in manifest bundles

### ✅ CORRECT: ir.asset Records (For Snippet-Specific Assets)

**In snippet XML files** (e.g., `views/website_snippets.xml`):

```xml
<!-- Snippet definition -->
<template id="snippet_tool_name" name="Tool Name">
    <section class="s_tool_name">
        <!-- Snippet HTML content -->
    </section>
</template>

<!-- Asset registration (ODOO STANDARD PRACTICE) -->
<record id="uac_website_tools.tool_name_js" model="ir.asset">
    <field name="name">Tool Name JS</field>
    <field name="bundle">web.assets_frontend</field>
    <field name="path">uac_website_tools/static/src/js/tool_name.js</field>
</record>

<record id="uac_website_tools.tool_name_css" model="ir.asset">
    <field name="name">Tool Name CSS</field>
    <field name="bundle">web.assets_frontend</field>
    <field name="path">uac_website_tools/static/src/css/tool_name.css</field>
</record>
```

### ✅ CORRECT: Manifest Assets (For Global/Common Utilities Only)

**In `__manifest__.py`** (for truly global utilities):

```python
'assets': {
    'web.assets_frontend': [
        # ONLY truly global/common utilities
        'uac_website_tools/static/src/css/common.css',
        'uac_website_tools/static/src/js/common.js',
        'uac_website_tools/static/src/js/tool_usage_tracker.js',
        # DO NOT include snippet-specific assets here
    ]
}
```

### ❌ WRONG: Template-Based Loading

```xml
<!-- ❌ NEVER DO THIS -->
<template id="wrong_pattern">
    <script src="/path/to/file.js"/>
    <link href="/path/to/file.css"/>
    <script>
        // Inline JavaScript
    </script>
</template>
```

### ❌ CRITICAL ERROR: Duplicate Asset Loading

**The most critical mistake** is loading the same asset in both places:

```python
# ❌ WRONG: In __manifest__.py
'assets': {
    'web.assets_frontend': [
        'uac_website_tools/static/src/css/callidraw.css',  # ❌ DUPLICATE
        'uac_website_tools/static/src/js/callidraw.js',    # ❌ DUPLICATE
    ]
}
```

```xml
<!-- ❌ WRONG: Also in website_snippets.xml -->
<record id="uac_website_tools.callidraw_css" model="ir.asset">
    <field name="bundle">web.assets_frontend</field>
    <field name="path">uac_website_tools/static/src/css/callidraw.css</field>  <!-- ❌ DUPLICATE -->
</record>
```

**This causes:**
- CSS conflicts and broken styling
- JavaScript loading errors
- Website editor failures
- ES6 import statement errors

### ❌ WRONG: website_assets.xml Files

```xml
<!-- ❌ DELETE THESE FILES -->
<template id="assets_tool_name">
    <script src="..."/>
    <link href="..."/>
</template>
```

## ✅ Updated Files

All JavaScript files have been updated to follow Odoo 17 standards:

- ✅ `common.js` - Common utilities
- ✅ `scholarpad.js` - ScholarPad tool (with multi-touch support)
- ✅ `callidraw.js` - CalliDraw tool
- ✅ `callilines.js` - CalliLines PDF generator
- ✅ `callimotion.js` - CalliMotion animation tool
- ✅ `calligraphy_poll.js` - Calligraphy polling system
- ✅ `code_playground.js` - Code playground editor
- ✅ `manuscript_restoration.js` - Manuscript restoration tool
- ✅ `qr_code_studio.js` - QR code generator
- ✅ `svg_animator.js` - SVG animation tool
- ✅ `svg_transformer.js` - SVG transformation tool
- ✅ `calcomp.js` - Calligraphy composition tool

## 🎯 **Tab-Specific Data Processing Patterns**

### **CRITICAL: Complex Tool Data Handling**

Many website tools have multiple tabs with different data formats. **Proper data processing is essential** for tool functionality.

### **Pattern: Tab Detection and Data Processing**

```javascript
const ToolWidget = publicWidget.Widget.extend({
    selector: '.s_org_tool_name',

    /**
     * Get active tab type
     * @private
     */
    _getActiveTabType: function () {
        const container = this.el;
        const activeTab = container.querySelector('.tab-content.active');
        return activeTab ? activeTab.id : 'tab-default';
    },

    /**
     * Get data from active tab with proper formatting
     * @private
     */
    _getDataFromActiveTab: function () {
        const tabType = this._getActiveTabType();

        switch (tabType) {
            case 'tab-contact':
                return this._generateContactVCard();
            case 'tab-wifi':
                return this._generateWiFiString();
            case 'tab-sms':
                return this._generateSMSString();
            case 'tab-email':
                return this._generateEmailString();
            default:
                return this._getSimpleTextData();
        }
    },

    /**
     * Generate vCard format for contact data
     * @private
     */
    _generateContactVCard: function () {
        const container = this.el;
        const firstName = container.querySelector('#contact-first-name')?.value.trim() || '';
        const lastName = container.querySelector('#contact-last-name')?.value.trim() || '';
        const email = container.querySelector('#contact-email')?.value.trim() || '';
        const phone = container.querySelector('#contact-phone')?.value.trim() || '';
        // ... collect all fields

        return `BEGIN:VCARD
VERSION:3.0
N:${lastName};${firstName};;;
FN:${firstName} ${lastName}
EMAIL;TYPE=WORK:${email}
TEL;TYPE=WORK:${phone}
END:VCARD`;
    },

    /**
     * Generate WiFi connection string
     * @private
     */
    _generateWiFiString: function () {
        const container = this.el;
        const ssid = container.querySelector('#wifi-ssid')?.value.trim() || '';
        const security = container.querySelector('#wifi-security')?.value.trim() || 'WPA';
        const password = container.querySelector('#wifi-password')?.value.trim() || '';

        return `WIFI:T:${security};S:${ssid};P:${password};;`;
    },

    /**
     * Generate SMS format
     * @private
     */
    _generateSMSString: function () {
        const container = this.el;
        const phone = container.querySelector('#sms-phone')?.value.trim() || '';
        const message = container.querySelector('#sms-message')?.value.trim() || '';

        return `SMSTO:${phone}:${message}`;
    },
});
```

### **Key Principles for Data Processing**

1. **✅ Tab Detection**: Always detect which tab is active
2. **✅ Format-Specific Processing**: Each data type needs proper formatting
3. **✅ Field Validation**: Validate required fields before processing
4. **✅ Standard Compliance**: Follow protocol standards (vCard, WiFi, SMS, etc.)
5. **✅ Error Handling**: Graceful handling of missing or invalid data

### **Common Data Formats**

- **vCard**: `BEGIN:VCARD\nVERSION:3.0\n...`
- **WiFi**: `WIFI:T:WPA;S:NetworkName;P:password;;`
- **SMS**: `SMSTO:+1234567890:Message text`
- **Email**: `mailto:user@example.com?subject=Subject&body=Body`
- **Phone**: `tel:+1234567890`
- **URL**: `https://example.com` (with validation)

## 🔄 Widget Lifecycle & Best Practices

### Widget Lifecycle Methods

```javascript
const ToolWidget = publicWidget.Widget.extend({
    selector: '.s_tool_name',

    /**
     * Called when widget is initialized
     */
    init: function (parent, options) {
        this._super.apply(this, arguments);
        // Initialize properties
    },

    /**
     * Called when widget starts (DOM ready)
     */
    start: function () {
        // Main initialization logic
        this._setupEventListeners();
        this._initializeCanvas();
        return this._super(...arguments);
    },

    /**
     * Called when widget is destroyed
     */
    destroy: function () {
        // Cleanup: intervals, listeners, etc.
        this._cleanup();
        this._super(...arguments);
    },
});
```

### Best Practices

1. **✅ Proper Cleanup**: Always clear intervals, remove event listeners in `destroy()`
2. **✅ Error Handling**: Wrap initialization in try-catch blocks
3. **✅ Performance**: Use `disabledInEditableMode: false` for editor compatibility
4. **✅ Responsive**: Handle window resize events for canvas-based tools
5. **✅ Accessibility**: Add proper ARIA labels and keyboard support

## 🔄 Snippet JavaScript Conversion Process

### **CRITICAL: Converting DOMContentLoaded to publicWidget**

**Before (WRONG - DOMContentLoaded pattern):**
```javascript
/** @odoo-module **/

document.addEventListener('DOMContentLoaded', () => {
    'use strict';
    initializeTool();
});

function initializeTool() {
    const container = document.getElementById('tool-container');
    if (!container) {
        console.warn('Container not found'); // ❌ Runs on every page!
        return;
    }
    // Tool logic here
}
```

**After (CORRECT - publicWidget pattern):**
```javascript
/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";

const ToolWidget = publicWidget.Widget.extend({
    selector: '#tool-container, .s_tool_name',
    disabledInEditableMode: false,

    start: function () {
        // Tool logic here - no need to check container existence
        this._initializeTool();
        return this._super(...arguments);
    },

    _initializeTool: function () {
        // Your tool logic here
    },
});

publicWidget.registry.toolName = ToolWidget;
export default ToolWidget;
```

### **Migration Checklist**

When converting snippet JavaScript files:

1. **✅ Remove DOMContentLoaded**: Delete all `document.addEventListener('DOMContentLoaded')`
2. **✅ Add publicWidget import**: `import publicWidget from "@web/legacy/js/public/public_widget"`
3. **✅ Convert to Widget**: Use `publicWidget.Widget.extend()`
4. **✅ Set correct selector**: Match snippet CSS classes/IDs
5. **✅ Move logic to start()**: Put initialization in `start()` method
6. **✅ Remove container checks**: Widget handles missing containers
7. **✅ Register widget**: `publicWidget.registry.toolName = Widget`
8. **✅ Export widget**: `export default Widget`
9. **✅ CRITICAL: Preserve data processing**: Ensure all complex formatting logic is maintained
10. **✅ Update CSS selectors**: Synchronize CSS with new class names
11. **✅ Test all functionality**: Verify all tool features work correctly
12. **✅ Test on blank page**: Should not show console errors
13. **✅ Test with snippet**: Should initialize correctly

## 🎨 **CSS Class Synchronization Requirements**

### **CRITICAL: Template and CSS Must Match**

When updating template class names, **CSS selectors MUST be updated** to match. This is a common source of styling issues.

### **Synchronization Process**

1. **✅ Update Template Classes**:
   ```xml
   <!-- Before -->
   <div id="tool-container">
       <canvas id="qr-canvas"></canvas>
   </div>

   <!-- After -->
   <div class="s_org_tool_container">
       <canvas class="s_org_tool_canvas"></canvas>
   </div>
   ```

2. **✅ Update CSS Selectors**:
   ```css
   /* Before */
   #tool-container {
       padding: 20px;
   }
   #qr-canvas {
       border: 1px solid #ccc;
   }

   /* After */
   .s_org_tool_container {
       padding: 20px;
   }
   .s_org_tool_canvas {
       border: 1px solid #ccc;
   }
   ```

3. **✅ Update JavaScript Selectors**:
   ```javascript
   // Before
   const canvas = container.querySelector('#qr-canvas');

   // After
   const canvas = container.querySelector('.s_org_tool_canvas');
   ```

### **Automated CSS Update Commands**

For bulk updates, use sed commands:

```bash
# Update CSS file to match new class names
sed -i 's/#tool-container/.s_org_tool_container/g' static/src/css/tool.css
sed -i 's/#qr-canvas/.s_org_tool_canvas/g' static/src/css/tool.css
```

### **CSS Synchronization Checklist**

1. **✅ Inventory all class changes** in template
2. **✅ Update CSS selectors** to match new classes
3. **✅ Update JavaScript selectors** to match new classes
4. **✅ Test styling** after changes
5. **✅ Verify responsive behavior** still works
6. **✅ Check browser console** for CSS errors

## 🎯 Benefits of Correct Asset Loading

### ir.asset Records for Snippets:
- ✅ **Odoo Standard**: Follows core Odoo practices
- ✅ **Conditional Loading**: Assets may load only when needed
- ✅ **Better Organization**: Assets stay with snippet definitions
- ✅ **Performance**: Potentially better (load only what's used)
- ✅ **Maintenance**: Easier to manage snippet-specific assets

### Overall Benefits:
- ✅ **Odoo 17 Compatibility**: Future-proof code
- ✅ **Better Performance**: Proper asset bundling
- ✅ **Standards Compliance**: Follows Odoo best practices
- ✅ **Multi-touch Support**: Works on all devices
- ✅ **Maintainability**: Consistent code structure
- ✅ **No Template Pollution**: Clean separation of concerns
- ✅ **No Duplicate Loading**: Prevents CSS/JS conflicts

## � CRITICAL ARCHITECTURAL DISCOVERY

### The website_assets.xml Anti-Pattern

**❌ NEVER CREATE `website_assets.xml` FILES**

This was a **fundamental architectural mistake** in our module. Odoo's core website module **NEVER** uses `website_assets.xml` files. Instead:

1. **✅ Snippets use `ir.asset` records** in their XML files
2. **✅ Common utilities use `__manifest__.py` assets**
3. **✅ JavaScript uses `publicWidget.Widget` pattern**
4. **✅ Automatic initialization** via widget registry

### Why This Matters

- **🚀 Performance**: Proper bundling and caching
- **🛡️ Standards Compliance**: Follows Odoo architecture
- **🔧 Maintainability**: Consistent with core modules
- **⚡ Multi-touch Support**: Works correctly with touch devices
- **🎯 Editor Compatibility**: Integrates with website builder

### Migration Impact

Converting from the old pattern to the correct pattern:

1. **✅ Fixes multi-touch issues**
2. **✅ Improves performance** (proper asset bundling)
3. **✅ Ensures future compatibility** with Odoo updates
4. **✅ Reduces code complexity** (no manual asset loading)
5. **✅ Follows Odoo best practices**

## 📚 References

- [Odoo 17+ JavaScript Framework Documentation](https://www.odoo.com/documentation/17.0/developer/reference/frontend/javascript_reference.html)
- [Odoo Core Website Module](https://github.com/odoo/odoo/tree/17.0/addons/website) (`/usr/lib/python3/dist-packages/odoo/addons/website/`)
- [Frontend Development Guidelines](docs/frontend.md) - Portal and website development patterns
- [publicWidget Documentation](https://www.odoo.com/documentation/17.0/developer/reference/frontend/public_widget.html) - Odoo Developer Documentation
- [Website Snippet Development](https://www.odoo.com/documentation/17.0/developer/tutorials/website.html) - Official Odoo Tutorial

## 📋 **Complete Refactoring Checklist**

### **Pre-Refactoring Analysis**
- [ ] **Inventory all data processing functions** in original code
- [ ] **Document complex formatting logic** (vCard, WiFi, SMS, etc.)
- [ ] **List all tab types** and their specific data requirements
- [ ] **Identify all CSS classes and IDs** used in templates
- [ ] **Note all event handlers** and their functionality

### **Template Updates**
- [ ] **Update template ID** to use `s_<org>_<tool>` format
- [ ] **Update section class** to match template ID
- [ ] **Update all internal classes** to use `s_<org>_<tool>_<element>` format
- [ ] **Remove all `onclick` handlers** from template
- [ ] **Add `data-action` attributes** for button interactions
- [ ] **Update snippet reference** in snippets menu

### **JavaScript Conversion**
- [ ] **Remove DOMContentLoaded** pattern
- [ ] **Add publicWidget import** and extend pattern
- [ ] **Set correct widget selector** to match template class
- [ ] **Convert initialization logic** to `start()` method
- [ ] **Preserve all data processing functions** (CRITICAL)
- [ ] **Update all DOM selectors** to match new class names
- [ ] **Implement proper event delegation** with `data-action`
- [ ] **Register and export widget** properly

### **CSS Synchronization**
- [ ] **Update all CSS selectors** to match new class names
- [ ] **Test styling** after selector changes
- [ ] **Verify responsive behavior** still works
- [ ] **Check for CSS conflicts** with other modules

### **Asset Management**
- [ ] **Add `ir.asset` records** for CSS and JavaScript
- [ ] **Remove assets from manifest** (if snippet-specific)
- [ ] **Test asset loading** in development mode
- [ ] **Verify no duplicate loading** conflicts

### **Quality Assurance**
- [ ] **Test on blank page** - no console errors
- [ ] **Test snippet insertion** - proper initialization
- [ ] **Test all tool functionality** - verify data processing works
- [ ] **Test all tabs/modes** - ensure proper data formatting
- [ ] **Test save/export features** - verify output quality
- [ ] **Test responsive behavior** - mobile/tablet compatibility
- [ ] **Test browser compatibility** - Chrome, Firefox, Safari
- [ ] **Performance testing** - no memory leaks or slow operations

### **Documentation**
- [ ] **Update code comments** to reflect new patterns
- [ ] **Document any breaking changes** in functionality
- [ ] **Update user documentation** if UI changes occurred
