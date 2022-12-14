
pub fn testArrays() {
    const declarations = || {
        int[3] array            ; assert array.length==3
        int[2] a                ; assert a.length==2

        int[2] b = @arrayOf(int, 1,3)
        const c  = @arrayOf(int, 7,13,17)           ; assert @typeOf(c) is int[3]
        const d  = @arrayOf(float, 1.0, 3.3, 7.0)   ; assert @typeOf(d) is float[3]

        int[9]* e1 = null
        int*[7] e2
        int[2]*[1] e3
        int*[2]*[1]* e4 = null

        const g = @arrayOf(int, 1 as int,2,3)   ; assert @typeOf(g) is int[3]
    }
    const arrayOfArray = || {
        int[3][1] a
        assert @typeOf(a[0]) is int[3]
        assert @typeOf(a[0][0]) is int
        assert @typeOf(a[0][1]) is int
        assert @typeOf(a[0][2]) is int
        assert a.length==1
        assert a[0].length==3
        assert a[0][0] == 0

        a[0][1] := 77

        const b = a[0][1]
        assert b==77
    }
    const arrayOfAnonStruct = || {
        struct(int a, float b)[2] a
        assert a.length==2
        assert @typeOf(a[0]) is struct(int,float)
        assert @typeOf(a[0][0]) is int
        assert @typeOf(a[0][1]) is float
        assert @typeOf(a[0].a) is int
        assert @typeOf(a[0].b) is float

        assert a[0][0] == 0

        const b = a[0]
    }
    const arrayOfNamedStructOfArray = || {
        struct SOA(pub int[5] array) {
            pub fn setArray(int[5] values) { this.array := values }
        }
        SOA[2] soa = @arrayOf(SOA, SOA(),SOA() )
        assert soa.length==2
        assert @typeOf(soa[0]) is SOA
        assert @typeOf(soa[1]) is SOA
        assert soa[0].array.length==5
        assert @typeOf(soa[0].array) is int[5]
        assert @typeOf(soa[1].array) is int[5]
        assert @typeOf(soa[0].array[0]) is int

        soa[0].setArray(@arrayOf(int, 1,2,3,4,5))
        soa[1].setArray(@arrayOf(int, 10,20,30,40,50))
        assert soa[0].array is @arrayOf(int, 1,2,3,4,5)

        const z1 = soa[0].array[0]
        assert z1 == 1
        assert soa[0].array[1] == 2

        assert soa[0].array is @arrayOf(int, 1,2,3,4,5)
        assert soa[1].array is @arrayOf(int, 10,20,30,40,50)
    }
    const arrayLength = || {
        int[4] a

        const len = a.length
        assert len==4

        const b = @arrayOf(int, 0,1,2,3,4,5)   ; assert @typeOf(b) is int[6]
        assert b.length == 6

        assert @arrayOf(int, 1,2,3).length==3
        assert int[5].length==5
    }
    const shouldNotCompile = || {

    }
    declarations()
    arrayOfArray()
    arrayOfAnonStruct()
    arrayOfNamedStructOfArray()
    arrayLength()
    shouldNotCompile()

    testLiteralArrays()
}

fn testLiteralArrays() {
    const test1 = || {
        // zero initialised
        int[2] array
        assert array[0] == 0
        assert array[1] == 0
        int n = 0
        assert array[n] == 0
        assert array.length==2
        assert array.subtype is int
        assert @sizeOf(array) == 8

        int[2]* ptr
        assert ptr is null

        ptr := &@arrayOf(int, 3 as int, 7)

        assert @typeOf(ptr[0]) is int[2]
        assert ptr[0][0] == 3
        assert ptr[0][1] == 7
        assert ptr.length==2
    }
    const test2 = || {
        // initialised
        int[2] array = @arrayOf(int, 5, 10)

        assert array[0] == 5
        assert array[1] == 10
        assert @typeOf(array[0]) is int
        assert @typeOf(array[1]) is int

        b = @arrayOf(int, 3, 7)
        assert @typeOf(b) is int[2]
        assert b[0] == 3
        assert b[1] == 7
    }
    const test3 = || {

    }
    const test4 = |int[2] a| {
        assert a[0] == 77
        assert a[1] == 88
    }
    const test5 = || {
        @arrayOf(int, 99,100)
        const a = @arrayOf(int, 101,102)[0]
        assert a==101
    }
    const test7 = || {

    }
    const shouldNotCompile = || {
        //int[1] a
        //b = a[1] // out of bounds

        //int[2] a = @arrayOf(int, 1,2,3) // too many values

        //int[2] a = @arrayOf(float, 1, 1f) // bad cast
    }
    test1()
    test2()
    test3()
    test4(@arrayOf(int, 77,88) as int[2])
    test5()
    test7()
    shouldNotCompile()
}
