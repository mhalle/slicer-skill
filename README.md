# slicer-skill

This repository provides the groundwork for an **AI coding skill** that assists with
programming questions related to [3D Slicer](https://www.slicer.org).  The primary piece of
content is `SKILL.md` which describes how an agent can prepare its environment and what
resources are available for search.

## Getting started

Install the skill (see Installation below).  The agent reads `SKILL.md` for
data sources and workflow instructions and runs `scripts/setup.sh` automatically
to fetch the required repositories when needed.

## Installation

### Claude.ai

Download the `.skill` file from the
[latest release](https://github.com/mhalle/slicer-skill/releases/latest/download/slicer-skill.skill)
and add it to Claude.ai.  See
[Using Skills in Claude](https://support.claude.com/en/articles/12512180-using-skills-in-claude)
for instructions.

### Claude Code

**Option A — Download the `.skill` file (recommended):**

Download the latest release from the
[latest release](https://github.com/mhalle/slicer-skill/releases/latest/download/slicer-skill.skill)
and open the `.skill` file.  Claude Code will prompt you to install it.

**Option B — Clone the repository:**

```sh
git clone https://github.com/mhalle/slicer-skill ~/.claude/skills/slicer-skill
```

Claude Code automatically reads `SKILL.md` files from `~/.claude/skills/`.
The skill will be available in all sessions without additional configuration.
The agent will run `scripts/setup.sh` automatically when it needs the local
repositories.

You can also add the skill to a single session with `--add-dir`:

```sh
claude --add-dir /path/to/slicer-skill
```

### Other agents

Most AI coding agents that support the SKILLS.md convention (Codex, Cursor,
Windsurf, etc.) can use this skill by pointing them at the cloned directory.
The typical approach is to add a reference to your project's agent
configuration file (e.g. `AGENTS.md`, `CLAUDE.md`, or equivalent):

````markdown
## Slicer Programming Reference

For help answering 3D Slicer programming questions, use the slicer skill
located at:

    /path/to/slicer-skill

That directory contains `SKILL.md` with instructions for searching Slicer
source code, extensions, and community discussions.  The agent will run
`scripts/setup.sh` automatically when it needs the local repositories.
````

## MCP Server

This repository includes `slicer-mcp-server.py`, a self-contained
[Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server that
runs inside 3D Slicer.  It exposes tools such as `list_nodes`,
`execute_python`, `screenshot`, and `load_sample_data` over HTTP so that MCP
clients (Claude Code, Claude Desktop, Cline, etc.) can interact with a live
Slicer session.

**Important:** The MCP configuration (`.mcp.json`) should **not** be included
in the skill directory itself.  A `.mcp.json` inside a skill would activate
the MCP connection for every user who installs the skill, which is unexpected
and a security risk.  Instead, users enable the MCP server in their own
project by copying the sample configuration.  The skill repo ships
`mcp.json.sample` as a template and `.mcp.json` is gitignored.

### Quick start

1. Open 3D Slicer and paste the contents of `slicer-mcp-server.py` into the
   Python console (or run it via `execfile`).
2. Copy `mcp.json.sample` to `.mcp.json` in **your project directory** (not
   the skill directory), or add the equivalent to `claude_desktop_config.json`,
   etc.:
   ```sh
   cp /path/to/slicer-skill/mcp.json.sample /path/to/your-project/.mcp.json
   ```
3. Your MCP client can now query the scene, execute code, and take screenshots
   in Slicer.

To stop the server from within Slicer: `mcpLogic.stop()`

### Related projects

* **[slicerSkill](https://github.com/jumbojing/slicerSkill)** — a cloud-only
  adaptation of this skill by @jumbojing.  It replaces local repository clones
  with web-search directives (GitHub code search, ReadTheDocs, Doxygen), making
  it zero-setup at the cost of requiring network access.  Designed for
  OpenCode / Gemini workflows.
* **[mcp-slicer](https://github.com/zhaoyouj/mcp-slicer)** — a standalone
  MCP server for 3D Slicer by @zhaoyouj, installable via `pip` / `uvx`.  It
  uses Slicer's built-in WebServer API as a bridge and can be launched outside
  of Slicer.
* **[SlicerDeveloperAgent](https://github.com/muratmaga/SlicerDeveloperAgent)**
  — a Slicer extension by Murat Maga that embeds an AI coding agent directly
  inside 3D Slicer using Gemini, letting users prompt, run, and iterate on
  scripts and modules without leaving the application.  See the
  [Discourse discussion](https://discourse.slicer.org/t/developer-agent-for-slicer/44787)
  for background.
* **[NA-MIC Project Week 44 — Claude Scientific Skill for Imaging Data Commons](https://projectweek.na-mic.org/PW44_2026_GranCanaria/Projects/ClaudeScientificSkillForImagingDataCommons/)**
  — a project that developed a Claude skill for the
  [Imaging Data Commons](https://portal.imaging.datacommons.cancer.gov/)
  (IDC), published at
  [ImagingDataCommons/idc-claude-skill](https://github.com/ImagingDataCommons/idc-claude-skill).

### Security warning

The MCP server grants any connected client the ability to **execute arbitrary
Python code** inside your Slicer process.  This is powerful but carries
significant risk:

* **Code execution** — A compromised or malicious MCP client can run any code
  with the full privileges of the Slicer process, including reading and writing
  files, accessing the network, and installing software.
* **Protected Health Information (PHI)** — If you are working with patient
  data or other confidential information, be aware that an MCP client (and the
  remote AI model behind it) may send and receive data that includes PHI.
  Ensure you comply with your institution's data-handling policies, HIPAA, and
  any other applicable regulations.
* **Third-party models** — Prompts and tool responses may be transmitted to
  cloud-hosted AI services.  Do not assume that data shared through the MCP
  connection stays local.

**We strongly recommend running the MCP server inside a contained
environment** rather than on your everyday workstation:

* **Docker** — Use a containerised Slicer such as
  [SlicerDockers](https://github.com/pieper/SlicerDockers) or the official
  [Slicer/SlicerDocker](https://github.com/Slicer/SlicerDocker).
* **Virtual machines** — Provision a VM through
  [Jetstream2](https://jetstream-cloud.org/),
  [vast.ai](https://vast.ai/),
  AWS, GCP, Azure, or any other cloud provider.  This isolates the Slicer
  process (and any data it loads) from your local machine.

By keeping Slicer and the MCP server in an isolated environment you limit the
blast radius of any unintended or malicious actions and reduce the chance of
accidentally exposing sensitive data.
