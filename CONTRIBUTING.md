# Contributing guide

A short guide to keep the project clean.

## 1. Branches naming

Use following format: `type/feature-name`

* **feature/**: to create a new feature
* **fix/**: to fix a bug
* **docs/**: to update docs
* **refactor/**: to clean code without changing any feature

## 2. Commit conventions

Use following format: `<type>: <verb> <desc>`

* `feat`: add a new functionality
* `fix`: fix a bug
* `chore`: update dependencies

> To access the [Full list of Conventional Commits](https://courses-vfourny.vercel.app/ci-cd/conventional-commit)

## 3. Coding conventions

* Variables/functions: `camelCase` (ex.: `myFunction`, `myVariable`)
* Classes: `PascalCase` (ex.: `MyClass`)
* Files: `kebab-case` (ex.: `home-screen.dart`)

## 4. Pull Requests procedure (PR)

Before submitting any changes, please follow the next steps:

* **Up-to-date:** be synchronized with the most recent branch (`main` or `develop`)
* **Testings:** the code should be compiling without any warning/error and work within an Android environment
* **Description:** write a short but detailed description of the new implementation you will be pushing
* **Merging:** wait for a reviewer to accept your changes before merging