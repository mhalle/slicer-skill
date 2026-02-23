# MCP Server Reference

The Slicer MCP server (`slicer-mcp-server.py`) runs inside a live 3D Slicer
session and exposes tools over HTTP at `http://localhost:2026/mcp`.  It uses the
MCP Streamable HTTP transport, so no external dependencies are needed beyond
Slicer's built-in WebServer module.

## When the server is not running

If Slicer is not running or the server script has not been started, MCP tool
calls will fail with a connection error.  This is expected.  The skill's core
functionality — source-code search, Discourse API, extension index — works
independently of the MCP server.  Simply proceed without the MCP tools.

Do not:
- Attempt to start Slicer or the server on behalf of the user
- Retry failed connections repeatedly
- Treat connection errors as a problem to diagnose

## Client configuration

To connect an MCP client to the Slicer server, add the following to your
project's `.mcp.json` (or `claude_desktop_config.json`, etc.):

```json
{
  "mcpServers": {
    "slicer": {
      "type": "http",
      "url": "http://localhost:2026/mcp"
    }
  }
}
```

A sample file is provided at `mcp.json.sample` in the skill root.  This is
not activated automatically — copy it to `.mcp.json` in your project when you
want to enable the MCP connection.

## Starting the server

The user must start the server themselves from within Slicer:

1. Open 3D Slicer
2. Paste the contents of `slicer-mcp-server.py` into the Python console
   (or run `execfile("/path/to/slicer-mcp-server.py")`)
3. A consent dialog will appear on first MCP client connection — the user
   must click "Yes" to allow access

To stop: `mcpLogic.stop()` in the Slicer Python console.

## Available tools

The server exposes these MCP tools (discovered automatically via `tools/list`):

| Tool | Description |
|------|-------------|
| `list_nodes` | List MRML nodes in the scene (optionally filtered by class) |
| `get_node_properties` | Get the full property dump of a node by ID |
| `execute_python` | Execute Python code inside the running Slicer |
| `screenshot` | Capture the Slicer application window as a PNG |
| `load_sample_data` | Load a named sample dataset (MRHead, CTChest, etc.) |

## Using `execute_python`

This is the most powerful tool.  It runs arbitrary Python code in Slicer's
environment with `slicer`, `vtk`, `qt`, and `ctk` available in the namespace.

### Returning values with `__result`

To get a value back from `execute_python`, assign it to the special variable
`__result`:

```python
# Good — returns the volume count
__result = len(slicer.util.getNodesByClass("vtkMRMLScalarVolumeNode"))
```

```python
# Bad — prints to Slicer's console but returns nothing useful to the MCP client
print(len(slicer.util.getNodesByClass("vtkMRMLScalarVolumeNode")))
```

If `__result` is not set, the tool returns `"OK (no __result set)"`.

### Known limitation: no state persistence

Each `execute_python` call runs in a fresh namespace.  Variables set in one
call do not survive to the next.  If you need to build up state across calls,
store values on persistent objects:

```python
# Call 1: store a value
slicer.myData = {"count": 42}
```

```python
# Call 2: retrieve it
__result = slicer.myData["count"]
```

### UI responsiveness

Code runs on Slicer's main Qt thread.  For long operations, call
`slicer.app.processEvents()` periodically to keep the UI responsive.
Call it before `screenshot` to ensure views are up to date:

```python
slicer.app.processEvents()
slicer.util.forceRenderAllViews()
```

## Combining source search with live execution

The most effective workflow combines the skill's source-code search with
live execution via MCP:

1. **Search** the source code or script repository to find the right API
2. **Execute** it in the live Slicer session via `execute_python`
3. **Screenshot** to verify the result visually
4. **Iterate** based on what you see

Example: to apply a threshold to a volume, first search
`script_repository/segmentations.md` for threshold examples, then adapt and
run the code via `execute_python`, then take a `screenshot` to confirm.

## Tips

- Use `list_nodes` to discover what data is loaded before writing code
  that references specific nodes.
- Use `load_sample_data` with names like `MRHead`, `CTChest`, `CTACardio`,
  or `MRBrainTumor1` to get test data into an empty scene.
- Node IDs (from `list_nodes`) are more reliable than node names for
  `slicer.mrmlScene.GetNodeByID()`.  Names are not unique.
- The `screenshot` tool captures the entire application window.  Ensure the
  relevant view is visible before capturing.
- If `execute_python` returns an error traceback, read it carefully — Slicer
  error messages are usually informative about what went wrong.
