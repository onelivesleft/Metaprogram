// @Incomplete: Exit code on failure, test with test programs!
// @Incomplete: Test program deletes .exe files
// @Incomplete: compiler_set_command_line_arguments passes a Workspace parameter.
// @Incomplete: Should Workspaces be set to NO_OUTPUT by default, unless changed?

#module_parameters(VERBOSE := false);

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

    //
    // Create a workspace to contain the program we want to compile.
    // We can pass a name to compiler_create_workspace that gets reported
    // back to us in error messages:
    //
    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    options := get_build_options(w);

    do_initial_cwd   := true;
    check_bindings   := false;
    options_modified := false;
    user, system := compiler_get_command_line_arguments();

    #if VERBOSE {
        print("User arguments:   %\n", user);
        print("System arguments: %\n", system);
    }

    for system {
        if it == "-no_cwd"  do_initial_cwd = false;

        if it == "-release"  {
            set_optimization_level(*options, 2, 0);
            options.stack_trace = false;
            options_modified    = true;
        }

        if it == "-quiet"  {
            options.text_output_flags = 0;
        }
    }

    for user {
        if it == "-check_bindings"   check_bindings = true;
    }

    files, run_strings := compiler_get_source_files();
    if files {
        basename, path := get_basename_and_path(files[0]);

        old_wd := get_working_directory();

        if basename || path {
            if path {
                // We need to set an absolute output_path or it will no longer be correct if any metaprogram (including us) changes the working directory but doesn't touch the output_path.
                if !is_absolute_path(path) {
                    path = sprint("%/%", old_wd, path);
                }

                options.output_path = path;
            }
            if basename  options.output_executable_name = basename;
            options_modified = true;
        }

        #if VERBOSE {
            print("Basename: %\n", basename);
            print("Path:     %\n", path);
        }

        // We set the working directory, because relative paths specified in things
        // like #import should not have their meaning depend on where you were when
        // you started the compiler. @Cleanup: Maybe this becomes unnecessary if
        // import works a little differently.
        if do_initial_cwd && path {
            #if VERBOSE   print("Changing working directory to '%'.\n", path);
            set_working_directory(path);

            // To set the working directory, we need to change the filenames of all the arguments,
            // if they are relative, otherwise they will now be wrong ... sigh!!
            // The whole reason we are setting directory is, the meaning of the program should not
            // be dependent on where the compiler is when it starts. It should be invariant.
            for * files {
                old_filename := <<it;
                if is_absolute_path(old_filename) continue;
                <<it = sprint("%/%", old_wd, old_filename);
                #if VERBOSE  print("... Remapping '%' to '%'.\n", old_filename, <<it);
            }
        }
    }

    if options_modified  set_build_options(options, w);

    // As the compiler builds the target program, we can listen in on messages
    // that report the status of the program. In later examples we can use
    // these messages to do sophisticated things, but for now, we'll just
    // use them to report on the status of compilation.

    // To tell the compiler to give us messages, we need to call compiler_begin_intercept
    // before we add any code to the target workspace.
    compiler_begin_intercept(w);

    #if VERBOSE {
        print("Input files: %\n", files);
        print("Run strings: %\n", files);
    }

    for files        add_build_file(it, w);
    for run_strings  add_build_string(tprint("#run %;\n", it), w);

    // Call message_loop(), which is a routine of ours below that will receive the messages.
    message_loop(check_bindings = check_bindings);

    // When we're done, message_loop will return.
    // We call compiler_end_intercept to tell the compiler we are done.
    compiler_end_intercept(w);

    {
        // None of the code in this file is intended to end up in an executable
        // of any kind. So, we tell the compiler not to make an executable for us:

        set_build_options_dc(.{do_output=false, write_added_strings=false});
    }
}

#run build();

//
// message_loop() runs the event loop that reads the messages.
// You can do whatever you want with those messages. The goal
// of this example is just to show the different kinds of messages,
// so we don't do anything crazy yet. But you can do some things
// that are crazy.
//
message_loop :: (check_bindings: bool) {
    while true {
        // We ask the compiler for the next message. If one is not available,
        // we will wait until it becomes available.
        message := compiler_wait_for_message();
        if !message break;

        // A non-null result is a struct Message, defined in modules/Compiler.
        // We can switch on message.kind to decide what to do.
        if message.kind == {
          case .TYPECHECKED;
            #if VERBOSE {
                typechecked := cast(*Message_Typechecked) message;
                n := typechecked.all.count;
                if n == 1 {
                    print("  1 thing has been typechecked.\n");
                } else {
                    print("  % things have been typechecked.\n", n);
                }
            }

            // We get this message every time some code has passed typechecking.
            // We can inspect the code, search for things, modify code, etc.
            // For now we'll just report how much code has been typechecked.
            do_error_checking(message, check_bindings = check_bindings);

            {
                // This file is a copy of:
                // `Default_Metaprogram.jai` version `beta 0.0.099`
                // ... but with this block added.
                metaprogram :: #import "Metaprogram";
                metaprogram.check_message(message);
            }

          case .COMPLETE;
            finish_error_checking();
            // The compiler sends us this message when compilation is finished.
            break;
        }
    }
}

#import "Basic";
#import "Compiler";
#import "Check";
