---
name: boot
description: Boot skills into a project from the local skills repository, or create new ones.
disable-model-invocation: true
---

Two skill tiers:

- **Global** (`~/.kimi-code/skills/`): always available. This skill is one.
- **Project** (`.agents/skills/`): linked per project from the repository.

Repository: **`C:/Users/17445/Desktop/HwFee-skills/.agents/skills/`**

Link, never copy. On Windows `ln -s` copies directories - always use `mklink /J`.

## Boot existing skills

1. **Audit the project.** List the root, read `README`, `package.json`, `AGENTS.md`, entry points. Skip to step 2 if empty.
2. **Ask the user what they plan to do.** No recommendations until intent is clear.
3. List every subdirectory under the repository path. Read each `SKILL.md` frontmatter `description`.
4. Present recommended skills: name + one-line reason each, filtered by project context and user intent.
5. **Wait for confirmation.** Link nothing before the human says yes.
6. Ensure `.agents/skills/` exists. For each confirmed skill, create a junction:

   ```bash
   cmd //c "mklink /J .agents\\skills\\<skill-name> C:\\Users\\17445\\Desktop\\HwFee-skills\\.agents\\skills\\<skill-name>"
   ```

7. **Done when**: every junction resolves - `ls .agents/skills/<skill-name>/SKILL.md` succeeds for each.

## Create a new skill

1. Invoke **`writing-great-skills`** and follow its principles.
2. Create the skill at the repository path under `<new-skill-name>/SKILL.md`.
3. Link it via junction (step 6 above).
4. **Done when**: the new skill has no `writing-great-skills` failure-mode violations (premature completion, duplication, sediment, sprawl, no-op), and its junction resolves.
