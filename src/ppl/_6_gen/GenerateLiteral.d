module ppl._6_gen.GenerateLiteral;

import ppl.internal;

final class GenerateLiteral {
    GenerateModule gen;
    LLVMBuilder builder;

    this(GenerateModule gen) {
        this.gen     = gen;
        this.builder = gen.builder;
    }
    void generate(LiteralArray n) {

        /// Alloca some space
        string name = n.generateName();
        gen.lhs  = builder.alloca(n.type.getLLVMType(), name);
        auto ptr = gen.lhs;

        if(n.length() != n.type.countAsInt()) {
            /// Set to all zeroes
            builder.store(constAllZeroes(n.type.getLLVMType()), ptr);
        }

        /// Set the values
        foreach(i, ch; n.elementValues()) {
            ch.visit!GenerateModule(gen);
            gen.rhs = gen.castType(gen.rhs, ch.getType(), n.type.subtype);

            gen.setArrayValue(ptr, gen.rhs, i.as!int, "[%s]".format(i));
        }

        /// Set literal array ptr as the lhs
        gen.lhs = ptr;
        gen.rhs = builder.load(gen.lhs);
    }
    void generate(LiteralFunction n, LLVMValueRef llvmValue) {
        assert(llvmValue);

        auto f = n.parent.as!Function;

        auto type       = n.type.getFunctionType();
        auto paramTypes = type.paramTypes();
        auto numParams  = paramTypes.length;

        auto entry = llvmValue.appendBasicBlock("entry");

        /// Entry
        gen.moveToBlock(entry);

        /// Visit body statements
        foreach(ch; n.children) {
            ch.visit!GenerateModule(gen);
        }

        if(type.returnType().isVoid) {
            if(!n.hasChildren || !n.last().isReturn()) {
                builder.retVoid();
            }
        }

        gen.rhs = llvmValue;
    }
    void generate(LiteralNull n) {
        gen.rhs = constNullPointer(n.type.getLLVMType());
    }
    void generate(LiteralNumber n) {
        LLVMValueRef value;
        switch(n.type.category()) with(Type) {
            case BOOL:   value = constI8(n.value.getInt()); break;
            case BYTE:   value = constI8(n.value.getInt()); break;
            case SHORT:  value = constI16(n.value.getInt()); break;
            case INT:    value = constI32(n.value.getInt()); break;
            case LONG:   value = constI64(n.value.getLong()); break;
            case HALF:   value = constF16(n.value.getDouble()); break;
            case FLOAT:  value = constF32(n.value.getDouble()); break;
            case DOUBLE: value = constF64(n.value.getDouble()); break;
            default:
            assert(false, "Invalid type %s".format(n.type));
        }
        gen.rhs = value;
    }
    void generate(LiteralString n) {
        assert(n.llvmValue);
        gen.rhs = n.llvmValue;
    }
    void generate(LiteralTuple n) {
        Tuple tuple           = n.type.getTuple();
        Type[] structTypes    = n.elementTypes();
        Variable[] structVars = tuple.getMemberVariables();

        /// alloca
        gen.lhs = builder.alloca(tuple.getLLVMType(), "tuple_literal");
        LLVMValueRef structPtr = gen.lhs;

        /// Zero the struct if not all values are being set
        if(!n.allValuesSpecified()) {
            builder.store(constAllZeroes(tuple.getLLVMType()), structPtr);
        }

        auto elements     = n.elements();
        auto elementTypes = n.elementTypes();

        auto varNames = tuple.getMemberVariables().map!(it=>it.name).array;
        auto varTypes = tuple.memberVariableTypes();

        foreach(i, e; elements) {
            e.visit!GenerateModule(gen);
            gen.rhs = gen.castType(gen.rhs, elementTypes[i], varTypes[i]);

            gen.setStructValue(structPtr, gen.rhs, i.as!int);
        }

        gen.lhs = structPtr;
        gen.rhs = builder.load(structPtr);
    }
}