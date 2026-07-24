---
name: boot
description: Boot skills into a project from the local skills repository, or create new ones.
disable-model-invocation: true
---

Two skill tiers, both sourced from the central skills repository:

- **Global** (`~/.kimi-code/skills/`): always available in every session. Junctioned from `<repo>/global-skills/`.
- **Project** (`.agents/skills/`): available only in the current project. Junctioned from `<repo>/.agents/skills/`.

Central repository: **`C:/Users/17445/Desktop/HwFee-skills`**

| Tier | Repository source | Junction target |
|------|------------------|-----------------|
| Global | `C:/Users/17445/Desktop/HwFee-skills/global-skills/<skill>` | `~/.kimi-code/skills/<skill>` |
| Project | `C:/Users/17445/Desktop/HwFee-skills/.agents/skills/<skill>` | `<project>/.agents/skills/<skill>` |

Link, never copy. On Windows `ln -s` copies directories — always use `mklink /J`.

## Boot a global skill

1. Read `<repo>/global-skills/` — every subdirectory is a global skill. Read each `SKILL.md` frontmatter `description`.
2. Ask the user which global skill they want, or recommend based on their intent.
3. **Wait for confirmation.** Link nothing before the human says yes.
4. Create the junction:

   ```bash
   cmd //c "mklink /J C:\\Users\\17445\\.kimi-code\\skills\\<skill-name> C:\\Users\\17445\\Desktop\\HwFee-skills\\global-skills\\<skill-name>"
   ```

5. **Done when**: `ls ~/.kimi-code/skills/<skill-name>/SKILL.md` succeeds.

## Boot project skills into another project

1. **Audit the target project.** List the root, read `README`, `package.json`, `AGENTS.md`, entry points. Skip to step 2 if empty.
2. **Ask the user what they plan to do.** No recommendations until intent is clear.
3. List every subdirectory under `<repo>/.agents/skills/`. Read each `SKILL.md` frontmatter `description`.
4. Present recommended skills: name + one-line reason each, filtered by project context and user intent.
5. **Wait for confirmation.** Link nothing before the human says yes.
6. Ensure the target project's `.agents/skills/` exists. For each confirmed skill, create a junction:

   ```bash
   cmd //c "mklink /J <target-project>\\.agents\\skills\\<skill-name> C:\\Users\\17445\\Desktop\\HwFee-skills\\.agents\\skills\\<skill-name>"
   ```

7. **Done when**: every junction resolves — `ls <target>/.agents/skills/<skill-name>/SKILL.md` succeeds for each.

## Create a new skill

1. Invoke **`writing-great-skills`** and follow its principles.
2. Decide tier: **global** (all sessions) → create at `<repo>/global-skills/<skill-name>/SKILL.md`; **project** (this repo's testing ground) → create at `<repo>/.agents/skills/<skill-name>/SKILL.md`.
3. For global skills, also junction it into `~/.kimi-code/skills/` so it activates immediately.
4. **Done when**: the new skill has no `writing-great-skills` failure-mode violations (premature completion, duplication, sediment, sprawl, no-op), and its junction resolves.
