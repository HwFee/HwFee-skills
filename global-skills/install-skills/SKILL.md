---
name: install-skills
description: Install, add, distribute, junction, or remove agent skills. Use when the user asks to install a skill, add a skill, set up a skill, junction/link a skill to a project, distribute a skill to another project, delete a skill, or remove a skill.
---

Central repository: **`/c/Users/17445/Desktop/HwFee-skills`** (`$REPO`).
All skill entities live here; every other location is a junction.

| Tier | Entity location | Junction target |
|------|----------------|-----------------|
| Global | `$REPO/global-skills/<skill>/` | `~/.agents/skills/<skill>/` |
| Project | `$REPO/.agents/skills/<skill>/` | `<project>/.agents/skills/<skill>/` |

**Windows rule**: `cmd //c "mklink /J …"`, never `ln -s` (copies directories on Windows).

**Git Bash pitfalls (learned 2026-08-07, cost 3 failed attempts)**:

1. **Pass mklink as ONE quoted string**: `cmd //c "mklink /J $link $target"`. Separate-argument form (`cmd //c mklink /J "$link" "$target"`) breaks — MSYS2 path conversion mangles `/J` into a filesystem path → `Invalid switch`.
2. **Backslash directly before `$` kills bash variable expansion**: `".agents\\skills\\$s"` passes a literal `$s` to cmd (creates a junk `skills$s` junction). Never interpolate a variable right after a backslash. Build paths first with forward slashes, convert via `cygpath -w`, store in a variable, then interpolate:
   ```bash
   link=$(cygpath -w "$PWD/.agents/skills/$s")
   target=$(cygpath -w "/c/Users/17445/Desktop/HwFee-skills/.agents/skills/$s")
   cmd //c "mklink /J $link $target"
   ```
3. **`mklink /J` does not verify the target exists** — it happily creates junctions to nonexistent paths. Always verify after each batch: `ls <link>/SKILL.md` for every junction.
4. **Junctions must stay out of git** — add `.agents/` to the target project's `.gitignore` before committing anything (git would otherwise enumerate junction contents as real files).

## Determine context

Check `pwd` to know which role you play:

- **You are the repo** (`pwd` = `$REPO`): destinations are relative. You touch `global-skills/` and `.agents/skills/` directly.
- **You are a target project** (anywhere else): use absolute `$REPO` paths, and after placing a project skill in the repo, junction it into the current project.

## Install a skill

**默认安装为项目级**（`$REPO/.agents/skills/<skill>/`）。只有用户明确要求"安装成全局"时才装到全局；全局技能的体系由用户自己管理，用户需要全局时会主动提醒，不要默认询问 global/project。

### Fetch

| Source | Command |
|---|---|
| skills.sh ecosystem | `npx skills add <owner/repo@skill> -a kimi-code-cli -y` |
| Custom URL | `npx skills add <url> --skill -y` |
| GitHub (whole repo) | `git clone`, delete `.git` |
| GitHub (subdirectory) | sparse checkout, copy out the subdirectory |
| Local | already in place — skip |

npx lands at `.agents/skills/<name>/` in `pwd`. GitHub lands at your temp path. Call this `<src>`.

### Place

**Global:**

```bash
mv <src> $REPO/global-skills/<skill>/
cmd //c "mklink /J C:\\Users\\17445\\.agents\\skills\\<skill> C:\\Users\\17445\\Desktop\\HwFee-skills\\global-skills\\<skill>"
```

**Project:**

```bash
mv <src> $REPO/.agents/skills/<skill>/
```

Then, if you are in a target project (not the repo), also junction it in:

```bash
cmd //c "mklink /J <pwd>\\.agents\\skills\\<skill> C:\\Users\\17445\\Desktop\\HwFee-skills\\.agents\\skills\\<skill>"
```

### Record

Add a row to the inventory table in `$REPO/AGENTS.md`:

```
| **<name>** | <origin-type> | <source> | <YYYY-MM-DD> |
```

Origin types: `skills.sh ecosystem`, `GitHub`, `GitHub (plugin)`, `npm package wrapper`, or `local`. Source formats match existing rows in the table.

**For global skills**, also add the skill name to the installed list in `~/.agents/AGENTS.md`:

```
已安装的全局技能：`boot`（元技能）、`all-search`（多引擎搜索）、`install-skills`（技能安装管理）、`<skill>`（<简述>）。
```

**Done when**: `SKILL.md` resolves at the target path, both AGENTS.md entries are committed.

## Distribute an existing skill

Skill is already in `$REPO/.agents/skills/<skill>/`.

**If you are the repo**, ask for the target project path:

```bash
mkdir -p <target>/.agents/skills
cmd //c "mklink /J <target>\\.agents\\skills\\<skill> C:\\Users\\17445\\Desktop\\HwFee-skills\\.agents\\skills\\<skill>"
```

**If you are the target project**:

```bash
cmd //c "mklink /J .agents\\skills\\<skill> C:\\Users\\17445\\Desktop\\HwFee-skills\\.agents\\skills\\<skill>"
```

**Done when**: `ls <target>/.agents/skills/<skill>/SKILL.md` succeeds.

## Remove a skill

### Global

```bash
cmd //c "rmdir C:\\Users\\17445\\.agents\\skills\\<skill>"
rm -rf $REPO/global-skills/<skill>
```

Remove its row from `$REPO/AGENTS.md` and its entry from the installed list in `~/.agents/AGENTS.md`.

### Project

```bash
rm -rf $REPO/.agents/skills/<skill>
```

Warn: any junction into another project is now broken. Remove its row from `$REPO/AGENTS.md`.

**Done when**: entity deleted, junction deleted (global), row removed.
