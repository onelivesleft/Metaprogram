# Metaprogram

An upgraded version of `Default_Metaprogram`.  To use it install this module as you normally do, and then edit this code into the `modules/Default_Metaprogram.jai` file in the compiler.  Do so by replacing the `if !message break;` line in it with:

```jai
        if !message break;

        {
            // This file is a copy of:
            // `Default_Metaprogram.jai` version `beta 0.0.100`
            // ...but with this block added.
            metaprogram :: #import "Metaprogram";
            metaprogram.check_message(message);
        }
```

If you're comfortable using `diff`, the `Default_Metaprogram.diff` file provided here can be used to automate the change.

If you'd rather not directly edit the compiler `Default_Metaprogram.jai` then copy it, make the edit, then use the `-meta` command line option to use your new version.

You can toggle the metaprogram features by editing the constants at the top of `Metaprogram.jai`
