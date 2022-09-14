module ppl._2_parse.ParseVariable;

import ppl.internal;

final class ParseVariable {
private:
    Module module_;

    enum Loc { LOCAL, PARAM, FUNCTYPE_PARAM, RETURN_TYPE, STRUCT_MEMBER, TUPLE_MEMBER }

    auto exprParser()   { return module_.exprParser; }
    auto typeParser()   { return module_.typeParser; }
    auto typeDetector() { return module_.typeDetector; }
    auto builder()      { return module_.nodeBuilder; }
public:
    this(Module module_) {
        this.module_ = module_;
    }
    Type parseParameterForTemplate(Tokens t, ASTNode parent) {
        Type type;
        if(typeDetector().isType(t, parent)) {
            type = typeParser.parseForTemplate(t, parent);
        }

        if(t.kind() == TT.COMMA) {
            assert(false);
        } else {
            /// name
            assert(t.kind() == TT.IDENTIFIER, "type=%s".format(t.get()));
            t.next();
        }
        return type;
    }
    /// foo ( type name, b )
    ///       ^^^^^^^^^  ^
    void parseParameter(Tokens t, ASTNode parent) {
        parse(t, parent, Loc.PARAM);
    }
    /// (type name)
    ///  ^^^^^^^^^
    void parseFunctionTypeParameter(Tokens t, ASTNode parent) {
        parse(t, parent, Loc.FUNCTYPE_PARAM);
    }
    /// (return type)
    ///         ^^^^
    void parseReturnType(Tokens t, ASTNode parent) {
        parse(t, parent, Loc.RETURN_TYPE);
    }
    /// struct S ( [pub] [static] [var|const] type name ...
    ///            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    void parseStructMember(Tokens t, ASTNode parent) {
        parse(t, parent, Loc.STRUCT_MEMBER);
    }
    /// [int a, int ...
    ///  ^^^^^  ^^^
    void parseTupleMember(Tokens t, ASTNode parent) {
        parse(t, parent, Loc.TUPLE_MEMBER);
    }
    /// [static | const ] type name ...
    void parseLocal(Tokens t, ASTNode parent) {
        parse(t, parent, Loc.LOCAL);
    }
private:
    ///
    /// type
    /// id
    /// type id
    /// [ pub static const ] type id "=" expression
    ///
    void parse(Tokens t, ASTNode parent, Loc loc) {
        //dd("variable", t.get);
        auto v = makeNode!Variable(t);
        parent.add(v);

        ///
        /// Handle access
        ///
        if(t.value()=="pub") {
            switch(loc) {
                case Loc.STRUCT_MEMBER:
                    t.setAccessPublic(true);
                    t.next();
                    break;
                default:
                    module_.addError(t, "Visibility modifier not allowed here", true);
                    t.next();
                    break;
            }
        }

        if(parent.isModule() && t.isPublic) {
            module_.addError(t, "Global variables cannot be public", true);
            t.setAccessPublic(false);
        }

        v.type     = TYPE_UNKNOWN;
        v.isPublic = t.isPublic;

        bool seenStatic, seenConst, hasExplicitType;

        bool _nameRequired() {
            switch(loc) with(Loc) {
                case LOCAL: case PARAM: case STRUCT_MEMBER:
                    return true;
                default:
                    return false;
            }
        }
        bool _nameAllowed() {
            switch(loc) with(Loc) {
                case LOCAL: case PARAM: case FUNCTYPE_PARAM: case STRUCT_MEMBER: case TUPLE_MEMBER:
                    return true;
                default:
                    return false;
            }
        }
        bool _typeRequired() {
            switch(loc) with(Loc) {
                case STRUCT_MEMBER: case TUPLE_MEMBER: case FUNCTYPE_PARAM: case RETURN_TYPE:
                    return true;
                default:
                    return false;
            }
        }
        bool _staticAllowed() {
            switch(loc) with(Loc) {
                case STRUCT_MEMBER:
                    return true;
                default:
                    return false;
            }
        }
        bool _varConstAllowed() {
            switch(loc) with(Loc) {
                case LOCAL:
                    return true;
                default:
                    return false;
            }
        }

        ///
        /// Handle static and or const
        ///
        outer: while(true) {
            switch(t.value()) {
                case "static":
                    if(!_staticAllowed()) module_.addError(t, "'static' not allowed here", true);
                    if(seenStatic) module_.addError(t, "'static' specified more than once", true);
                    v.isStatic = true;
                    seenStatic = true;
                    t.next();
                    break;
                case "const":
                    if(!_varConstAllowed()) module_.addError(t, "'const' not allowed here", true);
                    if(seenConst) module_.addError(t, "'const' specified more than once", true);
                    v.isConst  = true;
                    seenConst  = true;
                    t.next();
                    break;
                default: break outer;
            }
        }

        ///
        /// Look for the Type
        ///
        if(typeDetector().isType(t, v)) {
            hasExplicitType = true;
            v.type = typeParser.parse(t, v);
            assert(v.type);
        } else {
            /// no explicit type
            if(_typeRequired()) {
                module_.addError(t, "Variable type required", false);
            }

            if(!seenConst) {
                if(_typeRequired()) {
                    errorMissingType(module_, t, t.value());
                }
                if(t.kind() == TT.IDENTIFIER && t.peek(1).kind == TT.IDENTIFIER) {
                    errorMissingType(module_, t, t.value());
                }
            }
        }

        bool _initRequired() {
            return loc==Loc.LOCAL && !hasExplicitType;
        }

        ///
        /// Look for the name
        ///
        if(t.isKind(TT.IDENTIFIER) && loc != Loc.RETURN_TYPE && t.value() != "return" && !t.get().templateType) {
            if(!_nameAllowed()) {
                module_.addError(t, "Variable name not allowed here", true);
            }

            v.name = t.value();

            if(v.name=="this") {
                module_.addError(t, "'this' is a reserved word", true);
            }
            t.next();

            /// '=' Initialiser
            if(t.isKind(TT.EQUALS)) {
                t.next();

                auto ini = makeNode!Initialiser;
                ini.var = v;
                v.add(ini);

                exprParser().parse(t, ini);

            } else {
                if(_initRequired()) {
                    module_.addError(v, "Implicitly typed variable requires initialisation", true);
                }
                if(v.isConst) {
                    module_.addError(v, "Const variable must be initialised", true);
                }
            }
        } else {
            if(_nameRequired()) {
                module_.addError(t, "Variable name required", false);
            }
        }

        if(v.type.isUnknown() && t.isKind(TT.LANGLE)) {
            t.prev();
            module_.addError(v, "Type %s not found".format(t.value()), false);
        }

        v.setEndPos(t);
    }
}