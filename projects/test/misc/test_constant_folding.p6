
// everything in this function should be removable
fn foobar() {
    // if
    const A = 1
    if(A==1) {
        b = 2
    }

    // select non-expr
    select {
        true : {}
        else : { @ctUnreachable() }
    }

    // select expr
    const SEVEN = 7
    const B = select(A) {
        0    : { 3.1 }
        1    : { SEVEN }
        else : { 2 }
    }
    @ctAssert(B==7)
}

pub fn testConstantFolding() {

    foobar()

    binaryExpressions()
    unaryExpressions()
    arrayInit()
    ifStatements()
    ifExpressions()
    selectExpressions()

    // Should not compile:

    //const int D        // needs initialiser
    //const const X = 1  // 'const' specified twice
    //A += 1             // modifying const

    import misc::test_constant_folding2
    testConstantFolding2()
}
fn binaryExpressions() {
    const A = (((1 + (2))));    assert A == 3
    const B = 2 + A;            assert B == 5

    const long D = 10/2;    assert D == 5
    const int E  = 3*5;     assert E == 15
    const F  = 9%2;         assert F == 1
    const F2 = 9/2;         assert F2 == 4;     assert @typeOf(F2) is int
    const F3 = 9/2.0;       assert F3 == 4.5;   assert @typeOf(F3) is float
    const G  = 1+4;         assert G == 5
    const H  = 3-2;         assert H == 1

    const int I = 1 << 2;                    assert I == 4
    const int J = 0xff00_0000 as int >> 1;   assert J == 0xFF80_0000 as int
    const int K = 0xff00_0000 as int >>> 1;  assert K == 0x7F80_0000 as int

    const L = 1 < 2;    assert L
    const M = 1 > 2;    assert not M
    const N = 1 <= 1;   assert N
    const O = 1 >= 1;   assert O
    const P = 1 == 1;   assert P
    const Q = 1 != 1;   assert not Q

    const R = 0 & 0xff; assert R == 0
    const S = 1 ^ 0xff; assert S == 0xfe
    const T = 0 | 0xff; assert T == 0xff

    const U = true and false;   assert U is false
    const V = (true or false);  assert V is true

    // Should not compile:
    //const R1 = 1.0 << 1    // invalid
    //const R1 = 1.0 & 0xff  // invalid
}
fn unaryExpressions() {
    const W = 1 - -10;  assert W==11

    const woo = 1
    waa = -woo + (3 - ~3 as int);   assert waa==6
    wii = not true; assert wii is false

    const OK = -1.0
    // Should not compile:
    //const BAD = ~1.0
    //const BAD = not 1.0
}
fn arrayInit() {
    const ARRAY_LEN = 2
    int[ARRAY_LEN] array
        assert @typeOf(array) is int[2]

    const L1 = 1
    const L2 = L1+1
    int[L1][L2] array2
        assert @typeOf(array2) is int[1][2]
}
fn ifStatements() {
    if(true) {
        // If this block is folded, it needs to be put into a Container that is not scanned for variables
        // otherwise there will be a name collision with the 'a' declared later
        a = 1
    } else {
        a = 2
    }
    a = 3
}
fn ifExpressions() {
    const nonExprs = || {
        const VAL = 1
        i = 0
        if(true) {
            i += 1
        }
        assert(i==1)
        if(false) {
            i += 1
        }
        assert i==1
        if(1 + VAL == 2) {
            i += 1
        }
        assert i==2
        if(true) { i+=1 } else { i+=2 }
        assert i==3
        if(false) { i+=1 } else { i+=2 }
        assert i==5
    }
    const exprs = || {
        const a = if(true) 1 else 2;                    @ctAssert(a==1)
        const b = if(false) 3 else 4;                   @ctAssert(b==4)
        const c = if(true) 1 else if(true) 2 else 3;    @ctAssert(c==1)
        const d = if(true) 1 else if(false) 2 else 3;   @ctAssert(d==1)
        const e = if(false) 1 else if(true) 2 else 3;   @ctAssert(e==2)
        const f = if(1>2) 1 else if(2>3) 2 else 3;      @ctAssert(f==3)

        const g = if(int aa=0; true) aa else 7

        const j = 1
        const h = if(int aa=j; false) aa else 7

        @ctAssert(h==7)
    }
    nonExprs()
    exprs()
}
fn selectExpressions() {
    const A = select {
        true : 1
        else : 2
    }
    @ctAssert(A==1)
}