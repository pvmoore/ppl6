module ppl.ast.expr.Binary;

import ppl.internal;

/**
 *  Binary
 *      Expression
 *      Expression
 */
final class Binary : Expression {
public:
    Type type;
    Operator op;
    bool isPtrArithmetic;   /// ptr +/- integer

    this() {
        type = TYPE_UNKNOWN;
    }

/// ASTNode
    override bool isResolved()    { return type.isKnown() && left().isResolved() && right().isResolved(); }
    override NodeID id() const    { return NodeID.BINARY; }
    override Type getType()       { return type; }

/// Expression
    override int priority() const { return op.priority; }
    override CT comptime()        { return mergeCT(mergeCT(left(), right())); }


    Expression left()  { return children[0].as!Expression; }
    Expression right() { return children[1].as!Expression; }
    Type leftType()    { assert(left()); return left().getType(); }
    Type rightType()   { assert(right()); return right().getType(); }

    Expression otherSide(Expression e) {
        if(left().nid==e.nid) return right();
        if(right().nid==e.nid) return left();
        return null;
    }

    override string toString() {
        string opStr = "%s".format(op).toLower();
        return "Binary [kind=%s] [type=%s] [%s]".format(opStr, getType(), comptimeStr());
    }
}
