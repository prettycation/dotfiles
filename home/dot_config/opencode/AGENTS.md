# Personal OpenCode Rules

Respond in Chinese by default, unless the user explicitly asks for English or the task requires English output, such as commit messages, code comments, documentation, error messages, API copy, or user-facing product text.

Do not add decorative comments, explanatory noise, or unnecessary prose. Add comments only when the user asks for them, when the code is genuinely non-obvious, or when the existing project style requires comments.

Prefer simple, direct, maintainable solutions. Keep changes small and focused.

## Core Workflow

For development tasks, normally follow this workflow:

1. Analyze the problem.
2. Propose a plan.
3. Execute only after the plan is clear or the user explicitly asks you to implement directly.

If the user explicitly says "just implement", "directly change it", "execute the plan", or gives an unambiguous implementation request, you may proceed without asking for confirmation.

## Phase 1: Analyze the Problem

Goal: understand the request and the relevant code before making changes.

You must:

- Understand the user's intent.
- Ask a clarifying question if there is a blocking ambiguity.
- Search the relevant code before editing.
- Identify the root cause, not just the surface symptom.
- Look for duplicated logic, inconsistent naming, stale abstractions, unnecessary complexity, type mismatches, and hidden coupling.
- Expand the search if you find similar patterns elsewhere.

Do not:

- Modify files before understanding the problem.
- Skip code search.
- Jump directly to implementation when the scope is unclear.
- Invent requirements that the user did not ask for.

## Phase 2: Propose a Plan

Goal: make the change set, risk, and validation path clear.

You must:

- List files that need to be created, modified, or deleted.
- Explain the purpose of each change briefly.
- Define the success criteria.
- Define the validation commands, such as tests, type checks, or lint.
- Prefer reusing existing abstractions over adding new ones.
- Remove duplication when it is directly related to the task.

Do not:

- Add flexibility that was not requested.
- Create abstractions for single-use logic.
- Add configuration options unless the user asked for them or the project already has that pattern.
- Over-engineer for hypothetical future cases.

## Phase 3: Execute the Plan

Goal: implement the agreed solution with minimal, precise changes.

You must:

- Modify only code that is directly related to the task.
- Make every changed line traceable to the user's request.
- Match the existing project style.
- Remove unused imports, unused variables, and orphaned code introduced by your change.
- Run appropriate validation after editing.
- If validation fails, fix the issue or clearly explain the blocker.

Do not:

- Refactor unrelated code.
- Reformat unrelated sections.
- Change naming or style just because you prefer it.
- Delete pre-existing dead code unless the user asked for cleanup.
- Commit code unless the user explicitly asks.
- Start a development server unless the user explicitly asks.

## Simplicity Rules

Write the least code necessary to solve the problem correctly.

Before adding complexity, ask:

- Is this abstraction used more than once?
- Did the user ask for this flexibility?
- Does the project already use this pattern?
- Is this error case realistic?
- Would a senior maintainer consider this over-engineered?

If a solution is becoming large, look for a smaller design.

## Precision Rules

When editing existing code:

- Do not improve adjacent unrelated code.
- Do not reorder unrelated code.
- Do not change unrelated formatting.
- Do not rewrite working code unless the task requires it.
- If you notice unrelated issues, mention them separately instead of fixing them silently.

## Validation Rules

Convert vague tasks into verifiable outcomes:

- Bug fix: reproduce or identify the failure path, then verify the fix.
- Validation change: cover invalid input and verify accepted input still works.
- Refactor: preserve behavior and verify with existing tests or checks.
- Optimization: explain what improves and avoid behavior changes.

For multi-step tasks, use a concise plan:

```text
1. [Step] -> verify: [validation method]
2. [Step] -> verify: [validation method]
3. [Step] -> verify: [validation method]
```

## Lockfiles

Do not edit lockfiles directly.

Examples:

- `package-lock.json`
- `pnpm-lock.yaml`
- `yarn.lock`
- `bun.lock`
- `Cargo.lock`
- `Gemfile.lock`
- `uv.lock`
- `poetry.lock`

Use the package manager or language tool that owns the lockfile instead.

Examples:

- `npm install`
- `pnpm install`
- `yarn install`
- `bun install`
- `cargo update`
- `bundle install`
- `uv add`
- `poetry add`

## Markdown

Use fenced code blocks with triple tildes by default:

```text
example
```

Exception: if the target file already consistently uses backticks, preserve the existing style.

## MCP Usage

Use `context7` when the task requires accurate external documentation for a third-party library, framework, SDK, or API.

Do not call MCP tools unnecessarily. Use them only when they materially improve correctness.
