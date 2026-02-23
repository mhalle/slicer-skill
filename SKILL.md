---
name: slicer-skill
description: >
  Searches and reasons over 3D Slicer source code, extensions, and community
  discussions. Use when answering questions about medical imaging, MRML scene
  graphs, VTK/ITK pipelines, Slicer Python scripting, C++ module development,
  extension development, Qt-based module UI, segmentation, volume rendering,
  DICOM workflows, and the Slicer build system.
compatibility: "Requires git and bash"
metadata:
  version: "2.1"
---

# Slicer Skill

An AI coding skill for answering programming questions about
[3D Slicer](https://www.slicer.org).  It provides two local repositories and
two web APIs as data sources.

---

## Setup

Repositories are cached in `~/.cache/slicer-skill/repositories/`.  If the
directories `slicer-source/` or `slicer-extensions/` are missing there, run:

```sh
scripts/setup.sh
```

The script shallow-clones both repos and writes a stamp file so that
subsequent runs skip if the stamp is less than 24 hours old.  Pass `--force`
to bypass the age check.

The cache directory can be overridden when `~/.cache` is not writable
(e.g. sandboxed environments):

```sh
# Via argument
scripts/setup.sh /tmp/slicer-skill-${USER}

# Via environment variable
export SLICER_SKILL_CACHE_DIR=/tmp/slicer-skill-${USER}
scripts/setup.sh
```

Both `--force` and a custom directory can be combined in any order.
When a custom directory is used, all path references below should be read
relative to `<CACHE_DIR>/repositories/` instead of
`~/.cache/slicer-skill/repositories/`.

---

## Data Sources

All local paths below are relative to `~/.cache/slicer-skill/repositories/`.

### 1. Slicer Source (local)

Path: `slicer-source/`

The full Slicer application source tree.  Use Grep/Read to search for symbols,
read documentation, and inspect module implementations.

### 2. ExtensionsIndex (local)

Path: `slicer-extensions/`

Extensions are community-developed add-ons that extend Slicer with new modules,
algorithms, and integrations.  The index contains 241 extensions across 63
categories (Segmentation, IGT, Quantification, Informatics, Registration, etc.).

Each `.json` file (e.g. `SlicerIGT.json`) contains `scm_url`, `category`,
`build_dependencies`, and `tier`.  To find extensions by topic:

```sh
grep -l '"category": "Segmentation"' ~/.cache/slicer-skill/repositories/slicer-extensions/*.json
```

If `jq` is available, use it to query the index more precisely:

```sh
EXTDIR=~/.cache/slicer-skill/repositories/slicer-extensions

# List all categories
jq -r '.category' "$EXTDIR"/*.json | sort -u

# Find extensions in a category with their repo URLs
for f in "$EXTDIR"/*.json; do
  jq -r 'select(.category == "Segmentation") | .scm_url' "$f" 2>/dev/null
done

# Get full details for a specific extension
jq . "$EXTDIR"/SlicerIGT.json
```

To inspect an extension's source code, read its JSON file for the `scm_url`
field and clone the repository on demand.  On-demand clones go as siblings of
`slicer-source/` and `slicer-extensions/`, using the extension's own name:

```sh
REPO_DIR=~/.cache/slicer-skill/repositories
EXTENSION=SlicerIGT  # example

# Clone if not already present; pull if it is
if [ -d "$REPO_DIR/$EXTENSION/.git" ]; then
  git -C "$REPO_DIR/$EXTENSION" pull --ff-only 2>/dev/null || true
else
  scm_url=$(jq -r '.scm_url' "$REPO_DIR/slicer-extensions/$EXTENSION.json")
  git clone --depth 1 "$scm_url" "$REPO_DIR/$EXTENSION"
fi
```

Well-known extensions that demonstrate common patterns:
- **SlicerIGT** — multi-module C++ extension (image-guided therapy, transforms, Qt widgets)
- **MONAILabel** — Python extension integrating deep learning inference
- **SegmentEditorExtraEffects** — custom Segment Editor effects
- **SlicerElastix** — registration extension wrapping an external tool
- **SlicerDMRI** — diffusion MRI processing (tractography, tensor estimation)

### 3. Discourse (API)

Search the Slicer community forum via the Discourse search API:

```
https://discourse.slicer.org/search.json?q=<query>
```

Use this when source-code search is insufficient — forum threads often explain
*why* things work a certain way, not just *how*.  Results include topic titles,
excerpts, and links to full discussions.

**Query filters** — append these to the search term:

| Filter | Example | Effect |
|--------|---------|--------|
| `category:` | `segmentation category:support` | Restrict to a category (`support`, `dev`, `announcements`, `community`) |
| `status:solved` | `volume rendering status:solved` | Only topics with an accepted answer |
| `@username` | `transforms @lassoan` | Posts by a specific user |
| `tags:` | `segmentation tags:python` | Filter by topic tag |
| `order:latest` | `DICOM order:latest` | Sort by most recent |
| `after:` / `before:` | `arrayFromVolume after:2024-01-01` | Date range filter |
| `in:first` | `pip_install in:first` | Search only opening posts (skip replies) |

Paginate with `&page=2`, `&page=3`, etc. (50 results per page).  The response
field `grouped_search_result.more_full_page_results` indicates whether more
pages exist.

**Tip:** Combine filters for precise results, e.g.:
```
https://discourse.slicer.org/search.json?q=segment%20editor%20category:support%20status:solved%20order:latest
```

### 4. Dependencies (SuperBuild + web)

Slicer's `SuperBuild/External_*.cmake` files specify the exact repository URL,
git tag, and build flags for each dependency (VTK, ITK, SimpleITK, CTK, DCMTK, etc.).
Grep these files for version and configuration information.  For API details of
a dependency, use web search — cloning multi-GB dependency repos is rarely
worthwhile.

---

## MCP Server (live Slicer interaction)

This skill includes an MCP server (`slicer-mcp-server.py`) that runs inside a
live 3D Slicer session.  When connected, it provides tools to list scene nodes,
execute Python code, take screenshots, and load sample data — letting you
combine source-code knowledge with live interaction.

**The MCP server is optional** and not enabled by default.  The user must
configure their MCP client and start the server inside Slicer before the tools
become available.  See [references/mcp.md](references/mcp.md) for client
configuration, usage patterns, the `__result` convention, and tips for
effective tool use.

---

## Script Repository

The Slicer source tree contains working Python snippets that demonstrate common
tasks.  **Search the script repository first** when implementing or explaining
Slicer features — these are the closest equivalent to official cookbook recipes
and are more accurate than ad-hoc code generation.

Main entry point: `slicer-source/Docs/developer_guide/script_repository.md`

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

When searching for an example, grep within these files by topic keyword rather
than searching the entire source tree.

---

## Slicer Architecture — Where to Look

### Project Structure

Inspect `slicer-source/` to understand the top-level layout:

- `Base/` — Core application framework.
  - `Base/Python/slicer/` — The `slicer` Python package (`util.py`, `ScriptedLoadableModule.py`, etc.).
  - `Base/QTCore/` — Non-GUI application logic (settings, I/O manager, module factory).
  - `Base/QTGUI/` — Main application GUI (layout manager, module panel, data widgets).
  - `Base/Logic/` — Application-level logic classes.
- `Libs/` — Shared libraries that do not depend on Qt.
  - `Libs/MRML/Core/` — MRML scene graph: node classes, events, serialization.
  - `Libs/vtkSegmentationCore/` — Segmentation data structures and conversion logic.
  - `Libs/vtkITK/` — VTK/ITK bridge filters.
  - `Libs/vtkTeem/` — Teem-based readers (NRRD, DWI).
- `Modules/` — Built-in modules by type:
  - `Modules/Loadable/` — C++ modules with Qt UI (Volumes, Segmentations, Markups, Transforms, etc.).
  - `Modules/Scripted/` — Python-only modules (SegmentEditor, DICOM, SampleData, etc.).
  - `Modules/CLI/` — Command-line interface modules (filters, registration, model makers).
- `Docs/developer_guide/` — Developer documentation in Markdown/RST.
- `SuperBuild/` — CMake `External_*.cmake` files defining each dependency.

### Module Types

Slicer has three module types.  Reference implementations:

- **Scripted modules**: `Modules/Scripted/SampleData/` or `Modules/Scripted/SegmentStatistics/`.
  Base classes: `Base/Python/slicer/ScriptedLoadableModule.py`.
- **Loadable modules** (C++ with Qt UI): `Modules/Loadable/Volumes/` or `Modules/Loadable/Markups/`.
- **CLI modules**: `Modules/CLI/AddScalarVolumes/` — XML description + C++ executable.

Overview doc: `Docs/developer_guide/module_overview.md`.

### MRML (Medical Reality Markup Language)

MRML is the in-memory scene graph holding all data.

- Conceptual overview: `Docs/developer_guide/mrml_overview.md`
- Developer reference: `Docs/developer_guide/mrml.md`
- Node headers: `Libs/MRML/Core/vtkMRML*Node.h`
- Python API: `Base/Python/slicer/util.py` — `getNode()`, `loadVolume()`, `arrayFromVolume()`, etc.

### Segment Editor

- Module and widget: `Modules/Scripted/SegmentEditor/`
- Effect implementations: `Modules/Loadable/Segmentations/EditorEffects/Python/SegmentEditorEffects/`
- Base class API: `AbstractScriptedSegmentEditorEffect.py` in the same directory
- Usage examples: `script_repository/segmentations.md`

### VTK and ITK Patterns

- VTK/ITK bridge: `Libs/vtkITK/`
- VTK add-on utilities: `Docs/developer_guide/vtkAddon.md`
- Real-world VTK pipelines: browse `.cxx` files in `Modules/Loadable/`
- For VTK/ITK API details beyond what's in Slicer source, use web search

### Build System

- Top-level: `CMakeLists.txt`
- Dependencies: `SuperBuild/External_*.cmake` (one per dependency with repo URL and git tag)
- Build guides: `Docs/developer_guide/build_instructions/`
- Module CMake patterns: `CMakeLists.txt` in any module under `Modules/Loadable/` or `Modules/CLI/`

### Extension Development

- Developer guide: `Docs/developer_guide/extensions.md`
- Extension scaffolding: `Modules/Scripted/ExtensionWizard/`
- Extension index files: `slicer-extensions/*.json` (contain `scm_url`, category, dependencies)
- To study a real extension, clone it on demand into
  `~/.cache/slicer-skill/repositories/<ExtensionName>` (see Data Sources §2)
  and read its `CMakeLists.txt` and module directories — the structure mirrors
  core modules

### Python Utilities

- `Base/Python/slicer/util.py` — most important file: data loading, node access, array conversion
- `Base/Python/slicer/ScriptedLoadableModule.py` — base classes for scripted modules
- `Base/Python/slicer/parameterNodeWrapper/` — declarative module parameters
- `Base/Python/slicer/__init__.py` — top-level namespace (`slicer.mrmlScene`, `slicer.app`, etc.)

### Coding Style

- Style guide: `Docs/developer_guide/style_guide.md`
- Contribution guidelines: `CONTRIBUTING.md`
- Python conventions: examine `Modules/Scripted/SegmentStatistics/` for naming patterns
- C++ conventions: browse `.cxx`/`.h` files in `Modules/Loadable/` (VTK style)

### Testing

- Python test base class: `ScriptedLoadableModuleTest` in `Base/Python/slicer/ScriptedLoadableModule.py`
- Python test examples: `Modules/Scripted/SegmentStatistics/Testing/`, `Modules/Scripted/SampleData/Testing/`
- C++ test examples: `Testing/` subdirectories under `Modules/Loadable/`
- Debugging guides: `Docs/developer_guide/debugging/`
- Python FAQ: `Docs/developer_guide/python_faq.md`

---

## Common Pitfalls

These are frequently encountered mistakes that are **not obvious from reading
the source code alone**.

- **`arrayFromVolume` returns a view, not a copy.** After modifying the array
  in-place, call `slicer.util.arrayFromVolumeModified(volumeNode)` to notify
  the display pipeline.  Forgetting this results in the view not updating.
- **MRML node names are not unique identifiers.** Multiple nodes can share the
  same name.  Use `node.GetID()` for reliable identification.
- **The Python console runs on the main Qt thread.** Long-running operations
  block the UI.  Use `slicer.app.processEvents()` in loops or
  `qt.QTimer.singleShot()` callbacks.
- **Coordinate system conventions.** Slicer uses RAS internally; many file
  formats use LPS.  RAS/LPS transforms are a common source of sign-flip bugs.
- **Volume axis ordering.** `arrayFromVolume()` returns arrays in KJI order
  (slice, row, column), not IJK.
- **Extension CMake patterns differ from standalone projects.** Use
  `slicerMacroBuildScriptedModule`, `slicerMacroBuildLoadableModule`, etc.
  Plain `add_library` will not integrate with Slicer's module loading.
- **`slicer.util.pip_install()` for runtime dependencies.** Slicer bundles its
  own Python environment.  Use `pip_install("package")` in module code, not
  system pip.

---

## Common Workflows

**Load DICOM data, segment a structure, export the result:**
1. DICOM import — `script_repository/dicom.md`
2. Segmentation — `script_repository/segmentations.md`
3. Export — search `script_repository/segmentations.md` for "export"
   and `script_repository/models.md` for surface mesh saving

**Create a new scripted module from scratch:**
1. Scaffolding — `Modules/Scripted/ExtensionWizard/`
2. Module pattern — `Modules/Scripted/SampleData/` as a template
3. Parameter node wrapper — `Base/Python/slicer/parameterNodeWrapper/`
4. Testing — `Modules/Scripted/SegmentStatistics/Testing/`

**Add a custom Segment Editor effect:**
1. Base class API — `AbstractScriptedSegmentEditorEffect.py` in
   `Modules/Loadable/Segmentations/EditorEffects/Python/SegmentEditorEffects/`
2. Example effects — other `SegmentEditor*Effect.py` files in the same directory
3. Registration — search for `registerEditorEffect`

**Build Slicer or an extension from source:**
1. Build instructions — `Docs/developer_guide/build_instructions/`
2. SuperBuild dependencies — `SuperBuild/External_*.cmake`
3. Extension build — `Docs/developer_guide/extensions.md`

**Work with transforms and coordinate systems:**
1. Transform examples — `script_repository/transforms.md`
2. RAS/LPS conventions — search `Docs/` for "coordinate" or "RAS"
3. Transform node API — `Libs/MRML/Core/vtkMRMLTransformNode.h`

---
