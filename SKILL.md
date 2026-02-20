---
name: slicer
description: >
  Search and reason over 3D Slicer source code, extensions, and community
  discussions.  Use for questions about medical imaging, MRML scene graphs,
  VTK/ITK pipelines, Slicer Python scripting, C++ module development,
  extension development, Qt-based module UI, segmentation, volume rendering,
  DICOM workflows, and the Slicer build system.
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

### Script Repository

The Slicer source tree contains a rich collection of scripted examples and utilities
under the **Script Repository** section of the documentation (located in
`slicer-source/Docs/developer_guide/script_repository.md` and related files).  When
implementing or explaining Slicer features, agents should **search the script repository
first** — it contains working Python snippets that demonstrate how to accomplish common
tasks such as:

- Loading and saving data (volumes, models, segmentations, transforms, etc.)
- Manipulating MRML nodes and the scene graph
- Working with the Segment Editor and its effects
- Creating and updating views, layouts, and widget properties
- Accessing volume data as NumPy arrays via `slicer.util.arrayFromVolume`
- Running CLI modules and connecting to module logic classes
- Registering custom keyboard shortcuts, timers, and event observers

These snippets are the closest equivalent to "official cookbook recipes" and are
frequently more accurate and idiomatic than ad-hoc code generation.  When answering a
user's question, prefer citing or adapting a script repository example over writing code
from scratch.

The script repository is assembled from per-topic markdown files.  The main entry point
is `slicer-source/Docs/developer_guide/script_repository.md`, which includes:

| File                          | Topics covered                                      |
| ----------------------------- | --------------------------------------------------- |
| `script_repository/gui.md`    | Layouts, views, widget access, keyboard shortcuts   |
| `script_repository/volumes.md`| Loading volumes, NumPy access, scalar/vector data   |
| `script_repository/segmentations.md` | Segment Editor, effects, import/export       |
| `script_repository/transforms.md`    | Linear and non-linear transforms             |
| `script_repository/markups.md`       | Fiducials, curves, planes, ROIs              |
| `script_repository/models.md`        | Surface meshes, polydata, model display      |
| `script_repository/dicom.md`         | DICOM loading, exporting, database           |
| `script_repository/plots.md`         | Chart views and plot series                  |
| `script_repository/sequences.md`     | Time sequences, browsing, replay             |
| `script_repository/registration.md`  | Image registration workflows                 |
| `script_repository/screencapture.md` | Screenshots, video, 3D export                |
| `script_repository/subjecthierarchy.md` | Subject hierarchy tree operations         |
| `script_repository/tractography.md`  | Diffusion tractography                       |
| `script_repository/batch.md`         | Batch processing patterns                    |
| `script_repository/webserver.md`     | Slicer web server API                        |

When searching for an example, grep within these files by topic keyword rather than
searching the entire source tree.

---

## Slicer Architecture — Where to Learn About Key Concepts

Rather than duplicating Slicer's documentation, this section tells you **where to look**
in the checked-out repositories to learn about each major concept.  Read the referenced
files directly when you need to understand or explain a topic.

### Project Structure

Inspect `slicer-source/` to understand the top-level layout:

- `Base/` — Core application framework.
  - `Base/Python/slicer/` — The `slicer` Python package (`util.py`, `ScriptedLoadableModule.py`, etc.).  Read these to understand the Python API surface.
  - `Base/QTCore/` — Non-GUI application logic (settings, I/O manager, module factory).
  - `Base/QTGUI/` — Main application GUI (layout manager, module panel, data widgets).
  - `Base/Logic/` — Application-level logic classes.
- `Libs/` — Shared libraries that do not depend on Qt.
  - `Libs/MRML/Core/` — The MRML scene graph: node classes, events, serialization.  Header files (`vtkMRML*.h`) document the node hierarchy.
  - `Libs/vtkSegmentationCore/` — Segmentation data structures and conversion logic.
  - `Libs/vtkITK/` — VTK/ITK bridge filters.
  - `Libs/vtkTeem/` — Teem-based readers (NRRD, DWI).
- `Modules/` — Built-in modules, organized by type:
  - `Modules/Loadable/` — C++ modules with Qt UI (Volumes, Segmentations, Markups, Transforms, Models, VolumeRendering, etc.).
  - `Modules/Scripted/` — Python-only modules (SegmentEditor, DICOM, SampleData, ExtensionWizard, SegmentStatistics, etc.).
  - `Modules/CLI/` — Command-line interface modules (filters, registration, model makers).
- `Docs/developer_guide/` — Developer documentation in Markdown/RST.
- `SuperBuild/` — CMake `External_*.cmake` files that define each dependency's repository URL, tag, and build flags.

### Module Types

Slicer has three module types.  To understand the conventions for each, read these
reference implementations:

- **Scripted modules**: Read `slicer-source/Modules/Scripted/SampleData/` or
  `slicer-source/Modules/Scripted/SegmentStatistics/` for the standard pattern:
  a module class, a widget class, a logic class, and a test class, all in Python.
  The base classes are defined in `slicer-source/Base/Python/slicer/ScriptedLoadableModule.py`.
- **Loadable modules** (C++ with Qt UI): Read `slicer-source/Modules/Loadable/Volumes/`
  or `slicer-source/Modules/Loadable/Markups/` for the pattern: a `qSlicer*Module` class,
  a widget, a logic, and MRML node classes, built with CMake.
- **CLI modules**: Read `slicer-source/Modules/CLI/AddScalarVolumes/` for the minimal
  pattern: an XML description file and a C++ (or Python) executable using
  `SlicerExecutionModel`.

For an overview document, read `slicer-source/Docs/developer_guide/module_overview.md`.

### MRML (Medical Reality Markup Language)

MRML is the in-memory scene graph that holds all data.  To learn about it:

- Read `slicer-source/Docs/developer_guide/mrml_overview.md` for the conceptual overview.
- Read `slicer-source/Docs/developer_guide/mrml.md` for the developer reference.
- Browse header files in `slicer-source/Libs/MRML/Core/` — each `vtkMRML*Node.h` file
  documents a node type (volume, model, segmentation, transform, display, storage, etc.).
- For the Python API to the scene, read `slicer-source/Base/Python/slicer/util.py` —
  functions like `getNode()`, `loadVolume()`, `arrayFromVolume()`, and `updateVolumeFromArray()`
  are defined there.

### Segment Editor

The Segment Editor is one of Slicer's most complex subsystems.  To understand it:

- Read `slicer-source/Modules/Scripted/SegmentEditor/` for the module and widget.
- Read the Python effects in
  `slicer-source/Modules/Loadable/Segmentations/EditorEffects/Python/SegmentEditorEffects/`
  — each file (`SegmentEditorThresholdEffect.py`, `SegmentEditorDrawEffect.py`, etc.)
  implements one effect and serves as a template for custom effects.
- Read the abstract base classes in the same directory
  (`AbstractScriptedSegmentEditorEffect.py`, etc.) to understand the effect API.
- Search the script repository file `script_repository/segmentations.md` for usage examples.

### VTK and ITK Patterns

When questions involve VTK or ITK classes:

- Search `slicer-dependencies/VTK/` for VTK header files and examples.
- Search `slicer-dependencies/ITK/` for ITK header files and examples.
- Read `slicer-source/Libs/vtkITK/` for how Slicer bridges VTK and ITK.
- Read `slicer-source/Docs/developer_guide/vtkAddon.md` for Slicer's VTK add-on utilities.
- For VTK pipeline patterns used in Slicer modules, browse `.cxx` files in
  `slicer-source/Modules/Loadable/` — these show real-world VTK pipeline construction,
  smart pointer usage, and observer patterns.

### Build System

Slicer uses CMake with a SuperBuild pattern:

- `slicer-source/CMakeLists.txt` — top-level build configuration.
- `slicer-source/SuperBuild/External_*.cmake` — one file per dependency, specifying the
  repository URL, git tag, and CMake arguments.  Read these to find the exact version of
  VTK, ITK, CTK, DCMTK, etc. that Slicer uses.
- `slicer-source/Docs/developer_guide/build_instructions/` — platform-specific build guides.
- For module-level CMake patterns, read `CMakeLists.txt` in any module under
  `Modules/Loadable/` or `Modules/CLI/`.

### Extension Development

To understand how extensions are structured and distributed:

- Read `slicer-source/Docs/developer_guide/extensions.md` for the developer guide.
- Inspect the Extension Wizard at `slicer-source/Modules/Scripted/ExtensionWizard/` —
  this is the tool that generates new extension scaffolding.
- Browse `slicer-extensions/` for real extension examples.  Well-structured extensions
  that demonstrate common patterns include:
  - `slicer-extensions/SlicerIGT/` — a multi-module C++ extension for image-guided therapy
    with loadable modules, transforms, and Qt widgets.
  - `slicer-extensions/MONAILabel/` — a Python extension integrating deep learning inference.
- The `slicer-extensions/` directory also contains `.json` index files
  (e.g. `SlicerIGT.json`).  These specify the repository URL, description, and
  dependencies for each extension.  Read them when you need to locate an extension's
  source repository.

### Python Utilities and the `slicer` Package

The `slicer` Python package is the primary API for scripting.  To understand it:

- Read `slicer-source/Base/Python/slicer/util.py` — this is the most important file.
  It defines data loading/saving functions, node access, array conversion, and
  UI utilities.
- Read `slicer-source/Base/Python/slicer/ScriptedLoadableModule.py` — defines the base
  classes for scripted modules (`ScriptedLoadableModule`, `ScriptedLoadableModuleWidget`,
  `ScriptedLoadableModuleLogic`, `ScriptedLoadableModuleTest`).
- Read `slicer-source/Base/Python/slicer/parameterNodeWrapper/` — the parameter node
  wrapper system for declarative module parameters.
- Read `slicer-source/Base/Python/slicer/__init__.py` for the top-level namespace
  (access to `slicer.mrmlScene`, `slicer.app`, `slicer.modules`, etc.).

### Discourse Archive — Searching Community Knowledge

The discourse archive contains ~18,700 rendered forum topics organized by year and month:

```
slicer-discourse/archive/rendered-topics/
  2017/ 2018/ 2019/ 2020/ 2021/ 2022/ 2023/ 2024/ 2025/ 2026/
    YYYY-MM/
      YYYY-MM-DD-topic-slug-idNNNNN.md
```

Each file is a single Discourse thread rendered as Markdown.  The filename includes a
date, a human-readable slug, and the topic ID.  To search effectively:

- Grep across the archive for keywords (e.g. `grep -rn "arrayFromVolume" slicer-discourse/`).
- Use the `slicer-discourse/archive/INDEX.md` file for an overview.
- When code-search in `slicer-source` is insufficient, search the discourse archive
  for community workarounds, tips, and explanations — forum threads often explain
  *why* things work a certain way, not just *how*.

---

## Common Pitfalls

These are frequently encountered mistakes that are **not obvious from reading the source
code alone**.  The agent should be aware of them when generating or reviewing Slicer code.

- **`arrayFromVolume` returns a view, not a copy.** After modifying the array in-place,
  you must call `slicer.util.arrayFromVolumeModified(volumeNode)` to notify the
  display pipeline.  Forgetting this results in the view not updating.
- **MRML node names are not unique identifiers.** Multiple nodes can share the same name.
  Use `node.GetID()` for reliable identification, not `node.GetName()`.
- **The Python console runs on the main Qt thread.** Long-running operations block the
  UI.  Use `slicer.app.processEvents()` in loops or run work in a background thread
  with `qt.QTimer.singleShot()` callbacks.
- **Coordinate system conventions.** Slicer uses RAS (Right-Anterior-Superior) internally,
  while many file formats and tools use LPS (Left-Posterior-Superior).  Transforms
  between RAS and LPS are a common source of sign-flip bugs.
- **Volume axis ordering.** `slicer.util.arrayFromVolume()` returns arrays in KJI order
  (slice, row, column), not IJK.  This is the reverse of what many users expect.
- **Extension CMake patterns differ from standalone projects.** Extensions must use
  Slicer-specific CMake macros (e.g. `slicerMacroBuildScriptedModule`,
  `slicerMacroBuildLoadableModule`).  Using plain `add_library` will not integrate
  correctly with Slicer's module loading system.
- **`slicer.util.pip_install()` for runtime dependencies.** Slicer bundles its own Python
  environment.  Extensions should install additional Python packages via
  `slicer.util.pip_install("package")` in their module code, not via system pip.

---

## Extending the Skill

Additional data sources can be added by editing `setup.sh` and updating this document.
For example, if a new GitHub repository is released with tutorials, the script can be
extended to clone that repository and document its purpose here.

Agents that understand the SKILLS.md format should parse this file and use its sections to
bootstrap their reasoning about how to prepare and query the environment.

---

*Created and maintained by the Slicer community.*
