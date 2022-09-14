module ppl.build.ParseResolveFoldPass;

import ppl.internal;

/**
 *  Run a single pass of Parse/Resolve/Fold
 */
final class ParseResolveFoldPass {
private:
    bool nodesModified;
    Set!int unresolved;
public:
    Set!int getUnresolved() {
        return unresolved;
    }
    bool isResolved() {
        return unresolved.length==0;
    }
    bool isModified() {
        return nodesModified;
    }
    void runSinglePass(Module[] modules, bool stalemate) {
        nodesModified = false;
        unresolved = new Set!int;

        // Reset fold count
        foreach(m; modules) {
            m.folder.reset();
        }

        parseModules(modules);
        resolveModules(modules, stalemate);
        foldModules(modules);
    }
private:
    void parseModules(Module[] modules) {
        foreach(m; modules) {
            if(!m.isParsed()) {
                m.parser.parse();
            }
        }
    }
    void resolveModules(Module[] modules, bool isStalemate) {

        //int numUnresolvedModules = 0;

        foreach(m; modules) {

            bool resolved  = m.resolver.resolve(isStalemate);
            nodesModified |= m.resolver.isModified();

            unresolved.add(
                m.resolver.getUnresolvedNodes().map!(it=>it.nid).array
            );

            // if(resolved) {
            //     //log("\t.. %s is resolved", m.canonicalName);
            // } else {
            //     //log("\t.. %s is unresolved", m.canonicalName);
            //     numUnresolvedModules++;
            // }
        }
        //log("There are %s unresolved modules, %s unresolved nodes", numUnresolvedModules, unresolved.length);
    }
    void foldModules(Module[] modules) {
        foreach(m; modules) {
            if(m.folder.foldModule()) {
                nodesModified = true;
                m.resolver.setASTModified();
            }
        }
    }
}