#scope_module


#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "Process";


modules_folder :: "modules";
modules_list_filename :: "modules.lst";

special_import_char_as_string :: "|";
special_import_char           :: special_import_char_as_string[0];
separator_char         :: #char ".";
download_locally_char  :: #char ".";

cwd := "";


// @TODO report this weird unrepoable bug
/*
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
*/


check_imports :: (message: *Message) {
    if message.kind == .FAILED_IMPORT {
        message_import := cast(*Message_Failed_Import) message;
        if message_import.status != .NOT_FOUND
            return;

        if cwd == ""  cwd = get_working_directory();

        target_module_name := message_import.target_module_name;

        if message_import.host_module_name {
            // If we're in a managed module which imports a sibling we need to remap that sibling
            host_path_id := message_import.host_module_name;
            bite(*host_path_id, special_import_char);
            if host_path_id  {
                modules, found := table_find(downloaded_modules, host_path_id);
                if found {
                    found = false;
                    for modules  if it == target_module_name {
                        target_module_name = tprint("%1%2%3", it, special_import_char_as_string, host_path_id);
                        found = true;
                        break;
                    }
                    if !found {
                        print("[Import] %: Module not present in modules.lst\n", message_import.target_module_name);
                        return;
                    }
                }
            }
        }

        import, ok := parse_import(target_module_name);
        if !ok {
            if contains(message_import.target_module_name, special_import_char)
                print(#string __

[Import] Could not parse import: expected import formats we handle are:

Github module:
    %1[1;36m#import "Module|v#.#.#|Repository.User";%1[m

    e.g.
    %1[1;36m#import "Strings|v1.0.8|jai_string.onelivesleft";%1[m

    To download the module into this project instead of into your modules_downloaded folder,
    prefix the module with a `.`:
    %1[1;36m#import ".Strings|v1.0.8|jai_string.onelivesleft";%1[m

Local module:
    %1[1;36m#import "Module|c:/path/to/parent/folder";%1[m

__, "\e");
            return;
        }

        base_path : string= ---;
        if #complete import.kind == {
            case .DOWNLOAD;
            if #complete import.download_kind == {
                case .GITHUB;
                if import.is_local_to_project  base_path = tprint("%1/%2", cwd, modules_folder);
                else                           base_path = downloaded_modules_folder;
            }

            case .PATH;
            base_path = "";
            if import.is_local_to_project  base_path = cwd;
            else                           base_path = "";

            case .INLINE;
            provide_import(message.workspace, message_import, .FULL_TEXT, import.text);
            return;

        }
        replace(*base_path, #char "\\", #char "/");

        if #complete import.kind == {
            case .DOWNLOAD;
            path := find_downloaded_import_at_path(import, base_path);
            if path {
                provide_import(message.workspace, message_import, .PATH_TO_DIRECTORY, path);
                return;
            }
            else {
                downloaded := download_import(import, base_path);
                path = find_downloaded_import_at_path(import, base_path);
                if path {
                    provide_import(message.workspace, message_import, .PATH_TO_DIRECTORY, path);
                    return;
                }
            }

            case .PATH;
            path, is_file := find_import_at_path(import, base_path);
            if path {
                if is_file {
                    // @TODO report this bug - first line is what we want but it doesn't work
                    //provide_import(message.workspace, message_import, .PATH_TO_FILE, path);
                    provide_import(message.workspace, message_import, .FULL_TEXT, read_entire_file(path));
                }
                else
                    provide_import(message.workspace, message_import, .PATH_TO_DIRECTORY, path);
                return;
            }

            case .INLINE;
        }
    }
}


Import :: struct {
    union {
        name : string;
        text : string;
    }
    version: string;
    local_path_id : string;

    github_username: string;
    github_reponame: string;

    kind: enum u8 { PATH; DOWNLOAD; INLINE; };
    download_kind: enum u8 { GITHUB; };
    is_local_to_project : bool;
}


parse_import :: (import_string: string) -> Import, ok: bool {
    import : Import = ---;
    ok : bool = ---;

    if !import_string  return import, false;

    if contains(import_string, #char "\n") {
        import.kind = .INLINE;
        import.text = import_string;
        return import, true;
    }

    if import_string[0] == download_locally_char {
        import.is_local_to_project = true;
        advance(*import_string, 1);
    }
    else {
        import.is_local_to_project = false;
    }

    import.name, ok = bite(*import_string, special_import_char);
    if !ok || !import.name return import, false;

    import.local_path_id = import_string;

    if contains(import_string, special_import_char) { // Only downloaded imports have the special char twice
        import.kind = .DOWNLOAD;
        import.download_kind = .GITHUB;

        import.version, ok = bite(*import_string, special_import_char);
        if !ok || !check_version(import.version) return import, false;

        import.github_reponame, ok = bite(*import_string, separator_char);
        if !ok || !import.github_reponame return import, false;

        import.github_username = import_string;
        if !ok || !import.github_username return import, false;
    }
    else {
        import.kind = .PATH;
        import.is_local_to_project = true;

        if import.local_path_id.count >= 2 && import.local_path_id[0] == #char "." && import.local_path_id[1] == #char "/"
            advance(*import.local_path_id, 2);

        if import.local_path_id.count > 1 && ends_with(import.local_path_id, #char "/")
            import.local_path_id.count -= 1;

        #if OS == .WINDOWS {
            if import.local_path_id.count >= 2 && import.local_path_id[1] == #char ":"
                import.is_local_to_project = false;
        }
        else {
            if import.local_path_id && import.local_path_id[0] == #char "/"
                import.is_local_to_project = false;
        }
    }

    return import, true;
}


check_version :: (version: string) -> bool {
    if version == "" || version[0] != #char "v"  return false;
    advance(*version, 1);

    s : string = ---;
    ok : bool = ---;

    s, ok = bite(*version, #char ".");
    if !ok || !string_is_digits(s)  return false;

    s, ok = bite(*version, #char ".");
    if !ok || !string_is_digits(s)  return false;

    if !string_is_digits(version)  return false;

    return true;
}


string_is_digits :: (s: string) -> bool {
    for i: 0 .. s.count - 1  if s[i] < #char "0" || s[i] > #char "9"  return false;
    return true;
}


find_import_at_path :: (import: Import, base_directory: string) -> string, is_file: bool {
    if import.is_local_to_project && !file_exists(base_directory)  return "", false;

    file_path := import_path(import, base_directory);
    folder_path := file_path;
    folder_path.count -= 4; // remove .jai extension

    if file_exists(file_path) {
        if file_exists(folder_path) {
            print("[Import] %1: Module import is ambiguous: both \"%1/\" and \"%1.jai\" exist.\n", import.name);
            return "", false;
        }
        return file_path, true;
    }

    if file_exists(folder_path)
        return folder_path, false;
    else
        return "", false;
}


downloaded_modules : Table(string, [..] string);

find_downloaded_import_at_path :: (import: Import, base_directory: string) -> string {
    if !file_exists(base_directory)  return "";

    path := import_path(import, base_directory);
    if !file_exists(path)  return "";

    version_path := parent_path(path);
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
            array_add(*modules_present, module_name);
        }
        if !modules_list_text  break;
    }
    table_set(*downloaded_modules, import.local_path_id, modules_present);

    return path;
}


import_path :: (import: Import, base_directory: string) -> string {
    if #complete import.kind == {
        case .DOWNLOAD;
        return tprint("%/%/%/%/%", base_directory, import.github_username, import.github_reponame, import.version, import.name);

        case .PATH;
        if import.is_local_to_project {
            if import.local_path_id
                return tprint("%/%/%.jai", base_directory, import.local_path_id, import.name);
            else
                return tprint("%/%.jai", base_directory, import.name);
        }
        else
            return tprint("%/%.jai", import.local_path_id, import.name);

        case .INLINE;
        return "";
    }
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
        print("\n[Import] %: Error while running: ", import.name);
        print_joined(command);
        print("\n\n%\n", error_string);
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



parent_path :: (s: string) -> string {
    return slice(s, 0, last_index(s, #char "/"));
}
