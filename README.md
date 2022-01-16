# Metaprogram

An upgraded version of `Default_Metaprogram`.  To use it either copy the `Metaprogram` folder into your jai modules folder, or symlink it there.  Then edit the following code into the `modules/Default_Metaprogram.jai` file in the compiler.


Below the line `files, run_strings := compiler_get_source_files();` add:

```jai
    {
        // User-added block for Metaprogram module, non-standard!
        metaprogram :: #import "Metaprogram";
        metaprogram.update_options();
    }
```

Below the line `if !message break;` add:

```jai
        {
            // User-added block for Metaprogram module, non-standard!
            metaprogram :: #import "Metaprogram";
            metaprogram.check_message(message);
        }
```

If you'd rather not directly edit the compiler `Default_Metaprogram.jai` then copy it, make the edit, then use the `-meta` command line option to use your new version.

You can toggle the metaprogram features by editing the constants at the top of `Metaprogram.jai`

Features:
* Use Environment Variables
* Pointer-into-resizable-array check
* Carriage-Return check
* `build` string for single file programs
* Managed Imports


## Use Environment Variables

When enabled the metaprogram will check for the following environment variables:

* `JAI_IMPORT_DIR` - set to a collection of folder paths separated by `;` to add them as if with `-import_dir`
* `JAI_CHECK_BINDINGS` - if set to non-zero will enable the `-check_bindings` option.
* `JAI_QUIET` - if set to non-zero will enable the `-quiet` option.


## Pointer into resizable array check

Enable as either a `.WARNING` or `.ERROR`: it will try and detect when you take a pointer into a resizable array (`[..] $T`); such a pointer will become invalid when the array reallocates itself (which can happen any time you add to it).


## Carriage-Return check

When enabled as either `.WARNING` or `.ERROR` it will report any string literal which contains a carriage return (`\r`) character.
When enabled as `.FIX` it will remove the carriage returns from the string. (WIP: currently it pads the end of the string with as many nulls as there were `\r`)
You may mark a string with `@Contains_Carriage_Return` to have it ignore this check.


## Build String

Allows you to create a build script inside your program, so even a simple single-file program can set compiler options, check compiler messages, etc.

Add a #string to your program called `build`, and it will be ran as a build script for your program.  For example:

```jai
build :: #string __jai
    #import "Compiler";
    build_options := get_build_options();
    build_options.output_executable_name = "not_the_same_name.exe";

    workspace := compiler_create_workspace();
    set_build_options(build_options, workspace);

    add_build_file(#file, workspace);
__jai
```


## Managed Imports

Managed imports provides a mechanism to (a) allow for importing files via a specified path and (b) automatically download modules hosted on github (currently hard-coded to only use github, more sites can be added later).


### Warning!

Since jai provides arbitary compile-time execution, using this feature is a vector for RCE.  This is just the same as any other package manager, the only difference being you can get owned simply by compiling the code; you don't need to run it.  Only import modules you trust!


### Disclaimer!

This is using a new compiler feature so is new code; it probably has bugs!  If you run into problems you can raise an issue, but it's probably easier to just msg me on the SB discord.


### Dependencies

* You need to be on compiler version `beta 0.0.101` or later.
* For downloading you need `git` installed and working.


### Path Syntax

To specify a path for a module place it after a `|` character in the import string.  i.e.:

```jai
#import "<module>|<path>";
```

For example:

```jai
#import "Foo|c:/repos/modules";
```

The path can be absolute or relative (to the project);


### Github Syntax

The syntax to download a module from Github is:

```jai
#import "<module>|<version>|<repo>.<user>";
```

For example:
```jai
#import "Strings|v1.0.8|jai-string.onelivesleft";
```

*Note that `<version>` must be in the form `v#.#.#`.*

When you use this syntax the compiler will check the downloaded modules folder (a path set at the top of `Metaprogram.jai`) for the specified module.  If it doesn't find it it'll use `git` to download it.

Alternatively, you may import directly into your program by prefixing the module name with a `.`:
```jai
#import ".<module>|<version>|<repo>.<user>";
```

For example:
```jai
#import ".Strings|v1.0.8|jai-string.onelivesleft";
```

This will search inside / download into your program directory in the `modules` sub-folder.


### Github modules

To set up a module which can be downloaded automatically in this manner:
* Create a github repository for it.
* Create the module as a folder in that repo, with a `module.jai` file inside (as normal).
* Create a `modules.lst` file in the root of the repo, which lists every folder ni the repo that is a module.
* Create a release of the repo, and tag it with the version.  The version tag must be of the form `v#.#.#`.  For example, the tag for the `Strings` module above is `v1.0.8`.

Example module: https://github.com/onelivesleft/jai-string

*(Currently the entire repo is downloaded and held, but in future versions all files/folders in the repo which are not listed in the `modules.lst` file will be deleted)*


### Awful bonus feature

You can inline a module directly in the string if you use a `#string`.  For example:

```jai
Foo :: #import #string __jai
    my_module_has_a_string :: "It does!\n";
__jai;

main :: () {
    write_string(Foo.my_module_has_a_string);
}
```
