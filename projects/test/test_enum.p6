
// Element type is int
enum A {
    ONE,        // 0
    TWO,        // 1
    THREE = 5,  // 5
    FOUR,       // 6
    FIVE = 2,   // 2
    SIX         // 3
}
// Element type is byte
enum B : byte {
    ONE,        // 0
    TWO,        // 1
    THREE       // 2
}
enum C : float {
    ONE,        // 0.0
    TWO = 10,   // 10.0
    THREE       // 11.0
}
enum D : long {
    ONE   = 1 << 0,     // 1
    TWO   = 1 << 1,     // 2
    THREE = 1 << 2,     // 4
    FOUR  = 1 << 3      // 8
}
//enum D : bool {}
//enum E : int* {}
//enum G : String {}
//enum G : String* {}

//enum Nope <T> { ONE}           // No template params allowed
//enum Nope2 : void { ONE }      // void not allowed
//enum Nope3 {}                  // Cannot be empty

pub fn testEnum() {
    const initialisation = || {
        const a = A.SIX;    assert @typeOf(a) is A
                            assert a.value == 3
        const b = a;        assert @typeOf(b) is A
                            assert b.value == 3
        const c = A.FIVE.value; assert @typeOf(c) is int
                                assert c == 2

        A d
        A e = A.THREE          ; assert e.value == 5
        //A f = A             // nope
        //A g = B::ONE        // incompatible types

        C f = C.THREE          ; assert @typeOf(f.value) is float;  assert f.value == 11.0
    }
    const comparison = || {
        // is
        // Must be exact enum type and value
        const a = A.ONE is A.ONE        ; assert a
        const b = A.ONE is not A.TWO    ; assert b
        const c = A.ONE is not B.ONE    ; assert c

        // booleans
        // Compares values regardless of enum type
        const g  = A.ONE == B.ONE               ; assert @typeOf(g) is bool; assert g
        const g2 = A.ONE != B.TWO               ; assert @typeOf(g2) is bool; assert g2
        const g3 = A.ONE.value < A.TWO.value    ; assert g3
        const g4 = A.THREE > A.TWO              ; assert g4
        const h = A.SIX
        const i = B.TWO
        assert h == A.SIX
        assert h >= i
    }
    const conversion = || {
        // rewritten --> A.THREE.value as int
        const a = A.THREE as int; assert a == 5

        // New EnumMember created with value 4
        const b = 4 as A;   assert @typeOf(b) is A
                            assert b == 4
                            assert b.value == 4

        // cast to different enum not allowed
        //const c = A.FOUR as B
    }
    const manipulation = || {
        const a = A.TWO + A.TWO     ; assert @typeOf(a) is A;    assert a.value == 2
        b   = D.ONE | D.TWO         ; assert @typeOf(b) is D;    assert b.value == 3
        A c = A.TWO + 1             ; assert c.value == 2

        c := c + A.TWO               ; assert c.value == 3

        // op assign
        b += D.THREE                ; assert @typeOf(b) is D;    assert b.value == 7
        b += 1                      ; assert @typeOf(b) is D;    assert b.value == 8

        const d = D.ONE | D.TWO | D.THREE
            assert @typeOf(d) is D
            assert d.value == 7
    }
    const misc = || {
        assert @sizeOf(A) == 4
        assert @sizeOf(A.ONE) == 4

        alias A2 = A
        A2 a2 = A.ONE;   assert @typeOf(a2) is A

        const a = A.TWO; assert @typeOf(a) is A; assert a == 1
    }
    const functionParams = || {
        const foo  = |int a| { return 0 }
        const foo1 = |A a| { return 1 }
        const foo2 = |B b| { return 2 }
        const foo3 = |A a, B b| { return 3+a+b }

        assert 0 == foo(1)
        assert 1 == foo1(A.ONE)
        assert 2 == foo2(B.TWO)
        foo1(A.ONE | A.TWO)
        assert 3+5+0 == foo3(A.THREE, B.ONE)
    }
    const properties = || {
        assert A.length == 6
        assert B.length == 3
        assert C.length == 3
        assert D.length == 4
    }
    const constValues = || {
        const VALUE = 3
        enum Enum {
            A = VALUE
        }
        assert Enum.A == 3
    }
    const imported = || {
        import imports::imports2
        Colour col = Colour.GREEN;     assert col == 1
    }
    initialisation()
    comparison()
    conversion()
    manipulation()
    misc()
    functionParams()
    properties()
    constValues()
    imported()
}
