
pub struct A(
    pub int a         = 1,
    pub static int sa = 2)
{
    pub fn foo(/*A* this*/) { return 1 }
    pub static fn sfoo() { return 2 }
    pub enum Enum { ONE=3 }

    pub struct B(
        pub int b         = 3,
        pub static int sb = 4)
    {
        pub fn foo(/*B* this*/) { A a; return 3 }
        pub static fn sfoo() { return 4 }
        pub enum Enum { ONE=4 }

        pub struct C(
            pub int c         = 5,
            pub static int sc = 6)
        {
            pub fn foo(/*C* this*/) { A ac; B bc; return 5 }
            pub static fn sfoo() { return 6 }
            pub enum Enum { ONE=5 }

            pub struct D(
                pub int d         = 7,
                pub static int sd = 8)
            {
                pub fn foo(/*D* this*/) { A ad; B bd; C cd; return 7 }
                pub static fn sfoo() { return 8 }
                pub enum Enum { ONE=6 }
            }
        }
    }
    // For external testing. E is pub
    pub struct E(
        int a            = 98,
        static int b     = 99,
        pub int c        = 100,
        pub static int d = 101)

    // For external testing. F is private
    struct F(
        int a        = 102,
        static int b = 103
    )
    // private enum
    enum G { ONE }
}
//====================================================================================
pub struct TA <T1>(
    pub T1 a         = 1,
    pub static T1 sa = 2)
{
    pub fn foo() /*TA* this*/ { return 10 }
    pub static fn sfoo() { return 20 }

    pub struct B(pub T1 b = 3)
    pub enum Enum : T1 { ONE=2 }

    pub struct TB <T2>(
        pub T1 a = 100,
        pub T2 b = 4,
        pub static T2 sb = 5)
    {
        pub fn foo() /*TB* this*/ { return 30 }
        pub static fn sfoo() { return 40 }

        pub struct C(pub T2 c = 6)
        pub enum Enum : T2 { ONE=3 }

        pub struct TC <T3>(
            pub T1 a         = 200,
            pub T2 b         = 300,
            pub T3 c         = 7 as T3,
            pub static T3 sc = 8 as T3)
        {
            pub fn foo() /*TC* this*/ { return 50 }
            pub static fn sfoo() { return 60 }

            pub struct D(pub T3 d = 9 as T3)
            pub enum Enum : T3 { ONE=4 }

            pub struct TD <T4>(
                pub T1 a = 300,
                pub T2 b = 400,
                pub T3 c = 500,
                pub T4 d = 10,
                pub static T4 sd = 11)
            {
                pub fn foo() /*TD* this*/ { return 70 }
                pub static fn sfoo() { return 80 }

                pub struct E(pub T4 e = 7)
                pub enum Enum : T4 { ONE=5 }
            }
        }
    }
    // For external testing. TE is pub
    pub struct TE <T5>(
        pub int a = 50,
        pub static int b = 51,
        int c = 52,
        static int d = 53
    )

    // For external testing. TF is private
    struct TF <T6>(
        int a = 54,
        static int b = 55
    )
}
//====================================================================================
pub fn testInnerStructs() {
    const groundLevel = || {
        A aa
        //B b   // not visible
        //C c   // not visible
        //D d   // not visible
        const t  = A()
        assert 1 == t.a
        assert 2 == A.sa
        assert 1 == t.foo()
        assert 2 == A.sfoo()

        A::Enum e = A::Enum.ONE;  assert e.value==3

        TA<int> aaa
        const t2 = TA<int>()
        assert 1 == t2.a
        assert 2 == TA<int>.sa
        assert 10 == t2.foo()
        assert 20 == TA<int>.sfoo()

        TA<int>::Enum e2 = TA<int>::Enum.ONE; assert e2.value==2
    }
    const level1 = || {
        //A.B ab2   // identifier B not found

        A::B aa
        const t = A::B()
        //var a = t.a         // not visible
        //var sa = A::B.sa    // not visible
        assert 3 == t.b
        assert 4 == A::B.sb
        assert 3 == t.foo()
        assert 4 == A::B.sfoo()

        A::B::Enum e = A::B::Enum.ONE;  assert e.value==4

        TA<int>::B t2 = TA<int>::B()
        assert 3 == t2.b

        assert TA<int>::TB<float>::Enum.ONE==3

        TA<int>::TB<float> t3 = TA<int>::TB<float>()
        assert 4.0 == t3.b
        assert 100 == t3.a
        assert 5.0 == TA<int>::TB<float>.sb
        assert 30 == t3.foo()
        assert 40 == TA<int>::TB<float>.sfoo()

        // TA<int>::C t4        // inner type C not found

        const ae = A::E()
        //assert ae.a == 98  // private
        //assert A::E.b == 99 // private
        assert ae.c == 100
        assert A::E.d == 101

        //const af = A::F()     // private
        //assert af.a == 102    // private
        //assert A::F.b == 103  // private
    }
    const level2 = || {
        A::B::C abc
        alias ABC = A::B::C
        ABC abc3

        const t = A::B::C()
        assert 5 == t.c
        assert 6 == A::B::C.sc
        assert 5 == t.foo()
        assert 6 == A::B::C.sfoo()

        assert 5 == A::B::C::Enum.ONE

        const tt = TA<int>::TB<long>::C()
        assert 6 == tt.c

        const ttt = TA<int>::TB<float>::TC<byte>()
        assert 7 == ttt.c
        assert 200 == ttt.a
        assert 300.0 == ttt.b
        assert 8 == TA<int>::TB<float>::TC<byte>.sc
        assert 50 == ttt.foo()
        assert 60 == TA<int>::TB<float>::TC<byte>.sfoo()
    }
    const level3 = || {
        A::B::C::D a
        const t = A::B::C::D()
        assert 7 == t.d
        assert 8 == A::B::C::D.sd
        assert 7 == t.foo()
        assert 8 == A::B::C::D.sfoo()

        assert 6 == A::B::C::D::Enum.ONE

        const tt = TA<int>::TB<long>::TC<int>::D()
        assert 9 == tt.d

        const ttt = TA<int>::TB<int>::TC<long>::TD<float>()
        assert 10.0 == ttt.d
        assert 11.0 == TA<int>::TB<int>::TC<long>::TD<float>.sd
        assert 70 == ttt.foo()
        assert 80 == TA<int>::TB<int>::TC<long>::TD<float>.sfoo()
    }
    groundLevel()
    level1()
    level2()
    level3()

    import structs::inner_structs2
    testExternalInnerStructs()
}
