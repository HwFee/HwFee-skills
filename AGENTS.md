# HwFee Skills

A skills repository for testing and experimenting with newly installed agent skills.

## What this repo is

This repo exists solely as a workspace for installing, testing, and iterating on
agent skills. It is **not** an application or library project.

## Layout

```
.
├── .agents/skills/   # all skills live here (tracked)
├── AGENTS.md         # this file (tracked)
└── .gitignore        # whitelist-only ignore rules (tracked)
```

Everything else is git-ignored. Only `.agents/skills/`, `AGENTS.md`, and
`.gitignore` are tracked.

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

## Working with this repo

- To permanently track a new skill, place it under `.agents/skills/` and commit.
- Do not commit test output, generated examples, or data files unless they
  belong inside a skill directory.
