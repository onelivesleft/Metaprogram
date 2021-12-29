# Metaprogram

An upgraded version of `Default_Metaprogram`.  To use it either copy the `Metaprogram` folder into your jai modules folder, or symlink it there.  Then edit the following code into the `modules/Default_Metaprogram.jai` file in the compiler.  Do so by replacing the `if !message break;` line in it with:

```jai
        if !message break;

        {
            // User-added block for Metaprogram module, non-standard!
            metaprogram :: #import "Metaprogram";
            metaprogram.check_message(message);
        }
```

If you'd rather not directly edit the compiler `Default_Metaprogram.jai` then copy it, make the edit, then use the `-meta` command line option to use your new version.

You can toggle the metaprogram features by editing the constants at the top of `Metaprogram.jai`

Features:
* Pointer-into-resizable-array check
* Managed Imports

(Lots more features planned...)


## Pointer into resizable array check

Enable as either a `.WARNING` or `.ERROR`: it will try and detect when you take a pointer into a resizable array (`[..] $T`); such a pointer will become invalid when the array reallocates itself (which can happen any time you add to it).


## Managed Imports

Managed imports provides a mechanism to automatically download modules hosted on github (currently hard-coded to only use github).


### Warning!

Since jai provides arbitary compile-time execution, using this feature is a vector for RCE.  This is just the same as any other package manager, the only difference being you can get owned simply by compiling the code; you don't need to run it.  Only import modules you trust!


### Disclaimer!

This is using a new compiler feature so is new code; it probably has bugs!  If you run into problems you can raise an issue, but it's probably easier to just msg me on the SB discord.


### Dependencies

* You need to be on compiler version `beta 0.0.101` or later.
* You need `git` installed and working.


### Syntax

With this feature enabled modules will automatically be downloaded when you use the approriate syntax.  This syntax is:

```jai
#import "<module>/<version>/<repo>.<user>";
```

For example:
```jai
#import "Strings/v1.0.8/jai-string.onelivesleft";
```

When you use this syntax the compiler will check the downloaded modules folder (a path set at the top of `Metaprogram.jai`) for the specified module.  If it doesn't find it it'll use `git` to download it.

Alternatively, you may import directly into your program by prefixing the module name with a `.`:
```jai
#import ".<module>/<version>/<repo>.<user>";
```

For example:
```jai
#import ".Strings/v1.0.8/jai-string.onelivesleft";
```

This will search inside your program directory in the `modules` sub-folder.


### Github modules

To set up a module which can be downloaded automatically in this manner:
* Create a github repository for it.
* Create the module as a folder in that repo, with a `module.jai` file inside (as normal).
* Create a `modules.lst` file in the root of the repo, which lists every folder ni the repo that is a module.
* Create a release of the repo, and tag it with the version.  For example, the tag for the Strings module above is "v1.0.8".  Whatever you use for the tag is what must be placed inside the `/../` in the `#import`.

Example module: https://github.com/onelivesleft/jai-string

*(Currently the entire repo is downloaded and held, but in future versions all files/folders in the repo which are not listed in the `modules.lst` file will be deleted)*
