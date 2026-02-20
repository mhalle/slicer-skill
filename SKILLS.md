# Slicer Skill

This repository contains the information and helper scripts needed by an AI coding agent ("skill")
that is designed to answer questions about the [3D Slicer](https://www.slicer.org) application and
its extension ecosystem.  It is intentionally generic so that it can be consumed by any tool that
understands the SKILLS.md convention (e.g. Claude Code, OpenAI agents, etc.).

## Goal

When invoked the skill should ensure it has a local copy of the relevant Slicer resources:

1. The **Slicer source code** – the official C++/Python repositories that make up the
   application.
2. The **Extensions Index** – a machine‑readable list of third‑party extensions and their
   repositories.  The skill should iterate through the index files and clone each listed
   repository so that extension code is available for searching.
3. The **Discourse archive** – a mirror of the Slicer Discourse forum content (see
   https://github.com/pieper/slicer-discourse-archive) to allow question‑answering based on
   past community discussions.

With these resources available locally, the agent can use standard command‑line tools
(`git grep`, `grep`, `find`, etc.) to search for symbols, examples, documentation,
Python modules, build configurations, and other snippets that help it craft accurate and
precise responses to programming questions about Slicer.

> 📁 Repositories are checked out into subdirectories of the skill workspace named
> `slicer-source`, `slicer-extensions`, `slicer-discourse` and `slicer-dependencies` respectively.
> You are free to override these paths by setting the `SLICER_SRC_DIR`, `SLICER_EXT_DIR`,
> `SLICER_DISCOURSE_DIR` and `SLICER_DEP_DIR` environment variables before running the setup script.

> **SKILLS.md Format & Parsing Hints**
>
> - Agents and tools should look for these canonical sections: **Goal**, **Setup
>   Instructions**, **How the Agent Should Use the Data**, and **Extending the Skill**.
> - Keep runnable commands in fenced code blocks and list environment variables that
>   can be overridden (for example `SLICER_SRC_DIR`, `SLICER_EXT_DIR`, `SLICER_DISCOURSE_DIR`,
>   `SLICER_DEP_DIR`).
> - If machine metadata is needed, prefer a short YAML frontmatter block or an explicit
>   `Metadata` subsection describing the repository layout and parsing semantics.
> - Provide short examples of common queries (e.g., `git -C slicer-source grep -n "symbol"`)
>   to make it easier for automated tooling to validate the environment.

---

## Setup Instructions

The easiest way to obtain and refresh the necessary data is by running the provided shell
script:

```sh
./setup.sh
```

On success it will create/update the following folders:

- `slicer-source` – a `git clone` of `https://github.com/Slicer/Slicer.git` (branch `main` by
  default).
- `slicer-extensions` – a `git clone` of the official [Slicer ExtensionsIndex](https://github.com/Slicer/ExtensionsIndex).
  After cloning it enumerates the JSON index files and clones every extension repository it
  references.
- `slicer-discourse` – a `git clone` of
  `https://github.com/pieper/slicer-discourse-archive`.
 - `slicer-dependencies` – clones of the SuperBuild dependency repositories (VTK, ITK, CTK,
   DCMTK, teem, etc.) placed next to `slicer-source`. These checkouts mirror the exact
   repository URLs and git tags/commits referenced by the Slicer SuperBuild and are useful
   for inspecting build-time APIs, headers, and dependency versions.

The script is idempotent; re‑running it will `git pull` existing clones rather than cloning
afresh copy.  See the header of `setup.sh` for additional options.

> ⚠️ The extension index can contain hundreds of repositories and cloning them all may take a
> while.  You can limit which extensions are fetched by editing the `EXTENSION_FILTER`
> variable in `setup.sh` or by manually checking out only the subset you need.

---

## How the Agent Should Use the Data

Once the repositories are available, the agent should treat them as follows:

- **Search for code** using `git grep` within `slicer-source` or any extension subdirectory.
  Example: `git -C slicer-source grep -n "vtkSmartPointer"`.
- **Locate header files** or module documentation with `find`, e.g.:  
  `find slicer-source -name "*Logic.h"`.
- **Query the discourse archive** by grepping for keywords:  
  `grep -R "SegmentEditor" slicer-discourse`.
- **Understand project structure** by inspecting CMakeLists, Python `__init__.py` files, and
  other configuration files in the clones.

- **Use build dependencies** by inspecting `slicer-dependencies` when reasoning about
  build-time behavior: check headers, API versions and exact tags used by the SuperBuild.
  Example: `git -C slicer-dependencies/ITK grep -n "SomeITKSymbol"`.

The goal is not merely to index, but to *reason* over the material.  For example, when
asked "how do I add a module to the build", the agent can search CMake macros in
`slicer-source/Applications/CLI/CMakeLists.txt` and provide a snippet of the real
call sites.

## Extending the Skill

Additional data sources can be added by editing `setup.sh` and updating this document.
For example, if a new GitHub repository is released with tutorials, the script can be
extended to clone that repository and document its purpose here.

Agents that understand the SKILLS.md format should parse this file and use its sections to
bootstrap their reasoning about how to prepare and query the environment.

---

*Created and maintained by the Slicer community.*
