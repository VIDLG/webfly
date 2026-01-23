# WebFly Project Tasks

# Use sh as the shell
set shell := ["sh", "-c"]

# List all available commands
default:
    @just --list

# Flutter tasks (use: just flutter <command>)
flutter *args:
    cd flutter && just {{args}}