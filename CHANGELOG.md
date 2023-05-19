# 0.1.0

- Improve documentation
- Marks "usages" as `final` and not as functions.
- Various code quality improvements


# 0.0.3

- `README.md` formatting

# 0.0.2

- `README.md` formatting

# 0.0.1

## Initial rRelease 🎉

### Features:

**Commands**

| `dfn <command>`                   |                                                     |
| --------------------------------- | --------------------------------------------------- |
| `dfn`                             | core tool                                           |
| `dfn <script>`                    | run a register script                               |
| `dfn <args>`                      | forward args to `dart run` (tries *scripts* first)  |
| `dfn config`                      | for managing scripts                                |
| `dfn config add <script/path>`    | for registering scripts                             |
| `dfn config remove <script/path>` | for un-registering scripts (alias `dfn config rm`)  |
| `dfn list`                        | for showing all registered scripts (alias `dfn ls`) |

**Options**

| `dfn <option>`  |                                      |
| --------------- | ------------------------------------ |
| `dfn --help`    | show help and usage (alias `dfn -h`) |
| `dfn --verbose` | enable verbose logging               |
