module ppl.ast.Parameters;

import ppl.internal;

/**
 *  Function parameters
 */
final class Parameters : ASTNode {

/// ASTNode
    override bool isResolved() { return getParams().as!(ASTNode[]).areResolved; }
    override NodeID id() const { return NodeID.PARAMETERS; }
    override Type getType()    { return TYPE_VOID; }

    int numParams() const {
        return children.length.as!int;
    }
    string[] paramNames() {
        return getParams().map!(it=>it.name).array;
    }
    Type[] paramTypes() {
        return getParams().map!(it=>it.type).array;
    }
    Variable getParam(ulong index) {
        return getParams()[index];
    }
    Variable getParam(string name) {
        auto r = getParams().filter!(it=>it.name==name).takeOne();
        return r.empty ? null : r.front();
    }
    int getIndex(Variable param) {
        foreach(i, p; getParams()) {
            if(p.nid==param.nid) return i.as!int;
        }
        return -1;
    }
    Variable[] getParams() {
        return children[].as!(Variable[]);
    }
    LiteralFunction getLiteralFunction() {
        assert(parent.isLiteralFunction());
        return parent.as!LiteralFunction;
    }

    ///
    /// This function is not global so requires the this* of the enclosing struct.
    ///
    void addThisParameter(Struct ns) {
        /// Poke the this* ptr into the start of the parameter list

        auto a = makeNode!Variable;
        a.name = "this";
        if(ns.isClass()) {
            //a.type = ns;
        }
        a.type = Pointer.of(ns, 1);

        addToFront(a);
    }

    override string toString() {
        return "Parameters";
    }
}