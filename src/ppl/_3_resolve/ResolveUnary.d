module ppl._3_resolve.ResolveUnary;

import ppl.internal;

final class ResolveUnary {
private:
    Module module_;
    ResolveModule resolver;
    FoldModule folder;
public:
    this(ResolveModule resolver) {
        this.resolver = resolver;
        this.module_  = resolver.module_;
        this.folder   = module_.folder;
    }
    void resolve(Unary n) {
        /// If expression is a const literal number then apply the
        /// operator and replace Unary with the result
        if(n.isResolved && n.comptime()==CT.YES) {
            auto lit = n.expr().as!LiteralNumber;
            if(lit) {
                bool ok = lit.value.applyUnary(n.op);
                if(ok) {
                    lit.str = lit.value.getString();

                    folder.fold(n, lit);
                    return;
                } else {
                    module_.addError(n, "(%s %s) is not supported".format(n.op.value, n.expr.getType), true);
                }
            }
        }
    }
}
