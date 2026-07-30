# HwFee Skills

Central skills repository - the single source of truth for all agent skills. Other
projects and the user-global skills directory junction from here, never copy.

## Architecture

```
HwFee-skills/
├── global-skills/       # user-global skills (real, tracked)
├── .agents/skills/      # project skills (real, tracked, NOT a junction)
├── AGENTS.md
└── .gitignore
```

| Tier | Entity location | Junction target | Scope |
|------|----------------|-----------------|-------|
| Global | `global-skills/<skill>/` | `~/.agents/skills/<skill>/` | All sessions |
| Project | `.agents/skills/<skill>/` | `<project>/.agents/skills/<skill>/` | Per project |

- Each skill has a `SKILL.md` at its root.
- `~/.agents/skills/` contains only junctions back to `global-skills/` (cross-tool user scope; `~/.kimi-code/skills/` is no longer used).
- The user-global instruction file lives at `~/.agents/AGENTS.md`.
- This repo's `.agents/skills/` is a real directory so skills can be tested directly.
- Install, distribute, and remove skills via the **`install-skills`** skill (`/install-skills`).
- Do not commit test output or generated code. Media files from testing live in `*-test/` (auto-ignored).

## Updating skills

`npx skills update` does **not** work in this repo - skills are real directories, not
tracked by the skills CLI (all show "Source: local"). Update manually by origin type.

### Workflow

1. **Check for updates** (skip `local` skills only):

   | Origin type | How to check |
   |---|---|
   | skills.sh ecosystem | `npx skills add <repo> -l` to list available skills; compare with installed |
   | GitHub | `gh api 'repos/<owner>/<repo>/commits?per_page=3'` or `gh api repos/<owner>/<repo>/releases` |
   | GitHub (plugin) | `gh api repos/<owner>/<repo>/releases` - compare tag with installed VERSION |
   | npm package wrapper | `npm view <package> version` vs `npm list -g <package>` |

2. **Update the skill** (by origin type):

   | Origin type | How to update |
   |---|---|
   | skills.sh ecosystem | `git clone --depth 1 <repo> /tmp/<name>`, then copy the skill dir from `/tmp/<name>/skills/<skill>/` |
   | GitHub | `git clone --depth 1 <repo> /tmp/<name>`, `rm -rf` old skill dir, `cp -r /tmp/<name>/ <skill>/`, `rm -rf <skill>/.git` |
   | GitHub (plugin) | `git clone --depth 1 --branch <tag> <repo> /tmp/<name>`, copy from subdirectory |
   | npm package wrapper | `npm install -g <package>` if newer; skill file itself is local, rarely changes |
   | local | Skip - no upstream to pull from |

3. **Verify junctions** - after replacing a skill directory, confirm junctions still resolve:

   ```bash
   # Global skills
   ls ~/.agents/skills/<skill>/SKILL.md

   # Project skills distributed to other projects
   ls <target-project>/.agents/skills/<skill>/SKILL.md
   ```

   Junctions point to the **path**, not the inode, so `rm -rf` + `cp -r` is safe. But if a
   junction was lost or never created, recreate it:

   ```bash
   # Global
   cmd //c "mklink /J C:\Users\17445\.agents\skills\<skill> C:\Users\17445\Desktop\HwFee-skills\global-skills\<skill>"
   # Project (in target project)
   cmd //c "mklink /J <project>\.agents\skills\<skill> C:\Users\17445\Desktop\HwFee-skills\.agents\skills\<skill>"
   ```

4. **Update inventory** - update the "Latest verified" date in the AGENTS.md inventory
   table. If a source was found incorrect, correct it.

### Pitfalls (learned 2026-07-29)

- **`vercel-labs/skills` ≠ `vercel-labs/agent-skills`**: the former is the skills CLI tool
  (only contains `find-skills`); the latter is Vercel's actual skill collection. Don't
  record `vercel-labs/skills@<skill>` for skills that live in `vercel-labs/agent-skills`.
- **Always verify source before recording**: use `npx skills add <repo> -l` to confirm a
  skill exists in the repo before writing it as the source. Incorrect sources make future
  updates impossible.
- **`npx skills find <name>`** searches the skills.sh registry across all publishers -
  useful for finding the real source of a skill with unknown origin.
- **all-search + firecrawl** is effective for finding GitHub repos by skill content -
  search unique phrases from SKILL.md to locate the original repo.

## Testing skills

Create a scratch directory at the repo root named after the skill with a `-test` suffix,
e.g. `kami-test`. Test directories are auto-ignored.

## Skills inventory

Track origin so skills can be updated from upstream.

### Global skills (`global-skills/`)

| Skill | Origin type | Source | Latest verified |
|---|---|---|---|
| **all-search** | local | - | 2026-07-29 |
| **boot** | local | - | - |
| **install-skills** | local | - | 2026-07-29 |

### Project skills (`.agents/skills/`)

| Skill | Origin type | Source | Latest verified |
|---|---|---|---|
| **65535** | local | - | 2026-07-30 |
| **agently-mail** | npm package wrapper | `@tencent-qqmail/agently-cli`; skill via `npx skills add https://agent.qq.com --skill -g -y` | 2026-07-29 |
| **bundle-size-optimization** | GitHub | `aj-geddes/useful-ai-prompts@bundle-size-optimization` | 2026-07-29 |
| **deploy-to-vercel** | skills.sh ecosystem | `vercel-labs/agent-skills@deploy-to-vercel` | 2026-07-29 |
| **design-md** | GitHub | `google-labs-code/stitch-skills@design-md` | 2026-07-29 |
| **find-skills** | skills.sh ecosystem | `vercel-labs/skills@find-skills` | 2026-07-23 |
| **framer-motion-animator** | GitHub | `patricio0312rev/skills@framer-motion-animator` | 2026-07-29 |
| **frontend-design** | GitHub | `anthropics/skills@frontend-design` | 2026-07-29 |
| **gc-minimal-zine-poster** | GitHub | `LiamGvchi/gc-minimal-zine-poster` | 2026-07-29 |
| **grill-me** | GitHub | `mattpocock/skills@grill-me` | 2026-07-29 |
| **ian-xiaohei-illustrations** | GitHub | `helloianneo/ian-xiaohei-illustrations` | 2026-07-23 |
| **kami** | GitHub (plugin) | `tw93/Kami` -> `plugins/kami/skills/kami/` | 2026-07-29 (v1.11.0) |
| **lieflat-charts** | GitHub | `larashero3-dotcom/lieflat-charts` | 2026-07-29 |
| **react-performance-optimization** | GitHub | `nickcrew/claude-ctx-plugin@react-performance-optimization` | 2026-07-29 |
| **signal-geometry** | GitHub | `CaliCastle/skills` | 2026-07-24 |
| **tailwind-css-patterns** | GitHub | `giuseppe-trisciuoglio/developer-kit@tailwind-css-patterns` | 2026-07-29 |
| **vercel-react-best-practices** | skills.sh ecosystem | `vercel-labs/agent-skills@vercel-react-best-practices` | 2026-07-29 |
| **vercel-react-view-transitions** | skills.sh ecosystem | `vercel-labs/agent-skills@vercel-react-view-transitions` | 2026-07-29 |
| **web-design-guidelines** | skills.sh ecosystem | `vercel-labs/agent-skills@web-design-guidelines` | 2026-07-29 |
| **writing-great-skills** | GitHub | `mattpocock/skills@writing-great-skills` | 2026-07-29 |
