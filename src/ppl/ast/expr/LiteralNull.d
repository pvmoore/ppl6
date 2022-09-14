module ppl.ast.expr.LiteralNull;

import ppl.internal;

/**
 *  LiteralNull
 */
final class LiteralNull : Expression, CompileTimeConstant {
    Type type;

    this() {
        type = TYPE_UNKNOWN;
    }

    static LiteralNull makeConst(Type t = TYPE_UNKNOWN) {
        auto lit = makeNode!LiteralNull;
        lit.type = t;
        return lit;
    }

/// ASTNode
    override bool isResolved()    { return type.isKnown(); }
    override NodeID id() const    { return NodeID.LITERAL_NULL; }
    override Type getType()       { return type; }

/// Expression
    override int priority() const { return 15; }
    override CT comptime()        { return CT.YES; }

/// CompileTimeConstant
    LiteralNull copy() {
        auto c = makeNode!LiteralNull;
        c.type = type;
        return c;
    }
    bool isTrue() {
        return false;
    }

/// Object
    override string toString() {
        return "LiteralNull [type=%s]".format(type);
    }
}