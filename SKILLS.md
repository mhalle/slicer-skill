---
name: slicer
description: Search and reason over 3D Slicer source, extensions, and community discussions
version: "1.0"
setup: ./setup.sh
requires: [git, perl, bash]
---

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

---

## Prerequisites

The setup script requires the following tools to be available on `$PATH`:

- **git** – for cloning and updating repositories.
- **perl** – used to parse CMake files when resolving SuperBuild dependencies.
- **bash** – the setup script targets Bash (macOS `/bin/bash` or Linux).

On macOS the built-in versions of these tools are sufficient. On minimal Linux
containers you may need to install `perl` and `git` explicitly.

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

The script is idempotent; re-running it will `git pull` existing clones rather than cloning
afresh.  On completion it writes a `.setup-stamp.json` timestamp file. Subsequent runs
automatically skip if the stamp is less than 24 hours old. Pass `--force` to bypass the
age check:

```sh
./setup.sh --force
```

### Verifying the setup

After the script finishes, confirm the key directories exist:

```sh
ls slicer-source/CMakeLists.txt slicer-extensions/README.md slicer-discourse/README.md slicer-dependencies/VTK
```

If any path is missing, re-run `./setup.sh` and check for error output.

> **Disk space and time:** A full clone (source + all extensions + dependencies + discourse)
> requires roughly 10–15 GB and can take 20+ minutes on a typical connection. You can
> limit which extensions are fetched by setting the `EXTENSION_FILTER` variable in
> `setup.sh` or by manually checking out only the subset you need.

---

## How the Agent Should Use the Data

Once the repositories are available the agent should search, read, and reason
over them to answer Slicer programming questions.  The key strategies are:

- **Search for code symbols** across `slicer-source`, extension subdirectories, or
  `slicer-dependencies`.
  CLI example: `git -C slicer-source grep -rn "vtkSmartPointer"`.
- **Find files by name or pattern** — locate headers, Python modules, CMake configs, etc.
  CLI example: `find slicer-source -name "*Logic.h"`.
- **Query the discourse archive** for community discussions about a topic.
  CLI example: `grep -rn "SegmentEditor" slicer-discourse`.
- **Inspect build dependencies** in `slicer-dependencies` when reasoning about
  build-time behavior, API versions, or exact tags used by the SuperBuild.
  CLI example: `git -C slicer-dependencies/VTK grep -rn "vtkNew"`.
- **Understand project structure** by reading CMakeLists, Python `__init__.py` files, and
  other configuration files in the clones.

> Agents with higher-level file search and content search tools (e.g. Glob, Grep, Read)
> should prefer those over raw shell commands when available.  The CLI examples above are
> provided for reference and for agents that only have shell access.

The goal is not merely to index, but to *reason* over the material.  For example, when
asked "how do I add a module to the build", the agent can search CMake macros in
`slicer-source` and provide a snippet of the real call sites.

## Extending the Skill

Additional data sources can be added by editing `setup.sh` and updating this document.
For example, if a new GitHub repository is released with tutorials, the script can be
extended to clone that repository and document its purpose here.

Agents that understand the SKILLS.md format should parse this file and use its sections to
bootstrap their reasoning about how to prepare and query the environment.

---

*Created and maintained by the Slicer community.*
