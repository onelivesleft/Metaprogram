// what will we control with enviroment?
// [x] enable check bindings
// [ ] enable quiet mode
// [ ] add import dir
//

update_options :: () #expand {
    #if use_environment_variables {
        {
            value, found := get_environment_variable("JAI_CHECK_BINDINGS");
            if found && value && value != "0"
                `check_bindings = true;
        }

        {
            value, found := get_environment_variable("JAI_QUIET");
            if found && value && value != "0"
                `options.text_output_flags = 0;
        }

        {
            value, found := get_environment_variable("JAI_IMPORT_DIR");
            if found && value {
                new_path: [..] string;
                array_add(*new_path, ..`options.import_path);
                while true {
                    path := trimmed_bite(*value, #char ";");
                    if path  array_add(*new_path, path);
                    if !value  break;
                }
                `options.import_path = new_path;
            }
        }
    }
}


get_environment_variable :: ($$name: string) -> string, found: bool {
    #if OS == .WINDOWS
        sys :: #import "Windows";
    else
        sys :: #import "POSIX";

    #if is_constant(name) {
        result := sys.getenv(name.data);
    }
    else {
        c_name := to_c_string(name);
        defer free(c_name);
        result := sys.getenv(c_name);
    }

    if result  return to_string(result), true;
    else       return "", false;
}
