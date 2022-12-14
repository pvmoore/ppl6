module ppl._2_parse.ParseStatement;

import ppl.internal;

private const string VERBOSE_MODULE = null; // "test";

final class ParseStatement {
private:
    Module module_;

    auto structParser() { return module_.structParser; }
    auto varParser()    { return module_.varParser; }
    auto typeParser()   { return module_.typeParser; }
    auto typeDetector() { return module_.typeDetector; }
    auto exprParser()   { return module_.exprParser; }
    auto funcParser()   { return module_.funcParser; }
    auto attrParser()   { return module_.attrParser; }

    auto builder()      { return module_.nodeBuilder; }
public:
    this(Module module_) {
        this.module_ = module_;
    }

    void parse(Tokens t, ASTNode parent) {
        // Debug logging
        static if(VERBOSE_MODULE) {
            if(module_.canonicalName==VERBOSE_MODULE) {
                dd("[", module_.canonicalName, "] statement line:", t.line+1, " parent:", parent.id, "token:", t.get);
                //scope(exit) dd("end statement line:", t.line+1);
            }
        }

        /// Check for statements on the same line that are not separated by semicolons /////////////
        if(t.kind() != TT.SEMICOLON && t.onSameLine() && !t.peek(-1).kind.isOneOf(TT.SEMICOLON, TT.COMMA)) {
            auto lastChild = parent.last;
            if(lastChild) {
                if(parent.id!=NodeID.STRUCT &&
                   !lastChild.isParameters &&
                   !lastChild.isComposite)
                {
                    warn(t, "Statement on the same line: %s %s %s".format(parent.id, lastChild.id, t.get()));
                }
            }
        }

        consumeAttributes(t, parent);
        if(!t.hasNext()) return;

        /// Handle access //////////////////////////////////////////////////////////////////////////

        /// Default to private access
        t.setAccessPublic(false);

        if(t.kind() == TT.IDENTIFIER) {
            if("pub" == t.value()) {

                checkPubAccess(t, parent);

                t.setAccessPublic(true);
                t.next();
            }
        }

        /// Parse some sort of identifier //////////////////////////////////////////////////////////
        if(t.kind() == TT.IDENTIFIER)  {
            switch(t.value()) {
                case "alias":
                    parseAlias(t, parent);
                    return;
                case"assert":
                    parseAssert(t, parent);
                    return;
                case "break":
                    parseBreak(t, parent);
                    return;
                case "const":
                    varParser().parseLocal(t, parent);
                    return;
                case "continue":
                    parseContinue(t, parent);
                    return;
                case "enum":
                    parseEnum(t, parent);
                    return;
                case "extern":
                    funcParser().parseExtern(t, parent);
                    return;
                case "if":
                    noExprAllowedAtModuleScope(t, parent);
                    exprParser.parse(t, parent);
                    return;
                case "import":
                    parseImport(t, parent);
                    return;
                case "loop":
                    parseLoop(t, parent);
                    return;
                case "return":
                    parseReturn(t, parent);
                    return;
                case "select":
                    noExprAllowedAtModuleScope(t, parent);
                    exprParser.parse(t, parent);
                    return;
                case "static":
                    /// static type name
                    /// static type name =
                    /// static name {
                    /// static name <

                    /// static fn
                    if(t.peek(1).value=="fn") {
                        funcParser().parse(t, parent);
                    } else if(t.peek(2).kind==TT.LCURLY) {
                        funcParser().parse(t, parent);
                    } else if (t.peek(2).kind==TT.LANGLE) {
                        funcParser().parse(t, parent);
                    } else {
                        if(parent.isA!Struct) {
                            module_.addError(t, "Struct properties are not allowed in the body", true);
                            varParser().parseStructMember(t, parent);
                        } else {
                            /// Consume this token
                            module_.addError(t, "'static' not allowed here", true);
                            t.next();
                        }
                    }
                    return;
                case "class":
                case "struct":
                    /// Could be a struct/tuple decl

                    if(t.value() == "struct" && t.peek(1).kind == TT.LBRACKET) {
                        /// "struct" "("
                        varParser().parseLocal(t, parent);
                    } else {
                        /// "struct|class" id "{"
                        /// "struct|class" id "<"
                        structParser().parse(t, parent);
                    }
                    return;
                case "fn":
                    if(t.peek(1).kind == TT.LBRACKET) {
                        /// fn()type
                        varParser().parseLocal(t, parent);
                    } else {
                        /// fn id(
                        funcParser().parse(t, parent);
                    }
                    return;
                default:
                    if(t.peek(1).kind == TT.EQUALS) {
                        varParser().parseLocal(t, parent);
                        return;
                    }
                    break;
            }
        }

        /// Parse some sort of TT (token type) /////////////////////////////////////////////////////
        switch(t.kind()) with(TT) {
            case SEMICOLON:
                t.next();
                if(t.kind() == SEMICOLON) module_.addError(t, "Extra semi-colon found", true);
                return;
            case PIPE:
                /// Lambda
                noExprAllowedAtModuleScope(t, parent);
                exprParser.parse(t, parent);
                return;
            case AT:
                if(t.peek(1).value == "typeOf") {
                    // must be a variable decl
                    varParser().parseLocal(t, parent);
                    return;
                }
                noExprAllowedAtModuleScope(t, parent);
                exprParser.parse(t, parent);
                return;
            //case LBRACKET:
            //    errorBadSyntax(module_, t, "Parenthesis not allowed here");
            //    break;
            case LSQBRACKET:
                errorBadSyntax(module_, t, "Unexpected character");
                break;
            default:
                break;
        }

        /// Check if it is a Type //////////////////////////////////////////////////////////////////

        /// type
        /// type .
        /// type (
        /// type is
        auto node = parent;
        if(node.hasChildren) node = node.last();
        int eot = typeDetector().endOffset(t, node);
        if(eot!=-1) {
            /// First token is a type so this could be one of:
            ///  - constructor
            ///  - variable declaration
            ///  - type.xxx
            ///  - is_expr
            auto nextTok = t.peek(eot+1);

            if(nextTok.kind == TT.DOT) {
                /// dot
                noExprAllowedAtModuleScope(t, parent);
                exprParser.parse(t, parent);
            } else if(nextTok.kind == TT.LBRACKET) {
                /// Constructor
                noExprAllowedAtModuleScope(t, parent);
                exprParser.parse(t, parent);
            } else if(nextTok.value=="is") {
                /// is
                noExprAllowedAtModuleScope(t, parent);
                exprParser.parse(t, parent);
            } else {
                /// Variable decl
                varParser().parseLocal(t, parent);
            }

            return;
        }

        /// Check for call to a template function //////////////////////////////////////////////////

        /// name < ... > (      // call
        /// name<...> |a| {     // call with lambda arg
        /// name<...> {         // call with lambda arg
        if(t.kind() == TT.IDENTIFIER && t.peek(1).kind == TT.LANGLE) {
            int end;
            if(ParseHelper.isTemplateParams(t, 1, end)) {
                auto nextTok = t.peek(end+1);
                auto ntt     = nextTok.kind;

                if(ntt==TT.LCURLY || ntt==TT.PIPE || ntt==TT.LBRACKET) {
                    /// Ok
                } else {
                    errorMissingType(module_, t, t.value);
                }
            }
        }

        /// Test for 'Type name' where Type is not known ///////////////////////////////////////////
        if(parent.isModule && t.kind() == TT.IDENTIFIER && t.peek(1).kind == TT.IDENTIFIER) {
            errorMissingType(module_, t, t.value);
        }

        /// It must be an expression ///////////////////////////////////////////////////////////////
        noExprAllowedAtModuleScope(t, parent);
        exprParser.parse(t, parent);
    }
private: //=============================================================================== private
    void consumeAttributes(Tokens t, ASTNode parent) {
        while(t.kind() == TT.AT) {
            int lastIndex = t.index();
            attrParser().parse(t, parent);
            if(t.index() == lastIndex) break;
        }
    }
    void checkPubAccess(Tokens t, ASTNode parent) {

        /// "pub" is only valid at module or struct scope:
        auto p = parent; if(p.isComposite || p.isA!Placeholder) p = p.parent;
        if(!p.isModule && !p.isA!Struct) {
            module_.addError(t, "'pub' visibility modifier not allowed here", true);
            return;
        }

        /// The only valid subsequent statements are:
        ///     - Module/struct scope function decl
        ///     - Module/struct scope struct decl
        ///     - Module/struct scope enum decl
        ///     - Module scope alias
        auto n = t.peek(1);

        if(n.value=="fn") return;
        if(n.value=="static" && t.peek(2).value=="fn") return;
        if(n.value=="extern" && t.peek(2).value=="fn") return;
        if(n.value=="struct") return;
        if(n.value=="class") return;
        if(n.value=="enum") return;
        if(n.value=="alias") return;

        bool isType = typeDetector().isType(t, parent, 1);
        if(!isType) {
            module_.addError(t, "'pub' visibility modifier not allowed here", true);
        }
    }
    void noExprAllowedAtModuleScope(Tokens t, ASTNode parent) {
        if(parent.isA!Module) {
            errorBadSyntax(module_, t, "Expressions not allowed at module scope");
        }
    }
    /// import       ::= "import" [identifier "="] module_paths
    /// module_path  ::= identifier { "::" identifier }
    /// module_paths ::= module_path { "," module-path }
    ///
    void parseImport(Tokens t, ASTNode parent) {

        /// "import"
        t.next();

        string _collectModuleName() {
            string moduleName = t.value;
            t.markPosition();
            t.next();

            while(t.kind() == TT.DBL_COLON) {
                t.next();
                moduleName ~= "::";
                moduleName ~= t.value;
                t.next();
            }

            /// Check that the import exists
            import std.file : exists;
            if(!exists(module_.config.getFullModulePath(moduleName))) {
                t.resetToMark();
                module_.addError(t, "Module %s does not exist".format(moduleName), false);
            }
            t.discardMark();

            module_.buildState.moduleRequired(moduleName);

            return moduleName;
        }

        while(true) {
            auto imp = makeNode!Import(t);
            parent.add(imp);

            if(t.peek(1).kind == TT.EQUALS) {
                /// module_alias = canonicalName
                imp.aliasName = t.value();
                t.next(2);

                if(findImportByAlias(imp.aliasName, imp.previous())) {
                    module_.addError(imp, "Module alias %s already found in this scope".format(imp.aliasName), true);
                }
            }

            imp.moduleName = _collectModuleName();
            module_.addImport(imp);

            if(findImportByCanonicalName(imp.moduleName, imp)) {
                module_.addError(imp, "Module %s already imported".format(imp.moduleName), true);
            }

            /// Trigger the loading of the module
            imp.mod = module_.buildState.getOrCreateModule(imp.moduleName);

            /// For each exported function and type, add proxies to this module
            foreach(f; imp.mod.parser.publicFunctions.values) {
                auto fn       = makeNode!Function;
                fn.name       = f;
                fn.moduleName = imp.moduleName;
                fn.isImport   = true;
                imp.add(fn);
            }
            foreach(d; imp.mod.parser.publicTypes.values) {
                auto def        = Alias.make();
                def.name        = d;
                def.type        = TYPE_UNKNOWN;
                def.moduleName  = imp.moduleName;
                def.isImport    = true;
                imp.add(def);
            }

            // ',' or end of Statement
            if(t.kind() == TT.COMMA) {
                t.next();
            } else break;

            imp.setEndPos(t);
        }
    }
    ///
    /// alias ::= "alias" identifier "=" type
    ///
    void parseAlias(Tokens t, ASTNode parent) {

        auto alias_ = Alias.make(t);
        parent.add(alias_);

        alias_.isPublic = t.isPublic;

        /// "alias"
        t.skip("alias");

        /// identifier
        alias_.name = t.value();
        t.next();

        /// =
        t.skip(TT.EQUALS);

        /// type
        alias_.type = typeParser().parse(t, alias_);
        //dd("alias_", alias_.name, "type=", alias_.type, "root=", alias_.getRootType);

        alias_.isImport   = false;
        alias_.moduleName = module_.canonicalName;

        alias_.setEndPos(t);
    }
    ///
    /// return_statement ::= "return" [ expression ]
    ///
    void parseReturn(Tokens t, ASTNode parent) {

        auto r = makeNode!Return(t);
        parent.add(r);

        int line = t.get().line;

        /// return
        t.next();

        /// [ expression ]
        /// This is a bit of a hack.
        /// If there is something on the same line and it's not a '}'
        /// then assume there is a return expression
        if(t.kind() != TT.RCURLY && t.get().line == line) {
            exprParser().parse(t, r);
        }

        r.setEndPos(t);
    }
    void parseAssert(Tokens t, ASTNode parent) {
        t.skip("assert");

        auto a = makeNode!Assert(t);
        parent.add(a);

        exprParser().parse(t, a);

        a.setEndPos(t);
    }
    void parseBreak(Tokens t, ASTNode parent) {

        auto b = makeNode!Break(t);
        parent.add(b);

        t.skip("break");

        b.setEndPos(t);
    }
    void parseContinue(Tokens t, ASTNode parent) {
        auto c = makeNode!Continue(t);
        parent.add(c);

        t.skip("continue");

        c.setEndPos(t);
    }
    void parseLoop(Tokens t, ASTNode parent) {

        auto loop = makeNode!Loop(t);
        parent.add(loop);

        t.skip("loop");

        t.skip(TT.LBRACKET);

        /// Init statements (must be Variables or Binary)
        auto inits = Composite.make(t, Composite.Usage.INLINE_KEEP);
        loop.add(inits);

        if(t.kind() == TT.RBRACKET) errorBadSyntax(module_, t, "Expecting loop initialiser");

        while(t.kind() != TT.SEMICOLON) {

            parse(t, inits);

            t.expect(TT.COMMA, TT.SEMICOLON);
            if(t.kind() == TT.COMMA) t.next();
        }

        t.skip(TT.SEMICOLON);

        if(t.kind() == TT.RBRACKET) errorBadSyntax(module_, t, "Expecting loop condition");

        /// Condition
        auto cond = Composite.make(t, Composite.Usage.INNER_KEEP);
        loop.add(cond);
        if(t.kind() != TT.SEMICOLON) {
            exprParser().parse(t, cond);
        } else {

        }

        t.skip(TT.SEMICOLON);

        /// Post loop expressions
        auto post = Composite.make(t, Composite.Usage.INNER_KEEP);
        loop.add(post);
        while(t.kind() != TT.RBRACKET) {

            exprParser().parse(t, post);

            t.expect(TT.COMMA, TT.RBRACKET);
            if(t.kind() == TT.COMMA) t.next();
        }
        t.skip(TT.RBRACKET);

        t.skip(TT.LCURLY);

        /// Body statements
        auto body_ = Composite.make(t, Composite.Usage.INNER_KEEP);
        loop.add(body_);

        while(t.kind() != TT.RCURLY) {
            parse(t, body_);
        }
        t.skip(TT.RCURLY);

        loop.setEndPos(t);
    }
    void parseEnum(Tokens t, ASTNode parent) {

        auto e = makeNode!Enum(t);
        parent.add(e);

        e.isPublic = t.isPublic;

        /// enum
        t.skip("enum");

        /// name
        e.name       = t.value();
        e.moduleName = module_.canonicalName;
        t.next;

        /// : type (optional)
        if(t.kind() == TT.COLON) {
            t.next();

            e.elementType = typeParser.parse(t, e);
        }

        /// {
        t.skip(TT.LCURLY);

        while(t.kind() != TT.RCURLY) {

            auto value = makeNode!EnumMember(t);
            e.add(value);

            /// name
            value.name = t.value();
            value.type = e;
            t.next();

            if(t.kind() == TT.EQUALS) {
                t.next();

                exprParser().parse(t, value);
            }

            value.setEndPos(t);

            t.expect(TT.COMMA, TT.RCURLY);
            if(t.kind() == TT.COMMA) t.next();
        }

        /// }
        t.skip(TT.RCURLY);

        e.setEndPos(t);
    }
}

