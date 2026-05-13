# AGENTS.md

- Keep changes small and focused on packaging `entire`.
- Prefer editing `flake.nix` and `package.nix` directly instead of introducing extra layers.
- This repo uses shared skills via `.agents/`; check those symlinks when a task matches one of the shared workflows.
- If the package needs an update, refresh the pinned upstream release metadata and rebuild to confirm the hashes.
- `GSTACK_HOME=.gstack` — gstack data lives in the repo, not `~/.gstack/`.
