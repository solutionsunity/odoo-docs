# Git Commit Standards

## Commit Message Format

```
[TYPE] module_name: one line description

Detailed description of the changes (for significant changes only)
- Technical references
- Use case explanation
- Result of the change
```

## Types

- **[FIX]**: Bug fixes
- **[ADD]**: New features
- **[REM]**: Feature removal
- **[REF]**: Code refactoring without functionality change
- **[IMP]**: Improvements to existing features
- **[MOV]**: Code moving without functionality change
- **[CLN]**: Code cleanup (removing dead code, comments, etc.)
- **[UPD]**: Update dependencies or data
- **[DOC]**: Documentation updates
- **[TEST]**: Test additions or corrections

## Examples

### Simple commit (one-liner)

```
[FIX] web_model_field_selector: Reset fieldPath when model changes
```

### Detailed commit (with description)

```
[IMP] sms_notification: Add support for multiple field types

Technical:
- Added support for char, text, and selection field types
- Implemented dynamic field selection based on field type
- Refactored field selection logic to use ModelFieldSelector widget

Use case:
- Users need to select fields of different types for SMS notifications
- Previous implementation only supported phone fields

Result:
- Users can now select any field type for SMS notifications
- Improved UX with proper field selection interface
- Better validation of selected fields
```

## Best Practices

1. **Be specific**: The one-liner should clearly indicate what changed
2. **Use present tense**: Write "Add feature" not "Added feature"
3. **Module name**: Always include the affected module name
4. **Detailed description**: For significant changes, include:
   - Technical details of the implementation
   - The use case or problem being solved
   - The result or impact of the change
5. **Reference issues**: Include references to issues or tickets when applicable
6. **Keep it concise**: The one-liner should be less than 72 characters if possible
7. **Separate commits**: Make separate commits for separate concerns

## When to Use Detailed Descriptions

Include detailed descriptions when:
- Making significant changes to functionality
- Implementing complex features
- Making architectural changes
- Fixing complex bugs
- Changes that affect multiple modules
