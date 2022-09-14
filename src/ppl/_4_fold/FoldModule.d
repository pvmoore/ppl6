module ppl._4_fold.FoldModule;

import ppl.internal;

/**
 *  Remove unused AST nodes.
 *  Evaluate contant expressions/statements.
 */
final class FoldModule {
private:
    Module mod;
    FoldUnreferenced _folder;
    FoldUnreferenced folder() {
        // FIXME - Lazy initialisation
        if(_folder is null) {
            _folder = new FoldUnreferenced(mod, mod.resolver);
        }
        return _folder;
    }
public:
    this(Module mod) {
        this.mod = mod;
    }
    /** Start of a parse/resolve/fold pass. Reset the counters here. */
    void reset() {
        folder().resetFoldCount();
    }
    /**
     * Fold Module and return true if anything was changed.
     */
    bool foldModule() {

        foreach(n; mod.children[].dup) {
            recursiveVisit(n);
        }

        folder().processModule();

        return folder.getNumFolds() > 0;
    }
    void fold(ASTNode removeMe, bool dereference = true) {
        folder().fold(removeMe, dereference);
    }
    void fold(ASTNode replaceMe, ASTNode withMe, bool dereference = true) {
        folder().fold(replaceMe, withMe, dereference);
    }
private:
    void recursiveVisit(ASTNode node) {
        if(!node.isAttached()) return;

        if(node.id() == NodeID.STRUCT) {
            if(node.as!Struct.isTemplateBlueprint()) return;
        } else if(node.isFunction()) {
            auto f = node.as!Function;
            if(f.isTemplateBlueprint()) return;
            if(f.isImport) return;
        } else if(node.isAlias()) {
            auto a = node.as!Alias;
            if(a.isStandard() && !a.type.isAlias()) return;
        }

        foreach(n; node.children[].dup) {
            recursiveVisit(n);
        }

        foldNode(node);
    }
    void foldNode(ASTNode node) {
        switch(node.id()) with(NodeID) {
            case ADDRESS_OF:
                fold(node.as!AddressOf);
                break;
            case ALIAS:
                fold(node.as!Alias);
                break;
            case ARRAY:
                fold(node.as!Array);
                break;
            case AS:
                fold(node.as!As);
                break;
            case ASSERT:
                fold(node.as!Assert);
                break;
            case BINARY:
                fold(node.as!Binary);
                break;
            case BREAK:
                fold(node.as!Break);
                break;
            case BUILTIN_FUNC:
                fold(node.as!BuiltinFunc);
                break;
            case CALL:
                fold(node.as!Call);
                break;
            case CALLOC:
                fold(node.as!Calloc);
                break;
            case CASE:
                fold(node.as!Case);
                break;
            case CLASS:
                fold(node.as!Class);
                break;
            case COMPOSITE:
                fold(node.as!Composite);
                break;
            case CONSTRUCTOR:
                fold(node.as!Constructor);
                break;
            case CONTINUE:
                fold(node.as!Continue);
                break;
            case DOT:
                fold(node.as!Dot);
                break;
            case ENUM:
                fold(node.as!Enum);
                break;
            case ENUM_MEMBER:
                fold(node.as!EnumMember);
                break;
            case ENUM_MEMBER_VALUE:
                fold(node.as!EnumMemberValue);
                break;
            case FUNCTION:
                fold(node.as!Function);
                break;
            case FUNC_TYPE:
                fold(node.as!FunctionType);
                break;
            case IDENTIFIER:
                fold(node.as!Identifier);
                break;
            case IF:
                fold(node.as!If);
                break;
            case INDEX:
                fold(node.as!Index);
                break;
            case IS:
                fold(node.as!Is);
                break;
            case IMPORT:
                fold(node.as!Import);
                break;
            case INITIALISER:
                fold(node.as!Initialiser);
                break;
            case LAMBDA:
                fold(node.as!Lambda);
                break;
            case LITERAL_ARRAY:
                fold(node.as!LiteralArray);
                break;
            case LITERAL_FUNCTION:
                fold(node.as!LiteralFunction);
                break;
            case LITERAL_NULL:
                fold(node.as!LiteralNull);
                break;
            case LITERAL_NUMBER:
                fold(node.as!LiteralNumber);
                break;
            case LITERAL_STRING:
                fold(node.as!LiteralString);
                break;
            case LITERAL_TUPLE:
                fold(node.as!LiteralTuple);
                break;
            case LOOP:
                fold(node.as!Loop);
                break;
            case MODULE_ALIAS:
                fold(node.as!ModuleAlias);
                break;
            case PARAMETERS:
                fold(node.as!Parameters);
                break;
            case PARENTHESIS:
                fold(node.as!Parenthesis);
                break;
            case PLACEHOLDER:
                fold(node.as!Placeholder);
                break;
            case RETURN:
                fold(node.as!Return);
                break;
            case SELECT:
                fold(node.as!Select);
                break;
            case STRUCT:
                fold(node.as!Struct);
                break;
            case TUPLE:
                fold(node.as!Tuple);
                break;
            case TYPE_EXPR:
                fold(node.as!TypeExpr);
                break;
            case UNARY:
                fold(node.as!Unary);
                break;
            case VALUE_OF:
                fold(node.as!ValueOf);
                break;
            case VARIABLE:
                fold(node.as!Variable);
                break;

            default:
                throwIf(true, "FoldModule: Implement me: %s", node.id());
                break;
        }
    }
    void fold(AddressOf n) {
        if(n.expr.id()==NodeID.VALUE_OF) {
            auto valueof = n.expr.as!ValueOf;
            auto child   = valueof.expr();
            folder.fold(n, child);
        }
    }
    void fold(Alias n) {
        if(n.isTypeof()) {
            if(n.first().isResolved()) {
                n.type = n.first().getType();
                n.convertToStandard();
                folder.fold(n.first());
            }
        }
    }
    void fold(Array n) {

    }
    void fold(As n) {

    }
    void fold(Assert n) {

    }
    void fold(Binary n) {

    }
    void fold(Break n) {

    }
    void fold(BuiltinFunc n) {

    }
    void fold(Call n) {

    }
    void fold(Calloc n) {

    }
    void fold(Case n) {

    }
    void fold(Class n) {

    }
    void fold(Composite n) {
        switch(n.usage) with(Composite.Usage) {
            case INNER_REMOVABLE:
            case INLINE_REMOVABLE:
                /// If it's empty then just remove it
                if(n.numChildren()==0) {
                    folder().fold(n);
                    break;
                }
                /// If there is only a compile time constant in this scope then fold
                if(n.numChildren==1) {
                    auto cct = n.first().as!CompileTimeConstant;
                    if(cct) {
                        folder().fold(n, cct.copy());
                    }
                }
                break;
            default:
                break;
        }
    }
    void fold(Constructor n) {

    }
    void fold(Continue n) {

    }
    void fold(Dot n) {
        auto lt      = n.leftType();
        auto rt      = n.rightType();
        auto builder = mod.nodeBuilder;

        /// Rewrite Enum.A where A is also a type declared elsewhere
        //if(lt.isEnum && n.right().isTypeExpr) {
        //    auto texpr = n.right().as!TypeExpr;
        //    if(texpr.isResolved) {
        //        auto id = builder.identifier(texpr.toString());
        //        fold(n.right(), id);
        //        return ;
        //    }
        //}
    }
    void fold(Enum n) {

    }
    void fold(EnumMember n) {

    }
    void fold(EnumMemberValue n) {

    }
    void fold(Function n) {

    }
    void fold(FunctionType n) {

    }
    void fold(Identifier n) {

    }
    void fold(If n) {

    }
    void fold(Index n) {

    }
    void fold(Is n) {

    }
    void fold(Import n) {

    }
    void fold(Initialiser n) {

    }
    void fold(Lambda n) {

    }
    void fold(LiteralArray n) {

    }
    void fold(LiteralFunction n) {

    }
    void fold(LiteralNull n) {

    }
    void fold(LiteralNumber n) {

    }
    void fold(LiteralString n) {

    }
    void fold(LiteralTuple n) {

    }
    void fold(Loop n) {

    }
    void fold(ModuleAlias n) {

    }
    void fold(Parameters n) {

    }
    void fold(Parenthesis n) {
        /// We don't need any Parentheses any more
        folder().fold(n, n.expr());
    }
    void fold(Placeholder n) {
        /// If children==1 -> replace with child
        /// else           -> Don't remove
        if(n.numChildren()==1) {
            auto child = n.first();
            folder().fold(n, child);
        } else if(n.numChildren()>1) {
            assert(false, "Expecting Placeholder to contain only 1 child");
        }
    }
    void fold(Return n) {

    }
    void fold(Select n) {

    }
    void fold(Struct n) {

    }
    void fold(Tuple n) {

    }
    void fold(TypeExpr n) {

    }
    void fold(Unary n) {

    }
    void fold(ValueOf n) {
        if(n.expr().id() == NodeID.ADDRESS_OF) {
            auto addrof = n.expr.as!AddressOf;
            auto child  = addrof.expr();
            folder().fold(n, child);
            return;
        }
    }
    void fold(Variable n) {

    }
}