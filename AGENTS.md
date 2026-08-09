# AGENTS.md

## Workflow preferences

- **Commit + push automatically**: After completing a task or set of changes, commit the work and push to `origin/main` (branch `main`) without being asked. Use a concise, descriptive commit message.
- **Never force-push** or rewrite shared history.
- **Check CI status**: After pushing, verify the GitHub Actions run passes. If CI fails, fix the issue and push again.
- Do not commit secrets or the embedded token in the remote URL.

## Project

Flutter app (Inkwell). Run `flutter analyze` and `flutter test` before committing when the Flutter SDK is available locally.
