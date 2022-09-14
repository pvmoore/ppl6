module ppl.ast.node_utils;

import ppl.internal;

T makeNode(T)() {
    T n = new T;
    n.nid = g_nodeid++;
    assert(n.children);
    return n;
}
T makeNode(T)(Tokens t) {
    T n          = new T;
    n.nid        = g_nodeid++;
    n.line       = t.line;
    n.column     = t.column;
    n.attributes = t.getAttributesAndClear();
    assert(n.children);
    return n;
}

bool isAs(inout ASTNode n)              { return n.id()==NodeID.AS; }
bool isBinary(inout ASTNode n)          { return n.id()==NodeID.BINARY; }
bool isCall(inout ASTNode n)            { return n.id()==NodeID.CALL; }
bool isCase(inout ASTNode n)            { return n.id()==NodeID.CASE; }
bool isComposite(inout ASTNode n)       { return n.id()==NodeID.COMPOSITE; }
bool isAlias(inout ASTNode n)           { return n.id()==NodeID.ALIAS; }
bool isDot(inout ASTNode n)             { return n.id()==NodeID.DOT; }
bool isExpression(inout ASTNode n)      { return n.as!Expression !is null; }
bool isFunction(inout ASTNode n)        { return n.id()==NodeID.FUNCTION; }
bool isIdentifier(inout ASTNode n)      { return n.id()==NodeID.IDENTIFIER; }
bool isIf(inout ASTNode n)              { return n.id()==NodeID.IF; }
bool isIndex(inout ASTNode n)           { return n.id()==NodeID.INDEX; }
bool isInitialiser(inout ASTNode n)     { return n.id()==NodeID.INITIALISER; }
bool isLambda(inout ASTNode n)          { return n.id()==NodeID.LAMBDA; }
bool isLiteralNull(inout ASTNode n)     { return n.id()==NodeID.LITERAL_NULL; }
bool isLiteralNumber(inout ASTNode n)   { return n.id()==NodeID.LITERAL_NUMBER; }
bool isLiteralFunction(inout ASTNode n) { return n.id()==NodeID.LITERAL_FUNCTION; }
bool isLoop(inout ASTNode n)            { return n.id()==NodeID.LOOP; }
bool isModule(inout ASTNode n)          { return n.id()==NodeID.MODULE; }
bool isParameters(inout ASTNode n)      { return n.id()==NodeID.PARAMETERS; }
bool isReturn(inout ASTNode n)          { return n.id()==NodeID.RETURN; }
bool isSelect(inout ASTNode n)          { return n.id()==NodeID.SELECT; }
bool isTypeExpr(inout ASTNode n)        { return n.id()==NodeID.TYPE_EXPR; }
bool isVariable(inout ASTNode n)        { return n.id()==NodeID.VARIABLE; }

bool areAll(NodeID ID)(ASTNode[] n)  { return n.all!(it=>it.id==ID); }
bool areResolved(ASTNode[] nodes)    { return nodes.all!(it=>it.isResolved()); }
bool areResolved(Expression[] nodes) { return nodes.all!(it=>it.isResolved()); }
bool areResolved(Variable[] nodes)   { return nodes.all!(it=>it.isResolved()); }

Call getCall(ASTNode n) {
    if(n.isA!Call) return n.as!Call;
    if(n.isA!ExpressionRef) return getCall(n.as!ExpressionRef.reference);
    return null;
}
Identifier getIdentifier(ASTNode n) {
    if(n.isA!Identifier) return n.as!Identifier;
    if(n.isA!ExpressionRef) return getIdentifier(n.as!ExpressionRef.reference);
    return null;
}

bool isPublic(ASTNode n) {
    switch(n.id) with(NodeID) {
        case STRUCT:
        case CLASS:
            return n.as!Struct.isPublic;
        case ALIAS:
            return n.as!Alias.isPublic;
        case ENUM:
            return n.as!Enum.isPublic;
        case FUNCTION:
            return n.as!Function.isPublic;
        case VARIABLE:
            return n.as!Variable.isPublic;
        case TUPLE:
            return false;
        default:
            assert(false, "implement me %s".format(n.id));
    }
}