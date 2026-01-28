# WebFly Project Tasks

# Use sh as the shell (e.g. Git Bash / MSYS2)
set shell := ["sh", "-c"]

# List all available commands
default:
    @just --list

# Flutter tasks (use: just flutter <command>)
flutter *args:
    cd flutter && just {{args}}

# Build everything for release packaging (refresh use_cases assets then build main web)
build-all:
    just flutter use-cases-refresh
    pnpm build