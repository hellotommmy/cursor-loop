# cursor-loop

Replicate Claude Code's `/loop` command in Cursor IDE using [Cursor Hooks](https://docs.cursor.com/agent/hooks).

The AI agent automatically re-prompts itself after each stop, enabling long-running iterative tasks (code generation, refactoring, test writing, theorem proving, etc.) to run for hours without human intervention.

## How it works

```
┌─────────────────────────────────────────────────────┐
│  You send a message to Cursor Agent                 │
│  ↓                                                  │
│  Agent works on the task...                         │
│  ↓                                                  │
│  Agent stops (done or needs more work)              │
│  ↓                                                  │
│  Cursor Hook fires → runs loop.ps1 / loop.sh       │
│  ↓                                                  │
│  Script reads loop-config.json                      │
│  ↓                                                  │
│  (Optional) Runs validation command                 │
│  ↓                                                  │
│  Returns {"decision": "continue", ...}              │
│  ↓                                                  │
│  Agent receives followup_message and continues      │
│  ↓                                                  │
│  ... repeats up to loop_limit times ...             │
└─────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Copy files to your project

Copy these into your project:

```
your-project/
├── .cursor/
│   ├── hooks.json          # Cursor hooks configuration
│   └── hooks/
│       ├── loop.ps1        # Windows hook script
│       └── loop.sh         # macOS/Linux hook script
└── loop-config.json        # Your task configuration
```

### 2. Configure hooks.json

**Windows:**
```json
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": "powershell -ExecutionPolicy Bypass -File .cursor/hooks/loop.ps1",
        "loop_limit": 25,
        "timeout": 600
      }
    ]
  }
}
```

**macOS / Linux:**
```json
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": "bash .cursor/hooks/loop.sh",
        "loop_limit": 25,
        "timeout": 600
      }
    ]
  }
}
```

### 3. Configure loop-config.json

Edit `loop-config.json` in your workspace root:

```json
{
  "task": "Your ongoing task description here. Be specific and detailed.",
  "validation_command": "npm test",
  "validation_shell": "powershell",
  "on_validation_fail": "Tests failed. Fix ALL errors below:\n{errors}",
  "on_validation_pass": "All tests pass. Continue improving.",
  "loop_limit": 25,
  "timeout": 600
}
```

### 4. Start the loop

Send your initial message to Cursor Agent. The hook will automatically keep it going.

## Configuration Reference

| Field | Type | Description |
|---|---|---|
| `task` | string | **Required.** The ongoing task message sent to the agent each iteration. |
| `validation_command` | string | Optional shell command to run between iterations (e.g. `npm test`, `cargo build`, `make`). Leave empty to skip. |
| `validation_shell` | string | `"powershell"` (default) or `"bash"`. Which shell runs the validation command. |
| `on_validation_fail` | string | Message template when validation fails. `{errors}` is replaced with command output. |
| `on_validation_pass` | string | Message shown when validation succeeds. |
| `loop_limit` | number | Max iterations before the hook stops re-prompting. Set in `hooks.json`. |
| `timeout` | number | Max seconds per hook execution. Set in `hooks.json`. |

## Examples

### Continuous test writing
```json
{
  "task": "Add more unit tests to increase coverage. Focus on edge cases and error paths. Run tests after each change.",
  "validation_command": "npm test",
  "on_validation_fail": "Tests failed! Fix them first:\n{errors}",
  "on_validation_pass": "All tests pass."
}
```

### Iterative refactoring
```json
{
  "task": "Continue refactoring: extract duplicated logic into shared utilities, improve type safety, add JSDoc comments.",
  "validation_command": "npx tsc --noEmit",
  "on_validation_fail": "Type errors found:\n{errors}",
  "on_validation_pass": "Type check passed."
}
```

### Theorem proving (Isabelle)
```json
{
  "task": "Check for remaining 'sorry' and prove them. Add more example lemmas. Use 'by eval' for executable model proofs.",
  "validation_command": "isabelle build -d . Covercrypt",
  "validation_shell": "bash",
  "on_validation_fail": "Build failed:\n{errors}",
  "on_validation_pass": "Build passed (no errors)."
}
```

### Pure generation (no validation)
```json
{
  "task": "Continue writing API documentation for all exported functions in src/. Cover parameters, return values, and examples.",
  "validation_command": ""
}
```

## How to stop the loop

- **Set `loop_limit`** in `hooks.json` — the loop stops after that many iterations.
- **Delete or rename** `loop-config.json` — the hook will stop with a "config not found" message.
- **Press the Stop button** in Cursor — the agent stops and the hook will try to continue, but you can reject the followup.

## Requirements

- [Cursor IDE](https://cursor.com) with Hooks support (v0.50+)
- Windows: PowerShell 5.1+ (built-in)
- macOS/Linux: bash + python3 (for JSON escaping)

## License

MIT
