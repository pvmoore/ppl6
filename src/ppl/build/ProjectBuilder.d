module ppl.build.ProjectBuilder;
///
/// Build the entire project.
///
import ppl.internal;

final class ProjectBuilder : BuildState {
private:

public:
    this(LLVMWrapper llvmWrapper, Config config) {
        super(llvmWrapper, config);
    }
    void build() {
        startNewBuild();
        //bool buildSuccessful = false;
        watch.start();
        bool astDumped;

        try{
            /// We know we need the program entry point
            moduleRequired(config.getMainModuleCanonicalName());

            ///============================ Start
            parseResolveFold();
            if(hasErrors()) return;

            //refInfo.process();

            removeUnreferencedNodesAfterResolution();
            afterResolution();
            if(hasErrors()) return;

            semanticCheck();
            if(hasErrors()) return;

            afterSemantic();
            if(hasErrors()) return;

            dumpAST();
            astDumped = true;

            if(generateIR()) {

                optimiseModules();

                combineModules();

                if(config.enableLink) {
                    if(link()) {
                        /// Link succeeded
                    }
                }
            }
            ///============================ End
        }catch(InternalCompilerError e) {
            writefln("\n=============================");
            writefln("!! Internal compiler error !!");
            writefln("=============================");
            writefln("%s", e.info);
            writefln("\n=============================");
            throw e;
        }catch(CompilationAborted e) {
            writefln("Compilation aborted ... %s\n", e.reason);
        }catch(Throwable e) {
            auto m = mainModule ? mainModule : modules ? modules.values[0] : null;
            addError(new UnknownError(m, "Unhandled exception: %s".format(e)), true);
        }finally{
            if(!astDumped) dumpAST();
            flushLogs();
            watch.stop();
        }
    }
private:
    void optimiseModules() {
        if(!config.enableOptimisation) return;
        logState("[???] optimise");
        foreach(m; modules.values) {
            optimiser.optimise(m);
            if(config.collectOutput) {
                optimisedIr[m.canonicalName] = m.llvmValue.dumpToString();
            }
        }
    }
    void combineModules() {
        logState("[???] combining");
        auto otherModules = allModules()
                                .filter!(it=>it.nid != mainModule.nid)
                                .map!(it=>it.llvmValue)
                                .array;

        if(otherModules.length>0) {
            llvmWrapper.linkModules(mainModule.llvmValue, otherModules);
        }

        if(config.enableOptimisation) {
            /// Run optimiser again on combined file
            optimiser.optimiseCombined(mainModule);
        }
        if(config.collectOutput) {
            linkedIr  = mainModule.llvmValue.dumpToString();
            linkedASM = llvmWrapper.x86Target.writeToStringASM(mainModule.llvmValue);
        }

        writeLL(mainModule, "");
        writeASM(llvmWrapper, mainModule);
    }
    bool link() {
        logState("[???] linking");
        return linker.link(mainModule);
    }
}
