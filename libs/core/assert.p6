@module_priority(-900_000)

pub fn __assert(bool result, byte* moduleName, int line) {
    if(@expect(not result, false)) {
        print("ERROR: Assertion failed at ")
        print(moduleName)
        print(":")
        println(line)
        exit(-1)
    }
}
