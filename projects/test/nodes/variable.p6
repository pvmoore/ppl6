

pub fn testVariables() {
    const basicTypes = || {
        bool a
        bool a1  = true
        bool* a2 = &a1      ; assert *a2 == true

        byte b
        byte b1  = 1 as byte
        byte b2  = b1
        byte* b3 = &b2      ; assert *b3 == 1

        short c
        short c1  = 2 as short
        short* c2 = &c1     ; assert *c2 == 2

        int d
        int d1   = 3
        int* d2  = &d1      ; assert *d2 == 3
        int** d3 = &d2      ; assert @typeOf(*d3) is int*
                              assert @typeOf(**d3) is int
                              assert **d3 == 3
        int d4 = 0b0000_1111; assert d4 == 15
        int d5 = 0xffff;      assert d5 == 65535


        half e
        half e1 = 1.1h

        float f
        float f1 = 1.1

        double g
        double g1 = 1.2d

        long h
        long h1 = 4

        const i = 0   ; assert @typeOf(i) is int

        //var var X = 1  // var specified twice
    }
    const anonStructs = || {
        struct(int) a
        struct(int a) a1

        struct(float, int)     b
        struct(float a, int b) b1
        struct(float a, int)   b2
        struct(float, int b)   b3

        struct(float) c = @structOf(1.3)
        const c1 = &c      ; assert @typeOf(c1) is struct(float)*
                             assert @typeOf(*c1) is struct(float)
                             assert *c1 == @structOf(1.3)
        const c2 = &c1     ; assert @typeOf(c2) is struct(float)**

    }
    const namedStructs = || {
        struct A(pub float a = 9)
        A a
        A a1   = A()
        A* a2  = &a1    ; assert @typeOf(a2) is A*   ; assert (*a2).a == 9.0
        A** a3 = &a2    ; assert @typeOf(a3) is A**  ; assert (**a3).a == 9.0
    }
    const arrays = || {
        int[1] a
        double[2] b

        const COUNT = 1
        int[COUNT] c        ; assert c.length==1

        int[3] d = @arrayOf(int, 1,2,3)   ; assert @typeOf(d) is int[3]

        float[2] e   = @arrayOf(float, 5.0, 7.0)
        float[2]* e1 = &e       ; assert @typeOf(e1) is float[2]*    ; assert (*e1)[0]==5.0
        const e2     = &e1      ; assert @typeOf(e2) is float[2]**   ; assert (**e2)[0]==5.0
    }
    declarations()
    initialisations()
    basicTypes()
    anonStructs()
    namedStructs()
    arrays()
}

fn declarations() {
    bool z   ; assert z == false
    byte a   ; assert a == 0
    short b  ; assert b == 0
    int c    ; assert c == 0
    long d   ; assert d == 0

    float e  ; assert e == 0.0
    double f ; assert f == 0.0

    z1 = true       ; assert @typeOf(z1) is bool; assert z1
    a1 = 1 as byte  ; assert @typeOf(a1) is byte; assert a1 == 1
    b1 = 1 as short ; assert @typeOf(b1) is short; assert b1 == 1
    c1 = 1 as int   ; assert @typeOf(c1) is int; assert c1 == 1
    d1 = 1 as long  ; assert @typeOf(d1) is long; assert d1 == 1

    e1 = 1 as float ; assert @typeOf(e1) is float; assert e1 == 1.0
    f1 = 1 as double; assert @typeOf(f1) is double; assert d1 == 1.0
}
fn initialisations() {
    bool a = true
    byte b = 1
    short c = 1
    int d = 1
    long e = 1
    float f = 1
    double g = 1
}