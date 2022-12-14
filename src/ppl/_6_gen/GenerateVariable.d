module ppl._6_gen.GenerateVariable;

import ppl.internal;

final class GenerateVariable {
    GenerateModule gen;
    LLVMBuilder builder;

    this(GenerateModule gen) {
        this.gen     = gen;
        this.builder = gen.builder;
    }
    void generate(Module module_) {
        generateLocalGlobalVariableDeclarations(module_);
        generateLocalStaticVariableDeclarations(module_);
        generateImportedStaticVariableDeclarations(module_);
    }
private:
    void generateLocalGlobalVariableDeclarations(Module module_) {
        foreach(v; module_.getVariables()) {
            auto g = module_.llvmValue.addGlobal(v.type.getLLVMType(), v.name);
            g.setInitialiser(constAllZeroes(v.type.getLLVMType()));

            if(v.isStatic && v.isPublic) {
                g.setLinkage(LLVMLinkage.LLVMLinkOnceODRLinkage);
            } else {
                g.setLinkage(LLVMLinkage.LLVMInternalLinkage);
            }
            v.llvmValue = g;
        }
    }
    void generateLocalStaticVariableDeclarations(Module module_) {
        foreach(ns; module_.getStructsAndClassesRecurse()) {
            foreach(v; ns.getStaticVariables()) {
                string name = "%s::%s".format(ns.name, v.name);
                auto g = module_.llvmValue.addGlobal(v.type.getLLVMType(), name);
                g.setInitialiser(constAllZeroes(v.type.getLLVMType()));
                g.setLinkage(LLVMLinkage.LLVMLinkOnceODRLinkage);
                v.llvmValue = g;
            }
        }
    }
    void generateImportedStaticVariableDeclarations(Module module_) {
        foreach(ns; module_.getImportedStructsAndClasses()) {
            foreach(v; ns.getStaticVariables()) {
                if(!v.isPublic) continue;

                string name = "%s::%s".format(ns.name, v.name);
                auto g = module_.llvmValue.addGlobal(v.type.getLLVMType(), name);
                g.setInitialiser(undef(v.type.getLLVMType()));
                g.setLinkage(LLVMLinkage.LLVMAvailableExternallyLinkage);
                v.llvmValue = g;
            }
        }
    }
}

