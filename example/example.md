# Example

1. list any registered scripts

    ```sh
    $ dfn list
    ✗ No scripts registered.
    Register a new script with dfn config add <script or path>
    ```

2. add a single, standalone script

    ```sh
    $ dfn config add example/hello_from_standalone.dart
    Registered hello_from_standalone
    ```

3. add a an entire folder that contains `dfn` subfolder

    ```sh
    $ dfn config add example
    Registered 1 new script from /path/to/example/dfn
    - hello_from_folder -> /path/to/example/scripts/hello_from_folder.dart
    ```

4. list newly registered scripts

    ```sh
    $ dfn list
    ✓ 2 scripts found:
      - hello_from_standalone -> /path/to/example/hello_from_standalone.dart
      - hello_from_folder -> /path/to/example/scripts/hello_from_folder.dart
    ```

5. run `hello_from_standalone`

    ```sh
    $ dfn hello_from_standalone
    Hello from standalone folder!
    ```

6. run `hello_from_folder`

    ```sh
    $ dfn hello_from_folder
    Hello from dfn folder!
    ```

6. remove `example` scripts

    ```sh
    $ dfn config remove example
    Removed: /path/to/example

    $ dfn list
    ✓ 1 script found:
      - hello_from_standalone -> /path/to/example/hello_from_standalone.dart
    ```
