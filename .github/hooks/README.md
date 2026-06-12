# Git Hooks

## Pre-commit Hook

This pre-commit hook performs automatic checks before finalizing your commit.

### Usage Instructions

To use this pre-commit hook:

1. Make the hook executable if it isn't already:
   ```bash
   chmod +x .github/hooks/pre-commit
   ```

2. Configure Git to use the hooks in the `.github/hooks` directory:
   ```bash
   git config core.hooksPath .github/hooks
   ```

3. The hook will automatically run when you execute `git commit`
