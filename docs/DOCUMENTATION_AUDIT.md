# 📚 Documentation Audit & Update Plan

Comprehensive audit of documentation vs current code state.

**Date**: 2026-01-21
**Status**: ⚠️ Needs updates for recent alias improvements

---

## ✅ What's Already Good

### Well-Documented Areas
- ✅ Installation process (getting-started/installation.md)
- ✅ System architecture (technical/architecture.md)
- ✅ AWS SSO setup (guides/aws-sso-setup.md)
- ✅ Python development (development/python-setup.md)
- ✅ Cloud setup (development/cloud-setup.md)
- ✅ Performance optimization (performance/rebuild-optimization.md)
- ✅ System health monitoring (monitoring/system-health.md)
- ✅ Troubleshooting (help/troubleshooting.md, technical/troubleshooting.md)

---

##  🔴 Missing/Outdated Documentation

### 1. NEW ALIAS SYSTEM (Not Documented!)

**Missing**:
- `home-manager/aliases/README.md` - EXISTS but NOT linked from docs/
- `home-manager/aliases/IMPROVEMENTS.md` - EXISTS but NOT linked
- `home-manager/scripts/README.md` - EXISTS but NOT linked
- New alias discovery tools:
  - `alias-find` - Interactive fuzzy search
  - `alias-quick` - Quick reference
  - `alias-help` - Documentation viewer
  - `alias-search` - Keyword search
  - `alias-list` - Alphabetical listing
  - `alias-count` - Count aliases

**New workflow aliases not documented**:
- `quickcommit` - Stage + commit
- `quickpush` - Stage + commit + push
- `quickamend` - Stage + amend
- `quicksave` - WIP commit
- `quickfix` - Stage + amend + force push

**New scripts not documented**:
- `git-fuzzy-checkout.sh` (`gcb` alias)
- `git-fuzzy-log.sh` (`fshow` alias)
- `git-fuzzy-stash.sh` (`fstash` alias)
- `system-rollback.sh` (`rollback` alias)
- `alias-cheatsheet.sh` (`alias-help` alias)

---

### 2. Broken/Outdated Links in docs/README.md

**Referenced but don't exist**:
- ❌ `guides/development-setup.md` (linked from README, doesn't exist)
- ❌ `guides/performance.md` (linked, doesn't exist)
- ❌ `guides/monitoring.md` (linked, doesn't exist)
- ❌ `guides/security.md` (linked, doesn't exist)
- ❌ `customization/shortcuts.md` (linked, doesn't exist)
- ❌ `customization/window-management.md` (linked, doesn't exist)
- ❌ `performance/resource-management.md` (linked, doesn't exist)
- ❌ `technical/nix-concepts.md` (linked, doesn't exist)
- ❌ `technical/home-manager.md` (linked, doesn't exist)
- ❌ `reference/flake-structure.md` (linked, doesn't exist)
- ❌ `reference/user-config.md` (linked, doesn't exist)
- ❌ `reference/darwin-modules.md` (linked, doesn't exist)
- ❌ `reference/home-manager-modules.md` (linked, doesn't exist)
- ❌ `reference/aliases.md` (linked, doesn't exist)
- ❌ `reference/scripts.md` (linked, doesn't exist)
- ❌ `reference/health-commands.md` (linked, doesn't exist)
- ❌ `reference/configuration-files.md` (linked, doesn't exist)
- ❌ `help/error-messages.md` (linked, doesn't exist)
- ❌ `help/community.md` (linked, doesn't exist)
- ❌ `help/contributing.md` (linked, doesn't exist)
- ❌ `help/issues.md` (linked, doesn't exist)

**Exists but wrong path**:
- ✅ `development/environment-templates.md` - EXISTS
- ✅ `customization/themes.md` - EXISTS
- ✅ `customization/paths.md` - EXISTS

---

### 3. New Root-Level Documentation Files

**Created but not linked from docs/**:
- `SCRIPTS_QUICKSTART.md` - Script usage guide
- `REFACTORING_ANALYSIS.md` - Refactoring recommendations
- `home-manager/aliases/README.md` - Alias reference
- `home-manager/aliases/IMPROVEMENTS.md` - Alias improvement history
- `home-manager/scripts/README.md` - Script documentation

---

## 🎯 Update Plan

### Phase 1: Fix docs/README.md (HIGH PRIORITY)

**Actions**:
1. Remove or create missing linked files
2. Add links to new documentation
3. Update quick start to mention new alias tools
4. Fix broken navigation

**Estimated time**: 2 hours

---

### Phase 2: Create Missing Reference Docs (HIGH PRIORITY)

**Create these files**:

#### `docs/reference/aliases.md`
```markdown
# Alias Reference

Complete reference for all shell aliases.

## Quick Discovery

- `alias-quick` - Quick reference (most-used)
- `alias-find` - Interactive fuzzy search
- `alias-help [category]` - Category-specific help
- `alias-search <keyword>` - Search by keyword

## Full Documentation

See [home-manager/aliases/README.md](../../home-manager/aliases/README.md) for:
- Complete alias list (~220 aliases)
- Usage examples
- Category breakdown
- Common workflows

## Quick Reference

[Link to alias-quick output]
```

#### `docs/reference/scripts.md`
```markdown
# Scripts Reference

Helper scripts for complex operations.

## Overview

See [home-manager/scripts/README.md](../../home-manager/scripts/README.md)

## Quick Usage

- `gcb` - Interactive git checkout
- `fshow` - Browse commits
- `fstash` - Apply stash
- `rollback` - System rollback
- `alias-help` - View documentation
```

---

### Phase 3: Update Existing Docs (MEDIUM PRIORITY)

**Files to update**:

#### `docs/getting-started/quick-reference.md`
- Add alias discovery tools
- Add workflow shortcuts
- Add interactive scripts

#### `docs/guides/terminal-setup.md`
- Document new alias system
- Explain discovery tools
- Add workflow examples

#### `docs/guides/system-overview.md`
- Mention scripts directory
- Explain alias organization
- Link to detailed docs

---

### Phase 4: Create Placeholder Files (LOW PRIORITY)

**Option A**: Create actual files
**Option B**: Remove links from README

**Recommended**: Option B (remove links), create files only when needed

**Files to remove from README links**:
- guides/development-setup.md (use development/* instead)
- guides/performance.md (use performance/* instead)
- guides/monitoring.md (use monitoring/* instead)
- guides/security.md (not implemented yet)
- All reference/* files (create in Phase 2)
- Various help/* files (not needed yet)

---

## 📋 Detailed Action Items

### Immediate (Do Now)

- [ ] Create `docs/reference/aliases.md`
- [ ] Create `docs/reference/scripts.md`
- [ ] Update `docs/README.md` to remove broken links
- [ ] Add links to new documentation in README
- [ ] Update `docs/getting-started/quick-reference.md`

### Short Term (This Week)

- [ ] Update `docs/guides/terminal-setup.md`
- [ ] Update `docs/guides/system-overview.md`
- [ ] Create `docs/guides/workflow-shortcuts.md` (NEW)
- [ ] Add troubleshooting section for aliases
- [ ] Update FAQ with alias questions

### Long Term (Optional)

- [ ] Create video/gif demos of interactive tools
- [ ] Add cheat sheet PDF
- [ ] Create printable quick reference
- [ ] Add search functionality to docs

---

## 🔧 Specific Updates Needed

### Update: docs/README.md

**Line 96** - Fix alias reference:
```diff
-- **[Aliases Reference](reference/aliases.md)** - All available shortcuts
++ **[Aliases Reference](../home-manager/aliases/README.md)** - All available shortcuts (~220 total)
++ **[Alias Quick Start](../SCRIPTS_QUICKSTART.md)** - Get started in 5 minutes
```

**Line 97** - Fix scripts reference:
```diff
-- **[Scripts Reference](reference/scripts.md)** - Automation tools
++ **[Scripts Reference](../home-manager/scripts/README.md)** - Helper scripts
```

**Add new section** after line 98:
```markdown
### Alias Discovery Tools

- **[alias-quick](../home-manager/aliases/README.md#quick-reference)** - Quick reference
- **[alias-find](../home-manager/aliases/README.md#alias-discovery)** - Interactive search
- **[alias-help](../home-manager/scripts/README.md#alias-cheatsheet)** - Documentation viewer
```

### Update: docs/getting-started/quick-reference.md

**Add section**:
```markdown
## Discovering Aliases

New to the system? Use these tools:

```bash
alias-quick                 # See most-used aliases
alias-find                  # Interactive fuzzy search
alias-help git             # Git aliases only
alias-search docker        # Search for docker aliases
```

## Quick Workflows

Save time with workflow shortcuts:

```bash
quickcommit "message"      # Stage all + commit
quickpush "message"        # Stage + commit + push
quickamend                 # Stage + amend last commit
```

## Interactive Git

Fuzzy-find with previews:

```bash
gcb                        # Checkout branch (interactive)
fshow                      # Browse commits (interactive)
fstash                     # Apply stash (interactive)
```
```

---

## 📊 Documentation Coverage Report

### Current Coverage

| Area | Status | Files | Notes |
|------|--------|-------|-------|
| Installation | ✅ Complete | 3 | Up to date |
| Basic Config | ✅ Complete | 6 | Up to date |
| Development | ✅ Good | 3 | Missing alias info |
| Customization | ⚠️ Partial | 4 | Some broken links |
| Performance | ✅ Complete | 1 | Up to date |
| Monitoring | ✅ Complete | 1 | Up to date |
| Terminal/Aliases | 🔴 Outdated | 0 | **NEEDS MAJOR UPDATE** |
| Scripts | 🔴 Missing | 0 | **NEW - NOT DOCUMENTED** |
| Reference | 🔴 Missing | 0 | **ALL LINKS BROKEN** |
| Help/Support | ⚠️ Partial | 2 | Missing some linked files |
| Technical | ✅ Good | 2 | Some broken links |
| Advanced | ✅ Complete | 3 | Up to date |

### Priority Areas

1. 🔴 **CRITICAL**: Alias & Script documentation
2. 🔴 **HIGH**: Fix broken links in README
3. 🟡 **MEDIUM**: Create reference documentation
4. 🟢 **LOW**: Create optional placeholder files

---

## 🎯 Success Criteria

Documentation is "up to date" when:

- [ ] No broken links in docs/README.md
- [ ] All new aliases documented
- [ ] All new scripts documented
- [ ] Discovery tools explained
- [ ] Quick reference updated
- [ ] Workflow shortcuts documented
- [ ] Navigation paths work
- [ ] User can find information in < 2 clicks

---

## 💡 Recommendations

### Documentation Philosophy

1. **Link, don't duplicate** - Point to authoritative source
2. **Update once** - Keep info in one place
3. **Progressive disclosure** - Quick start → detailed docs
4. **Examples first** - Show don't tell

### Structure Suggestion

```
docs/
├── README.md (navigation hub - LINKS to authoritative docs)
├── getting-started/ (basics)
├── guides/ (how-to)
├── development/ (dev setup)
└── reference/ (LINKS to actual docs, don't duplicate)

home-manager/
├── aliases/
│   └── README.md (AUTHORITATIVE alias docs)
└── scripts/
    └── README.md (AUTHORITATIVE script docs)

Root level:
├── SCRIPTS_QUICKSTART.md (quick start guide)
└── REFACTORING_ANALYSIS.md (technical analysis)
```

This avoids duplication and keeps docs maintainable.

---

## 🚀 Quick Fix (30 minutes)

Minimal viable update:

1. Edit `docs/README.md`:
   - Replace broken alias/script links with links to actual files
   - Remove reference to non-existent files

2. Create `docs/reference/README.md`:
   - Link to home-manager/aliases/README.md
   - Link to home-manager/scripts/README.md
   - Link to SCRIPTS_QUICKSTART.md

3. Update `docs/getting-started/quick-reference.md`:
   - Add alias-quick, alias-find, alias-help
   - Add workflow shortcuts
   - Add interactive scripts

**Done!** 90% of users can find what they need.

---

## 📝 Next Steps

Choose your approach:

**Option A: Quick Fix** (30 min)
- Fix broken links
- Add basic references
- Good enough for most users

**Option B: Comprehensive Update** (2-3 hours)
- Create all reference docs
- Update all guides
- Professional documentation

**Option C: Gradual Improvement** (over time)
- Do quick fix now
- Update docs as you use the system
- Add examples when you discover workflows

**My recommendation**: Option A (quick fix) now, then Option C (gradual) over time.
