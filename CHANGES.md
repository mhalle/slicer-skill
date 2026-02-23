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

## v2.2: custom cache directory and web-search fallback

### setup.sh: configurable cache directory

- Cache directory can now be overridden via a CLI argument
  (`setup.sh /tmp/slicer-skill-$USER`) or the `SLICER_SKILL_CACHE_DIR`
  environment variable.  Fixes permission issues in sandboxed environments
  (e.g. Claude Code) where `~/.cache` may not be writable.
- `--force` and the directory argument can be combined in any order.

### SKILL.md: web-search fallback (§5)

- Added a new **"Web Fallback"** data source section for use when local repos
  are unavailable.  Lists ReadTheDocs, Doxygen API reference
  (`apidocs.slicer.org`), GitHub code search, and the online Script Repository
  URL.
- Inspired by the cloud-only approach in
  [jumbojing/slicerSkill](https://github.com/jumbojing/slicerSkill), which
  replaces local clones entirely with web-search directives.

### README.md: related projects

- Added [jumbojing/slicerSkill](https://github.com/jumbojing/slicerSkill) to
  the Related projects section — a zero-setup, cloud-only adaptation designed
  for OpenCode / Gemini workflows.

### Version bumped to 2.2

## v2.4: skill packaging, version checking, and sandbox fixes

### GitHub Actions packaging workflow

- Added `.github/workflows/package.yml` — on version tags (`v*`), builds a
  `.skill` zip and creates a GitHub release with the file attached.
- Generic workflow derived from repo name; works as-is in any skill repo.

### SKILL.md metadata (agentskills.io spec)

- Replaced `version` field with `repository`, `release_url`, and `author`
  per the [agentskills.io specification](https://agentskills.io/specification).
- Updated repo URLs from `pieper/slicer-skill` to `mhalle/slicer-skill`.

### Version checking and auto-update

- Added "Version Checking" section to SKILL.md instructing agents to fetch
  `release_url`, compare tags, and offer to download the `.skill` file.
- Downloading and presenting a `.skill` file triggers installation in
  Claude Code.

### Discourse sandbox workaround

- Added note to the Discourse data source section: in sandboxed environments,
  seed `discourse.slicer.org` via a web search before fetching the API
  directly.

## v2.5: author update and MCP best practice

- Added jumbojing as a skill author.
- Added `.mcp.json` to `.gitignore`.
- **MCP best practice:** Documented that `.mcp.json` should never be included
  in a skill directory.  An MCP config bundled with a skill would silently
  activate the connection for every user who installs it — an unexpected
  behavior and a security risk.  The skill ships `mcp.json.sample` as a
  template; users copy it to their own project directory to opt in.
