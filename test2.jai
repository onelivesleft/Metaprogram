#import "Basic";


main :: () {
    array := float32.[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1, 2, 3, 4, 5, 6, 7, 8];
    ptr := array.data;

    #asm AVX, AVX2 {
        movups.y v:, [ptr];
        addps.y v, v, [ptr];
        movups.y [ptr], v;
    }

    print("%\n", array);

    p := *array;
    (<<p)[0] = 100;


    print("%\n", array);

    a := #ifx true then 1; else 0;
    print("%\n", a);
}


build :: #string __jai
    #import "Compiler";
    build_options := get_build_options();
    build_options.output_executable_name = "TEST!.exe";

    workspace := compiler_create_workspace();
    set_build_options(build_options, workspace);

    add_build_file(#file, workspace);
__jai
