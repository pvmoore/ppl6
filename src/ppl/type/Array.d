module ppl.type.Array;

import ppl.internal;
///
/// array_type::= "[" type ":" count_expr "]"
///
/// Array
///     Expression count_expr
///
final class Array : Statement, Type {
private:
    LLVMTypeRef _llvmType;
public:
    Type subtype;

    override bool isResolved() { return isKnown(); }
    override NodeID id() const { return NodeID.ARRAY; }
    override Type getType() { return this; }

/// Type
    override int category() const { return Type.ARRAY; }

    override bool isKnown() {
        return subtype &&
               subtype.isKnown() &&
               numChildren()>0 &&
               countExpr().isResolved() &&
               countExpr().isA!LiteralNumber;
    }
    override bool exactlyMatches(Type other) {
        /// Do the common checks
        if(!prelimExactlyMatches(this, other)) return false;
        /// Now check the base type
        if(!other.isArray()) return false;

        auto rightArray = other.getArrayType();

        if(!rightArray.subtype.exactlyMatches(subtype)) return false;

        return countAsInt() == rightArray.countAsInt();
    }
    override bool canImplicitlyCastTo(Type other) {
        /// Do the common checks
        if(!prelimCanImplicitlyCastTo(this,other)) return false;

        /// Now check the base type
        if(!other.isArray()) return false;

        auto rightArray = other.getArrayType();

        if(!rightArray.subtype.exactlyMatches(subtype)) return false;

        return countAsInt() == rightArray.countAsInt();
    }
    override LLVMTypeRef getLLVMType() {
        if(!_llvmType) {
            _llvmType = arrayType(subtype.getLLVMType(), countAsInt());
        }
        return _llvmType;
    }
    override string toSrcString() {
        return "%s[%s]".format(subtype.toSrcString(), countAsInt());
    }
    //============================================================
    void setCount(LiteralNumber lit) {
        assert(numChildren()==1);

        last().detach();
        add(lit);
    }
    Expression countExpr() {
        assert(numChildren()>0, "Expecting a countExpr");
        assert(last().isExpression());
        assert(subtype !is this);

        return last().as!Expression;
    }
    int countAsInt() {
        if(!isResolved()) return -1;
        assert(countExpr().isA!LiteralNumber,
            "Expecting count to be a literal number (it is a %s)".format(typeid(countExpr())));
        return countExpr().as!LiteralNumber.value.getInt();
    }
    override string toString() {
        return "Array [subtype=%s] [length=%s]".format(
            subtype.isKnown() ? subtype.toSrcString() : "?",
            countAsInt);
    }
}