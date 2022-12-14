
fn new() {}

pub fn testLiterals() {
    bools()
    bytes()
    shorts()
    ints()
    longs()
    halfs()
    floats()
    doubles()
    chars()
    strings()
}

fn bools() {
    bool b                  ; assert b is false
    bool b2 = true          ; assert b2
    bool b3 = true or false ; assert b3
    bool b4 = false         ; assert not b4
    bool b5 = not true      ; assert b5 is false; assert b5 == false
    //assert 1==0  // fails

}
fn bytes() {
    byte b1                 ; assert b1 == 0
    byte b2 = 100 as byte   ; assert b2 == 100
}
fn shorts() {
    short s                 ; assert s == 0
    short s2 = 1 as short   ; assert s2 == 1
}
fn ints() {
    int i                   ; assert i == 0
    int i2 = 3              ; assert i2 == 3
}
fn longs() {
    long l                  ; assert l == 0
    long l2 = 45            ; assert l2 == 45
}
fn halfs() {
    half h                  ; assert h == 0.0h
    half h2 = 3.14h         ; assert h2 == 3.14 as half
    half h3 = 3             ; assert h3 == 3.0h
}
fn floats() {
    float f                 ; assert f == 0.0
    float f2 = 3.14         ; assert f2 == 3.14
    float f3 = 3            ; assert f3 == 3.0
}
fn doubles() {
    double d                ; assert d == 0.0
    double d2 = 3.14        ; assert d2 == 3.14
    double d3 = 3.14d       ; assert d3 == 3.14 as double
    double d4 = 3           ; assert d4 == 3.0
    double d5 = 3.14d       ; assert d5 == 3.14 as double
}
fn chars() {
    int ch1 = 'a'           ; assert ch1 == 97
    int ch2 = '\n'          ; assert ch2 == 10
}
fn strings() {
    string s                ; assert s == ""    // empty string
    string s1 = "hello"     ; assert s1 == "hello"
    const s2 = r"there"     ; assert s2 == "there"

    string* s3              ; assert s3 is null

    const len = "stringy".length    ; assert len == 7
    const ptr = "stringy".ptr()     ; assert ptr

    const ch = "stringy"[0]         ; assert ch == 's'

    assert "abcd\tefg\0".length == 9
    assert r"abcd\tefg\0".length == 11

    assert "a\n"[1] == 10

    //const s4 = "a" "b" ; Need to concatenate string literals

    const multiline = """
hello
there
"""
    assert multiline.length == 16   // 1310hello1310there1310

    //"stringy"[0] = 'S' // readonly
}
