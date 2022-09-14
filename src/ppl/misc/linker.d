module ppl.misc.Linker;

import ppl.internal;

final class Linker {
private:
    LLVMWrapper llvm;
    StopWatch watch;
public:
    ulong getElapsedNanos() { return watch.peek().total!"nsecs"; }

    this(LLVMWrapper llvm) {
        this.llvm = llvm;
    }
    void clearState() {
        watch.reset();
    }

    bool link(Module m) {
        watch.start();
        string targetObj = m.config.targetPath.add(Filename(m.canonicalName).withExtension(".obj")).toString();
        string targetExe = m.config.targetPath.add(m.config.targetExe).toString();

        writeOBJ(llvm, m);

        auto args = [
            "link",
            "/NOLOGO",
            //"/VERBOSE",
            "/MACHINE:X64",
            "/WX",              /// Treat linker warnings as errors
            "/SUBSYSTEM:" ~ m.config.subsystem
        ];

        if(m.config.isDebug()) {
            args ~= [
                "/DEBUG:NONE",  /// Don't generate a PDB for now
                "/OPT:NOREF"    /// Don't remove unreferenced functions and data
            ];
        } else {
            args ~= [
                "/RELEASE",
                "/OPT:REF",     /// Remove unreferenced functions and data
                //"/LTCG",        /// Link time code gen
            ];
        }

        args ~= [
            targetObj,
            "/OUT:" ~ targetExe
        ];

        args ~= m.config.getExternalLibs();

        if(m.config.shouldLog(Logging.LINKER)) {
            writefln("link command: %s", args);
        }

        import std.process : spawnProcess, wait;

        int returnStatus;
        string errorMsg;
        try{
            auto pid = spawnProcess(args);
            returnStatus = wait(pid);
        }catch(Exception e) {
            errorMsg     = e.msg;
            returnStatus = -1;
        }

        if(returnStatus!=0) {
            m.buildState.addError(new LinkError(m, returnStatus, errorMsg), false);
        }

        /// Delete the obj file if required
        if(!m.config.writeOBJ) {
            import std.file : remove;
            remove(targetObj);
        }
        watch.stop();
        return returnStatus==0;
    }
}