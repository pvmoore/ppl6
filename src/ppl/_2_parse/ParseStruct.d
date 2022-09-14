module ppl._2_parse.ParseStruct;

import ppl.internal;

final class ParseStruct {
private:
    Module module_;

    auto stmtParser()   { return module_.stmtParser; }
    auto varParser()    { return module_.varParser; }
    auto typeDetector() { return module_.typeDetector; }
    auto findType()     { return module_.findType; }
    auto builder()      { return module_.nodeBuilder; }
public:
    this(Module module_) {
        this.module_ = module_;
    }
    ///
    /// "struct|class" name [ "<" tparams ">" ]                     "{" { statements } "}"
    ///
    /// "struct|class" name [ "<" tparams ">" ] "(" variables ")" [ "{" { statements } "}" ]
    ///
    void parse(Tokens t, ASTNode parent) {

        Struct n; // Class extends Struct

        if("class"==t.value()) {
            t.skip("class");
            n = makeNode!Class(t);
        } else {
            t.skip("struct");
            n = makeNode!Struct(t);
        }

        parent.add(n);

        n.moduleName = module_.canonicalName;
        n.isPublic   = t.isPublic;

        /// Is this type already defined?
        auto node = parent; if(node.hasChildren) node = node.last();
        auto type = findType().findType(t.value, node);

        if(type) {
            //dd("redefinition", type);
            if(type.isAlias()) {
                if(type.getAlias.isTemplateProxy()) {
                    /// Allow template proxy as this is what we are replacing
                } else {
                    module_.addError(n, "Type %s already defined".format(t.value()), true);
                }
            } else if(type.isStruct()) {
                auto ns = type.getStruct();

                if(ns.isDeclarationOnly) {
                    /// Re-use previous definition
                    ns.isDeclarationOnly = false;

                    n.detach();

                    n = ns;
                    module_.buildState.logParse("Re-using redefined struct %s", n.name);

                } else {
                    module_.addError(n, "Struct %s already defined".format(t.value), true);
                }
            }
        }

        /// name
        n.name = t.value();
        t.next();

        ///
        /// Stop here if this is just a declaration
        ///
        if(t.kind() != TT.LANGLE && t.kind() != TT.LCURLY && t.kind() != TT.LBRACKET) {
            n.isDeclarationOnly = true;
            return;
        }


        if(t.kind() == TT.LANGLE) {
            /// This is a template

            /// <
            t.skip(TT.LANGLE);

            n.blueprint = new TemplateBlueprint(module_);
            string[] paramNames;

            /// template params < A,B,C >
            while(t.kind() != TT.RANGLE) {

                if(typeDetector().isType(t, n)) {
                    module_.addError(t, "Template param name cannot be a type", true);
                }

                paramNames ~= t.value();
                t.next();

                t.expect(TT.RANGLE, TT.COMMA);
                if(t.kind() == TT.COMMA) t.next();
            }
            /// >
            t.skip(TT.RANGLE);


            /// (
            t.expect(TT.LBRACKET);

            int start  = t.index();
            int end    = t.findEndOfBlock(TT.LBRACKET);

            /// Skip to end of {} scope if there is one

            if(t.peek(end+1).kind == TT.LCURLY) {
                end = t.findEndOfBlock(TT.LCURLY, end);
            }

            n.blueprint.setStructTokens(null, paramNames, t[start..start+end+1].dup, t.isPublic);
            t.next(end+1);

            //dd("Struct template decl", n.name, n.blueprint.paramNames, n.blueprint.tokens.toString);

        } else {
            /// This is a concrete struct

            /// (
            t.expect(TT.LBRACKET);

            parseProperties(t, n);

            /// optional { body
            if(t.kind() == TT.LCURLY) {
                parseBody(t, n);
            }

            /// Do some house-keeping
            addDefaultConstructorIfMissing(t, n);
            checkPOD(t, n);
            addImplicitReturnThisToConstructors(n);
            addCallToDefaultConstructor(n);
            moveInitCodeInsideDefaultConstructor(n);
        }

        n.setEndPos(t);
    }
private:
    /// "(" variables ")"
    void parseProperties(Tokens t, Struct ns) {
        /// (
        t.skip(TT.LBRACKET);

        /// Variables
        while(t.kind() != TT.RBRACKET) {

            /// Default to private
            t.setAccessPublic(false);

            varParser().parseStructMember(t, ns);

            t.expect(TT.COMMA, TT.RBRACKET);
            if(t.kind() == TT.COMMA) t.next();
        }

        /// )
        t.skip(TT.RBRACKET);
    }
    /// "{" statements "}"
    void parseBody(Tokens t, Struct ns) {
        /// {
        t.skip(TT.LCURLY);

        /// Statements
        while(t.kind() != TT.RCURLY) {

            stmtParser().parse(t, ns);

            if(t.kind() == TT.COMMA) t.next();
        }
        /// }
        t.skip(TT.RCURLY);
    }
    /**
     *  If there is no default constructor 'new()' then create one
     */
    void addDefaultConstructorIfMissing(Tokens t, Struct ns) {
        auto defCons = ns.getDefaultConstructor();
        if(!defCons) {

            //  Function 'new' public
            //      LiteralFunction
            //          Parameters
            //              Variable 'this'

            defCons            = makeNode!Function;
            defCons.name       = "new";
            defCons.moduleName = module_.canonicalName;
            defCons.isPublic   = true;
            ns.add(defCons);

            auto params = makeNode!Parameters;
            params.addThisParameter(ns);

            auto type   = makeNode!FunctionType;
            type.params = params;

            auto bdy  = makeNode!LiteralFunction;
            bdy.add(params);
            bdy.type = type;
            defCons.add(bdy);
        }
    }
    /**
     *  If this is a POD then:
     *      - Add an error if there are any constructors
     *      - Set all properties, functions, structs and enums as public
     */
    void checkPOD(Tokens t, Struct s) {
        if(!s.isPOD()) return;

        if(s.isClass()) {
            // Classes are not allowed to be POD
            return;
        }

        foreach(i, c; s.getConstructors()) {
            if(c.params().numParams() > 1) {
                module_.addError(c, "POD structs can only have a default constructor", true);
            }
        }

        /// Set all properties, functions, structs, classes and enums to public
        foreach(n; s.getMemberFunctions()) {
            n.isPublic = true;
        }
        foreach(n; s.getStaticFunctions()) {
            n.isPublic = true;
        }
        foreach(n; s.getMemberVariables()) {
            n.isPublic = true;
        }
        foreach(n; s.getStaticVariables()) {
            n.isPublic = true;
        }
        foreach(n; s.getEnums()) {
            n.isPublic = true;
        }
        foreach(n; s.getStructs()) {
            n.isPublic = true;
        }
        foreach(n; s.getClasses()) {
            n.isPublic = true;
        }
    }
    /**
     *  Add implicit return 'this' at the end of all constructors
     */
    void addImplicitReturnThisToConstructors(Struct ns) {
        auto allCons = ns.getConstructors();
        foreach(c; allCons) {
            auto bdy = c.getBody();
            assert(bdy);

            /// Don't allow user to add their own return
            if(bdy.getReturns().length > 0) {
                module_.addError(bdy.getReturns()[0], "Constructor should not include a return statement", true);
                continue;
            }

            auto ret = builder().return_(builder().identifier("this"));
            bdy.add(ret);
        }
    }
    /// Every non-default constructor should start with a call to the default constructor
    void addCallToDefaultConstructor(Struct ns) {
        auto allCons = ns.getConstructors();
        foreach(c; allCons) {
            if(!c.isDefaultConstructor()) {
                auto bdy = c.getBody();
                assert(bdy);
                assert(bdy.first().isA!Parameters);

                // Dot
                //      "this"
                //      Call "new"
                //          "this"

                auto b = builder();

                auto call = b.call("new", null);
                call.add(b.identifier("this"));

                auto dot = b.dot(b.identifier("this"), call);

                /// Add it after Arguments
                bdy.insertAt(1, dot);
            }
        }
    }
    /// Move struct member variable initialisers into the default constructor
    void moveInitCodeInsideDefaultConstructor(Struct ns) {
        auto initFunc = ns.getDefaultConstructor();
        assert(initFunc);

        foreach_reverse(v; ns.getMemberVariables()) {
            if(v.hasInitialiser()) {
                /// Parameters should always be at index 0 so add these at index 1
                initFunc.getBody().insertAt(1, v.initialiser());
            }
        }
    }
}