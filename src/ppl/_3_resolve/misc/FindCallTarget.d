module ppl._3_resolve.misc.FindCallTarget;

import ppl.internal;
import common : contains;

__gshared bool doChat = false;

final class FindCallTarget {
private:
    Module module_;
    CollectOverloads collector;
    ImplicitTemplates implicitTemplates;
    CallableSet callableSet;
public:
    this(Module module_) {
        this.module_           = module_;
        this.collector         = new CollectOverloads(module_);
        this.implicitTemplates = new ImplicitTemplates(module_);
        this.callableSet       = new CallableSet(module_);
    }
    /// Assume:
    ///     call.argTypes() may not yet be known
    ///
    Callable standardFind(Call call, ModuleAlias modAlias=null) {

        //doChat = module_.canonicalName=="misc::misc";
        //doChat = call.name.contains("__nullCheck") &&
        //    module_.canonicalName=="test_optional";

        chat("---------------------------");
        chat("standardFind: \"%s\" (%s)", call.name, call.argTypes().toString());

        Struct ns = call.isStartOfChain() ? call.getAncestor!Struct : null;

        /// If template types have been specified and the name has not been manged yet
        /// then we need to mangle the name with the template types and extract the template
        if(call.isTemplated() && !call.name.contains("<")) {
            /// This is  call to a template function.

            /// We can't do anything until the template types are known and added to the name
            if(!call.templateTypes.areKnown()) {
                return CALLABLE_NOT_READY;
            }
            string mangledName = call.name ~ "<" ~ module_.buildState.mangler.mangle(call.templateTypes) ~ ">";
            chat("  mangledName %s", mangledName);
            /// Possible implicit this.call<...>(...)
            // if(ns) {
            //     extractTemplates(ns, call, mangledName, false);
            // }

            if(extractTemplates(call, modAlias, mangledName)) {
                call.name = mangledName;
            }
            return CALLABLE_NOT_READY;
        }

        /// Come back when all root level Placeholders have been removed
        if(ns && ns.containsPlaceholders()) {
            return CALLABLE_NOT_READY;
        }

        chat("looking for %s, from line %s", call.name, call.line()+1);

        /// Collect all the functions with the correct name
        if(!collector.collect(call, modAlias, callableSet)) {
            // Some of the targets are not ready yet
            return CALLABLE_NOT_READY;
        }

        /// If we get here then we have collected all of the possible targets

        {   /// If we only have one unfiltered Callable then just return it and check the types later
            Callable[] unfiltered = callableSet.getUnfiltered();
            if(unfiltered.length == 1 && !unfiltered[0].isTemplateBlueprint()) {
                return unfiltered[0];
            }
        }

        /// From this point onwards we need the resolved arg types
        if(!call.argTypes.areKnown()) {
            return CALLABLE_NOT_READY;
        }

        /// Filter out the targets that do not match the Call arguments
        callableSet.filter(call);

        /// Handle no matches
        if(!callableSet.hasAnyMatches()) {
            /// There are no remaining targets. Look for a possible template match
            auto templates = callableSet.getFuncTemplates();
            if(templates.length > 0) {
                chat("Looking for an implicit template");
                /// There is a template with the same name. Try that
                if(implicitTemplates.find(ns, call, templates)) {

                    chat("  Found an implicit template match");
                    /// If we get here then we found a match.
                    /// call.templateTypes have been set
                    return CALLABLE_NOT_READY;
                }
                chat("  No implicit template match");
            }

            string msg;
            if(call.paramNames.length>0) {
                auto buf = new StringBuffer;
                foreach(i, n; call.paramNames) {
                    if(i>0) buf.add(", ");
                    buf.add(n).add("=").add("%s".format(call.argTypes()[i]));
                }
                msg = "Function %s(%s) not found".format(call.name, buf.toString());
            } else {
                msg = "Function %s(%s) not found".format(call.name, call.argTypes().toString());
            }
            chat("%s", msg);
            module_.addError(call, msg, true);
            return CALLABLE_NOT_READY;
        }

        return oneOrMoreMatchesFound(call);
    }

    /// Assume:
    ///     Struct is known
    ///     call.argTypes may not yet be known
    ///     Callables may not yet be resolved
    ///
    Callable structFind(Call call, Struct ns, bool staticOnly) {
        assert(ns);

        //doChat = module_.canonicalName=="misc::misc";
        //doChat = call.name=="fook";

        chat("--------------------------");
        chat("structFind: \"%s.%s\" (%s) staticOnly=%s, from line %s",
            ns.name, call.name, call.argTypes().toString(), staticOnly, call.line()+1);

        /// Come back when all root level Placeholders have been removed
        if(ns.containsPlaceholders()) {
            return CALLABLE_NOT_READY;
        }

        /// If template types have been specified and the name has not been manged yet
        /// then we need to mangle the name with the template types and extract the template
        if(call.isTemplated() && !call.name.contains("<")) {
            chat("\t%s is templated", call.name);
            string mangledName = call.name ~ "<" ~ module_.buildState.mangler.mangle(call.templateTypes) ~ ">";

            extractTemplates(ns, call, mangledName, staticOnly);
            call.name = mangledName;
            return CALLABLE_NOT_READY;
        }

        /// Collect all the possible overloads
        callableSet.reset();
        Function[] fns;
        Variable[] vars;

        if(staticOnly) {
            fns  ~= ns.getStaticFunctions(call.name);
            vars ~= ns.getStaticVariable(call.name);

            chat("\tadding static funcs %s", fns);
            chat("\tadding static vars %s", vars);

            /// Ensure these functions are resolved
            //foreach(f; fns) {
            //    dd("    requesting function", f.name);
            //    functionRequired(f.getModule.canonicalName, f.name);
            //}

        } else {
            fns  ~= ns.getMemberFunctions(call.name);
            vars ~= ns.getMemberVariable(call.name);

            chat("\tadding member funcs %s", fns);
            chat("\tadding member vars %s", vars);
        }

        foreach(f; fns) {
            callableSet.add(Callable(f));
        }
        foreach(v; vars) {
            if(v && v.isFunctionPtr()) {
                callableSet.add(Callable(v));
            }
        }

        /// From this point onwards we need the resolved arg types
        if(!call.argTypes().areKnown()) {

            /// If any of the call arguments is a lambda then try to resolve that
            if(callableSet.numUnfiltered() > 0) {
                return findImplicitMatchWithUnknownArgs(call);
            }
            return CALLABLE_NOT_READY;
        }

        /// All the call arguemtns are now known

        chat("\tAll arg types are known");

        /// Try to filter the results down to one match
        callableSet.filter(call);

        if(!callableSet.hasAnyMatches()) {
            /// There are no remaining targets. Look for a possible template match

            chat("\tno matches");

            auto templates = callableSet.getFuncTemplates();
            if(templates.length > 0) {
                /// There is a template with the same name. Try that
                if(implicitTemplates.find(ns, call, templates)) {
                    /// If we get here then we found an implicit match.
                    /// call.templateTypes have been set
                    return CALLABLE_NOT_READY;
                }
            }

            /// Function not found

            if(call.name=="new" && ns.isPOD()) {
                /// Expect this to be converted into a call to the default constructor
                return CALLABLE_NOT_READY;
            }
            //if(call.name=="new") {
                // This is a bad constructor
            //    return CALLABLE_NOT_READY;
            //}

            string argsStr;
            if(call.paramNames.length>0) {
                auto buf = new StringBuffer;
                foreach(i, n; call.paramNames) {
                    if(i>0) buf.add(", ");
                    buf.add("%s".format(call.argTypes()[i])).add(" ").add(n);
                }
                argsStr = buf.toString();

            } else {
                argsStr = call.argTypes().toString();
            }

            string msg;
            Suggestions suggestions;

            if(callableSet.numInvisible() > 0) {
                msg ~= "Struct '%s' function %s(%s) is not visible";
            } else if(callableSet.numWithIncorrectParamNames() > 0) {
                msg ~= "Struct '%s' function does not match call '%s(%s)' - parameter names do not match";

                suggestions = new CallParamNameMismatchSuggestions(call, callableSet.getAllWithIncorrectParamNames().dup);

            } else {
                msg ~= "Struct '%s' does not have function %s(%s)";

                if(!staticOnly ) {
                    // TODO - If calling a static function on an instance variable
                    //        then we could show the static function that might have matched
                }

                if(fns.length>0) {
                    suggestions = new FunctionSuggestions(fns);
                }
            }

            msg = msg.format(ns.name, call.name, argsStr);

            module_.addError(new ParseError(module_, call, msg).addSuggestions(suggestions), true);

            return CALLABLE_NOT_READY;

        }

        return oneOrMoreMatchesFound(call);
    }
private:
    Callable oneOrMoreMatchesFound(Call call) {

        if(!callableSet.hasSingleMatch()) {
            /// More than one match
            module_.buildState.addError(new AmbiguousCall(module_, call, callableSet.getAllMatches().dup), true);
            return CALLABLE_NOT_READY;
        }

        /// If we get here then we have a single match
        Callable match = callableSet.getSingleMatch();

        /// Add the function to the resolution set
        if(match.isFunction()) {
            module_.buildState.moduleRequired(match.func.getModule().canonicalName);
        }

        return match;
    }
    ///
    /// Extract one or more function templates:
    ///
    /// If the template is in this module:
    ///     - Extract the tokens and add them to the module
    ///
    /// If the template is in another module:
    ///     - Create one proxy Function within this module using the mangled name
    ///     - Extract the tokens in the other module
    ///
    bool extractTemplates(Call call, ModuleAlias modAlias, string mangledName) {
        assert(call.isTemplated());

        /// Find the template(s)
        if(!collector.collect(call, modAlias, callableSet)) {
            return false;
        }

        if(callableSet.numUnfiltered()==0) {
            //throw new CompilerError(call,
            //    "Function template %s not found".format(call.name));
            return true;
        }

        Function[][string] toExtract;

        foreach(ft; callableSet.getUnfiltered()) {
            if(ft.isFunction()) {
                auto f = ft.func;
                assert(!f.isImport);

                if(!f.isTemplateBlueprint()) continue;
                if(f.blueprint.numTemplateParams()!=call.templateTypes.length) continue;

                /// Extract this one
                toExtract[f.moduleName] ~= f;
            }
        }

        foreach(k,v; toExtract) {
            auto m = module_.buildState.getOrCreateModule(k);
            m.templates.extract(v, call, mangledName);

            if(m.nid!=module_.nid) {
                /// Create the proxy
                auto proxy       = makeNode!Function;
                proxy.name       = mangledName;
                proxy.moduleName = m.canonicalName;
                proxy.isImport   = true;

                if(modAlias) {
                    if(!modAlias.imp.hasFunction(mangledName)) {
                        modAlias.imp.add(proxy);
                    }
                } else {
                    if(!module_.hasFunction(mangledName)) {
                        module_.add(proxy);
                    }
                }
            }
        }

        return true;
    }
    ///
    /// Extract one or more struct function templates
    ///
    void extractTemplates(Struct ns, Call call, string mangledName, bool staticOnly) {
        assert(call.isTemplated());

        chat("    extracting templates %s -> %s num template params=%s",
        call.name, mangledName, call.templateTypes.length);

        Function[] fns;

        if(staticOnly) {
            fns ~= ns.getStaticFunctions(call.name);
            //mangledName = "%s::%s".format(ns.getUniqueName, mangledName);
        } else {
            fns ~= ns.getMemberFunctions(call.name);
        }

        Function[][string] toExtract;

        foreach(f; fns) {
            if(!f.isTemplateBlueprint()) continue;
            if(f.blueprint.numTemplateParams()!=call.templateTypes.length) continue;

            /// Extract this one
            toExtract[f.moduleName] ~= f;
        }

        chat("    toExtract = %s", toExtract);

        foreach(k,v; toExtract) {
            auto m = module_.buildState.getOrCreateModule(k);
            m.templates.extract(v, call, mangledName);
        }
    }
    ///
    /// Some of the call args are unknown but we have some name matches.
    /// If we can resolve any function ptr call args then we might
    /// make some progress.
    ///
    /// eg. call args = (int, fn(UNKNOWN return void))
    /// nameMatches   = (int, fn(void return void))
    ///                 (int, fn(int return void))      // <-- match
    ///
    Callable findImplicitMatchWithUnknownArgs(Call call) {
        //if(call.name.indexOf("each")!=-1) dd("findImplicitMatchWithUnknownArgs", call);

        bool _checkFuncPtr(FunctionType param, FunctionType arg) {
            bool _numArgsMatch() {
                return param.numParams() == arg.numParams();
            }
            bool _returnTypesSameOrUnknown() {
                return param.returnType().isUnknown() ||
                arg.returnType().isUnknown() ||
                param.returnType.exactlyMatches(arg.returnType());
            }
            return _numArgsMatch() && _returnTypesSameOrUnknown();
        }

        Callable[] possibleMatches;

        foreach(callable; callableSet.getUnfiltered()) {
            Type[] argTypes   = call.argTypes();
            Type[] paramTypes = callable.paramTypes();

            bool possibleMatch = !callable.isTemplateBlueprint() &&
                                 call.numArgs() == callable.numParams();

            /// TODO - This does not handle named arguments properly

            for(auto i=0; possibleMatch && i<call.numArgs(); i++) {
                auto arg   = argTypes[i];
                auto param = paramTypes[i];

                if(arg.isUnknown()) {
                    if(arg.isFunction() && param.isFunction()) {
                        /// This is an unresolved function ptr argument.
                        /// Filter out where number of args is different.
                        /// If return type is known, filter out if they are different
                        possibleMatch = _checkFuncPtr(param.getFunctionType(), arg.getFunctionType());
                    } else {
                        /// We have an unknown that we can't handle
                        return CALLABLE_NOT_READY;
                    }
                } else {
                    possibleMatch = arg.canImplicitlyCastTo(param);
                }
            }
            if(possibleMatch) {
                //dd("\tPossible match:", callable);
                possibleMatches ~= callable;
            } else {
                //dd("\tNot a match   :", callable);
                //overloads.remove(callable);
            }
        }
        if(possibleMatches.length==1) {
            //dd("\tWe have a winner", overloads[0]);
            return possibleMatches[0];
        }

        return CALLABLE_NOT_READY;
    }
    void chat(A...)(lazy string fmt, lazy A args) {
        if(doChat) {
            dd(format(fmt, args));
        }
    }
}