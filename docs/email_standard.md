# Email Templates and Notification Standards

## Email Sending Methods

Odoo provides multiple methods for sending emails, each with different behaviors regarding layout wrapping and chatter logging:

### Method 1: `template.send_mail()` (Recommended for Clean Emails)
```python
template.send_mail(self.id)  # Queued sending
template.send_mail(self.id, force_send=True)  # Immediate sending
```
- ✅ **Clean emails** with only template content
- ✅ **No automatic layout wrapping** (no "View" buttons, "Powered by Odoo" footer)
- ✅ **Portal-friendly** for external users
- ❌ **No automatic chatter logging**

### Method 2: `message_post_with_source()` (Automatic Chatter Logging)
```python
self.message_post_with_source(template, subtype_xmlid='mail.mt_comment')
```
- ✅ **Automatic chatter logging**
- ❌ **Automatic layout wrapping** with Odoo headers/footers
- ❌ **Backend "View" buttons** confusing for portal users

### Method 3: `send_mail()` + Manual Chatter (Best Practice)
```python
template.send_mail(self.id)
self.message_post(body="Email sent to...", message_type='notification')
```
- ✅ **Clean emails** without layout wrapping
- ✅ **Chatter audit trail** with custom messages
- ✅ **Full control** over email appearance and logging

## Email Queue vs Force Send

**Always prefer email queue over force_send:**
```python
# ✅ Good: Uses email queue for reliability
template.send_mail(self.id)

# ❌ Avoid: Bypasses queue, blocks user operations
template.send_mail(self.id, force_send=True)
```

**Benefits of email queue:**
- Non-blocking user operations
- Retry mechanism for failed emails
- Monitoring and debugging capabilities
- Respects mail server configuration

## Template Recipient Configuration

**Prefer template-based recipient configuration over Python overrides:**

```xml
<!-- ✅ Good: Template handles recipient -->
<field name="email_to">{{ object.email }}</field>
<field name="email_to">{{ object.env['model.name'].get_recipient() }}</field>
```

```python
# ✅ Good: Simple, consistent
template.send_mail(self.id)

# ❌ Avoid: Parameter overrides create confusion
template.send_mail(self.id, email_values={'email_to': 'someone@example.com'})
```

## Email Layout Considerations

**For different user types:**
- **Admin/Internal Users**: Layout wrapping acceptable (backend access available)
- **Portal/External Users**: Clean emails preferred (no confusing backend links)

**Implementation approach:**
- Use `send_mail()` for portal users (clean emails)
- Use `message_post_with_source()` only when layout wrapping is acceptable
- Always add manual chatter logging for audit trail

## Settings-Based Email Control

**Always respect user settings for email notifications:**
```python
def _send_notification(self, notification_type):
    settings = self.env['settings.model'].get_default_settings()

    # Check if notification is enabled
    if not getattr(settings, config['enabled_field'], False):
        return False

    # Check if recipient is configured
    if not config['recipient_email']:
        return False

    # Send email
    template.send_mail(self.id)
```

**Settings control points:**
- Boolean fields for enable/disable notifications
- Computed fields based on recipient configuration
- Clear logging when notifications are disabled

## Email Template Best Practices

### Template Structure
```xml
<record id="email_template_name" model="mail.template">
    <field name="name">Template: Purpose Description</field>
    <field name="model_id" ref="model_target_model"/>
    <field name="subject">Clear Subject: {{ object.field }}</field>
    <field name="email_from">{{ user.email_formatted }}</field>
    <field name="email_to">{{ object.email }}</field>
    <field name="body_html" type="html">
        <!-- Professional template content -->
    </field>
    <field name="auto_delete" eval="True"/>
</record>
```

### Professional Email Layout
```xml
<!-- Standard Header -->
<div style="background-color: #DDDDDD; color: #FFFFFF; text-align: center; padding: 16px;">
    <img t-attf-src="/web/image/res.company/{{user.company_id.id}}/logo" t-att-alt="user.company_id.name + ' Logo'" style="box-sizing: border-box; vertical-align: middle; max-height: 75px;"/>
    <h2 t-attf-style="color:{{user.company_id.email_primary_color or '#212529'}};">Template Title</h2>
</div>

<!-- Body with proper styling -->
<div style="padding: 16px; font-family: Arial, sans-serif; color: #333333;">
    <p style="box-sizing:border-box;margin: 0 0 16px 0;">Content here</p>

    <!-- Buttons use secondary color -->
    <a t-attf-style="background-color:{{user.company_id.email_secondary_color or '#a14686'}};">Action Button</a>
</div>

<!-- Standard Footer -->
<div style="background-color: #DDDDDD; color: #1F1F1F; text-align: center; padding: 16px;">
    <p style="box-sizing:border-box;margin:0;">© <t t-esc="datetime.datetime.now().year"/> <t t-esc="user.company_id.name"/>. All rights reserved.</p>
</div>
```

**Email Colors:**
- `user.company_id.email_primary_color` - Headers, titles, text links
- `user.company_id.email_secondary_color` - Action buttons, call-to-action elements
- Always provide fallback colors (`#212529` for primary, `#a14686` for secondary)

### Buttons and Links Standards

#### Action Buttons (Secondary Color)
Use secondary color for prominent call-to-action buttons:
```xml
<!-- Primary action button -->
<a t-attf-href="{{action_url}}"
   t-attf-style="border-style:solid;box-sizing:border-box;border-color:{{user.company_id.email_secondary_color or '#a14686'}};border-width:1px;padding:5px 10px;color:#FFFFFF;text-decoration:none;background-color:{{user.company_id.email_secondary_color or '#a14686'}};border-radius:3px">
    Action Button Text
</a>
```

#### Text Links (Primary Color)
Use primary color for inline text links and table links:
```xml
<!-- Inline text link -->
<a t-attf-href="{{link_url}}"
   t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}}; text-decoration: none;">
    Link Text
</a>

<!-- Table action link -->
<td style="padding: 8px;">
    <a t-attf-href="{{record_url}}"
       t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}}; text-decoration: none;">
        View
    </a>
</td>
```

#### Button vs Link Decision Matrix
| Element Type | Color | Use Case | Example |
|--------------|-------|----------|---------|
| **Action Button** | Secondary | Primary actions, CTAs | "Renew Document", "Approve Request" |
| **Text Link** | Primary | Navigation, secondary actions | "View Details", "Edit Record" |
| **Table Link** | Primary | Row actions in tables | "View", "Edit", "Download" |

### Navigation URL Construction

#### Base URL Retrieval
Always use the proper method to get the base URL:
```xml
<t t-set="base_url" t-value="env['ir.config_parameter'].sudo().get_param('web.base.url')"/>
```

#### Record Navigation URLs
Standard pattern for navigating to specific records:
```xml
<!-- Single record form view -->
<a t-attf-href="{{base_url}}/web#id={{record.id}}&amp;view_type=form&amp;model={{model_name}}">

<!-- List view with domain filter -->
<a t-attf-href="{{base_url}}/web#model={{model_name}}&amp;view_type=list&amp;domain={{domain_filter}}">

<!-- Specific action with context -->
<a t-attf-href="{{base_url}}/web#action={{action_id}}&amp;active_id={{record.id}}">
```

#### URL Construction Examples
```xml
<!-- Document record -->
<t t-set="base_url" t-value="env['ir.config_parameter'].sudo().get_param('web.base.url')"/>
<a t-attf-href="{{base_url}}/web#id={{object.document_id.id}}&amp;view_type=form&amp;model=su.document">
    View Document
</a>

<!-- Partner record -->
<a t-attf-href="{{base_url}}/web#id={{object.partner_id.id}}&amp;view_type=form&amp;model=res.partner">
    View Partner
</a>

<!-- Sale order with specific action -->
<a t-attf-href="{{base_url}}/web#action=sale.action_orders&amp;active_id={{object.id}}">
    View Order
</a>
```

#### URL Parameters Reference
| Parameter | Description | Example |
|-----------|-------------|---------|
| `id` | Record ID to display | `id=123` |
| `model` | Model name | `model=sale.order` |
| `view_type` | View type to open | `view_type=form` |
| `action` | Specific action ID | `action=sale.action_orders` |
| `active_id` | Active record ID for action | `active_id=123` |
| `domain` | Filter domain for list views | `domain=[('state','=','draft')]` |

### Template Variables
- **`object`**: Current record being processed
- **`user`**: Current user triggering the action (use `user.company_id` for company)
- **`ctx`**: Context variables passed to template
- **`datetime`**: Python datetime module

### Template Syntax
**Field values (Python expressions):**
```xml
<field name="subject">{{ object.name }}</field>
<field name="email_to">{{ ','.join(recipients) }}</field>
```

**Body content (QWeb):**
```xml
<t t-esc="object.name"/>                    <!-- Display value -->
<t t-if="condition">Content</t>             <!-- Conditional -->
<t t-foreach="items" t-as="item">           <!-- Loop -->
<t t-attf-style="color:{{color}};">         <!-- Dynamic attributes -->
```

**Rule:** Use `{{ }}` in field definitions, use `<t t-*>` in body HTML

### Error Handling
```python
try:
    template.send_mail(self.id)
    self.message_post(body="Email sent successfully")
    return True
except Exception as e:
    _logger.error(f"Failed to send email: {str(e)}")
    return False
```

### Common Email Patterns

#### Document Notification with Navigation
```xml
<!-- Document expiry notification with action button -->
<t t-set="base_url" t-value="env['ir.config_parameter'].sudo().get_param('web.base.url')"/>

<p>Your document is expiring soon. Please take action:</p>

<!-- Primary action button (secondary color) -->
<p style="margin: 16px 0;">
    <a t-attf-href="{{base_url}}/web#id={{object.document_id.id}}&amp;view_type=form&amp;model=su.document"
       t-attf-style="border-style:solid;border-color:{{user.company_id.email_secondary_color or '#a14686'}};border-width:1px;padding:8px 16px;color:#FFFFFF;text-decoration:none;background-color:{{user.company_id.email_secondary_color or '#a14686'}};border-radius:3px">
        View Document
    </a>
</p>

<!-- Optional external action -->
<t t-if="object.renewal_url">
    <p>Or renew online:
        <a t-attf-href="{{object.renewal_url}}"
           t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}};">
            Renewal Portal
        </a>
    </p>
</t>
```

#### Summary Table with Actions
```xml
<!-- Summary table with navigation links -->
<t t-set="base_url" t-value="env['ir.config_parameter'].sudo().get_param('web.base.url')"/>

<table border="1" style="border-collapse: collapse; width: 100%;">
    <thead>
        <tr>
            <th style="padding: 8px;">Document</th>
            <th style="padding: 8px;">Status</th>
            <th style="padding: 8px;">Action</th>
        </tr>
    </thead>
    <tbody>
        <t t-foreach="documents" t-as="doc">
            <tr>
                <td style="padding: 8px;"><t t-esc="doc.name"/></td>
                <td style="padding: 8px;"><t t-esc="doc.state"/></td>
                <td style="padding: 8px;">
                    <a t-attf-href="{{base_url}}/web#id={{doc.id}}&amp;view_type=form&amp;model=su.document"
                       t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}}; text-decoration: none;">
                        View
                    </a>
                </td>
            </tr>
        </t>
    </tbody>
</table>
```

#### Multi-Action Email
```xml
<!-- Email with multiple action types -->
<t t-set="base_url" t-value="env['ir.config_parameter'].sudo().get_param('web.base.url')"/>

<p>Your request requires attention:</p>

<!-- Primary action (secondary color button) -->
<p style="margin: 16px 0;">
    <a t-attf-href="{{base_url}}/web#id={{object.id}}&amp;view_type=form&amp;model=request.model"
       t-attf-style="background-color:{{user.company_id.email_secondary_color or '#a14686'}};color:#FFFFFF;padding:8px 16px;text-decoration:none;border-radius:3px;display:inline-block;">
        Review Request
    </a>
</p>

<!-- Secondary actions (primary color links) -->
<p>Additional options:</p>
<ul>
    <li>
        <a t-attf-href="{{base_url}}/web#model=related.model&amp;domain=[('request_id','=',{{object.id}})]"
           t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}};">
            View Related Records
        </a>
    </li>
    <li>
        <a t-attf-href="{{base_url}}/web#action=custom.action_reports&amp;active_id={{object.id}}"
           t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}};">
            Generate Report
        </a>
    </li>
</ul>
```

### Color Usage Guidelines

#### Do's ✅
- Use secondary color for primary action buttons
- Use primary color for text links and navigation
- Always provide fallback colors
- Maintain consistent styling across templates
- Use `t-attf-style` for dynamic color application

#### Don'ts ❌
- Don't hardcode colors without fallbacks
- Don't mix color purposes (primary for buttons, secondary for links)
- Don't use colors that don't contrast well with backgrounds
- Don't forget to escape URLs with `&amp;` in XML

#### Color Accessibility
```xml
<!-- Good: High contrast, proper fallbacks -->
<a t-attf-style="background-color:{{user.company_id.email_secondary_color or '#a14686'}};color:#FFFFFF;">

<!-- Good: Readable link color -->
<a t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}};">

<!-- Bad: No fallback -->
<a t-attf-style="color: {{user.company_id.email_primary_color}};">

<!-- Bad: Poor contrast -->
<a style="color: #CCCCCC; background-color: #FFFFFF;">
```

### Troubleshooting Navigation URLs

#### Common Issues and Solutions

**Issue: `KeyError: 'web'` in templates**
```xml
<!-- ❌ Wrong: web variable not available -->
<a t-attf-href="{{web.base_url}}/web#id={{object.id}}">

<!-- ✅ Correct: Use env to get base URL -->
<t t-set="base_url" t-value="env['ir.config_parameter'].sudo().get_param('web.base.url')"/>
<a t-attf-href="{{base_url}}/web#id={{object.id}}">
```

**Issue: URLs not working in email**
```xml
<!-- ❌ Wrong: Missing proper escaping -->
<a t-attf-href="{{base_url}}/web#id={{object.id}}&view_type=form&model=su.document">

<!-- ✅ Correct: Proper XML escaping -->
<a t-attf-href="{{base_url}}/web#id={{object.id}}&amp;view_type=form&amp;model=su.document">
```

**Issue: Colors not applying**
```xml
<!-- ❌ Wrong: Missing t-attf- prefix -->
<a style="color: {{user.company_id.email_primary_color}};">

<!-- ✅ Correct: Use t-attf-style -->
<a t-attf-style="color: {{user.company_id.email_primary_color or '#875A7B'}};">
```

**Issue: Base URL not found**
```python
# Check if web.base.url is configured
base_url = self.env['ir.config_parameter'].sudo().get_param('web.base.url')
if not base_url:
    # Set default or handle missing configuration
    base_url = 'http://localhost:8069'
```

#### Testing Navigation Links
```python
# Test URL construction in Python
def test_navigation_url(self):
    base_url = self.env['ir.config_parameter'].sudo().get_param('web.base.url')
    record_url = f"{base_url}/web#id={self.id}&view_type=form&model={self._name}"
    _logger.info(f"Generated URL: {record_url}")
    return record_url
```

## Notification System Architecture

### Centralized Notification Method
```python
def _send_notification(self, notification_type):
    """Centralized notification sending method."""
    settings = self._get_notification_settings()
    config = self._get_notification_config(notification_type, settings)

    # Validation
    if not self._validate_notification(config, notification_type):
        return False

    # Send email
    template = self.env.ref(config['template_ref'])
    template.send_mail(self.id)

    # Log to chatter
    self.message_post(body=config['log_message'])
    return True
```

### Configuration-Driven Approach
```python
notification_config = {
    'admin_notification': {
        'enabled_field': 'enable_admin_notification_emails',
        'template_ref': 'module.email_template_admin',
        'log_message': 'Admin notification sent'
    },
    'user_confirmation': {
        'enabled_field': 'enable_user_confirmation_emails',
        'template_ref': 'module.email_template_confirmation',
        'log_message': 'Confirmation email sent'
    }
}
```

## Testing Email Functionality

### Development Testing
- Use email queue for testing (avoid force_send)
- Check Settings > Technical > Email > Emails for queue status
- Verify chatter logging appears correctly
- Test with different user types (admin, portal)

### Production Considerations
- Monitor email queue for failed messages
- Set up proper SMTP configuration
- Configure email server limits and intervals
- Implement proper error logging and alerting
