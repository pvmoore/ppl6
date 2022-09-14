module ppl.config.Config;

import ppl.internal;
import std.array;
import std.path;

final class Config {
private:
    enum Mode { DEBUG, RELEASE }
    Mode mode;
    string mainModuleCanonicalName;
    Include[string] includes;   // key = baseModuleName
    string[] libs;
public:
    struct Include {
        string baseModuleName;  /// eg. "core"
        string absPath;
    }

    Filename mainFile;      // eg. "test.p6"
    Filename targetExe;     // eg. "test.exe"
    Directory basePath;
    Directory targetPath;   // eg. ".target/"

    /// Compilation options
    bool enableNullChecks   = true;
    bool enableAsserts      = true;
    bool enableInlining     = true;
    bool enableBoundsChecks = true;     // Not currently used
    bool enableOptimisation = true;
    bool enableFastMaths    = true;     // Not currently used

    /// Logging options
    ulong loggingFlags = Logging.HEADER | Logging.STATE | Logging.STATS;

    /// Link options
    bool enableLink  = true;
    string subsystem = "console";

    int maxErrors = int.max;

    /// Collect data for display in ide
    bool collectOutput = false;

    /// Compiler meta options
    bool logTokens    = false;

    bool writeASM     = true;
    bool writeOBJ     = true;
    bool writeAST     = true;
    bool writeIR      = true;
    bool writeJSON    = false;

    ///==================================================================================

    bool isDebug()   { return mode==Mode.DEBUG; }
    bool isRelease() { return mode==Mode.RELEASE; }
    string getMainModuleCanonicalName() { return mainModuleCanonicalName; }
    Include[] getIncludes() { return includes.values; }
    bool shouldLog(Logging flags) { return (loggingFlags & flags) != 0; }

    string getEntryFunctionName() {
        if(subsystem=="console") return "main";
        if(subsystem=="windows") return "WinMain";
        assert(false, "Unknown subsystem : " ~ subsystem);
    }

    void initialise() {
        mainModuleCanonicalName = mainFile.withoutExtension().value
                                          .replace("/", "::").replace("\\", "::");

        generateTargetDirectories();
    }
    void addLib(string path) {
        libs ~= path;
    }
    void addInclude(string name, string path) {
        includes[name] = Include(name, normaliseDir(path, true));
    }
    void setToDebug() {
        mode               = Mode.DEBUG;
        enableNullChecks   = true;
        enableAsserts      = true;
        enableInlining     = false;
        enableOptimisation = true; //false; // fixme
        enableFastMaths    = true;
        enableBoundsChecks = true;

        libs ~= "external/.target/x64/Debug/tgc.lib";
    }
    void setToRelease() {
        mode               = Mode.RELEASE;
        enableNullChecks   = true;
        enableAsserts      = false;
        enableInlining     = true;
        enableOptimisation = true;
        enableFastMaths    = true;
        enableBoundsChecks = false;

        libs ~= "external/.target/x64/Release/tgc.lib";
    }

    ///
    /// Return the full path including the module filename and extension
    ///
    string getFullModulePath(string canonicalName) {
        auto baseModuleName = splitCanonicalName(canonicalName)[0];
        auto path           = basePath.toString();

        foreach(lib; includes) {
            if(lib.baseModuleName==baseModuleName) {
                path = lib.absPath;
            }
        }

        assert(path.endsWith("/"));

        return path ~ canonicalName.replace("::", "/") ~ ".p6";
    }
    /**
     *  Convert "mod/mod2.p6" to "mod::mod2"
     */
    string getCanonicalName(string relpath) {
        import std.array : replace;
        return relpath[0..relpath.length-3].replace("\\", "::").replace("/", "::");
    }
    string[] getExternalLibs() {
        if(isDebug) {
            string[] dynamicRuntime = [
                "msvcrtd.lib",
                "ucrtd.lib",
                "vcruntimed.lib"
            ];
            //string[] staticRuntime = [
            //    "libcmt.lib",
            //    "libucrt.lib",
            //    "libvcruntime.lib"
            //];
            return dynamicRuntime ~ libs;
        }
        string[] dynamicRuntime = [
            "msvcrt.lib",
            "ucrt.lib",
            "vcruntime.lib"
        ];
        //string[] staticRuntime = [
        //    "libcmt.lib",
        //    "libucrt.lib",
        //    "libvcruntime.lib"
        //];
        return dynamicRuntime ~ libs;
    }

    override string toString() {
        auto buf = new StringBuffer;
        buf.add("Main file .... %s\n".format(mainFile));
        buf.add("Base path .... %s\n".format(basePath));
        buf.add("Target path .. %s\n".format(targetPath));
        buf.add("Target exe ... %s\n\n".format(targetExe));

        buf.add("[option] Build         = %s\n", isDebug ? "DEBUG" : "RELEASE");
        buf.add("[option] Null checks   = %s\n".format(enableNullChecks));
        buf.add("[option] Bounds checks = %s\n".format(enableBoundsChecks));
        buf.add("[option] Asserts       = %s\n".format(enableAsserts));
        buf.add("[option] Inline        = %s\n".format(enableInlining));
        buf.add("[option] Optimise      = %s\n".format(enableOptimisation));
        buf.add("[option] Fast maths    = %s\n".format(enableFastMaths));
        buf.add("[option] Link          = %s\n".format(enableLink));
        buf.add("[option] Subsystem     = %s\n\n".format(subsystem));

        foreach(lib; includes) {
            buf.add("[include] %s %s\n", lib.baseModuleName, lib.absPath);
        }
        buf.add("\n");
        foreach(lib; libs) {
            buf.add("[lib] %s\n", lib);
        }
        return buf.toString();
    }
private:
    /// eg. "core::console" -> ["core", "console"]
    static string[] splitCanonicalName(string canonicalName) {
        assert(canonicalName);
        return canonicalName.split("::");
    }
    void generateTargetDirectories() {
        createTargetDir("");
        createTargetDir("tok/", "tok");
        createTargetDir("ast/", "ast");
        createTargetDir("ir/", "ll");
        createTargetDir("ir_opt/", "ll");
        createTargetDir("bc/", "bc");
        //createTargetDir("json/", "json");
    }
    void createTargetDir(string dir, string[] deleteExtensions...) {
        import std.file : exists, mkdir, remove, dirEntries, SpanMode;
        auto path = targetPath.add(Directory(dir));

        if(!path.exists()) {
            path.create();
        } else {
            // Delete old files

            string pattern = "*.{";
            foreach(i, ext; deleteExtensions) {
                if(i>i) pattern ~= ",";
                pattern ~= ext;
            }
            pattern ~= "}";

            foreach(f; dirEntries(path.toString(), pattern, SpanMode.shallow, false)) {
                remove(f);
            }
        }
    }
}