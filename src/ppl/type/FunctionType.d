module ppl.type.FunctionType;

import ppl.internal;

/**
 *  FunctionType
 *      { Variable } parameters
 *      Variable     return type
 */
final class FunctionType : ASTNode, Type {
private:
    LLVMTypeRef _llvmType;
public:
    /// This gets calculated later by the FunctionLiteral if there is one.
    Type _returnType;

    /// Point to Parameters of FunctionLiteral.
    Parameters params;

    /// True if this is a func ptr rather than an actual function.
    /// Both are represented using the same type so this flag is
    /// required for @isFunctionPtr
    bool isFunctionPtr;

    override bool isResolved() { return isKnown(); }
    override NodeID id() const { return NodeID.FUNC_TYPE; }
    override Type getType() { return this; }

    void returnType(Type t) {
        _returnType = t;
    }
    Type returnType() {
        if(params) return firstNotNull(_returnType, TYPE_UNKNOWN);

        return children[$-1].as!Variable.type;
    }

    int numParams() {
        if(params) return params.numParams();
        return numChildren()-1;
    }
    Type[] paramTypes() {
        /// If there is a FunctionLiteral
        if(params) return params.paramTypes();

        /// Variable or extern function
        assert(children[].all!(it=>it.isVariable()), "children=%s".format(children[]));

        assert(numChildren() > 0, "FunctionType has no children");

        /// Last child will be the return type
        return children[0..$-1].map!(it=>it.getType()).array;
    }
    string[] paramNames() {
        /// If there is a FunctionLiteral
        if(params) return params.paramNames();

        /// Variable or extern function
        assert(children[].all!(it=>it.isVariable()));

        assert(numChildren() > 0, "FunctionType has no children");

        /// Last child will be the return type
        return children[0..$-1].map!(it=>it.as!Variable.name).array;
    }

/// Type interface
    override int category() const {
        return Type.FUNCTION;
    }
    override bool isKnown() {
        return returnType().isKnown() && paramTypes.areKnown();
    }
    override bool exactlyMatches(Type other) {
        /// Do the common checks
        if(!prelimExactlyMatches(this, other)) return false;
        /// Now check the base type

        if(!other.isFunction()) return false;

        auto right = other.getFunctionType();

        /// check returnType
        if(!returnType.exactlyMatches(right.returnType())) return false;

        auto pt  = paramTypes();
        auto pt2 = right.paramTypes();

        return .exactlyMatch(pt, pt2);
    }
    override bool canImplicitlyCastTo(Type other) {
        /// Do the common checks
        if(!prelimCanImplicitlyCastTo(this,other)) return false;

        /// Now check the base type
        if(!other.isFunction()) return false;
        auto right = other.getFunctionType();

        /// check returnType
        if(!returnType.exactlyMatches(right.returnType())) return false;

        auto pt  = paramTypes();
        auto pt2 = right.paramTypes();

        return .exactlyMatch(pt, pt2);
    }
    override LLVMTypeRef getLLVMType() {
        if(!_llvmType) {
            _llvmType = function_(returnType.getLLVMType(),
                                  paramTypes().map!(it=>it.getLLVMType()).array);
        }
        return _llvmType;
    }
    override string toSrcString() {
        string paramsPart;
        string retPart;

        if(paramTypes.areKnown()) {
            paramsPart = "%s".format(paramTypes().length == 0 ? "" : paramTypes().toString());
        } else {
            paramsPart = "?";
        }

        if(returnType().isKnown()) {
            if(!returnType().isVoid()) {
                retPart = " return %s".format(returnType());
            }
        } else {
            retPart = " return ?";
        }
        return "fn(%s%s)".format(paramsPart, retPart);
    }
    //============================================================
    override string toString() {
        return "FunctionType [type=%s]".format(toSrcString());
    }
}