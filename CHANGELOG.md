# v1.1.1 - 2022-01-06
* Added `check_for_carriage_returns` option.
* Added fourth choice for Option: `.FIX`

# v1.1.0 - 2022-01-03
* Changed github import format to `#import "Module|v#.#.#|repo.user"`
* Added ability to import local file by specifying path, e.g. `#import "MyModule|c:/repos/modules"`
* Added ability to inline module text: use a `#string` for the import string. This is dumb.
* Added use of environment variables.

# v1.0.2 - 2021-12-29
* Fixed hang when `modules.lst` contained no `\n`.

# v1.0.1 - 2021-12-29
* Removed references to Code_Sequence.
* Added `CHANGELOG.md`.

# v1.0.0
* First release.
