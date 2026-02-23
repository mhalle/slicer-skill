# MCP Server Improvements

Planned improvements for `slicer-mcp-server.py`, the MCP server that runs
inside 3D Slicer and exposes tools to MCP clients (Claude Code, Claude Desktop,
Cline, etc.).

## Bug fixes

### Fix `execute_python` state persistence
Each `execute_python` call creates a fresh `exec_globals` dict, so variables
don't survive between calls.  A client that runs `x = 5` in one call and
`print(x)` in the next gets a `NameError`.  Fix: use a single shared
`exec_globals` dict that persists for the session.

### Import `ctk` so it's available in `execute_python`
The code lists `ctk` in the namespace injection loop (`globals().get("ctk")`)
but never imports it, so it silently resolves to `None`.  Add `import ctk` at
the top of the script alongside `qt`, `vtk`, and `slicer`.

### Fix notification responses
JSON-RPC notifications should produce no response.  The server currently
returns `{}`, which isn't valid JSON-RPC and could confuse strict clients.
Return an empty body with HTTP 204 instead.

### Guard `mcpStatusMessage` against headless mode
`slicer.util.mainWindow()` returns `None` when there's no GUI (testing,
headless server).  The current code will crash with an `AttributeError` on
`.statusBar()`.  Add a `None` check.

## New tools

### Structured node properties
Replace the current `get_node_properties` tool (which returns VTK's
unstructured `PrintSelf()` text dump) with two complementary tools:

- **`list_node_attributes`** — given a node ID, return the list of
  attribute/property names available on that node.  Cheap and always
  structured.
- **`get_node_attribute`** — given a node ID and attribute name, return the
  value.

This lets the agent discover what's on a node and drill into specific
properties without paying for a full dump every time.

### View-specific screenshots
Add an optional `view` parameter to the `screenshot` tool to capture a single
view (Red, Green, Yellow, 3D) instead of always grabbing the entire
application window.

### `list_sample_data`
Add a tool that returns the names and descriptions of available sample
datasets, making `load_sample_data` self-discoverable instead of requiring
the client to guess valid names.

## Protocol improvements

### Session ID handling
The Streamable HTTP transport spec says the server should issue an
`Mcp-Session-Id` header on `initialize` and the client sends it back on
subsequent requests.  The server is currently stateless, which works for
single-client use but can't distinguish multiple clients.

### CORS origin restriction
CORS is enabled with no origin restriction (`enableCORS=True`).  Any webpage
in the user's browser can hit `localhost:2026/mcp`.  The one-time consent
dialog mitigates this, but once the user clicks "Yes" for a legitimate client,
any other origin can piggyback for the rest of the session.  Consider
restricting allowed origins or adding per-request token auth.

## Larger features

### MCP resources for the scene graph
The MRML scene, current layout, and loaded module list are natural read-only
data that MCP resources were designed for.  Exposing these as resources would
let clients subscribe to scene changes and browse available modules without
needing `execute_python`.
