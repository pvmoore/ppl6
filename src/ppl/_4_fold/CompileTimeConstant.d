module ppl._4_fold.CompileTimeConstant;

import ppl.internal;

interface CompileTimeConstant {
    Expression copy();
    bool isTrue();
    Type getType();
}