module ppl._3_resolve.misc.Callable;

import ppl.internal;

struct Callable {
    uint id;
    Function func;
    Variable var;

    this(Variable v) {
        this.id   = g_callableID++;
        this.var  = v;
    }
    this(Function f) {
        this.id   = g_callableID++;
        this.func = f;
    }
    bool resultReady()         { return getNode() !is null; }
    bool isVariable()          { return var !is null; }
    bool isFunction()          { return func !is null; }
    bool isStatic()            { return var ? var.isStatic : func.isStatic; }
    bool isStructMember()      { return func ? func.isMember() : var.isMember(); }
    bool isTemplateBlueprint() { return func ? func.isTemplateBlueprint() : false; }
    bool isPrivate()           { return func ? !func.isPublic : !var.isPublic; }

    string getName()           { return func ? func.name : var.name; }
    Type getType()             { return func ? func.getType : var.type; }
    ASTNode getNode()          { return func ? func : var; }
    int numParams()            { return getType.getFunctionType().numParams(); }
    string[] paramNames()      { return getType.getFunctionType().paramNames(); }
    Type[] paramTypes()        { return getType.getFunctionType().paramTypes(); }
    Module getModule()         { return func ? func.getModule() : var.getModule(); }
    Struct getStruct()         { return func ? func.getStruct() : var.getStruct(); }

    /**
     *  If the Call has named params then return the arg types of the Call in
     *  the same order as the param types of this Callable.
     *  If the names do not match then return null.
     *  Otherwise just return the call arg types which are already in order
     */
    Type[] getCallArgTypesInOrder(Call call) {
        import common : indexOf;
        if(call.numArgs()==0) {
            return null;
        } else if(call.paramNames.length > 0) {
            string[] names = paramNames();
            Type[] callArgTypes = call.argTypes();
            Type[] inOrder = new Type[callArgTypes.length];
            foreach(i, name; call.paramNames) {
                int index = names.indexOf(name);
                if(index==-1) return null;

                inOrder[index] = callArgTypes[i];
            }
            return inOrder;
        }
        return call.argTypes();
    }

    size_t toHash() const @safe pure nothrow {
        assert(id!=0);
        return id;
    }
    /// Every node is unique
    bool opEquals(ref const Callable o) const @safe  pure nothrow {
        assert(id!=0 && o.id!=0);
        return o.id==id;
    }
    string toString() {
        if(!resultReady()) return "Not ready";
        string t = isTemplateBlueprint() ? " TEMPLATE":"";
        if(!getType.getFunctionType()) {
            return "%s:%s%s %s(type=%s)".format(id, func?"FUNC":"VAR", t, getName(), getType());
        }
        return "%s:%s%s %s(%s)".format(id, func?"FUNC":"VAR", t, getName(), paramTypes());
    }
}

string toString(DynamicArray!Callable array) {
    string s = "[";
    foreach(i, c; array.values) {
        if(i>0) s ~= ", ";
        s ~= c.toString();
    }
    return s ~= "]";
}
