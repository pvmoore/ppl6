@module_priority(-100_000)

fn new() {

}

struct FilePath(
    pub string directory,
    pub string filename)
{
    pub fn new(string fullPath) {
        // todo
        assert false
    }
    pub fn new(string directory, string filename) {
        this.directory := directory
        this.filename := filename
    }

    pub fn isFile() { return false }
    pub fn isDirectory() { return false }
}

struct File(
    pub FilePath path)
{
    pub fn exists() { return false }
}
