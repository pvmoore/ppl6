module ppl.error.Suggestions;

import ppl.internal;

abstract class Suggestions {
    abstract string toPrettyString();
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class CallParamNameMismatchSuggestions : Suggestions {
private:
    Call call;
    Callable[] possibleMatches;
public:
    this(Call call, Callable[] possibleMatches) {
        this.call = call;
        this.possibleMatches = possibleMatches;
    }
    override string toPrettyString() {
        return "";
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
final class FunctionSuggestions : Suggestions {
    Function[] funcs;
    this(Function[] funcs) {
        this.funcs = funcs;
    }
    override string toPrettyString() {

        string getFuncSignature(Type[] params, Type retType) {
            string a = params.length==0 ? "void" : params.toString;
            return "{%s -> %s}".format(a, retType);
        }

        auto buf = new StringBuffer;
        buf.add("Suggestions:\n\n");


        foreach(f; funcs) {

            string moduleName = f.moduleName;
            auto funcType     = f.getType().getFunctionType();
            auto paramTypes   = funcType ? funcType.paramTypes() : [];
            //auto retType      = funcType.returnType();

            auto params = f.params();
            auto names = params.paramNames();

            // Format parameter string
            string paramStr;
            if(names.length == paramTypes.length) {
                foreach(i; 0..names.length) {
                    if(i>0) paramStr ~= ", ";
                    paramStr ~= "%s %s".format(paramTypes[i], names[i]);
                }
            } else {
                paramStr = paramTypes.toString();
            }

            string s = "[%s L:%s] %s(%s)".format(moduleName, f.line()+1, f.name, paramStr);

            buf.add("\t%s\n", s);
        }
        return buf.toString();
    }
}