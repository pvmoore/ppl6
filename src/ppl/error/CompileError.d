module ppl.error.CompileError;

import ppl.internal;

abstract class CompileError {
public:
    int id;
    int line;
    int column;
    Module module_;
    Suggestions suggestions;

    this(Module module_, int line, int column) {
        this.id      = g_errorIDs++;
        this.module_ = module_;
        this.line    = line;
        this.column  = column;
    }
    abstract string getKey();
    abstract string toConciseString();
    abstract string toPrettyString();

    final auto addSuggestions(Suggestions s) {
        this.suggestions = s;
        return this;
    }
protected:
    string conciseErrorMsg(string msg) {
        if(line==-1 || column==-1) {
            return "[%s] %s".format(module_.fullPath, msg);
        }
        return "[%s Line %s:%s] %s".format(module_.fullPath, line+1, column, msg);
    }
    string prettyErrorMsg(string msg) {

        auto buf = new StringBuffer;

        void _addSuggestions() {
            if(suggestions) {
                buf.add("\n\n");
                buf.add(suggestions.toPrettyString());
            }
        }

        if(line==-1 || column==-1) {
            buf.add(conciseErrorMsg(msg));
            _addSuggestions();
            return buf.toString();
        }

        auto lines = From!"std.stdio".File(module_.fullPath, "rb").byLineCopy().array;

        if(lines.length<=line) {
            buf.add(conciseErrorMsg(msg));
            _addSuggestions();
            return buf.toString();
        }

        buf.add(conciseErrorMsg(msg));

        string spaces;
        for(int i=0; i<column; i++) { spaces ~= " "; }

        auto errorLineStr = convertTabsToSpaces(lines[line]);

        buf.add("\n%s|\n", spaces);
        buf.add("%sv\n", spaces);
        buf.add("%s", errorLineStr);

        _addSuggestions();

        return buf.toString();
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class TokeniseError : CompileError {
private:
    string msg;
public:
    this(Module m, int line, int column, string msg) {
        super(m, line, column);
        this.msg     = msg;
    }
    override string getKey() {
        return "%s|%s|%s|%s".format(module_.canonicalName, line, column, msg);
    }
    override string toConciseString() {
        return conciseErrorMsg(msg);
    }
    override string toPrettyString() {
        return prettyErrorMsg(msg);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class ParseError : CompileError {
private:
    Tokens tokens;
    ASTNode node;
    string msg;
public:
    this(Module m, Tokens t, string msg) {
        super(m, t.line, t.column);
        this.tokens = t;
        this.msg    = msg;
    }
    this(Module m, ASTNode n, string msg) {
        super(m, n.line, n.column);
        this.node = n;
        this.msg  = msg;
    }
    override string getKey() {
        return "%s|%s|%s".format(module_.canonicalName, line, column);
    }
    override string toConciseString() {
        return conciseErrorMsg(msg);
    }
    override string toPrettyString() {
        return prettyErrorMsg(msg);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class UnknownError : CompileError {
private:
    string msg;
public:
    this(Module m, string msg) {
        super(m, -1, -1);
        this.msg = msg;
    }
    override string getKey() {
        return "%s".format(msg);
    }
    override string toConciseString() {
        return conciseErrorMsg(msg);
    }
    override string toPrettyString() {
        return msg;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class AmbiguousCall : CompileError {
private:
    Call call;
    string name;
    Type[] argTypes;
    Callable[] overloadSet;
    Function[] templateFunctions;
    Type[][] templateParams;
public:
    this(Module m, Call call, Callable[] overloadSet) {
        super(m, call.line, call.column);
        this.call        = call;
        this.overloadSet = overloadSet.dup;
    }
    this(Module m, Call call, Function[] templateFunctions, Type[][] templateParams) {
        super(m, call.line, call.column);
        this.call              = call;
        this.templateFunctions = templateFunctions;
        this.templateParams    = templateParams;
    }
    override string getKey() {
        return "%s|%s|%s".format(module_.canonicalName, call.line, call.column);
    }
    override string toConciseString() {
        return conciseErrorMsg("Ambiguous call");
    }
    override string toPrettyString() {
        auto buf = new StringBuffer;

        buf.add(prettyErrorMsg("Ambiguous call"));

        auto numMatches = overloadSet.length + templateFunctions.length;

        buf.add("\n\n\t%s matches found:\n\n", numMatches);

        string getFuncSignature(Type[] params, Type retType) {
            string a = params.length==0 ? "void" : params.toString();
            return "{%s -> %s}".format(a, retType);
        }

        foreach(i, f; templateFunctions) {
            string moduleName = f.getModule.canonicalName;
            auto paramTokens  = f.blueprint.getParamTokens();

            string s1 = "%s Line %4s".format(moduleName, f.line+1);
            string s2 = "%35s\t%s <%s>".format(s1, call.name,
                templateParams[i].toString());

            buf.add("\t%s\n", s2);
        }

        foreach(callable; overloadSet) {
            auto funcType     = callable.getType().getFunctionType();
            auto params       = funcType.paramTypes();
            auto retType      = funcType.returnType();
            string moduleName = callable.getModule.canonicalName;
            auto node         = callable.getNode();

            string s1 = "%s Line %4s".format(moduleName, node.line+1);
            string s2 = "%35s\t%s %s".format(s1, call.name, getFuncSignature(params, retType));

            buf.add("\t%s\n", s2);
        }
        return buf.toString();
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class LinkError : CompileError {
private:
    int status;
    string msg;
public:
    this(Module m, int status, string msg) {
        super(m, 0, 0);
        this.status  = status;
        this.msg     = msg;
    }
    override string getKey() {
        return "%s|%s".format(status, msg);
    }
    override string toConciseString() {
        return conciseErrorMsg("Link error: "~msg);
    }
    override string toPrettyString() {
        return "Link error: Status code: %s, msg: %s".format(status, msg);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class InternalCompilerError : Exception {
public:
    string info;

    this(ASTNode n, string userMsg) {
        super("");
        formatInfo(n, userMsg);
    }
    this(Tokens t, string userMsg) {
        super("");
        formatInfo(t, userMsg);
    }
    void formatInfo(ASTNode node, string userMsg) {
        formatInfo(node.getModule(), node.line()+1, userMsg);
    }
    void formatInfo(Tokens t, string userMsg) {
        formatInfo(t.module_, t.line()+1, userMsg);
    }
    void formatInfo(Module m, int line, string userMsg) {
        info ~= "\nMessage : "~userMsg;
        if(m) {
            info ~= "\nModule  : %s".format(m.canonicalName);
        }
        info ~= "\nLine    : %s".format(line);
    }
}
