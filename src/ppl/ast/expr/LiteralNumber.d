module ppl.ast.expr.LiteralNumber;

import ppl.internal;

/**
 *  LiteralNumber
 */
final class LiteralNumber : Expression, CompileTimeConstant {
private:
    Type _type;
public:
    string str;
    EvalValue value;

    this() {
        _type = TYPE_UNKNOWN;
    }
    void set(string strValue, Type type) {
        this.str = strValue;
        this._type = type;
        this.value = EvalValue(this);
    }

    Type type() {
        return _type;
    }
    // Called from EvalValue
    void type(Type type) {
        _type = type;
    }

    void setType(Type t) {
        value.changeType(_type, t);
        _type = t;
    }

    static LiteralNumber makeConst(string strValue, Type t) {
        auto lit  = makeNode!LiteralNumber;
        lit.str   = strValue;
        lit._type = t;
        if(t.isUnknown) {
            lit.determineType();
        } else {
            lit.value = EvalValue(lit);
        }
        return lit;
    }
/// CompileTimeConstant
    LiteralNumber copy() {
        auto c   = makeNode!LiteralNumber;
        //c.line   = line;
        //c.column = column;
        c.str    = str;
        c._type  = _type;
        c.value  = EvalValue(c);
        return c;
    }
    bool isTrue() {
        return value.getBool() == true;
    }

/// ASTNode
    override bool isResolved()    { return _type.isKnown(); }
    override NodeID id() const    { return NodeID.LITERAL_NUMBER; }
    override Type getType()       { return _type; }

/// Expression
    override int priority() const { return 15; }
    override CT comptime()        { return CT.YES; }


    void determineType() {
        From!"std.typecons".Tuple!(Type,string) r = parseNumberLiteral(str);
        _type  = r[0];
        str    = r[1];
        value  = EvalValue(this);
    }
    override string toString() {
        string v = value.getString();
        //string v = value.lit && value.type && value.type.isKnown ? value.getString() : str;
        return "LiteralNumber: %s [type=%s]".format(v, _type);
    }
}
