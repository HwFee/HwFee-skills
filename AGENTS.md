# HwFee Skills

A skills repository for testing and experimenting with newly installed agent skills.

## What this repo is

This repo exists solely as a workspace for installing, testing, and iterating on
agent skills. It is **not** an application or library project.

## Layout

```
.
├── .agents/skills/   # project skills (tracked)
├── global-skills/    # user-global skills (tracked)
├── AGENTS.md         # this file (tracked)
└── .gitignore        # whitelist-only ignore rules (tracked)
```

Everything else is git-ignored. Only `.agents/skills/`, `global-skills/`,
`AGENTS.md`, and `.gitignore` are tracked.

## Skill conventions

- Skills are stored under `.agents/skills/<skill-name>/`.
- Each skill has a `SKILL.md` at its root.
- Install new skills via `npx skills` or by copying a skill directory into
  `.agents/skills/`.
- After installing, test the skill in this repo before promoting it elsewhere.

## Testing skills

To test a skill, create a scratch directory at the repo root named after the
skill with a `-test` suffix, e.g. `kami-test` or `image2-gen-test`. Any files
generated during testing go in that directory.

Test directories are automatically git-ignored by the whitelist `.gitignore` —
no cleanup needed before committing.

## Skills inventory

Track each skill's origin so it can be updated from upstream later.

| Skill | Origin type | Source | Latest verified |
|---|---|---|---|
| **agently-mail** | npm package wrapper | `@tencent-qqmail/agently-cli`; skill via `npx skills add https://agent.qq.com --skill -g -y` | — |
| **find-skills** | skills.sh ecosystem | `vercel-labs/skills@find-skills` | 2026-07-23 |
| **gc-minimal-zine-poster** | GitHub | `LiamGvchi/gc-minimal-zine-poster` | 2026-07-23 |
| **grill-me** | local | — | — |
| **image2-gen** | local | — | — |
| **kami** | GitHub (plugin) | `tw93/Kami` → `plugins/kami/skills/kami/` | 2026-07-23 (v1.10.0) |
| **lieflat-charts** | local | — | — |
| **writing-great-skills** | local | — | — |

### Update check

Skills with a `Source` can be updated by re-fetching from that source. Update before promoting to other projects. Run `npx skills update` first; for manually-copied skills, clone the source repo and compare.

## Working with this repo

- To permanently track a new skill, place it under `.agents/skills/` and commit.
- **When adding a new skill, record its origin in the Skills inventory table above** — if it came from an external source (GitHub, npm, skills.sh), note the URL; if it's local/custom, mark it as `local`.
- Do not commit test output, generated examples, or data files unless they
  belong inside a skill directory.
