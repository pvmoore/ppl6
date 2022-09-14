module ppl.ppl6;

import ppl.internal;

final class PPL6 {
    static shared PPL6 _instance;
    this() {}
public:
    static auto instance() {
        auto i = cast(PPL6)atomicLoad(_instance);
        if(!i) {
            i = new PPL6;
            atomicStore(_instance, cast(shared)i);
        }
        return i;
    }
    ProjectBuilder createProjectBuilder(Config config) {
        return new ProjectBuilder(g_llvmWrapper, config);
    }
    IncrementalBuilder createIncrementalBuilder(Config config) {
        return new IncrementalBuilder(g_llvmWrapper, config);
    }
}
