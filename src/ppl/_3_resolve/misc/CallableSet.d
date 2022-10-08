module ppl._3_resolve.misc.CallableSet;

import ppl.internal;

/**
 * Manage the list of Callable candidates for a Call.
 */
final class CallableSet {
private:
    Module mod;
    Callable[] unfiltered;

    Function[] funcTemplates;
    Callable[] nonMatches;
    Reason[] nonMatchReasons;
    Callable[] partialMatches;
    Callable[] exactMatches;
public:
    enum Reason { NONE, NUM_PARAMS, PARAM_NAME, PARAM_TYPE, INVISIBLE }

    bool hasSingleMatch() { return exactMatches.length==1 || (exactMatches.length==0 && partialMatches.length==1); }
    bool hasAnyMatches() { return exactMatches.length > 0 || partialMatches.length > 0; }
    int numUnfiltered() { return unfiltered.length.as!int; }
    int numInvisible() { return nonMatchReasons.filter!(r=>r==Reason.INVISIBLE).count().as!int; }
    int numWithIncorrectParamNames() { return nonMatchReasons.filter!(r=>r==Reason.PARAM_NAME).count().as!int; }

    Callable getSingleMatch() {
        assert(hasSingleMatch());
        return exactMatches.length==1 ? exactMatches[0] : partialMatches[0];
    }
    Callable[] getAllMatches() { return exactMatches ~ partialMatches; }
    Callable[] getExactMatches() { return exactMatches; }
    Callable[] getPartialMatches() { return partialMatches; }
    Function[] getFuncTemplates() { return funcTemplates; }
    Callable[] getNonMatches() { return nonMatches; }
    Reason[] getNonMatchReasons() { return nonMatchReasons; }
    Callable[] getUnfiltered() { return unfiltered; }
    Callable[] getAllWithIncorrectParamNames() {
        Callable[] results;
        foreach(i; 0..nonMatches.length) {
            if(nonMatchReasons[i] == Reason.PARAM_NAME) results ~= nonMatches[i];
        }
        return results;
    }

    ulong length() { return partialMatches.length + exactMatches.length; }

    this(Module mod) {
        this.mod = mod;
    }

    void reset() {
        this.unfiltered.length = 0;
        this.funcTemplates.length = 0;
        this.nonMatches.length = 0;
        this.nonMatchReasons.length = 0;
        this.exactMatches.length = 0;
        this.partialMatches.length = 0;
    }
    void add(Callable c) {
        unfiltered ~= c;
    }
    /**
     *  Try to match all Callables against the Call.
     *  Produce a list of possible matches
     */
    void filter(Call call) {
        import common : indexOf;

        Type[] callArgTypes = call.argTypes();

        lp: foreach(j, callable; unfiltered) {

            if(callable.isTemplateBlueprint()) {
                // Save this for later if we can't find anything suitable
                funcTemplates ~= callable.func;
                continue;
            }
            if(isInvisible(call, callable)) {
                nonMatches ~= callable;
                nonMatchReasons ~= Reason.INVISIBLE;
                continue;
            }

            Type[] paramTypes = callable.paramTypes();

            if(paramTypes.length != callArgTypes.length) {
                nonMatches ~= callable;
                nonMatchReasons ~= Reason.NUM_PARAMS;
                continue;
            }

            if(call.paramNames.length > 0) {
                // named arguments
                string[] paramNames = callable.paramNames();
                foreach(i, name; call.paramNames) {
                    int index = paramNames.indexOf(name);
                    if(index==-1) {
                        // Param not found
                        nonMatches ~= callable;
                        nonMatchReasons ~= Reason.PARAM_NAME;
                        continue lp;
                    }

                    auto argType   = callArgTypes[i];
                    auto paramType = paramTypes[index];

                    if(!argType.canImplicitlyCastTo(paramType)) {
                        nonMatches ~= callable;
                        nonMatchReasons ~= Reason.PARAM_TYPE;
                        continue lp;
                    }
                }
            } else {
                // standard argument list
                if(!canImplicitlyCastTo(callArgTypes, paramTypes)) {
                    nonMatches ~= callable;
                    nonMatchReasons ~= Reason.PARAM_TYPE;
                    continue;
                }
            }

            Type[] argTypesInOrder = callable.getCallArgTypesInOrder(call);

            // If we get here then we have at least a partial match
            assert(argTypesInOrder.length == callArgTypes.length);

            if(argTypesInOrder.length == 0 || argTypesInOrder.exactlyMatch(paramTypes)) {
                exactMatches ~= callable;
            } else {
                partialMatches ~= callable;
            }
        }
    }
private:
    bool isInvisible(Call call, Callable c) {
        if(c.getModule().nid != mod.nid) {
            // Callable is in a different module

            if(c.isPrivate()) {

                if(c.isStructMember()) {
                    auto targetStruct = c.getStruct();
                    assert(targetStruct);

                    auto callerStruct = call.getAncestor!Struct;
                    if(!callerStruct || callerStruct != targetStruct) {
                        return true;
                    }
                } else {
                    return true;
                }
            }
        } else {
            // In the same module
        }
        return false;
    }
}