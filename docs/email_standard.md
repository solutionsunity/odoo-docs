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
- Use consistent header with company logo
- Clear, structured body content
- Professional footer with company information
- Responsive design for mobile devices
- Proper styling with inline CSS

### Template Variables
- **`object`**: Current record being processed
- **`user`**: Current user triggering the action
- **`company`**: Current company record
- **`ctx`**: Context variables

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
