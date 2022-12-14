module ppl._3_resolve.ResolveAs;

import ppl.internal;

final class ResolveAs {
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
    void resolve(As n) {

        auto lt      = n.leftType();
        auto rt      = n.rightType();
        auto builder = module_.nodeBuilder;

        if(!lt.isKnown() || !rt.isKnown()) return;

        /// If cast is unnecessary then just remove the As
        if(lt.exactlyMatches(rt)) {
            folder.fold(n, n.left());
            return;
        }

        /// Enum as Enum (they must be different enums because they didn't exactly match)
        if(lt.isEnum() && rt.isEnum()) {
            /// eg. A.VAL as B
            errorBadExplicitCast(module_, n, lt, rt);
            return;
        }

        /// enum as non-enum
        /// eg. E1 as 4
        if(lt.isEnum() && !rt.isEnum()) {
            /// Rewrite to left.value as right

            auto value = builder.enumMemberValue(lt.getEnum(), n.left());

            n.addToFront(value);

            resolver.setModified(n);
            return;
        }

        /// non-enum as enum
        /// eg. 4 as E1
        if(!lt.isEnum() && rt.isEnum()) {
            /// Create new EnumMember to represent this value
            auto member = builder.enumMember(rt.getEnum(), n.left());

            folder.fold(n, member);
            return;
        }

        /// If left is a literal number then do the cast now
        auto lit = n.left().as!LiteralNumber;
        if(lit && rt.isValue()) {

            lit.value.as(rt);
            lit.str = lit.value.getString();

            folder.fold(n, lit);
            return;
        }

        bool _isValidRewrite(Type t) {
            return t.isValue() && (t.isTuple() || t.isArray() || t.isStruct());
        }

        if(_isValidRewrite(lt) && _isValidRewrite(rt)) {
            /// Tuple value -> Tuple value

            /// This is a reinterpret cast

            /// Rewrite:
            ///------------
            /// As
            ///    left
            ///    right
            ///------------
            /// ValueOf type=rightType
            ///    As
            ///       AddressOf
            ///          left
            ///       AddressOf
            ///          right

            auto p = n.parent;

            auto value = makeNode!ValueOf;

            auto left  = builder.addressOf(n.left());
            auto right = builder.addressOf(n.right());
            n.add(left);
            n.add(right);

            folder.fold(n, value);

            value.add(n);

            return;
        }
    }
}