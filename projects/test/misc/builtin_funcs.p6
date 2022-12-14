
pub fn testBuiltinFuncs() {
    const sizeOf = || {
        byte a = 0 as byte;     assert 1 == @sizeOf(a)
        int b = 0;              assert 4 == @sizeOf(b)
        double c = 0;           assert 8 == @sizeOf(c)
        struct(int,bool) d;     assert 8 == @sizeOf(d)  // [4,4]

        struct A()                  // align 1
        struct B(byte a)            // align 1
        struct C(short a, byte b)   // align 2
        struct D(int a, byte b)     // align 4
        struct E(double a, byte b)  // align 8

        assert @sizeOf(A) == 0
        assert @sizeOf(B) == 1
        assert @sizeOf(C) == 4      // 2+2
        assert @sizeOf(D) == 8      // 4+4
        assert @sizeOf(E) == 16     // 8+8

        assert 4  == @sizeOf(0)
        assert 12 == @sizeOf(@arrayOf(int, 1,2,3))
        assert 16 == @sizeOf(@structOf(1,2,3,4) as struct(int,int,int,int))
    }
    const alignOf = || {
        assert @alignOf(byte) == 1
        assert @alignOf(short) == 2
        assert @alignOf(int) == 4
        assert @alignOf(long) == 8
        assert @alignOf(half) == 2
        assert @alignOf(float) == 4
        assert @alignOf(double) == 8
        assert @alignOf(struct(int,byte)) == 4      // tuple
        assert @alignOf(byte[1]) == 1               // array

        struct A()
        struct B(byte a)
        struct C(short a, byte b)
        struct D(int a, byte b)
        struct E(double a, byte b)

        assert @alignOf(A) == 1
        assert @alignOf(B) == 1
        assert @alignOf(C) == 2
        assert @alignOf(D) == 4
        assert @alignOf(E) == 8
    }
    const typeOf = || {
        assert @typeOf(0)      is int
        //assert @typeOf(double) is double   // @typeOf(type) invalid

        @typeOf(0) a            ; assert @typeOf(a) is int
        @typeOf(1+1.1) b        ; assert @typeOf(b) is float

        alias A = @typeOf(1+1)  ; assert A is int
        alias B = @typeOf(A)    ; assert B is int

        const func = |@typeOf(0) x| {
            return x+1
        }
        assert 7 == func(6)
    }
    const initOf = || {
        assert @initOf(int) is 0
        assert @initOf(float) is 0.0
        assert @initOf(byte*) is null
    }
    const isPointer = || {
        assert @isPointer(int*)
        assert @isPointer(int**)
        assert not @isPointer(int)

        int a
        int* b
        assert not @isPointer(a)
        assert @isPointer(b)
    }
    const isValue = || {
        assert @isValue(int)
        assert not @isValue(int*)
        assert not @isValue(int**)

        int a
        int* b
        assert @isValue(a)
        assert not @isValue(b)
    }
    const isInteger = || {
        assert @isInteger(10)
        assert @isInteger(int)
        assert not @isInteger(3.1)
    }
    const isReal = || {
        assert @isReal(3.1)
        assert @isReal(float)
        assert not @isReal(3)
    }
    const isStruct = || {
        struct A()
        A a
        assert @isStruct(A)
        assert @isStruct(a)
        assert not @isStruct(3)
        assert not @isStruct(3.1)
    }
    const isFunction = || {
        struct A()
        const f = || {}

        assert @isFunction(testBuiltinFuncs)
        assert @isFunction(@typeOf(testBuiltinFuncs))
        assert not @isFunction(f)
        assert not @isFunction(@typeOf(f))
        assert not @isFunction(1)
        assert not @isFunction(1.1)
        assert not @isFunction(A)
    }
    const isFunctionPtr = || {
        struct A()
        const f = || {}
        assert @isFunctionPtr(f)
        assert @isFunctionPtr(@typeOf(f))
        assert not @isFunctionPtr(testBuiltinFuncs)
        assert not @isFunctionPtr(@typeOf(testBuiltinFuncs))
        assert not @isFunctionPtr(1)
        assert not @isFunctionPtr(1.1)
        assert not @isFunctionPtr(A)
    }
    const expect = || {
        v = 1
        if(@expect(v==2, false)) {

        }
        const a = 10
        const b = @expect(10, a)
        const c = @expect(a, 10)

        const d = true
        const e = @expect(d, true)

        const f = @expect(10, 10 as short)
    }
    sizeOf()
    alignOf()
    typeOf()
    initOf()
    isPointer()
    isValue()
    isInteger()
    isReal()
    isStruct()
    isFunction()
    expect()
}
