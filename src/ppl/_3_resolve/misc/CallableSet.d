module ppl._3_resolve.misc.CallableSet;

import ppl.internal;

/**
 * Manage the list of Callable candidates for a Call.
 */
final class CallableSet {
private:
    Module mod;
    Call call;
    Type[] callArgTypes;
    Callable[] results;

    enum Reason { NONE, NUM_PARAMS, PARAM_NAME, PARAM_TYPE, INVISIBLE }

    Callable[] funcTemplates;
    Callable[] nonMatches;
    Reason[] nonMatchReasons;
    Callable[] partialMatches;
    Callable[] exactMatches;
public:
    Callable[] getExactMatches() { return exactMatches; }
    Callable[] getPartialMatches() { return partialMatches; }
    Callable[] getFuncTemplates() { return funcTemplates; }

    void reset(Call call) {
        this.mod = call.getModule();
        this.call = call;
        this.callArgTypes = call.argTypes();
        this.results.length = 0;
        this.funcTemplates.length = 0;
        this.nonMatches.length = 0;
        this.nonMatchReasons.length = 0;
        this.exactMatches.length = 0;
        this.partialMatches.length = 0;
    }
    void add(Callable c) {
        results ~= c;
    }
    /**
     * Return the best matches from the list of partial matches.
     * Assume there are at least two partial matches and no exact matches
     */
    // Callable[] getFilteredPartialMatches() {
    //     assert(exactMatches.length == 0);
    //     assert(partialMatches.length > 1);

    //     Callable[] matches;

    //     // Keep partial matches where the types exactly match
    //     // or they are either both integer or both real.

    //     foreach(c; partialMatches) {
    //         Type[] callArgTypesInOrder = c.getCallArgTypesInOrder(call);
    //         Type[] paramTypes = c.paramTypes();

    //         foreach(i; 0..paramTypes.length) {
    //             Type arg = callArgTypesInOrder[i];
    //             Type param = paramTypes[i];
    //             bool ok = true;

    //             if(arg.exactlyMatches(param)) {
    //                 /// match
    //             } else if(arg.isInteger()==param.isInteger() && arg.category()<param.category()) {
    //                 /// integer and arg is smaller than param
    //             } else if(arg.isReal()==param.isReal() && arg.category()<param.category()) {
    //                 /// real and arg is smaller than param
    //             } else {
    //                 /// nope
    //                 ok = false;
    //             }

    //             if(ok) {
    //                 matches ~= c;
    //             }
    //         }
    //     }

    //     return matches;
    // }
    /**
     *  Try to match all Callables against the Call.
     *  Produce a list of possible matches
     */
    void filter() {
        assert(call);
        assert(mod);
        import common : indexOf;

        lp: foreach(c; results) {
            if(c.isTemplateBlueprint()) {
                // Save this for later if we can't find anything suitable
                funcTemplates ~= c;
                continue;
            }
            if(isInvisible(c)) {
                nonMatches ~= c;
                nonMatchReasons ~= Reason.INVISIBLE;
                continue;
            }

            Type[] paramTypes = c.paramTypes();
            Type[] argTypesInOrder;

            if(paramTypes.length != callArgTypes.length) {
                nonMatches ~= c;
                nonMatchReasons ~= Reason.NUM_PARAMS;
                continue;
            }

            if(call.paramNames.length > 0) {
                // named arguments
                argTypesInOrder.length = callArgTypes.length;
                string[] paramNames = c.paramNames();
                foreach(i, name; call.paramNames) {
                    int index = paramNames.indexOf(name);
                    if(index==-1) {
                        // Param not found
                        nonMatches ~= c;
                        nonMatchReasons ~= Reason.PARAM_NAME;
                        continue lp;
                    }

                    auto argType   = callArgTypes[i];
                    auto paramType = paramTypes[index];

                    argTypesInOrder[i] = argType;

                    if(!argType.canImplicitlyCastTo(paramType)) {
                        nonMatches ~= c;
                        nonMatchReasons ~= Reason.PARAM_TYPE;
                        continue lp;
                    }
                }
            } else {
                // standard argument list
                argTypesInOrder = callArgTypes;

                if(!canImplicitlyCastTo(callArgTypes, paramTypes)) {
                    nonMatches ~= c;
                    nonMatchReasons ~= Reason.PARAM_TYPE;
                    continue;
                }
            }

            // If we get here then we have at least a partial match
            assert(argTypesInOrder.length == callArgTypes.length);

            if(argTypesInOrder.length == 0 || argTypesInOrder.exactlyMatch(paramTypes)) {
                exactMatches ~= c;
            } else {
                partialMatches ~= c;
            }
        }
    }
private:
    bool isInvisible(Callable c) {
        if(c.getModule().nid != mod.nid) {
            // Callable is in a different module
            if(c.isPrivate()) {
                assert(c.isStructMember());
                auto targetStruct = c.getStruct();
                assert(targetStruct);

                auto callerStruct = call.getAncestor!Struct;
                if(!callerStruct || callerStruct != targetStruct) {
                    return true;
                }
            }
        } else {
            // In the same module
        }
        return false;
    }
}