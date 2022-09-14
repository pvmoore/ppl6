module ppl.misc.writer;

import ppl.internal;
import std.stdio : File;

void writeTokens(Module m, Token[] tokens) {
    if(m.config.logTokens) {
        import std.array;

        string path = m.config.targetPath.add(Directory("tok/"))
                                         .add(Filename(m.canonicalName.replace("::", "_")).withExtension(".tok"))
                                         .toString();

        auto f = new FileLogger(path);
        foreach(i, t; tokens) {
            f.log("[%s] %s", i, t);
        }
    }
}
void writeLL(Module m, string subdir) {
    if(m.config.writeIR) {
        string path = m.config.targetPath.add(Directory(subdir))
                                         .add(Filename(m.fileName).withExtension(".ll"))
                                         .toString();

        m.llvmValue.writeToFileLL(path);
    }
}
bool writeASM(LLVMWrapper llvm, Module m) {
    if(m.config.writeASM) {
        string path = m.config.targetPath.add(Filename(m.fileName).withExtension(".asm")).toString();

        if(!llvm.x86Target.writeToFileASM(m.llvmValue, path)) {
            writefln("failed to write ASM %s", path);
            return false;
        }
    }
    return true;
}
bool writeOBJ(LLVMWrapper llvm, Module m) {
    string path = m.config.targetPath.add(Filename(m.fileName).withExtension(".obj")).toString();

    if(!llvm.x86Target.writeToFileOBJ(m.llvmValue, path)) {
        writefln("failed to write OBJ %s", path);
        return false;
    }
    return true;
}
void writeAST(Module m, Directory subdir) {
    import std.array : replace;
    if(m.config.writeAST) {
        string buf = m.dumpToString();

        string path = m.config.targetPath.add(subdir)
                                         .add(Filename(m.fileName.replace('.','_')).withExtension(".ast"))
                                         .toString();

        auto file = File(path, "w");
        file.rawWrite(buf);
    }
}
