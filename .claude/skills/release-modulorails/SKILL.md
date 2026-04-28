---
name: release-modulorails
description: Release a new version of the Modulorails Ruby gem to RubyGems. Handles version bump, CHANGELOG, commit, tag, push, GitHub release, and gem publication. Trigger this skill whenever the user asks to release, publish, ship, bump, or cut a new version of modulorails — even if they don't explicitly mention "release" or specify a version (ask for it if missing).
---

# Release the Modulorails gem

Run the full release pipeline for the `modulorails` gem. The user provides the version number (e.g. `1.7.0`) without the `v` prefix. If they omit it, ask before proceeding.

## Conventions

- `<version>`: the version number without `v` prefix (e.g. `1.7.0`)
- All commands run from the project root: `/home/claude/modulorails`
- GitHub repo: `https://github.com/moduloTech/modulorails`
- Gem published to: `https://rubygems.org/gems/modulorails`
- Tag format: `v<version>` (e.g. `v1.7.0`)
- The gemspec has `rubygems_mfa_required = 'true'`, so `gem push` will prompt for an OTP. Tell the user to have their authenticator app ready before step 7.

## Steps

### 1. Pre-flight check

- Run `git status` and `git diff` to surface any uncommitted changes.
- The release commit should only touch `lib/modulorails/version.rb` and `CHANGELOG.md`. If unrelated changes are pending, ask the user whether to include them, stash them, or abort.
- Confirm the current branch is `master` (the project's main branch) unless the user specified otherwise.

### 2. Bump the version constant

- Edit `lib/modulorails/version.rb` and replace the value of `VERSION` with `<version>`.
- The constant looks like: `VERSION = '1.6.0'.freeze` — keep the single quotes and `.freeze` to match the existing style.

### 3. Update CHANGELOG.md

The Modulorails CHANGELOG uses its own format — **do not** convert it to Keep-a-Changelog. The structure is:

```
# Unreleased

# <version>

<one-line summary, optional>

## Features
- ...

## Improvements
- ...

## Fixes
- ...

## Deprecations (will be removed in <next major>)
- ...
```

To update:

- Replace the `# Unreleased` heading with `# <version>` (and add a fresh `# Unreleased` line above it for the next cycle).
- Categorize changes under `## Features`, `## Improvements`, `## Fixes`, or `## Deprecations` as appropriate. Omit sections that have no entries.
- Run `git log --oneline <last-tag>..HEAD` to find the commits since the previous release; use those as the source of changelog entries. Phrase entries as user-facing descriptions, not commit-message echoes.

### 4. Commit the bump

Stage **only** `lib/modulorails/version.rb` and `CHANGELOG.md`, then commit. Match the project's existing release commit style — prior bumps use messages like `Bump modulorails to 1.6.0`:

```bash
git add lib/modulorails/version.rb CHANGELOG.md
git commit -m "$(cat <<'EOF'
Bump modulorails to <version>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Use whichever Co-Authored-By trailer matches the model running the session — don't hardcode an older one.)

### 5. Tag

```bash
git tag -a v<version> -m "v<version>"
```

### 6. Push commit and tag

```bash
git push origin master
git push origin v<version>
```

### 7. Build and push the gem to RubyGems

```bash
gem build modulorails.gemspec
gem push modulorails-<version>.gem
```

`gem push` will prompt for the OTP because `rubygems_mfa_required` is set in the gemspec. The user must enter it interactively — surface the prompt to them.

If the user is unauthenticated (`You don't have any sources that contain this gem.` or similar), they need to run `gem signin` first. Don't try to manage their RubyGems credentials.

After a successful push, delete the local `.gem` artifact: `rm modulorails-<version>.gem`.

### 8. Create the GitHub release

```bash
gh release create v<version> --title "v<version>" --notes "<notes>"
```

Notes should mirror the CHANGELOG section for this version (markdown-formatted). Pass the body via a HEREDOC if it's multi-line, e.g.:

```bash
gh release create v<version> --title "v<version>" --notes "$(cat <<'EOF'
## Features
- ...

## Fixes
- ...
EOF
)"
```

### 9. Confirm

- Print the GitHub release URL (`gh release view v<version> --json url -q .url`).
- Print the RubyGems URL: `https://rubygems.org/gems/modulorails/versions/<version>`.
- Remind the user that downstream apps can pull the new version via `bundle update modulorails`.

## Alternative: `bundle exec rake release`

The Rakefile already loads `bundler/gem_tasks`, so `bundle exec rake release` will, in one shot:

1. Verify the working tree is clean.
2. Build `modulorails-<version>.gem`.
3. Tag `v<version>` from the current HEAD.
4. Push the tag to `origin`.
5. `gem push` to RubyGems.

Use this only when:
- The version bump and CHANGELOG are already committed and pushed (it does **not** create the bump commit).
- The user explicitly asks for the shortcut.

The downsides vs. the step-by-step flow: if `gem push` fails (bad OTP, network), the tag is already pushed and you need to clean up manually. The manual flow keeps tag and gem push independent so each failure mode is recoverable on its own.

## Troubleshooting

- **`gem push` fails with 401 / OTP rejected**: the OTP window is short — re-run with a fresh code. Don't re-tag or re-commit; just retry the `gem push` step.
- **Tag already exists locally but push fails**: `git tag -d v<version>` and recreate after fixing the underlying issue. Never force-push a tag that's already on RubyGems.
- **`gem build` complains about missing files**: the gemspec uses `git ls-files` to enumerate files, so untracked files won't be in the gem. Stage them first if they belong, or `.gitignore` them if not.
- **GitHub release notes don't render properly**: HEREDOC quoting matters — use `<<'EOF'` (with quotes) to prevent shell expansion in the notes body.
