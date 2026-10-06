# upto

Jump to an ancestor directory by name in [fish](https://fishshell.com).

```console
~/a/b/c/test/d/e/f $ upto d
~/a/b/c/test/d $
```

Requires fish ≥ 3.1. Pure fish builtins, no dependencies.

## Install

```fish
fisher install zadewu/upto
```

## Usage

```
upto [NAME]
```

| You are in | Command | You land in | Why |
|---|---|---|---|
| `/a/b/c/test/d/e/f` | `upto d` | `/a/b/c/test/d` | exact match |
| `/a/b/c/test/d/e/f` | `upto te` | `/a/b/c/test` | prefix match (no exact) |
| `/a/test/b/testing/c` | `upto test` | `/a/test` | an exact match anywhere beats a nearer prefix match |
| `/a/test/b/test/c` | `upto test` | `/a/test/b/test` | nearest duplicate wins |
| `~/projects/x/y` | `upto` | `~/projects` | no name: top directory below `$HOME` |
| `/opt/x/y` | `upto` | `/opt` | no name, outside `$HOME`: top directory below `/` |

- Only ancestors are searched; the current directory itself never matches.
- Matching is case-sensitive. Glob characters (`*`, `?`, `[`) are matched literally.
- Paths with spaces work. Symlinked paths are kept as they appear in `$PWD`.
- `upto` uses a plain `cd`, so `cd -` and `prevd` take you back.
- Names starting with `-` need `--`: `upto -- -build`.

**Tab completion** lists ancestor names, nearest first, each name once.

### Errors

All errors print to stderr, exit with status 1 and leave you where you were.

| Situation | Message |
|---|---|
| No ancestor matches | `upto: no ancestor matching 'NAME'` |
| `upto` at `$HOME`, `/` or a top directory | `upto: already at top` |
| Name contains `/` | `upto: name must not contain '/'` |
| Empty name (`upto ''`) | `upto: name must not be empty` |
| `.` or `..` | `upto: invalid name '..'` |
| More than one name | `upto: too many arguments` |

## Development

Tests use [fishtape](https://github.com/jorgebucaran/fishtape):

```fish
fisher install jorgebucaran/fishtape
fishtape tests/*.fish
```

## License

[MIT](LICENSE)
