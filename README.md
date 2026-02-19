# slicer-skill

This repository provides the groundwork for an **AI coding skill** that assists with
programming questions related to [3D Slicer](https://www.slicer.org).  The primary piece of
content is `SKILLS.md` which describes how an agent can prepare its environment and what
resources are available for search.

## Getting started

1. Read `SKILLS.md` for detailed information about the expected workflow and data
   sources.
2. Run the helper script to fetch the required repositories:
   ```sh
   chmod +x setup.sh
   ./setup.sh
   ```
3. Use the resulting local copies when answering questions by invoking tools like
   `git grep`, `grep`, and `find`.

Creating first pass with this prompt to copilot:
```
I want to populate this repository with a SKILLS.md file and related content.  I want the skill to work with any compatible agent, like claude code or other AI coding tools.  I want the skill to know that a first thing it should do is to checkout the Slicer source code from github and also that it should checkout the Slicer extensions index and then iterate through the index files and checkout all the repositories that are listed in the index.  Then it should also checkout the contents of this repository https://github.com/pieper/slicer-discourse-archive so that it can query discourse posts about Slicer.  Once it has all of these it should use them to better respond to prompts about Slicer programming by using git grep, find, grep, and other command line utilities to identify content that could be helpful in specifically responding productively to prompts.
```