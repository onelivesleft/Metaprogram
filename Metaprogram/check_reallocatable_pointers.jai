#scope_module


becomes_invalid :: "Becomes_Invalid";


check_reallocatable_pointers :: (message: *Message) {
    if message.kind != .TYPECHECKED return;

    typechecked := cast(*Message_Typechecked) message;
    for typechecked.all {
        check_expression(it.expression);
        for expression: it.subexpressions
            check_expression(expression);
    }

    check_expression :: (expression: *Code_Node) {
        if !expression.enclosing_load
        || expression.enclosing_load.enclosing_import.module_type != .MAIN_PROGRAM
            return;

        if expression.kind == {
            case .BINARY_OPERATOR;
            op := cast(*Code_Binary_Operator) expression;
            if op.operator_type == #char "="
                check_right_hand_side(op.right);

            case .DECLARATION;
            decl := cast(*Code_Declaration) expression;
            if !has_note(decl, becomes_invalid)
            check_right_hand_side(decl.expression);
        }

        check_right_hand_side :: (expression: *Code_Node) #expand {
            if !expression || expression.type.type != .POINTER  return;

            // @TODO narrow this by checking element type matches pointer type
            //type := <<cast(*Type)*expression.type;

            for * node: <<expression {
                if node.kind == .IDENT {
                    ident := cast(*Code_Ident) node;
                    if !ident.resolved_declaration
                    || !ident.resolved_declaration.type_inst
                        continue;

                    pointer_to_resizable_array_message :: "It looks like you are taking a pointer to an item in a resizable array.  If the array reallocates (which can occur any time the array grows) the pointer will become invalid!  [You may silence this warning on a declaration by annotating it with @Becomes_Invalid]";
                    if ident.resolved_declaration.type_inst.inst_flags & .RESIZABLE {
                        report(expression, pointer_to_resizable_array_message, check_for_reallocatable_pointers);
                        `return;
                    }
                }
            }
        }
    }
}
