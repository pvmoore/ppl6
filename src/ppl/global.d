module ppl.global;
///
/// Handle all global shared initialisation and storage.
///
import ppl.internal;

public:

__gshared {
    enum INVALID_POSITION   = Position(-1,-1);
    enum TRUE               = -1;
    enum FALSE              = 0;
    enum TRUE_STR           = "-1";
    enum FALSE_STR          = "0";

    LLVMWrapper g_llvmWrapper;

// Unique static counters
    int g_nodeid      = 1;
    int g_callableID  = 1;
    int g_errorIDs    = 1;

// FileLogger g_logger;

    int[string] g_builtinTypes;
    string[int] g_typeToString;

    Operator[TT] g_ttToOperator;

    Token NO_TOKEN = Token.make(TT.NONE, null, 0, INVALID_POSITION, INVALID_POSITION);

    Type TYPE_UNKNOWN = new BasicType(Type.UNKNOWN);
    Type TYPE_BOOL    = new BasicType(Type.BOOL);
    Type TYPE_BYTE    = new BasicType(Type.BYTE);
    Type TYPE_INT     = new BasicType(Type.INT);
    Type TYPE_LONG    = new BasicType(Type.LONG);
    Type TYPE_FLOAT   = new BasicType(Type.FLOAT);
    Type TYPE_DOUBLE  = new BasicType(Type.DOUBLE);
    Type TYPE_VOID    = new BasicType(Type.VOID);

    /// Callable(0, null, null)
    Callable CALLABLE_NOT_READY;
}

shared static ~this() {
    if(g_llvmWrapper) g_llvmWrapper.destroy();
}

shared static this() {
    g_llvmWrapper = new LLVMWrapper;
    //g_logger = new FileLogger(".logs/log.log");

    g_builtinTypes["bool"]   = Type.BOOL;
    g_builtinTypes["byte"]   = Type.BYTE;
    g_builtinTypes["short"]  = Type.SHORT;
    g_builtinTypes["int"]    = Type.INT;
    g_builtinTypes["long"]   = Type.LONG;
    g_builtinTypes["half"]   = Type.HALF;
    g_builtinTypes["float"]  = Type.FLOAT;
    g_builtinTypes["double"] = Type.DOUBLE;
    g_builtinTypes["void"]   = Type.VOID;

    g_typeToString[Type.UNKNOWN]  = "?";
    g_typeToString[Type.BOOL]     = "bool";
    g_typeToString[Type.BYTE]     = "byte";
    g_typeToString[Type.SHORT]    = "short";
    g_typeToString[Type.INT]      = "int";
    g_typeToString[Type.LONG]     = "long";
    g_typeToString[Type.HALF]     = "half";
    g_typeToString[Type.FLOAT]    = "float";
    g_typeToString[Type.DOUBLE]   = "double";
    g_typeToString[Type.VOID]     = "void";
    g_typeToString[Type.TUPLE]    = "tuple";
    g_typeToString[Type.STRUCT]   = "named_struct";
    g_typeToString[Type.CLASS]    = "class";
    g_typeToString[Type.ARRAY]    = "array";
    g_typeToString[Type.FUNCTION] = "function";

    // unary
    //ttOperator[NEG] =
    //g_ttToOperator[TT.BIT_NOT] = Operator.BIT_NOT;
    //g_ttToOperator[TT.BOOL_NOT] = Operator.BOOL_NOT;

    g_ttToOperator[TT.DIV] = Operator.DIV;
    g_ttToOperator[TT.ASTERISK] = Operator.MUL;
    g_ttToOperator[TT.PERCENT] = Operator.MOD;

    g_ttToOperator[TT.PLUS] = Operator.ADD;
    g_ttToOperator[TT.MINUS] = Operator.SUB;

    g_ttToOperator[TT.SHL] = Operator.SHL;
    g_ttToOperator[TT.SHR] = Operator.SHR;
    g_ttToOperator[TT.USHR] = Operator.USHR;

    g_ttToOperator[TT.LANGLE] = Operator.LT;
    g_ttToOperator[TT.RANGLE] = Operator.GT;
    g_ttToOperator[TT.LTE] = Operator.LTE;
    g_ttToOperator[TT.GTE] = Operator.GTE;

    g_ttToOperator[TT.BOOL_EQ] = Operator.BOOL_EQ;
    g_ttToOperator[TT.BOOL_NE] = Operator.BOOL_NE;

    g_ttToOperator[TT.AMPERSAND] = Operator.BIT_AND;
    g_ttToOperator[TT.HAT] = Operator.BIT_XOR;
    g_ttToOperator[TT.PIPE] = Operator.BIT_OR;

    //g_ttToOperator[TT.BOOL_AND] = Operator.BOOL_AND;
    //g_ttToOperator[TT.BOOL_OR] = Operator.BOOL_OR;

    g_ttToOperator[TT.ADD_ASSIGN] = Operator.ADD_ASSIGN;
    g_ttToOperator[TT.SUB_ASSIGN] = Operator.SUB_ASSIGN;
    g_ttToOperator[TT.MUL_ASSIGN] = Operator.MUL_ASSIGN;
    g_ttToOperator[TT.DIV_ASSIGN] = Operator.DIV_ASSIGN;
    g_ttToOperator[TT.MOD_ASSIGN] = Operator.MOD_ASSIGN;
    g_ttToOperator[TT.BIT_AND_ASSIGN] = Operator.BIT_AND_ASSIGN;
    g_ttToOperator[TT.BIT_XOR_ASSIGN] = Operator.BIT_XOR_ASSIGN;
    g_ttToOperator[TT.BIT_OR_ASSIGN] = Operator.BIT_OR_ASSIGN;
    g_ttToOperator[TT.SHL_ASSIGN] = Operator.SHL_ASSIGN;
    g_ttToOperator[TT.SHR_ASSIGN] = Operator.SHR_ASSIGN;
    g_ttToOperator[TT.USHR_ASSIGN] = Operator.USHR_ASSIGN;
    g_ttToOperator[TT.EQUALS] = Operator.ASSIGN;
    g_ttToOperator[TT.COLON_EQUALS] = Operator.REASSIGN;
}