# Lua Preprocessor

A Lua preprocessor for conditional compilation, exclusion, and copying of build artifacts.

## Usage

### In-Place Processing
Process files in-place (modifies the source directory):

```bash
python preprocess.py <directory> [SYMBOL=value ...]
```

**Example:**

```bash
python preprocess.py . ENVIRONMENT=test DEBUG=false
```

### Out-of-Place Processing
Copy files to an output directory while processing (preserves source):

```bash
python preprocess.py --input <source> --output <target> [SYMBOL=value ...] [--preserve PATTERN ...]
```

**Example:**

```bash
python preprocess.py --input cluetrainer --output dist/cluetrainer ENVIRONMENT=production
```

This copies all files from `cluetrainer/` to `dist/cluetrainer/`, processes conditionals and directives, and handles exclusions/copies as specified in the Lua files.

### File Preservation and Target Cleanup

By default, all files in the target directory are deleted before processing starts. Use `--preserve` patterns to keep specific files:

```bash
python preprocess.py --input src --output dist --preserve "resources/**" --preserve "*.config"
```

**Behavior:**
- **Before processing:** All files in target directory are deleted **except** those matching preserve patterns
- A matching directory and all its contents are preserved without traversing it; this also applies to exclusions and explicit copies targeting its descendants
- If no `--preserve` patterns are given, the target directory is emptied by removing its immediate children recursively; unsafe output paths are rejected
- Empty directories are removed after cleaning
- **During processing:** Preserved paths are skipped (not overwritten), even if they do not yet exist in the target
- This is useful for keeping manually-maintained configuration files or large asset directories without manual cleanup

**Pattern Syntax:**
- `resources` or `resources/` — The entire resources directory
- `resources/*` — Direct children of resources/
- `resources/**` — All descendants of resources/
- `resources/**/*` — All files under resources/
- `*.config` — All .config files in root
- `configs/*.ini` — All .ini files in configs/

## Directives

### Conditional Compilation

```lua
--#if EXPRESSION
  -- Included if expression is true
--#elseif EXPRESSION
  -- Included if previous conditions were false and this is true
--#else
  -- Included if all previous conditions were false
--#endif
```

### Symbol Definition

```lua
--#define NAME VALUE
```

Defines a compile-time symbol. Symbols can be:
- Booleans: `true`, `false`
- Nil: `nil`
- Numbers: `42`, `-17`
- Strings: `"client"`, `"server"`

File-local definitions override CLI arguments.

### File and Directory Exclusion

```lua
--#exclude "path/"
--#exclude "path/" if EXPRESSION
--#exclude if EXPRESSION
```

- `--#exclude "path/"` — Exclude the path (file or directory)
- `--#exclude "path/" if EXPR` — Conditionally exclude the path
- `--#exclude if EXPR` — Conditionally exclude the current file

Paths are relative to the file containing the directive. Directory exclusions apply recursively.

### File and Directory Copying (Out-of-Place Mode Only)

```lua
--#copy "path/"
--#copy "path/" if EXPRESSION
--#copy "source/" to "target/"
--#copy "source/" to "target/" if EXPRESSION
```

- `--#copy "path/"` — Copy the path from source to output
- `--#copy "path/" if EXPR` — Conditionally copy the path
- `--#copy "source/" to "target/"` — Copy source to explicit target location (relative to output root)
- `--#copy "source/" to "target/" if EXPR` — Conditionally copy with explicit target

Paths in `--#copy` directives are relative to the file containing the directive and can reference paths outside the input root using `..`. This works with both files and directories. Copy directives are queued for processing—if the copied path contains Lua files, they will be processed recursively.

**Target path mapping:**
- When `to` is specified, target is relative to output root
- When `to` is not specified:
  - If source is inside input root, copied to equivalent path in output
  - If source is outside input root, copied to output root with source's directory name

## Expressions

Expressions support:
- Symbols, strings, numbers, `true`, `false`, `nil`
- Operators: `and`, `or`, `not`
- Comparisons: `==`, `~=`, `<`, `<=`, `>`, `>=`
- Parentheses for grouping

**Note:** Undefined symbols evaluate to `nil` (falsy).

## Processing Behavior

### Queue-Based Workflow (Out-of-Place Mode)

1. Clean target directory: delete all files except those matching preserve patterns
2. Initialize the queue with the source directory
3. Process queue items:
   - Check if target is in exclusion set; skip if excluded
   - Check if target matches preserve pattern; skip if preserved
   - If target already processed, skip (deduplication)
   - For Lua files: copy directive-free files unchanged; otherwise evaluate directives, collect excludes/copies, and write processed output
   - For other files: copy them unchanged to the target
   - For directories containing only non-Lua files and no subdirectories: copy the directory with `shutil.copytree`, respecting preserved and already-processed files
   - For other directories: queue only their immediate files and subdirectories, ahead of previously queued work
4. Delete excluded paths (deepest first to avoid cascading errors)

This workflow allows `--#copy` directives to add files and directories to the queue; Lua files are processed recursively.

The preprocessor logs processed files and skipped and deleted paths. On a terminal, a progress bar on the last line shows processed files and remaining queue entries; the estimate can change as directories and copy directives add work. Redirected output includes a final progress summary.

### In-Place Mode

Files are processed in-place with the same directive evaluation.

**Important:** `--#exclude` and `--#copy` directives are subject to their surrounding conditional blocks. A directive only takes effect if it's inside an active `--#if/elseif/else` block. This means processing order matters—directives are evaluated as the file is processed top-to-bottom.

Symbols defined with `--#define` in a file are file-local and do not affect other files.

## Example: In-Place Processing

**Input: main.lua**

```lua
--#define TARGET "client"
--#define DEBUG false

print("Shared code")

--#if TARGET == "client"
print("Client-specific code")
--#elseif TARGET == "server"
print("Server-specific code")
--#endif

--#if DEBUG
print("Debug mode")
--#endif

--#exclude "server/" if TARGET == "client"
```

**After:** `python preprocess.py . TARGET=client`

```lua

print("Shared code")


print("Client-specific code")



```

## Example: Out-of-Place Processing with Copies

**Input: cluetrainer/main.lua**

```lua
--#define ENVIRONMENT "production"

-- Copy zyklib library from dependencies
--#copy "../dependencies/zyklib/src/" to "zyklib/"

print("Application")
```

**Command:**

```bash
python preprocess.py --input cluetrainer --output dist/cluetrainer ENVIRONMENT=production
```

**Result:**
- All files from `cluetrainer/` are copied to `dist/cluetrainer/`
- `main.lua` is processed: copy directive queues `dependencies/zyklib/src/` to copy to `dist/cluetrainer/zyklib/`
- Files from `dependencies/zyklib/src/` are copied to `dist/cluetrainer/zyklib/`
- Any Lua files in `zyklib/` are processed recursively with the same ENVIRONMENT=production setting

## Example: Multi-Environment with Preserve

**Setup:**
```
cluetrainer/
├── main.lua (with --#copy for zyklib)
├── game/
└── resources/

dependencies/
└── zyklib/
    └── src/
```

**Command for production:**

```bash
python preprocess.py \
  --input cluetrainer \
  --output dist/production \
  --preserve "resources/**" \
  ENVIRONMENT=production
```

**Result:**
- Preprocessing happens only once (copy directive includes zyklib automatically)
- Resources directory is never touched/overwritten
- Build is clean and declarative through Lua directives

## Conditional Copies

Copy directives inside conditional blocks are subject to those conditions:

**Input: main.lua**

```lua
--#define ENVIRONMENT "development"

--#if ENVIRONMENT == "production"
--#copy "../dependencies/zyklib/src/" to "zyklib/"
--#endif

--#if ENVIRONMENT == "development"
--#copy "../dependencies/zyklib/debug/" to "zyklib/"
--#endif

print("Application")
```

**Processing with `ENVIRONMENT=production`:**
- Production condition is true, production zyklib is copied
- Development condition is false, development zyklib is not copied

**Processing with `ENVIRONMENT=development`:**
- Production condition is false, production zyklib is not copied
- Development condition is true, development zyklib is copied

This allows you to define different sets of dependencies for different configurations without duplicating logic.

## Design Notes

- **In-place modification:** In-place mode modifies files directly. Use Git or version control to track/revert changes.
- **Destructive:** Excluded files and directories are deleted permanently (unless preserved via `--preserve`).
- **Comment-based directives:** Directives are recognized only in Lua comments (`--#`), never inside strings.
- **No macros:** No code substitution or macro expansion—only conditional compilation.
- **Nested conditionals:** `--#if/elseif/else/endif` blocks support nesting.
- **Single-pass evaluation:** Directives are processed line-by-line. Exclude/copy directives depend on surrounding conditions.
- **Path escaping:** Copy directives can reference paths outside the input root using `..` (e.g., `../dependencies/`)
- **Explicit targets:** Use `to` keyword to specify exactly where copied paths end up in the output
- **Recursive processing:** Copy directives queue new work; Lua files are discovered and processed recursively.
- **Deduplication:** Each target path is processed at most once per run.
