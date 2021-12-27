// Workspace: Main
__new_command_line_strings : [1] string : .[
    "c:\\Repos\\jai-misc\\Metaprogram\\test.jai",
];
__new_command_line_arguments : [1] *u8;
#run {
    __new_command_line_arguments[0] = __new_command_line_strings[0].data;
    __command_line_arguments.data = __new_command_line_arguments.data;
    __command_line_arguments.count = __new_command_line_arguments.count;
}
#run main();
