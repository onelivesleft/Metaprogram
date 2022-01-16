// what will we control with enviroment?
// [x] enable check bindings
// [x] enable quiet mode
// [x] add import dir


update_options :: () #expand {
    #if use_build_string && #run (get_current_workspace() == 1) {

        build_header :: #string __jai
{
        __jai

        build_footer :: #string __jai
    set_build_options_dc(.{do_output=false}, 2);
}
        __jai

        if `files.count == 1 && `run_strings.count == 0 {
            file :: #import "File";
            program := file.read_entire_file(`files[0]);
            jai_string :: #import "String";
            start_marker :: "\nbuild :: #string ";
            index_of_build := jai_string.find_index_from_left(program, start_marker);
            if index_of_build >= 0 {
                end_marker := slice(program, index_of_build + start_marker.count);
                end_marker_index := 0;
                while end_marker_index < end_marker.count && end_marker[end_marker_index] > #char " "
                    end_marker_index += 1;
                end_marker.count = end_marker_index;
                if jai_string.contains_any_string(end_marker, "build")
                    compiler_report("Do not use \"build\" as part of your build #string terminator!");

                filepath := jai_string.replace(`files[0], "\\", "/");
                slash := jai_string.find_index_from_right(filepath, "/");
                if slash >= 0  filepath.count = slash + 1;

                build_script := slice(program, index_of_build + start_marker.count + end_marker.count);
                end_marker_index = jai_string.find_index_from_left(build_script, end_marker);
                if end_marker_index < 0
                    compiler_report("Could not find build #string terminator!");
                build_script.count = end_marker_index;

                build_script = jai_string.replace(build_script, "#filepath", tprint("\"%\"", filepath));
                build_script = jai_string.replace(build_script, "#file", tprint("\"%\"", `files[0]));

                build_script = jai_string.join(build_header, build_script, build_footer);

                `files = .[];
                new_strings : [..] string;
                array_add(*new_strings, build_script);
                `run_strings = new_strings;
            }
        }
    }

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
