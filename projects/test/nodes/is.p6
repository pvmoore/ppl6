
pub fn testIs() {
    primitives()
    pointers()
    structs()
    classes()
}

fn primitives() {
    assert 0 is 0
    assert 0 is not 1

    a = true; assert a is true; assert a is not false

    b = 0
    c = 0
    d = 1
    assert b is c
    assert b is not d
}
fn pointers() {
    int a = 0
    int b = 0
    int* p1 = &a
    int* p2 = &a

    assert p1 is p2     // same address

    int* p3 = &b
    int* p4 = &b

    assert p3 is p4     // same address

    assert p1 is not p3 // point to different objects even if the object values are the same
    assert p2 is not p4 // point to different objects even if the object values are the same
}
fn structs() {
    @pod
    struct A(int a, int b)

    const a1 = A()          // a:0, b:0
    const a2 = A(a:0, b:0)
    const a3 = A(a:1, b:0)

    // These are values and the contents are the same
    assert a1 is a2

    // The contents are different
    assert a1 is not a3

    //-----------------------------

    const b1 = A*()  // heap allocated
    const b2 = A*()

    // these are pointing to different addresses
    assert b1 is not b2
    //assert b1 is not a1  both sides must be pointer or value
}
fn classes() {
    class B(int a, int b) {
        fn new(int a, int b) { /* B this, */
            this.a := a
            this.b := b
        }
    }

    // These are all pointers
    const a1 = B()          // a:0, b:0
    const a2 = B(a:0, b:0)
    const a3 = B(a:1, b:0)

    // these are pointing to different addresses
    assert a1 is not a2

    // these are pointing to different addresses
    assert a1 is not a3
}