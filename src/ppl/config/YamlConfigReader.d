module ppl.config.YamlConfigReader;

import ppl.internal;
import dyaml;

final class YamlConfigReader {
private:
    Filepath yamlFile;
    Config config;
public:
    this(Filepath yamlFile) {
        this.yamlFile = yamlFile;
    }
    Config read() {
        Node root = Loader.fromFile(yamlFile.toString()).load();
        this.config = new Config();

        general(root);

        /// Standard libs
        config.addInclude("core", "./libs/");
        config.addInclude("std", "./libs/");

        srcDependencies(root);
        libDependencies(root);
        linker(root);

        config.initialise();

        return config;
    }
private:
    void general(Node root) {
        if(!root.containsKey("general")) return;
        Node general = root["general"];

        config.mainFile = Filename(getRequired!string(general, "main-file", "general"));
        config.targetPath = yamlFile.directory.add(Directory(getOptional!string(general, "target-path", ".target")));
        config.targetExe = Filename(getOptional!string(general, "target-exe", "out"));
        config.basePath = yamlFile.directory;

        auto path = Filepath(yamlFile.directory, config.mainFile);

        if(!path.exists()) {
            throw new Exception("mainFile '%s' does not exist".format(path.toString()));
        }

        if("release" == getOptional!string(general, "build", "debug")) {
            config.setToRelease();
        } else {
            config.setToDebug();
        }
    }
    void srcDependencies(Node root) {
        if(!root.containsKey("src-dependencies")) return;

        foreach(Node it; root["src-dependencies"].mappingKeys()) {
            auto key = it.as!string;
            auto dir = getRequired!string(root["src-dependencies"][key], "directory", key ~ ".src-dependencies");
            config.addInclude(key, dir);
        }
    }
    void libDependencies(Node root) {
        if(!root.containsKey("lib-dependencies")) return;

        foreach(Node it; root["lib-dependencies"].mappingKeys()) {
            string key = it.as!string;
            string whichLibs = config.isDebug ? "debug-libs" : "release-libs";
            string[] libs = getArray!string(root["lib-dependencies"][key], whichLibs);

            foreach(lib; libs) {
                config.addLib(lib);
            }
        }
    }
    void linker(Node root) {
        if(!root.containsKey("linker")) return;
        Node linker = root["linker"];

        config.enableLink = getOptional!bool(linker, "enable", true);
        config.subsystem  = getOptional!string(linker, "subsystem", "console");
    }
    T getRequired(T)(Node node, string key, string context) {
        if(!node.containsKey(key)) throw new Exception("Config file is missing required key '%s.%s'".format(context, key));
        return node[key].as!T;
    }
    T getOptional(T)(Node node, string key, T orElse) {
        if(node.containsKey(key)) return node[key].as!T;
        return orElse;
    }
    // There has to be a better way to do this
    T[] getArray(T)(Node node, string key) {
        T[] array;
        Node n = node[key];
        foreach(i; 0..n.length) {
            array ~= n[i].as!T;
        }
        return array;
    }
}