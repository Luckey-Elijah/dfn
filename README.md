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
| `dfn <script>`                    | run a register script                               |
| `dfn <args>`                      | forward args to `dart run` (tries *scripts* first)  |
| `dfn config`                      | for managing scripts                                |
| `dfn config add <script/path>`    | for registering scripts                             |
| `dfn config remove <script/path>` | for un-registering scripts (alias `dfn config rm`)  |
| `dfn list`                        | for showing all registered scripts (alias `dfn ls`) |


### Example:

1. Register script(s):
  ```sh
  $ dfn config add example # via "package" with a "scripts" directory
  Registered 1 new script from /Users/elijahluckey/Development/dfn/example/scripts
    - hello_from_folder -> /Users/elijahluckey/Development/dfn/example/scripts/hello_from_folder.dart
  $ dfn config add example/hello_from_standalone.dart 
  Registered hello_from_standalone
  ```

2. List all scripts:
  ```sh
  $ dfn list
  ✓ 2 scripts available: (61ms)
    - hello_from_standalone -> /Users/elijahluckey/Development/dfn/example/hello_from_standalone.dart
    - hello_from_folder -> /Users/elijahluckey/Development/dfn/example/scripts/hello_from_folder.dart
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
  Removed: /Users/elijahluckey/Development/dfn/example/hello_from_standalone.dart
  $ dfn config remove example # need to pass the directory for "packages"
  Removed: /Users/elijahluckey/Development/dfn/example
  ```

5. Forward args to `dart run`:
  ```sh
  $ dfn dfn:example_script
  Building package executable... 
  Built dfn:example_script.
  Hello from dart!
  args: [dfn:example_script]
  ```
