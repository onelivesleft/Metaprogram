#scope_module


log_message :: (message: *Message) {
    if message.kind == {
        case .COMPLETE;
        message_complete := cast(*Message_Complete) message;
        print("%\n", <<message_complete);

        case .DEBUG_DUMP;
        message_debug_dump := cast(*Message_Debug_Dump) message;
        print("%\n", <<message_debug_dump);

        case .FAILED_IMPORT;
        message_failed_import := cast(*Message_Failed_Import) message;
        print("%\n", <<message_failed_import);

        case .FILE;
        message_file := cast(*Message_File) message;
        print("%\n", <<message_file);

        case .IMPORT;
        message_import := cast(*Message_Import) message;
        print("%\n", <<message_import);

        case .PHASE;
        message_phase := cast(*Message_Phase) message;
        print("%\n", <<message_phase);

        case .TYPECHECKED;
        message_typechecked := cast(*Message_Typechecked) message;
        print("%\n", <<message_typechecked);
    }
}
