# Sysadmin Shell Scripts

System administration scripts. Built with a focus on Enterprise Linux (RHEL-based), but with some accommodation for Ubuntu and Debian systems too. Scripts will specify compatibility.

## Structure

- `server/` - Scripts that run on target servers
- `workstation/` - Scripts that run from admin workstation
- `boilerplates/` - Ideas, drafts and simple scripts
- `lib/` - Reference implementations (optional)
- `docs/` - Documentation and conventions

## Requirements

- RHEL 8+ or equivalent (Rocky Linux, AlmaLinux)
- Eventually Ubuntu and Debian, but my focus is RHEL
- Bash 4.2+ (I optimize for Bash, not POSIX)

## Usage

Scripts are independent and self-documenting. Each includes usage info in comments.

## Philosophy

- Safety first: backups before modifications
- Independence: scripts don't depend on each other
- Documentation: clear purpose and rollback procedures

## License

GPLv3 - See LICENSE file

I strongly believe in Free Software as defined by the Free Software Foundation, not merely "open source". All code in this repository is and will always be GPL-licensed to ensure these freedoms are preserved for all users.
