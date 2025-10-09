# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite with local and CI tests
- GitHub Actions workflows for automated building and testing
- Semantic release automation
- Docker container with Caddy for flexible reverse proxy configuration
- Environment variable support for all major Caddy features
- Rate limiting, basic auth, redirects, and custom headers support

### Changed
- Updated Caddyfile syntax for better ENV var handling

### Fixed
- Caddyfile validation issues
- Test script ENV var validation
