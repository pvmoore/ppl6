module ppl.type.Struct;

import ppl.internal;

/**
 *  Struct
 *      { Statement }
 */
class Struct : Statement, Type, Container {
protected:
    LLVMTypeRef _llvmType;
    int _size      = -1;
    int _alignment = -1;
    bool _isPacked = false;
public:
    string name;
    string moduleName;
    bool isPublic;

    /// Set to true if no body is specified.
    /// A full definition is expected later in the file.
    /// eg.
    /// struct Gold // this is declaration only
    /// // ...
    /// struct Gold() { ... }
    bool isDeclarationOnly;

/// Template stuff
    TemplateBlueprint blueprint;
    bool isTemplateBlueprint() {
        return blueprint !is null;
    }
    bool isTemplateInstance()  {
        import common : contains;
        return name.contains('<');
    }
/// end of template stuff

    int getSize() {
        if(_size==-1) {
            auto pack = attributes.get!PackedAttribute;
            if(pack) {
                _isPacked = true;
            }
            if(_isPacked) {
                _size = memberVariableTypes().map!(it=>it.size).sum;
            } else {
                _size = calculateAggregateSize(memberVariableTypes());
            }
        }
        return _size;
    }
    /// Alignment is alignment of largest member
    int getAlignment() {
        if(_alignment==-1) {
            if(numMemberVariables()==0) {
                /// An empty struct has align of 1
                _alignment = 1;
            } else {
                import std.algorithm.searching;
                _alignment = memberVariableTypes().map!(it=>it.alignment()).maxElement();
            }
        }
        return _alignment;
    }
    bool isPacked() {
        if(_size==-1) getSize();
        return _isPacked;
    }
    bool isPOD() {
        return attributes.get!PodAttribute !is null;
    }

    bool isVisibleToOtherModules() {
        if(!isPublic) return false;
        auto lp = getLogicalParent();
        if(lp.isModule()) return true;
        if(lp.isA!Struct) return lp.as!Struct.isVisibleToOtherModules();
        return false;
    }

/// ASTNode interface
    override bool isResolved() { return true; }
    override NodeID id() const { return NodeID.STRUCT; }
    override Type getType()    { return this; }

/// Type interface
    override int category() const { return Type.STRUCT; }
    override bool isKnown() { return true; }

    override bool exactlyMatches(Type other) {
        /// Do the common checks
        if(!prelimExactlyMatches(this, other)) return false;
        /// Now check the base type
        if(!other.isStruct()) return false;

        auto right = other.getStruct();

        return name==right.name;
    }
    override bool canImplicitlyCastTo(Type other) {
        /// Do the common checks
        if(!prelimCanImplicitlyCastTo(this,other)) return false;

        /// Now check the base type
        if(!other.isStruct()) return false;

        auto right = other.getStruct();

        return name==right.name;
    }
    override LLVMTypeRef getLLVMType() {
        if(!_llvmType) {
            _llvmType = struct_(name);
        }
        return _llvmType;
    }
    override string toSrcString() {
        return "%s".format(name);
    }
    ///========================================================================================
    Enum getEnum(string name) {
        return children[]
                .filter!(it=>it.id==NodeID.ENUM && it.as!Enum.name==name)
                .frontOrNull!Enum;
    }
    Enum[] getEnums() {
        return children[]
            .filter!(it=>it.id==NodeID.ENUM)
            .map!(it=>it.as!Enum)
            .array;
    }
    ///========================================================================================
    Class getClass(string name) {
        return children[]
                .filter!(it=>it.id==NodeID.CLASS && it.as!Class.name==name)
                .frontOrNull!Class;
    }
    Struct getStruct(string name) {
        return children[]
                .filter!(it=>it.id==NodeID.STRUCT && it.as!Struct.name==name)
                .frontOrNull!Struct;
    }
    Class[] getClasses() {
        return children[]
            .filter!(it=>it.id==NodeID.CLASS)
            .map!(it=>it.as!Class)
            .array;
    }
    Struct[] getStructs() {
        return children[]
            .filter!(it=>it.id==NodeID.STRUCT)
            .map!(it=>it.as!Struct)
            .array;
    }
    ///========================================================================================
    Variable[] getStaticVariables() {
        return children[]
                   .filter!(it=>it.id==NodeID.VARIABLE)
                   .map!(it=>it.as!Variable)
                   .filter!(it=>it.isStatic)
                   .array;
    }
    Variable getStaticVariable(string name) {
        return getStaticVariables()
            .filter!(it=>it.name==name)
            .frontOrNull!Variable;
    }
    ///========================================================================================
    Function[] getStaticFunctions() {
        return children[]
                   .filter!(it=>it.id==NodeID.FUNCTION)
                   .map!(it=>it.as!Function)
                   .filter!(it=>it.isStatic)
                   .array;
    }
    Function[] getStaticFunctions(string name) {
        return getStaticFunctions()
                    .filter!(it=>name==it.name)
                    .array;
    }
    ///========================================================================================
    Function[] getMemberFunctions() {
        return children[]
                   .filter!(it=>it.id==NodeID.FUNCTION)
                   .map!(it=>it.as!Function)
                   .filter!(it=>it.isStatic==false)
                   .array;
    }
    Function[] getMemberFunctions(string name) {
        return getMemberFunctions()
                    .filter!(it=>name==it.name)
                    .array;
    }
    ///========================================================================================
    int numMemberVariables() {
        return getMemberVariables().length.as!int;
    }
    Variable[] getMemberVariables() {
        return children[].filter!(it=>it.id==NodeID.VARIABLE)
                .map!(it=>it.as!Variable)
                .filter!(it=>it.isStatic==false)
                .array;
    }
    Variable getMemberVariable(string name) {
        return getMemberVariables()
                .filter!(it=>name==it.name)
                .frontOrNull!Variable;
    }
    Variable getMemberVariable(int index) {
        return getMemberVariables()[index];
    }
    Type[] memberVariableTypes() {
        return getMemberVariables()
                .map!(it=>it.as!Variable.type)
                .array;
    }
    LLVMTypeRef[] getLLVMTypes() {
        return memberVariableTypes()
                .map!(it=>it.getLLVMType())
                .array;
    }
    ///========================================================================================

    bool hasDefaultConstructor() {
        return getDefaultConstructor() !is null;
    }
    Function getDefaultConstructor() {
        foreach(f; getConstructors()) {
            if(f.isDefaultConstructor()) return f;
        }
        return null;
    }
    Function[] getConstructors() {
        return getMemberFunctions("new");
    }
    //=========================================================================================

    ///
    /// Return true if there are Placeholders at root level which signifies
    /// that a template function has just been added
    ///
    bool containsPlaceholders() {
        foreach(ch; children[]) {
            if(ch.isA!Placeholder) return true;
        }
        return false;
    }
    int getMemberIndex(Function var) {
        foreach( i, v; getMemberFunctions()) {
            if(var is v) return i.as!int;
        }
        return -1;
    }
    int getMemberIndex(Variable var) {
        if(!var) return -1;
        assert(!var.isStatic);
        foreach(i, v; getMemberVariables()) {
            if(var is v) return i.as!int;
        }
        return -1;
    }
    ///========================================================================================
    bool hasOperatorOverload(Operator op) {
        string fname = "operator";
        if(op==Operator.NEG) {
            fname ~= " neg";
        } else {
            fname ~= op.value;
        }
        return getMemberFunctions(fname).length > 0;
    }
    //========================================================================================
    override string toString() const {
        return "Struct '%s'".format(name);
    }
}