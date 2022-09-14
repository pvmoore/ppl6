@module_priority(-100_000)

pub fn println(bool b) {
    print(b);
    putchar(10)
}
pub fn println(long n) {
    print(n);
    putchar(10)
}
pub fn println(string s) {
    print(s.ptr(), s.length)
    putchar(10)
}
pub fn println(byte* ptr, long len) {
    print(ptr, len)
    putchar(10)
}
//
pub fn print(bool b) {
    if(b) print("true")
    else print("false")
}
pub fn print(long n) {
    List<byte> list

    if(n<0) {
        print("-")
        n := -n
    } else if(n==0) {
        print("0")
        return
    }
    loop(int i; n>0; n /= 10) {
        const mod = n%10
        list.add(('0' + mod) as byte)
    }
    list.eachReverse |ch| {
        putchar(ch)
    }
}
pub fn print(double n) {
    // todo
    print("TODO")
}
pub fn print(string s) {
    print(s.ptr(), s.length)
}
pub fn print(byte* bytes) {
    if(not bytes) return
    print(bytes, strlen(bytes))
}
pub fn print(byte* bytes, long length) {
    if(not bytes) return
    loop(long i; i<length; i+=1) {
        putchar(bytes[i])
    }
}
