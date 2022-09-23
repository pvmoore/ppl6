module ppl.internal;

public:

import core.atomic              : atomicLoad, atomicStore;
import core.memory              : GC;
import core.sync.mutex          : Mutex;

import std.stdio                : writefln, writeln;
import std.format               : format;
import std.string               : toLower, indexOf, lastIndexOf, leftJustify, rightJustify;
import std.conv                 : to;
import std.array                : Appender, appender, array, join;
import std.range                : takeOne;
import std.datetime.stopwatch   : StopWatch;

import std.algorithm.iteration  : each, map, filter, sum;
import std.algorithm.searching  : any, all, count, startsWith;
import std.algorithm.sorting    : sort;

import common : DynamicArray = Array;
import common : IQueue, makeSPSCQueue;
import common : Ansi, Borrowed, From, Hash, Hasher, Queue, Set, Stack, StringBuffer;
import common : as, dynamicDispatch, isA, flushConsole, endsWith, putIfAbsent,
                removeChars, repeat, toInt, visit;
import common : contains, insertAt, removeAt, remove, isOneOf, firstNotNull, throwIf;

import llvm.all;
import ppl;

import ppl.Attribute;
import ppl.Container;
import ppl.Mangler;
import ppl.ppl6;
import ppl.global;
import ppl.Operator;
import ppl.Position;
import ppl.Target;
import ppl.VariableOrFunction;

import ppl.ast.Parameters;
import ppl.ast.Placeholder;
import ppl.ast.node_utils;

import ppl.ast.expr.AddressOf;
import ppl.ast.expr.As;
import ppl.ast.expr.Binary;
import ppl.ast.expr.BuiltinFunc;
import ppl.ast.expr.Call;
import ppl.ast.expr.Calloc;
import ppl.ast.expr.Composite;
import ppl.ast.expr.Constructor;
import ppl.ast.expr.Dot;
import ppl.ast.expr.Expression;
import ppl.ast.expr.ExpressionRef;
import ppl.ast.expr.Identifier;
import ppl.ast.expr.If;
import ppl.ast.expr.Index;
import ppl.ast.expr.Initialiser;
import ppl.ast.expr.Is;
import ppl.ast.expr.Lambda;
import ppl.ast.expr.LiteralNumber;
import ppl.ast.expr.LiteralArray;
import ppl.ast.expr.LiteralFunction;
import ppl.ast.expr.LiteralMap;
import ppl.ast.expr.LiteralNull;
import ppl.ast.expr.LiteralString;
import ppl.ast.expr.LiteralTuple;
import ppl.ast.expr.ModuleAlias;
import ppl.ast.expr.Parenthesis;
import ppl.ast.expr.Select;
import ppl.ast.expr.TypeExpr;
import ppl.ast.expr.Unary;
import ppl.ast.expr.ValueOf;

import ppl.ast.stmt.Assert;
import ppl.ast.stmt.Break;
import ppl.ast.stmt.Continue;
import ppl.ast.stmt.Import;
import ppl.ast.stmt.Function;
import ppl.ast.stmt.Loop;
import ppl.ast.stmt.Return;
import ppl.ast.stmt.Statement;
import ppl.ast.stmt.Variable;

import ppl.build.AfterResolution;
import ppl.build.BuildState;
import ppl.build.IncrementalBuilder;
import ppl.build.ParseResolveFoldPass;

import ppl.error.CompilationAborted;
import ppl.error.CompileError;
import ppl.error.error_utils;
import ppl.error.Suggestions;

import ppl.templates.blueprint;
import ppl.templates.ImplicitTemplates;
import ppl.templates.ParamTokens;
import ppl.templates.ParamTypeMatcherRegex;
import ppl.templates.templates;

import ppl.type.Alias;
import ppl.type.Array;
import ppl.type.Class;
import ppl.type.Enum;
import ppl.type.Type;
import ppl.type.Pointer;
import ppl.type.BasicType;
import ppl.type.FunctionType;
import ppl.type.Struct;
import ppl.type.Tuple;
import ppl.type.type_utils;

import ppl.misc.Linker;
import ppl.misc.misc_logging;
import ppl.misc.node_builder;
import ppl.misc.optimiser;
import ppl.misc.util;
import ppl.misc.writer;

import ppl._1_lex.Lexer;
import ppl._1_lex.Token;
import ppl._1_lex.Tokens;

import ppl._2_parse.DetectType;
import ppl._2_parse.ParseAttribute;
import ppl._2_parse.ParseExpression;
import ppl._2_parse.ParseFunction;
import ppl._2_parse.ParseHelper;
import ppl._2_parse.ParseLiteral;
import ppl._2_parse.ParseModule;
import ppl._2_parse.ParseStruct;
import ppl._2_parse.ParseStatement;
import ppl._2_parse.ParseType;
import ppl._2_parse.ParseVariable;

import ppl._3_resolve.ResolveCalloc;
import ppl._3_resolve.ResolveAs;
import ppl._3_resolve.ResolveAlias;
import ppl._3_resolve.ResolveAssert;
import ppl._3_resolve.ResolveBinary;
import ppl._3_resolve.ResolveBuiltinFunc;
import ppl._3_resolve.ResolveCall;
import ppl._3_resolve.ResolveConstructor;
import ppl._3_resolve.ResolveEnum;
import ppl._3_resolve.ResolveIdentifier;
import ppl._3_resolve.ResolveIndex;
import ppl._3_resolve.ResolveIf;
import ppl._3_resolve.ResolveIs;
import ppl._3_resolve.ResolveLiteral;
import ppl._3_resolve.ResolveModule;
import ppl._3_resolve.ResolveSelect;
import ppl._3_resolve.ResolveUnary;
import ppl._3_resolve.ResolveVariable;

import ppl._3_resolve.misc.Callable;
import ppl._3_resolve.misc.CallableSet;
import ppl._3_resolve.misc.CollectOverloads;
import ppl._3_resolve.misc.FindCallTarget;
import ppl._3_resolve.misc.FindImport;
import ppl._3_resolve.misc.FindType;
import ppl._3_resolve.misc.FindIdentifierTarget;

import ppl._4_fold.CompileTimeConstant;
import ppl._4_fold.DeadCodeEliminator;
import ppl._4_fold.EvalBinaryUnary;
import ppl._4_fold.EvalModule;
import ppl._4_fold.FoldUnreferenced;
import ppl._4_fold.EvalValue;
import ppl._4_fold.FoldModule;

import ppl._5_check.CheckModule;
import ppl._5_check.ControlFlow;
import ppl._5_check.EscapeAnalysis;

import ppl._6_gen.GenerateBinary;
import ppl._6_gen.GenerateEnum;
import ppl._6_gen.GenerateFunction;
import ppl._6_gen.GenerateLiteral;
import ppl._6_gen.GenerateLoop;
import ppl._6_gen.GenerateIf;
import ppl._6_gen.GenerateModule;
import ppl._6_gen.GenerateSelect;
import ppl._6_gen.GenerateStruct;
import ppl._6_gen.GenerateVariable;

/// Debug logging
void dd(A...)(A args) {
    import std.stdio : writef, writefln;
    import common : flushConsole;

    foreach(a; args) {
        writef("%s ", a);
    }
    writefln("");
    flushConsole();
}

string convertTabsToSpaces(string s, int tabsize=4) {
    import std.string : indexOf;
    import std.array  : appender;
    import common : repeat;

    if(s.indexOf("\t")==-1) return s;
    auto buf = appender!(string);
    auto spaces = " ".repeat(tabsize);
    foreach(ch; s) {
        if(ch=='\t') buf ~= spaces;
        else buf ~= ch;
    }
    return buf.data;
}

private import std.path;
private import std.file;
private import std.array : array, replace;

string normaliseDir(string path, bool makeAbsolute=false) {
    if(makeAbsolute) {
        path = asAbsolutePath(path).array;
    }
    path = asNormalizedPath(path).array;
    path = path.replace("\\", "/") ~ "/";
    return path;
}
string normaliseFile(string path,) {
    path = asNormalizedPath(path).array;
    path = path.replace("\\", "/");
    return path;
}