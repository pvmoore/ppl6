@module_priority(-900_000)

fn new() {

}

pub fn __nullCheckFail(byte* moduleName, int line) {
    print("###############################################\n")
    print("ERROR: Null pointer dereferenced at ")
    print(moduleName)
    print(":")
    println(line)
    print("###############################################")
    exit(-1)
}
