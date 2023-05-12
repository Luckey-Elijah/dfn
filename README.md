# `dfn`: Dart as Functions + Scripting

**Install via**: 
- pub.dev: `dart pub global activate dfn`
- local development: `dart pub global activate -spath .`
- git repo: `dart pub global activate -sgit https://github.com/Luckey-Elijah/dfn.git`

## Usage

**TLDR;**:
- `dfn config add path/to/my_package` to add a dart package with a `dfn/` script collection
- `dfn config add path/to/my_script.dart` to add a "standalone" `.dart` script/file
- `dfn list` to list all registered scripts and their sources
- `dfn config remove <script_name>` to de-register a script that has been registered as a "standalone" script
- `dfn config remove <path/to/my_package>` to de-register a script collection from `dfn`
- `dfn -h` for help with usage

Commands that reserved and **won't work** as script names:
- `list` _lists all registered scripts and their sources_
- `config` _entry point for configuring all things `dfn`_

`dfn config add` looks for a directory called `dfn` in a given path. Given you have a dart package called: `example` at `path/to/my/example`. Everything in `example/dfn` will be registered to `dfn`s scripts.

```sh
$ dfn config add path/to/my/example
Registered 4 new scripts from /absolute/path/to/my/example/dfn
- upgrade_all_pub
- search_folder
- watch_files
- check_code_health
```

Now those scripts can be used like:

```sh
$ dfn upgrade_all_pub arg1 arg2
$ dfn search_folder arg1
$ dfn watch_files arg1
$ dfn check_code_health arg1 arg2
```

List all scripts with `dfn list`:
```sh
$ dfn list
- upgrade_all_pub -> path/to/my/example/dfn/upgrade_all_pub.dart
- search_folder -> path/to/my/example/dfn/search_folder.dart
- watch_files -> path/to/my/example/dfn/watch_files.dart
- check_code_health -> path/to/my/example/dfn/check_code_health.dart
```

Any _new_ `.dart` files added to `path/to/my/example/dfn` will **automatically** be register into `dfn`'s scripts.

For example:
```sh
$ dfn config add scripts path/to/my/example
Registered 1 new script from path/to/my/example/scripts
  - upgrade_all_pub -> /full/path/to/my/example/scripts/upgrade_all_pub.dart
  - search_folder -> /full/path/to/my/example/scripts/search_folder.dart
  - watch_files -> /full/path/to/my/example/scripts/watch_files.dart
  - check_code_health -> /full/path/to/my/example/scripts/check_code_health.dart

# create new script
$ touch path/to/my/example/dfn/hello.dart
```

Contents of the new `hello.dart` file:

```dart
void main() => print('hello, world!');
```

We can see the new `hello` script via `dfn list`

```sh
$ dfn list
- upgrade_all_pub -> path/to/my/example/dfn/upgrade_all_pub.dart
- search_folder -> path/to/my/example/dfn/search_folder.dart
- watch_files -> path/to/my/example/dfn/watch_files.dart
- check_code_health -> path/to/my/example/dfn/check_code_health.dart
- hello -> path/to/my/example/dfn/hello.dart
```

And use the newly created script:

```sh
$ dfn hello
hello, world!
```
