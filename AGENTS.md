# AGENTS.md

## Cursor Cloud specific instructions

This repository is a **GitBook-style documentation site** (Chinese technical notes on Docker / Redis / MySQL / Linux / Java). It is not a compiled application — the "app" is the rendered docs site. Structure is driven by `SUMMARY.md` (table of contents) and `README.md` (home page).

### Tooling
- Rendered with [Honkit](https://github.com/honkit/honkit) (the maintained successor to the deprecated GitBook CLI). It is pinned as a dev dependency in `package.json`.
- Dependencies install via `npm install` (run automatically by the startup update script).

### Run / build (see `package.json` scripts)
- Dev server: `npm run dev` (alias for `npx honkit serve`, serves on `http://localhost:4000`). Honkit live-reloads on markdown changes.
- Static build: `npm run build` (`npx honkit build`) → outputs to `_book/`.
- Cloud Agent 启动时会通过 `.cursor/start.sh` 自动拉起 Honkit（若 `package.json` 存在且 4000 端口尚未监听）。

### Notes / gotchas
- There is no lint or automated test suite in this repo; validation = building successfully and browsing the served site.
- The build/serve logs a non-fatal `Unknown language: "markup"` error from the highlight plugin for some code fences. Generation still reports `generation finished with success` and pages render correctly — this warning can be ignored.
- `_book/` (build output) and `node_modules/` are gitignored.
