# Changes from pieper/slicer-skill

This fork streamlines the original skill in two main ways:

1. **Dramatically reduced download size.**  The original `setup.sh` cloned
   ~10–15 GB of data, including full checkouts of every Slicer SuperBuild
   dependency (VTK, ITK, CTK, DCMTK, etc.), all 200+ extension repositories,
   and a Discourse archive.  The new setup shallow-clones only two
   repositories — Slicer source and the ExtensionsIndex — totalling well under
   1 GB.  Dependency details are found by grepping the existing
   `SuperBuild/External_*.cmake` files and web search; Discourse is searched
   via its public API; extension repos are cloned on demand when needed.

2. **Adherence to SKILL.md standards and conventions.**  The skill file has
   been restructured to follow the emerging conventions for AI coding skills,
   including spec-compliant YAML frontmatter, agent-focused content (no
   human-facing setup instructions), and clear data-source documentation.  See
   the [Claude Code skills documentation](https://docs.anthropic.com/en/docs/claude-code/skills)
   and [agentskills.io](https://agentskills.io) for background on the format.

---

## SKILL.md rewritten (481 → 345 lines)

- **Frontmatter fixed** to match spec: `name` changed from `slicer` to
  `slicer-skill`, removed non-standard fields (`version`, `setup`, `requires`),
  added `compatibility` and `metadata.version`.
- **Removed all references** to `slicer-dependencies/` and `slicer-discourse/`
  directories.  Dependencies are now handled by grepping
  `SuperBuild/External_*.cmake` files plus web search.  Discourse is searched
  via API instead of a local clone.
- **Added Discourse search API documentation** with 7 query filters
  (`category:`, `status:solved`, `@username`, `tags:`, `order:latest`,
  `after:`/`before:`, `in:first`), pagination, and a combined-filter example.
- **Expanded ExtensionsIndex section** with extension count (241 across 63
  categories), `jq` query examples, `grep` examples, and 5 well-known
  extension landmarks (SlicerIGT, MONAILabel, SegmentEditorExtraEffects,
  SlicerElastix, SlicerDMRI).
- **Removed human-facing sections**: Prerequisites, Setup Instructions,
  Verification, disk space warnings.  These belong in README.md, not in an
  agent-consumed skill file.
- **Trimmed architecture sections** for conciseness while preserving all
  file path pointers.
- **Removed design principle #6** ("leverage all four data sources") since the
  skill now uses two local repos + two APIs.

## setup.sh replaced

- **Deleted top-level `setup.sh`** (265 lines) that cloned ~10-15 GB of data
  (SuperBuild dependencies, all 200+ extension repos, discourse archive) with
  complex Perl-based CMake parsing and parallel cloning logic.
- **Created `scripts/setup.sh`** (~38 lines) that shallow-clones only two
  repos: Slicer source and ExtensionsIndex.  Keeps idempotency, staleness
  check (24h stamp file), and `--force` flag.

## Repositories moved to cache directory

- Cloned repos now live in `~/.cache/slicer-skill/repositories/` instead of
  the skill directory itself.  This keeps the skill directory clean and
  eliminates the need for `.gitignore` entries for cloned repos.
- Stamp file moved to `~/.cache/slicer-skill/.setup-stamp.json`.

## README.md updated

- All path references updated to `~/.cache/slicer-skill/repositories/`.
- Setup instructions reference `scripts/setup.sh`.
- Removed references to `slicer-dependencies/` and `slicer-discourse/`.

## MCP server documented

- **Added `references/mcp.md`** with detailed documentation for the MCP server:
  client configuration, available tools, the `__result` convention for
  `execute_python`, state persistence workaround, UI responsiveness tips, and
  the search-then-execute workflow pattern.
- **Added MCP section to SKILL.md** explaining that the server is optional and
  pointing to the reference file.
- **Renamed `.mcp.json` to `mcp.json.sample`** so that the MCP connection is
  not auto-activated when the skill directory is loaded.  Users copy the sample
  to `.mcp.json` in their own project when they want to enable it.

## .gitignore cleaned up

- Removed `slicer-source`, `slicer-extensions`, `slicer-dependencies`,
  `slicer-discourse`, and `.setup-stamp.json` entries (no longer needed since
  repos are cached outside the skill directory).
