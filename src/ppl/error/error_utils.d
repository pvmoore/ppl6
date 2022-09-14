module ppl.error.error_utils;

import ppl.internal;

void compilerError(ASTNode n, string msg = null) {
    throw new InternalCompilerError(n, msg);
}
void compilerError(Tokens t, string msg = null) {
    throw new InternalCompilerError(t, msg);
}
void warn(Tokens n, string msg) {
    writefln("WARN [%s Line %s] %s", n.module_.fullPath, n.line()+1, msg);
}
void warn(ASTNode n, string msg) {
    string path = n.isAttached() ? n.getModule().fullPath : "unattached";
    writefln("WARN [%s Line %s] %s", path, n.line()+1, msg);
}
void errorBadSyntax(Module m, ASTNode n, string msg) {
    m.addError(n, msg, false);
}
void errorBadSyntax(Module m, Tokens t, string msg) {
    m.addError(t, msg, false);
}
void errorBadImplicitCast(Module m, ASTNode n, Type from, Type to) {
    //throw new Error("");
    m.addError(n, "Cannot implicitly cast %s to %s".format(from, to), true);
}
void errorBadExplicitCast(Module m, ASTNode n, Type from, Type to) {
    m.addError(n, "Cannot cast %s to %s".format(from, to), true);
}

void errorMissingType(Module m, ASTNode n, string name) {
    m.addError(n, "Type %s not found".format(name), true);
}
void errorMissingType(Module m, Tokens t, string name=null) {
    if(name) {
        m.addError(t, "Type %s not found".format(name), true);
    } else {
        m.addError(t, "Type not found", true);
    }
}