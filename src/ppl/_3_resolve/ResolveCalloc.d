module ppl._3_resolve.ResolveCalloc;

import ppl.internal;

final class ResolveCalloc {
private:
    Module module_;
    ResolveModule resolver;
    ResolveAlias aliasResolver;
    FoldModule folder;
public:
    this(ResolveModule resolver) {
        this.resolver      = resolver;
        this.module_       = resolver.module_;
        this.aliasResolver = resolver.aliasResolver;
        this.folder        = module_.folder;
    }
    void resolve(Calloc n) {
        aliasResolver.resolve(n, n.valueType);

        if(n.valueType.isKnown()) {
            /// Rewrite Calloc to:

            /// As
            ///     Dot
            ///         GC
            ///         call calloc
            ///             size
            ///     TypeExpr

            auto b = module_.nodeBuilder;

            auto dot = b.callStatic("GC", "calloc", n);
            dot.second().add(b.makeInt(n.valueType.size()));

            auto as = b.as(dot, n.getType());

            folder.fold(n, as);
        }
    }
}