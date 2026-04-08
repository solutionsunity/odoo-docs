# Odoo Module QC Checklist

Run every item against **every file** before declaring a module production-ready.
Each item is binary — ✅ Pass or ❌ Fail. Fix all failures before shipping.

---

## 1. Python — File Structure

| # | Check | Grep / Rule |
|---|---|---|
| 1.1 | Copyright year is current for new modules, otherwise first year it appeared in git. | `grep -n "Copyright 20" **/*.py` |
| 1.2 | Import order: **stdlib → third-party → odoo**, each group separated by blank line | Manual |
| 1.3 | No inline imports inside methods, try/except, or conditions | `grep -n "^\s*import \|^\s*from " **/*.py` |
| 1.4 | `_logger = logging.getLogger(__name__)` present in every file that logs | Manual |
| 1.5 | Logger uses `%s` formatting, never f-strings or `%` concatenation | Manual |
| 1.6 | No `print()` statements | `grep -rn "print(" **/*.py` |

---

## 2. ORM — Model Definition

| # | Check | Rule |
|---|---|---|
| 2.1 | Every model has `_name`, `_description`, and `_order` | Manual |
| 2.2 | Class-level attributes (`_CONSTANTS`, `_sql_constraints`) are at top of class body, before any method | Manual |
| 2.3 | No `name_get()` — use `_compute_display_name` instead | `grep -n "def name_get" **/*.py` |
| 2.4 | No `invalidate_cache()` — use `invalidate_recordset()` | `grep -n "invalidate_cache" **/*.py` |
| 2.5 | No `@api.multi`, `@api.one` decorators (removed in Odoo 14+) | `grep -n "@api.multi\|@api.one" **/*.py` |
| 2.6 | `create()` uses `@api.model_create_multi` and signature `create(self, vals_list)` | `grep -n "def create" **/*.py` |
| 2.7 | No redundant `domain=` on One2many fields (comodel field already restricts) | Manual |
| 2.8 | No `store=True` on fields computed from `date.today()` or `datetime.now()` | Manual |

---

## 3. ORM — Field Definitions

| # | Check | Rule |
|---|---|---|
| 3.1 | All `Many2one` fields have explicit `ondelete` (`cascade`, `restrict`, or `set null`) | `grep -n "Many2one" **/*.py` — verify each has `ondelete=` |
| 3.2 | `ondelete='cascade'` only used when child records are meaningless without parent | Manual — use `restrict` to protect data integrity |
| 3.3 | No fields defined but never used in code or any view | Manual cross-check |
| 3.4 | `readonly=True` on fields that should never be user-edited | Manual |
| 3.5 | Computed fields without `store=True` have all dependencies in `@api.depends` | Manual |

---

## 4. ORM — Method Contracts

| # | Check | Rule |
|---|---|---|
| 4.1 | Every method operating on a single record calls `self.ensure_one()` | Manual |
| 4.2 | `action_*` public methods (UI-facing) return a valid action dict or `None` | Manual |
| 4.3 | Internal `_method()` never raises `UserError` — returns error dict or raises only for unrecoverable programmer errors | Manual |
| 4.4 | Guard/validation checks in `action_*` methods are **outside** the `try/except` block | Manual |
| 4.5 | `search()` calls that must include archived records use `with_context(active_test=False)` | `grep -n "\.search\(" **/*.py` — verify intent |
| 4.6 | One2many fields accessed via the relationship (`self.field_ids`) not re-queried via `search()` | Manual |
| 4.7 | No dead methods (defined but never called from code, views, or cron) | Manual |

---

## 5. Translations

| # | Check | Rule |
|---|---|---|
| 5.1 | All user-facing strings in `_()` | `grep -n "return {.*'error':\|'message':\|'title':" **/*.py` — verify wrapped |
| 5.2 | No f-strings inside `_()` — use `_('text %s', variable)` positional form | `grep -n '_( *f"' **/*.py` |
| 5.3 | Logger messages are NOT wrapped in `_()` (logs are for developers) | Manual |
| 5.4 | Notification titles and button strings in views use `string=` not hardcoded untranslatable labels | Manual |

---

## 6. Views / XML

| # | Check | Rule |
|---|---|---|
| 6.1 | Every `<xpath>` target verified to exist in Odoo 17 core | `grep -rn "/usr/lib/python3/dist-packages/odoo/addons/<module>/views/"` |
| 6.2 | No Odoo 16 CSS patterns: `app_settings_block`, `o_settings_container`, `o_setting_box` | `grep -n "app_settings_block\|o_settings_container\|o_setting_box" **/*.xml` |
| 6.3 | Settings views use Odoo 17 `<block>` and `<setting>` elements | Manual |
| 6.4 | `optional="show/hide"` only on `<tree>` fields — never on `<form>` fields | Manual |
| 6.5 | No `attrs={}` — use inline `invisible=`, `readonly=`, `required=` (Odoo 17) | `grep -n "attrs=" **/*.xml` |
| 6.6 | No invalid action types (only: `ir.actions.act_window`, `ir.actions.client`, `ir.actions.act_window_close`, `ir.actions.report`) | `grep -n "'type':" **/*.py` |
| 6.7 | All `ref=` values point to XML IDs that exist in the module or its dependencies | Manual |
| 6.8 | All XML IDs are unique across the module | `grep -n 'id="' **/*.xml \| sort \| uniq -d` |
| 6.9 | Fields referenced in button `invisible=` are loaded in the same list/tree view | Manual |
| 6.10 | `web_ribbon` widget used for archived state instead of custom banners | Manual |
| 6.11 | `widget="boolean_toggle"` used for `active` fields in tree and form views | Manual |
| 6.12 | No `@string` used as an XPath selector in view inheritance — rejected by Odoo 17 and unreliable in older versions due to translation | `grep -n '@string=' **/*.xml` — flag any inside `<xpath expr="...">` |

---

## 7. JavaScript / OWL

| # | Check | Rule |
|---|---|---|
| 7.1 | `/** @odoo-module **/` is **line 1** of every ES module file — copyright and any other comments go **after** it, never before | `grep -n "@odoo-module" **/*.js` — verify line number is 1 |
| 7.2 | Every `.js` file that uses `import` or `export` has `/** @odoo-module **/` | `grep -rL "@odoo-module" static/src/**/*.js` — flag any that use import/export without it |
| 7.3 | OWL component `static template` name matches the `t-name` in its XML template | Manual cross-check |
| 7.4 | All assets declared in `__manifest__.py` actually exist on disk | `ls` each path |
| 7.5 | No `console.log()` left in production code | `grep -rn "console.log" static/src/` |

---

## 8. Security

| # | Check | Rule |
|---|---|---|
| 8.1 | Every `_name` model has at least one row in `ir.model.access.csv` | Cross-check model names vs CSV |
| 8.2 | CSV uses only `base.group_system` or module-defined groups (no typos) | Manual |
| 8.3 | No `perm_*` attributes in XML record rules — permissions only in CSV | `grep -n "perm_read\|perm_write" **/*.xml` |
| 8.4 | Multi-company record rules use `company_id` domain with `company_ids` variable | Manual |
| 8.5 | `.sudo()` usage is justified and scoped as narrowly as possible | `grep -n "\.sudo()" **/*.py` — review each |

---

## 9. Data Files

| # | Check | Rule |
|---|---|---|
| 9.1 | No development artifacts in `data/` (`.txt`, test files, scratch data) | `ls data/` |
| 9.2 | Demo data is in `demo/`, not `data/` | Manual |
| 9.3 | `noupdate="1"` used only for records that must survive module upgrade | Manual |
| 9.4 | Cron jobs have `active` field set explicitly | `grep -n "ir_cron" data/*.xml` |

---

## 10. Manifest

| # | Check | Rule |
|---|---|---|
| 10.1 | Version follows `17.0.x.x.x` format | Manual |
| 10.2 | All files referenced in `data`, `views`, `demo` actually exist | Cross-check |
| 10.3 | All module dependencies are in `depends` | Manual |
| 10.4 | `license` is set and matches branding standard (`Other proprietary` for this project) | Manual |
| 10.5 | `author` matches branding standard (`Solutions Unity Co`) | Manual |

---

## 11. Consistency / DRY

| # | Check | Rule |
|---|---|---|
| 11.1 | No dead code: commented-out methods, placeholder stubs with no implementation path | `grep -n "# def \|# TODO\|# FIXME" **/*.py` |
| 11.2 | All methods following the same pattern are implemented consistently (e.g., all `_generate()` overrides return the same dict shape) | Manual |
| 11.3 | Fields that share overlapping `@api.depends` / `@api.constrains` lists use a shared constant (see `code_standard.md`) | Manual |
| 11.4 | No WET validation logic — identical checks not duplicated across `create()`, `write()`, and `action_*` | Manual |

---

## How to Run

1. Open the module directory.
2. Work through **every section top to bottom**.
3. For grep checks: run the command, review every match.
4. For manual checks: open each file and verify.
5. Log every ❌ with file + line number.
6. Fix all failures — do not skip any.
7. Re-run only the failed items to confirm green.

**A module passes QC only when every item in every section is ✅.**
