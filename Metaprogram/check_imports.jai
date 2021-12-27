#scope_module


#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "Process";


modules_folder :: "modules";
modules_list_filename :: "modules.lst";


// @TODO report this weird unrepoable bug
xcheck_imports :: (message: *Message) {
    if message.kind == .FAILED_IMPORT {
        import := cast(*Message_Failed_Import) message;
        if import.status != .NOT_FOUND
        || import.host_module_name
            return;

        import, ok := parse_import(import.target_module_name);
        // import is a *Import!
        print("%\n", type_of(import));
        print("%\n", import);
        print("%\n", <<import);
    }
}



check_imports :: (message: *Message) {
    if message.kind == .FAILED_IMPORT {
        message_import := cast(*Message_Failed_Import) message;
        if message_import.status != .NOT_FOUND
        || message_import.host_module_name
            return;

        import, ok := parse_import(message_import.target_module_name);
        if !ok {
            if contains(message_import.target_module_name, #char "/", #char ".")
                print(#string __

[Import] Could not parse import: expected format for a managed import is:
    %1[1;36m#import "Module/Version/Reponame.Username";%1[m

For example:
    %1[1;36m#import "Strings/v1.0.8/jai_string.onelivesleft";%1[m
__, "\e");
            return;
        }

        base_path := ifx import.is_local
                     then tprint("%1%2", #filepath, modules_folder)
                     else downloaded_modules_folder;
        replace(*base_path, #char "\\", #char "/");

        path := find_downloaded_import(import, base_path);
        if path {
            provide_import(message.workspace, message_import, .ABSOLUTE_PATH, path);
            //provide_import(message.workspace, message_import, .ABSOLUTE_PATH, tprint("%1%2/module.jai", #filepath, path));

            // File :: #import "File";
            // provide_import(message.workspace, message_import, .FULL_TEXT, File.read_entire_file(tprint("%1%2/module.jai", #filepath, path)));
            return;
        }
        else {
            downloaded := download_import(import, base_path);
            path = find_downloaded_import(import, base_path);
            if path {
                provide_import(message.workspace, message_import, .ABSOLUTE_PATH, path);
                //provide_import(message.workspace, message_import, .ABSOLUTE_PATH, tprint("%1%2/module.jai", #filepath, path));

                // File :: #import "File";
                // provide_import(message.workspace, message_import, .FULL_TEXT, File.read_entire_file(tprint("%1%2/module.jai", #filepath, path)));
                return;
            }
        }
    }
}


Import :: struct {
    is_local: bool;
    name : string;
    version: string;
    github_username: string;
    github_reponame: string;
}


parse_import :: (import_string: string) -> Import, ok: bool {
    import : Import = ---;
    ok : bool = ---;

    if !import_string  return import, false;

    if import_string[0] == #char "." {
        import.is_local = true;
        advance(*import_string, 1);
    }
    else {
        import.is_local = false;
    }

    import.name, ok = bite(*import_string, #char "/");
    if !ok || !import.name return import, false;

    import.version, ok = bite(*import_string, #char "/");
    if !ok || !import.version return import, false;

    import.github_reponame, ok = bite(*import_string, #char ".");
    if !ok || !import.github_reponame return import, false;

    import.github_username = import_string;
    if !ok || !import.github_username return import, false;

    return import, true;
}


downloaded_modules : Table(string, [..] string);

find_downloaded_import :: (import: Import, base_directory: string) -> string {
    if !file_exists(base_directory)  return "";

    path := import_path(import, base_directory);
    version_path := parent_path(path);
    modules, found := table_find(downloaded_modules, version_path); // @TODO only do this if host_module_name is here
    if found {
        for modules  if it == import.name  return path;
        print("[Import] %: Module not present in modules.lst\n", import.name);
        return "";
    }

    if !file_exists(path)  return "";

    modules_list_path := tprint("%/%", version_path, modules_list_filename);
    if !file_exists(modules_list_path) {
        print("[Import] %: Error processing local module import. Missing file: %\n", import.name, modules_list_path);
        return "";
    }

    modules_list_text := read_entire_file(modules_list_path);
    modules_present : [..] string;
    while true {
        module_name := trimmed_bite(*modules_list_text, #char "\n");
        if module_name {
            module_path := tprint("%/%", version_path, module_name);
            if !file_exists(module_path) {
                print("[Import] %: Module % not found, was listed in: %\n", import.name, module_name, modules_list_path);
                array_free(modules_present);
                return "";
            }
            array_add(*modules_present, import.name);
        }
        if !modules_list_text  break;
    }
    table_set(*downloaded_modules, version_path, modules_present);

    return path;
}


import_path :: (import: Import, base_directory: string) -> string {
    return tprint("%/%/%/%/%", base_directory, import.github_username, import.github_reponame, import.version, import.name);
}


download_import :: (import: Import, base_directory: string) -> bool {
    target_path := import_path(import, base_directory);
    version_path := parent_path(target_path); // remove name
    repo_path := parent_path(version_path); // remove version

    if !make_all_directories(repo_path) {
        print("\n[Import] %: Failed to make path: %\n\n", import.name, repo_path);
        return false;
    }

    command := string.[
        "git",
        "clone",
        "--branch", "",
        "--depth", "1",
        "", ""
    ];
    command[3] = import.version;
    command[6] = tprint("https://www.github.com/%/%.git", import.github_username, import.github_reponame);
    command[7] = version_path;

    print("[Import] %: Downloading % %...\n", import.name, command[6], import.version);

    successfully_launched, exit_code, output_string, error_string := os_run_command(..command, capture_and_return_output=true);
    if !successfully_launched {
        print("\n[Import] %: Failed to run: %\n\n", import.name, command);
        return false;
    }

    if exit_code {
        print("\n[Import] %: Error while running: %\n", command);
        print("\n%\n", error_string);
        return false;
    }

    // @TODO prune all non-module files (i.e. all files that are not modules.lst or a folder listed in modules.lst)

    return true;
}


make_all_directories :: (path: string) -> bool {
    if path.count <= 1  return false;

    for i: 1 .. path.count - 1 {
        if path[i] == #char "/" {
            section := slice(path, 0, i);
            if !file_exists(section)
                if !make_directory_if_it_does_not_exist(section)
                    return false;
        }
    }

    if ends_with(path, #char "/")  return true;
    else                           return make_directory_if_it_does_not_exist(path);
}


bite :: (s: *string, c: u8) -> left: string, found: bool {
    for i: 0 .. s.count - 1 {
        if (<<s)[i] == c {
            left := <<s;
            left.count = i;
            advance(s, (i + 1));
            return left, true;
        }
    }
    return "", false;
}


trimmed_bite :: (s: *string, c: u8) -> left: string, found: bool {
    left, found := bite(s, c);
    if !found  return left, false;

    start_index := 0;
    while start_index < left.count && left[start_index] <= #char " "
        start_index += 1;
    if start_index >= s.count  return "", true;

    end_index := left.count - 1;
    while end_index > start_index && left[end_index] <= #char " "
        end_index -= 1;
    end_index += 1;

    return slice(left, start_index, end_index), true;;
}


parent_path :: (s: string) -> string {
    return slice(s, 0, last_index(s, #char "/"));
}


contains :: (s: string, a: u8, b: u8) -> bool {
    for 0 .. s.count - 1  if s[it] == a || s[it] == b  return true;
    return false;
}


slice :: (s: string, from: int, to: int) -> string {
    if from < 0  from += s.count;
    if from < 0  from = 0;
    if to < 0  to += s.count;
    if to <= from  return "";

    result := s;
    result.data += from;
    result.count -= (from + result.count - to);
    return result;
}

replace :: (s: *string, from: u8, to: u8) {
    for 0 .. s.count - 1 {
        if (<<s)[it] == from {
            (<<s)[it] = to;
        }
    }
}

last_index :: (s: string, c: u8) -> int, bool {
    for < i: s.count - 1 .. 0  if s[i] == c  return i, true;
    return -1, false;
}

ends_with :: (s: string, c: u8) -> bool {
    return s && s[s.count - 1] == c;
}
