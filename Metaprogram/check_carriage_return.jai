#scope_module


contains_carriage_return :: "Contains_Carriage_Return";


check_carriage_return :: (message: *Message) {
    if message.kind != .TYPECHECKED return;

    typechecked := cast(*Message_Typechecked) message;
    for typechecked.all {
        check_expression(it.expression);
        for expression: it.subexpressions
            check_expression(expression);
    }

    check_expression :: (expression: *Code_Node) #expand {
        if !expression.enclosing_load
        || !expression.enclosing_load.enclosing_import
        || expression.enclosing_load.enclosing_import.module_type != .MAIN_PROGRAM
            return;

        if expression.kind == {
            case.DECLARATION;
            decl := cast(*Code_Declaration) expression;
            if decl.expression.kind != .LITERAL  return;

            literal := cast(*Code_Literal) decl.expression;
            if literal.value_type != .STRING
            || has_note(decl, contains_carriage_return)
                return;

            write_index, found := first_index(literal.values._string, #char "\r");
            if found {
                #if check_for_carriage_return == .FIX {
                    for read_index: write_index + 1 .. literal.values._string.count - 1 {
                        c := literal.values._string[read_index];
                        if c != #char "\r" {
                            literal.values._string[write_index] = c;
                            write_index += 1;
                        }
                    }
                    for i: write_index .. literal.values._string.count - 1
                        literal.values._string[i] = #char "\0";
                }
                else {
                    contains_carriage_return_message :: "This string literal contains carriage return (\\r) characters.";
                    report(expression, contains_carriage_return_message, check_for_carriage_return);
                    `return;
                }
            }
        }
    }
}
