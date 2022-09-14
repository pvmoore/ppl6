module ppl.templates.blueprint;

import ppl.internal;

final class TemplateBlueprint {
private:
    Module module_;
    Tokens nav;
    ParamTokens paramTokens;
    bool isPub;
public:
    Token[] tokens;
    string[] paramNames;

    bool isFunction;
    Set!string extracted;

    this(Module module_) {
        this.module_   = module_;
        this.nav       = new Tokens(null, null);
        this.extracted = new Set!string;
    }

    int numTemplateParams() {
        return paramNames.length.as!int;
    }
    int numFuncParams() {
        return paramTokens.numParams;
    }
    ParamTokens getParamTokens() {
        return paramTokens;
    }
    int indexOf(string paramName) {
        foreach(i, n; paramNames) {
            if(n==paramName) return i.as!int;
        }
        return -1;
    }
    void setStructTokens(Struct ns, string[] paramNames, Token[] tokens, bool isPub) {
        assert(tokens.length>0);

        assert(tokens[0].kind == TT.LBRACKET || tokens[0].kind == TT.LCURLY);
        assert(tokens[$-1].kind == TT.RBRACKET || tokens[$-1].kind == TT.RCURLY);

        this.paramNames = paramNames;
        this.tokens     = tokens;
        this.isPub      = isPub;
    }
    ///
    /// paramNames = eg. <U,V>
    /// tokens     ::= "(" [ params ] ["return" type]")" "{" {statment} "}"
    ///
    void setFunctionTokens(Struct ns, string[] paramNames, Token[] tokens, bool isPub) {
        assert(paramNames.length>0);
        assert(tokens.length>0);
        assert(tokens[0].kind == TT.LBRACKET);
        assert(tokens[$-1].kind == TT.RCURLY);

        this.isFunction  = true;
        this.paramNames  = paramNames;
        this.tokens      = tokens;
        this.paramTokens = new ParamTokens(ns, paramNames, tokens);
        this.isPub       = isPub;
    }
    Token[] extractStruct(string mangledName, Type[] types) {
        /// [ "pub" ] "struct" mangledName
        Token[] tempTokens;

        if(isPub) tempTokens ~= this.tokens[0].copy("pub");

        tempTokens ~= [
            this.tokens[0].copy("struct"),
            this.tokens[0].copy(mangledName)
        ] ~ this.tokens.dup;

        foreach(ref t; tempTokens) {
            if(t.kind == TT.IDENTIFIER) {
                int i = indexOf(t.value);
                if(i!=-1) {
                    t.templateType = types[i];
                }
            }
        }
        return tempTokens;
    }
    Token[] extractFunction(string mangledName, Type[] types, bool isStatic) {
        /// [pub] [static] "fn" mangledName ( params [return type]) { ... }

        assert(this.tokens[0].kind == TT.LBRACKET);

        Token[] tempTokens;

        if(isPub) tempTokens ~= this.tokens[0].copy("pub");
        if(isStatic) tempTokens ~= this.tokens[0].copy("static");

        tempTokens ~= this.tokens[0].copy("fn");

        tempTokens ~= [
            this.tokens[0].copy(mangledName)
        ] ~ this.tokens.dup;

        foreach(ref t; tempTokens) {
            if(t.kind == TT.IDENTIFIER) {
                int i = indexOf(t.value);
                if(i!=-1) {
                    t.templateType = types[i];
                }
            }
        }

        return tempTokens;
    }
    Type[] getFuncParamTypes(Module module_, Call call, Type[] templateTypes) {
        assert(templateTypes.length==paramNames.length);

        Type[] paramTypes;
        foreach(at; paramTokens.getTokensForAllParams()) {
            auto tokens = at.dup;

            nav.reuse(module_, tokens);

            applyTypes(tokens, templateTypes);

            paramTypes ~= module_.typeParser.parse(nav, call, false);
        }
        return paramTypes;
    }
    override string toString() {
        if(isFunction) {
            return "(%s)".format(paramTokens.getTokensForAllParams().map!(it=>"%s".format(it)).join(", "));
        }
        return super.toString();
    }
private:
    void applyTypes(Token[] tokens, Type[] types) {
        foreach(ref tok; tokens) {
            if(tok.kind == TT.IDENTIFIER) {
                long index = indexOf(tok.value);
                if(index!=-1) {
                    tok.templateType = types[index];
                }
            }
        }
    }
}