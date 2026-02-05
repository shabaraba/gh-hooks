# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.5](https://github.com/shabaraba/gh-hooks/compare/v0.1.4...v0.1.5) (2026-02-05)


### Features

* add asynchronous hook execution support ([#16](https://github.com/shabaraba/gh-hooks/issues/16)) ([8676470](https://github.com/shabaraba/gh-hooks/commit/867647053cc232c239134e39a746d20b7219006b))


### Documentation

* add CLAUDE.md ([b6501ea](https://github.com/shabaraba/gh-hooks/commit/b6501eaa9a3c3fbaf69e289221421074b1b2f5d6))

## [0.1.4](https://github.com/shabaraba/gh-hooks/compare/v0.1.3...v0.1.4) (2026-02-05)


### Bug Fixes

* implement lazy initialization to avoid startup errors ([#14](https://github.com/shabaraba/gh-hooks/issues/14)) ([b74b94a](https://github.com/shabaraba/gh-hooks/commit/b74b94aecf4003b5940366b37ed86358fe43477d))

## [0.1.3](https://github.com/shabaraba/gh-hooks/compare/v0.1.2...v0.1.3) (2026-02-05)


### Documentation

* explain RC and profile file installation ([#12](https://github.com/shabaraba/gh-hooks/issues/12)) ([8d150be](https://github.com/shabaraba/gh-hooks/commit/8d150be7f7bde170bc5e719c336d91e2b134a478))

## [0.1.2](https://github.com/shabaraba/gh-hooks/compare/v0.1.1...v0.1.2) (2026-02-05)


### Features

* install hooks to both RC and profile files ([#10](https://github.com/shabaraba/gh-hooks/issues/10)) ([2f307d4](https://github.com/shabaraba/gh-hooks/commit/2f307d4e23f9465ad3c21ac1fc8df8641dfaadcf))

## [0.1.1](https://github.com/shabaraba/gh-hooks/compare/v0.1.0...v0.1.1) (2026-02-05)


### Features

* add force install option and path verification ([c3a554c](https://github.com/shabaraba/gh-hooks/commit/c3a554cd5607c791e85da5763ac07f24d768e2e1))
* add GitHub CLI extension support ([7eeca9b](https://github.com/shabaraba/gh-hooks/commit/7eeca9bc2a79e075fa5eddc2f6dd0074b7629110))
* add multi-shell support (bash, zsh, fish, nushell) ([c2bc54c](https://github.com/shabaraba/gh-hooks/commit/c2bc54c3f8f7e4b421438269d4c296cc11375da0))
* add release automation with release-please ([#1](https://github.com/shabaraba/gh-hooks/issues/1)) ([a439848](https://github.com/shabaraba/gh-hooks/commit/a43984821ff2965194a8b50ee5f3d7ebb90b8aba))
* implement gh-hooks library for GitHub CLI automation ([b66cf75](https://github.com/shabaraba/gh-hooks/commit/b66cf7574138c3862cdcb3cb1294c6ffd68c1e8c))
* improve overview description in README ([#2](https://github.com/shabaraba/gh-hooks/issues/2)) ([112cf03](https://github.com/shabaraba/gh-hooks/commit/112cf0304fe1fbbcae72e6b6bad9a195dc90079e))


### Bug Fixes

* add multi-shell support for export syntax (bash/zsh compatibility) ([d4d058a](https://github.com/shabaraba/gh-hooks/commit/d4d058a4c761554351d12662bcde987abb3dcf54))
* extract PR number from merge command arguments ([30ebe1f](https://github.com/shabaraba/gh-hooks/commit/30ebe1fccf05e30d342c74d119da0947d3458bc1))
* handle symlinked shell RC files in force install ([d9e9e3e](https://github.com/shabaraba/gh-hooks/commit/d9e9e3eaa5d0b018969613ec27b8d23a9ff5cf47))
* improve gh hooks status command for multi-process detection ([3f7ccf5](https://github.com/shabaraba/gh-hooks/commit/3f7ccf5574592de89bb55829fae3d61160ac029f))


### Documentation

* clarify nushell abbreviation ([#3](https://github.com/shabaraba/gh-hooks/issues/3)) ([67daeb1](https://github.com/shabaraba/gh-hooks/commit/67daeb132bf0e063975cb5852a9ac5955db10e73))

## [0.1.0] - 2025-02-05

### Features

- Add GitHub CLI extension support
- Add multi-shell support (bash, zsh, fish, nushell)
- Implement gh-hooks library for GitHub CLI automation
- Add release-please integration for automated releases
- Add project-specific hooks configuration
- Add hook execution engine with PR merge/create/close detection
- Add release PR detection and version extraction
- Add examples for Rust and npm projects

### Documentation

- Add comprehensive README with installation guide
- Add INSTALL.md for detailed setup instructions
- Add HOOKS_SETUP.md for project's own hooks configuration
- Add API documentation for hook functions
