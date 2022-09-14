module ppl.type.Enum;

import ppl.internal;

/**
 *  Enum
 *      { EnumMember }
 */
final class Enum : Statement, Type {
private:
    LLVMTypeRef _llvmType;
public:
    string name;
    string moduleName;
    Type elementType;
    bool isPublic;

    this() {
        this.elementType = TYPE_INT;
    }

/// ASTNode interface
    override bool isResolved() {
        return elementType.isKnown() && allMembersAreResolved();
    }
    override NodeID id() const { return NodeID.ENUM; }
    override Type getType()    { return this; }

/// Type interface
    override int category() const { return Type.ENUM; }
    override bool isKnown()       { return true; }

    override bool exactlyMatches(Type other) {
        /// Do the common checks
        if(!prelimExactlyMatches(this, other)) return false;
        if(!other.isEnum()) return false;

        auto right = other.getEnum();

        return name==right.name;
    }
    override bool canImplicitlyCastTo(Type other) {
        /// Do the common checks
        if(!prelimCanImplicitlyCastTo(this, other)) return false;

        if(!other.isEnum()) return false;

        auto right = other.getEnum();

        return name==right.name;
    }
    override LLVMTypeRef getLLVMType() {
        if(!_llvmType) {
            _llvmType = struct_(name);
        }
        return _llvmType;
    }
    override string toSrcString() {
        return name;
    }
/// end of Type interface

    bool isVisibleToOtherModules() {
        if(!isPublic) return false;
        auto lp = getLogicalParent();
        if(lp.isModule()) return true;
        if(lp.isA!Struct) return lp.as!Struct.isVisibleToOtherModules();
        return false;
    }

    EnumMember[] members() {
        return children[].as!(EnumMember[]);
    }
    EnumMember member(string name) {
        return members().filter!(it=>it.name==name).frontOrNull!EnumMember;
    }


    bool allMembersAreResolved() {
        return members().all!(it=>it.isResolved());
    }
    Expression firstValue() {
        assert(hasChildren());
        return first().as!EnumMember;
    }

    override string toString() {
        return "Enum '%s'".format(name);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
/**
 *  EnumMember 'name'
 *      Expression
 */
final class EnumMember : Expression {
    string name;
    Enum type;

/// ASTNode
    override bool isResolved()    { return hasChildren() && expr().isResolved(); }
    override NodeID id() const    { return NodeID.ENUM_MEMBER; }
    override Type getType()       { return type; }

/// Expression
    override int priority() const { return 15; }
    override CT comptime()        { return expr().comptime(); }


    Expression expr() { return first().as!Expression; }

    override string toString() const {
        return "EnumMember '%s' [type=%s]".format(name, type);
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
/**
 *  EnumMemberValue
 *      Expression
 */
final class EnumMemberValue : Expression {
    Enum enum_;

/// ASTNode
    override bool isResolved()    { return hasChildren() && expr().isResolved(); }
    override NodeID id() const    { return NodeID.ENUM_MEMBER_VALUE; }
    override Type getType()       { return enum_.elementType; }

/// Expression
    override int priority() const { return 15; }
    override CT comptime()        { return expr().comptime(); }


    Expression expr() { return first().as!Expression; }

    override string toString() {
        return "EnumMemberValue %s [%s]".format(getType(), comptimeStr());
    }
}