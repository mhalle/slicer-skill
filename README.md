# slicer-skill

This repository provides the groundwork for an **AI coding skill** that assists with
programming questions related to [3D Slicer](https://www.slicer.org).  The primary piece of
content is `SKILL.md` which describes how an agent can prepare its environment and what
resources are available for search.

## Getting started

1. Read `SKILL.md` for detailed information about the expected workflow and data
   sources.
2. Run the helper script to fetch the required repositories:
   ```sh
   chmod +x setup.sh
   ./setup.sh
   ```
3. Use the resulting local copies when answering questions by searching for
   code, files, and community discussions across the cloned repositories.

## Using the skill from other projects

The slicer-skill directory is intended to be a **shared, standalone resource** that
multiple projects can reference.  You should not clone Slicer repositories into your
own project directory.

To point your AI agent at the skill, add a section like the following to your
project's configuration file (e.g. `CLAUDE.md`, `AGENTS.md`, or equivalent).
Replace `/path/to/slicer-skill` with the absolute path where you cloned this
repository:

```markdown
## Slicer Programming Reference

For help answering 3D Slicer programming questions, use the slicer skill located at:

    /path/to/slicer-skill

That directory contains `SKILL.md` with instructions for searching Slicer source
code, extensions, discourse archives, and dependency repositories.

**Important:** All slicer-skill data lives in that single shared directory.
Do NOT clone repositories into this project directory.

- If the repos are not yet set up, run `setup.sh` **from within the slicer-skill
  directory**:
  ```sh
  cd /path/to/slicer-skill && ./setup.sh
  ```
- All searches should target paths under `/path/to/slicer-skill/`:
  - `/path/to/slicer-skill/slicer-source/`
  - `/path/to/slicer-skill/slicer-extensions/`
  - `/path/to/slicer-skill/slicer-discourse/`
  - `/path/to/slicer-skill/slicer-dependencies/`
```

### Claude Code

When using [Claude Code](https://docs.anthropic.com/en/docs/claude-code), you can
also add the slicer-skill directory to your session with the `--add-dir` flag:

```sh
claude --add-dir /path/to/slicer-skill
```

This makes the skill and all its data available for searching without copying
anything into your project.
