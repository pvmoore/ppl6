module ppl._3_resolve.ResolveModule;

import ppl.internal;

private const bool VERBOSE = false;

final class ResolveModule {
private:
    ResolveAssert assertResolver;
    ResolveAs asResolver;
    ResolveBinary binaryResolver;
    ResolveBuiltinFunc builtinFuncResolver;
    ResolveCalloc callocResolver;
    CallResolver callResolver;
    ResolveConstructor constructorResolver;
    ResolveEnum enumResolver;
    ResolveIf ifResolver;
    ResolveIs isResolver;
    ResolveSelect selectResolver;
    ResolveLiteral literalResolver;
    ResolveIndex indexResolver;
    ResolveUnary unaryResolver;
    ResolveVariable variableResolver;

    BuildState state;
    StopWatch watch;
    DynamicArray!Callable overloadSet;
    bool modified;
    Set!ASTNode unresolved;
    bool stalemate            = false;
    bool externalModification = true;
    int iteration             = 0;
public:
    Module module_;
    ResolveAlias aliasResolver;
    ResolveIdentifier identifierResolver;
    bool isResolved = false;

    ulong getElapsedNanos()        { return watch.peek().total!"nsecs"; }
    ASTNode[] getUnresolvedNodes() { return unresolved.values; }
    bool isModified()              { return modified; }
    bool isStalemate()             { return stalemate; }
    int getCurrentIteration()      { return iteration; }
    void addUnresolved(ASTNode n)  { unresolved.add(n); }

    this(Module module_) {
        this.module_             = module_;
        this.state               = module_.buildState;

        this.asResolver          = new ResolveAs(this);
        this.aliasResolver       = new ResolveAlias(this);
        this.assertResolver      = new ResolveAssert(this);
        this.binaryResolver      = new ResolveBinary(this);
        this.builtinFuncResolver = new ResolveBuiltinFunc(this);
        this.callocResolver      = new ResolveCalloc(this);
        this.callResolver        = new CallResolver(this);
        this.constructorResolver = new ResolveConstructor(this);
        this.identifierResolver  = new ResolveIdentifier(this);
        this.enumResolver        = new ResolveEnum(this);
        this.indexResolver       = new ResolveIndex(this);
        this.ifResolver          = new ResolveIf(this);
        this.isResolver          = new ResolveIs(this);
        this.selectResolver      = new ResolveSelect(this);
        this.literalResolver     = new ResolveLiteral(this);
        this.unaryResolver       = new ResolveUnary(this);
        this.variableResolver    = new ResolveVariable(this);
        this.unresolved          = new Set!ASTNode;
        this.overloadSet         = new DynamicArray!Callable;
    }
    void clearState() {
        watch.reset();
        unresolved.clear();
        overloadSet.clear();
        iteration      = 0;
        isResolved     = false;
        externalModification = true;
    }
    void setModified(ASTNode node) {
        this.modified = true;
        node.setModified(iteration);
    }
    void setTokensModified() {
        isResolved           = false;
        externalModification = true;
    }
    void setASTModified() {
        isResolved           = false;
        externalModification = true;
    }

    ///
    /// Pass through any unresolved nodes and try to resolve them.
    /// Return true if all nodes and aliases are resolved and no modifications occurred.
    ///
    bool resolve(bool isStalemate) {
        watch.start();
        scope(exit) watch.stop();

        this.isResolved           = isResolved && !externalModification;
        this.externalModification = false;

        // Note: This is an optimisation. If there are problems where resolution is not being done
        //       then we can remove this early return.
        if(this.isResolved) {
            return true;
        }

        this.modified  = false;
        this.stalemate = isStalemate;
        this.iteration++;
        this.unresolved.clear();

        foreach(r; module_.children[].dup) {
            recursiveVisit(r);
        }

        this.isResolved = unresolved.length==0 && modified==false && externalModification==false;

        return isResolved;
    }
    //==============================================================================================
    void visit(AddressOf n) {

    }
    void visit(Alias n) {
        if(!n.isTypeof()) {
            aliasResolver.resolve(n, n.type);
        }
    }
    void visit(Array n) {
        aliasResolver.resolve(n, n.subtype);
    }
    void visit(As n) {
        asResolver.resolve(n);
    }
    void visit(Assert n) {
        assertResolver.resolve(n);
    }
    void visit(Binary n) {
        binaryResolver.resolve(n);
    }
    void visit(Break n) {
        if(!n.isResolved()) {
            n.loop = n.getAncestor!Loop;
            if(n.loop is null) {
                module_.addError(n, "Break statement must be inside a loop", true);
            }
        }
    }
    void visit(BuiltinFunc n) {
        builtinFuncResolver.resolve(n);
    }
    void visit(Call n) {
        callResolver.resolve(n);
    }
    void visit(Calloc n) {
        callocResolver.resolve(n);
    }
    void visit(Case n) {

    }
    void visit(Class n) {

    }
    void visit(Composite n) {

    }
    void visit(Continue n) {
        if(!n.isResolved()) {
            n.loop = n.getAncestor!Loop;
            if(n.loop is null) {
                module_.addError(n, "Continue statement must be inside a loop", true);
            }
        }
    }
    void visit(Constructor n) {
        constructorResolver.resolve(n);
    }
    void visit(Dot n) {

    }
    void visit(Enum n) {
        enumResolver.resolve(n);
    }
    void visit(EnumMember n) {

    }
    void visit(EnumMemberValue n) {
        enumResolver.resolve(n);
    }
    void visit(ExpressionRef n) {
        if(n.reference.isA!EnumMember) {
            auto em  = n.reference.as!EnumMember;
            auto ctc = em.expr.as!CompileTimeConstant;
            if(ctc) {
                // TODO - can't do this until possible call is resolved
                //folder.fold(n, ctc.copy());
            }
        }
    }
    void visit(Function n) {

    }
    void visit(FunctionType n) {

    }
    void visit(Identifier n) {
        identifierResolver.resolve(n);
    }
    void visit(If n) {
        ifResolver.resolve(n);
    }
    void visit(Import n) {

    }
    void visit(Index n) {
        indexResolver.resolve(n);
    }
    void visit(Initialiser n) {
        n.resolve();
    }
    void visit(Is n) {
        isResolver.resolve(n);
    }
    void visit(Lambda n) {

    }
    void visit(LiteralArray n) {
        literalResolver.resolve(n);
    }
    void visit(LiteralFunction n) {
        literalResolver.resolve(n);
    }
    void visit(LiteralMap n) {
        literalResolver.resolve(n);
    }
    void visit(LiteralNull n) {
        literalResolver.resolve(n);
    }
    void visit(LiteralNumber n) {
        literalResolver.resolve(n);
    }
    void visit(LiteralString n) {
        literalResolver.resolve(n);
    }
    void visit(LiteralTuple n) {
        literalResolver.resolve(n);
    }
    void visit(Loop n) {

    }
    void visit(Module n) {

    }
    void visit(ModuleAlias n) {

    }
    void visit(Parameters n) {

    }
    void visit(Parenthesis n) {
        assert(n.numChildren==1);
    }
    void visit(Placeholder n) {

    }
    void visit(Return n) {

    }
    void visit(Select n) {
        selectResolver.resolve(n);
    }
    void visit(Struct n) {

    }
    void visit(Tuple n) {

    }
    void visit(TypeExpr n) {
        aliasResolver.resolve(n, n.type);
    }
    void visit(Unary n) {
        unaryResolver.resolve(n);
    }
    void visit(ValueOf n) {

    }
    void visit(Variable n) {
        variableResolver.resolve(n);
    }
    //==========================================================================
    // void writeAST() {
    //     if(module_.config.writeJSON) writeJson();
    //     if(module_.config.writeAST==false) return;

    //     //dd("DUMP MODULE", module_);

    //     auto f = new FileLogger(module_.config.targetPath~"ast/" ~ module_.fileName~".ast");
    //     scope(exit) f.close();

    //     module_.dump(f);

    //     f.log("==============================================");
    //     f.log("======================== Unresolved Nodes (%s)", unresolved.length);

    //     foreach (i, n; unresolved.values) {
    //         f.log("\t[%s] Line %s %s", i, n.line, n.id);
    //     }
    //     f.log("==============================================");
    // }
    // void writeJson() {
    //     import std.stdio : File;

    //     auto s = JsonWriter.toString(module_);

    //     auto f = File(module_.config.targetPath~"json/" ~ module_.fileName ~ ".json", "w");

    //     f.write(s);
    // }
    bool isAStaticTypeExpr(Expression expr) {
        auto exprType       = expr.getType();
        bool isStaticAccess = exprType.isValue();
        if(isStaticAccess) {
            switch(expr.id()) with(NodeID) {
                case CONSTRUCTOR:
                case IDENTIFIER:
                case COMPOSITE:
                    isStaticAccess = false;
                    break;
                case DOT:
                    auto d = expr.as!Dot;
                    if(d.left.id==MODULE_ALIAS) {
                        isStaticAccess = d.right().isTypeExpr();
                    } else {
                        isStaticAccess = false;
                        //assert(false, "implement me %s.%s %s %s".format(d.left.id, d.right.id, expr.line+1, module_.canonicalName));
                    }
                    break;
                case INDEX:
                    isStaticAccess = false;
                    break;
                case TYPE_EXPR:
                    break;
                case VALUE_OF:
                    isStaticAccess = false;
                    break;
                default:
                    assert(false, "implement me %s %s %s".format(expr.id(), expr.line()+1, module_.canonicalName));
            }
        }
        return isStaticAccess;
    }
//==========================================================================
private:
    void recursiveVisit(ASTNode m) {

        if(!m.isAttached()) return;

        if(m.id()==NodeID.STRUCT) {
            if(m.as!Struct.isTemplateBlueprint()) return;
        } else if(m.isFunction()) {
            auto f = m.as!Function;
            if(f.isTemplateBlueprint()) return;
            if(f.isImport) return;
        } else if(m.isAlias()) {
            auto a = m.as!Alias;
            if(a.isStandard() && !a.type.isAlias()) return;
        }

        static if(VERBOSE) {
            dd("  resolve children of", typeid(m), "nid:", m.nid, module_.canonicalName, "line:", m.line()+1);
        }

        /// Resolve children
        foreach(n; m.children[].dup) {
            recursiveVisit(n);
        }

        static if(VERBOSE) {
            dd("    resolve", typeid(m), "nid:", m.nid, module_.canonicalName, "line:", m.line()+1);
        }

        /// Resolve this node
        m.visit!ResolveModule(this);

        if(!m.isAttached()) return;

        if(!m.isResolved()) unresolved.add(m);
    }
}