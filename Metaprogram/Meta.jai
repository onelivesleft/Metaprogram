is_absolute_path :: (path: string) -> bool { // This routine is probably not as correct as we'd like. We'd like to put in a better one! But maybe we will stop doing the cwd thing, or do it differently; hard to say.
    if !path return false;

    if path[0] == #char "/" return true;   // Backslashes have not been converted to forward slashes by this point.
    if path[0] == #char "\\" return true;  // Backslashes have not been converted to forward slashes by this point.
    if (path.count > 2) && (path[1] == #char ":") && (OS == .WINDOWS) return true;  // Drive letter stuff. Probably incomplete.

    if path.count >= 3 {
        // @Robustness: Check for a drive letter in character 0?  Anything else?
        if path[1] == #char ":" return true;
    }

    return false;
}

build :: () {
    w := compiler_create_workspace("Target Program");
    options := get_build_options(w);

    files, run_strings := compiler_get_source_files();

    compiler_begin_intercept(w);

    for files        add_build_file(it, w);
    for run_strings  add_build_string(tprint("#run %;\n", it), w);

    message_loop();

    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false, write_added_strings=false});
}

#run build();

message_loop :: (check_bindings: bool) {
    while true {
        message := compiler_wait_for_message();
        if !message break;

        {
            // This file is a copy of:
            // `Default_Metaprogram.jai` version `beta 0.0.100`
            // ...but with this block added.
            metaprogram :: #import "Metaprogram";
            metaprogram.check_message(message);
        }
    }
}

#import "Basic";
#import "Compiler";
