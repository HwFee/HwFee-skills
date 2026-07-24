# HwFee Skills

Central skills repository — the single source of truth for all agent skills. Other
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
| Global | `global-skills/<skill>/` | `~/.kimi-code/skills/<skill>/` | All sessions |
| Project | `.agents/skills/<skill>/` | `<project>/.agents/skills/<skill>/` | Per project |

- Each skill has a `SKILL.md` at its root.
- `~/.kimi-code/skills/` contains only junctions back to `global-skills/`.
- This repo's `.agents/skills/` is a real directory so skills can be tested directly.
- Install, distribute, and remove skills via the **`install-skills`** skill (`/install-skills`).
- Update skills with upstream via `npx skills update` (skills.sh) or re-clone (GitHub).
- Do not commit test output or generated code. Media files from testing live in `*-test/` (auto-ignored).

## Testing skills

Create a scratch directory at the repo root named after the skill with a `-test` suffix,
e.g. `kami-test`. Test directories are auto-ignored.

## Skills inventory

Track origin so skills can be updated from upstream.

### Global skills (`global-skills/`)

| Skill | Origin type | Source | Latest verified |
|---|---|---|---|
| **all-search** | skills.sh ecosystem | `vercel-labs/skills@all-search` | 2026-07-23 |
| **boot** | local | — | — |
| **install-skills** | local | — | 2026-07-24 |

### Project skills (`.agents/skills/`)

| Skill | Origin type | Source | Latest verified |
|---|---|---|---|
| **agently-mail** | npm package wrapper | `@tencent-qqmail/agently-cli`; skill via `npx skills add https://agent.qq.com --skill -g -y` | — |
| **bundle-size-optimization** | skills.sh ecosystem | `vercel-labs/skills@bundle-size-optimization` | 2026-07-24 |
| **deploy-to-vercel** | skills.sh ecosystem | `vercel-labs/skills@deploy-to-vercel` | 2026-07-24 |
| **find-skills** | skills.sh ecosystem | `vercel-labs/skills@find-skills` | 2026-07-23 |
| **framer-motion-animator** | skills.sh ecosystem | `vercel-labs/skills@framer-motion-animator` | 2026-07-24 |
| **frontend-design** | skills.sh ecosystem | `vercel-labs/skills@frontend-design` | 2026-07-24 |
| **gc-minimal-zine-poster** | GitHub | `LiamGvchi/gc-minimal-zine-poster` | 2026-07-23 |
| **grill-me** | local | — | — |
| **ian-xiaohei-illustrations** | GitHub | `helloianneo/ian-xiaohei-illustrations` | 2026-07-23 |
| **image2-gen** | local | — | — |
| **kami** | GitHub (plugin) | `tw93/Kami` → `plugins/kami/skills/kami/` | 2026-07-23 (v1.10.0) |
| **lieflat-charts** | local | — | — |
| **react-performance-optimization** | skills.sh ecosystem | `vercel-labs/skills@react-performance-optimization` | 2026-07-24 |
| **signal-geometry** | GitHub | `CaliCastle/skills` | 2026-07-24 |
| **tailwind-css-patterns** | skills.sh ecosystem | `vercel-labs/skills@tailwind-css-patterns` | 2026-07-24 |
| **vercel-react-best-practices** | skills.sh ecosystem | `vercel-labs/skills@vercel-react-best-practices` | 2026-07-24 |
| **vercel-react-view-transitions** | skills.sh ecosystem | `vercel-labs/skills@vercel-react-view-transitions` | 2026-07-24 |
| **web-design-guidelines** | skills.sh ecosystem | `vercel-labs/skills@web-design-guidelines` | 2026-07-24 |
| **writing-great-skills** | local | — | — |
