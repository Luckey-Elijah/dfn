# `dfn`: Dart as Functions + Scripting

**Install via**: 
- pub.dev: `dart pub global activate dfn`
- local development: `dart pub global activate -spath .`
- git repo: `dart pub global activate -sgit https://github.com/Luckey-Elijah/dfn.git`

## Usage

Overview:
| `dfn <command>`                   |                                                     |
| --------------------------------- | --------------------------------------------------- |
| `dfn`                             | core tool                                           |
| `dfn <script>`                    | run a registered script                             |
| `dfn <args>`                      | forward args to `dart run` (tries *scripts* first)  |
| `dfn config`                      | for managing scripts (see `add`/`rm`)                                |
| `dfn config add <script/path>`    | for registering scripts                             |
| `dfn config remove <script/path>` | for un-registering scripts (alias `dfn config rm`)  |
| `dfn list`                        | for showing all registered scripts (alias `dfn ls`) |


### Example:

1. Register script(s):
  ```sh
  $ dfn config add example # via "package" with a "scripts" directory
  Registered 1 new script from /path/to/example/scripts
    - hello_from_folder -> /path/to/example/scripts/hello_from_folder.dart

  $ dfn config add example/hello_from_standalone.dart 
  Registered hello_from_standalone
  ```

2. List all scripts:
  ```sh
  $ dfn list
  ✓ 2 scripts available:
    - hello_from_standalone -> /path/to/example/hello_from_standalone.dart
    - hello_from_folder -> /path/to/example/scripts
  ```

3. Run the scripts:
  ```sh
  $ dfn hello_from_standalone
  Hello from standalone file!
  
  $ dfn hello_from_folder
  Hello from script folder!
  ```

4. Remove the scripts:
  ```sh
  $ dfn config rm hello_from_standalone # rm or remove are both valid
  Removed: /path/to/example/hello_from_standalone.dart

  $ dfn config remove example # need to pass the directory for "packages"
  Removed: /path/to/example
  ```

5. Forward args to `dart run`:
  ```sh
  $ dfn test:test test/some_test.dart
  ```
