
pub fn testEscapees() {
    //rets()
    arguments()
}

fn rets() {
    const variables = || {
        // simple local values
        const bad1a = || {
            int a
            return &a   // bad
        }
        const bad1b = || {
            int[1] b
            return &b   // bad
        }
        const bad1c = || {
            struct(int,int) c
            return &c   // bad
        }
        const bad1d = || {
            struct D(int a)
            D d
            return &d   // bad
        }
        // nested local
        const bad2 = || {
            if(int a=0; true) return &a // bad
            return null as int*
        }
        // local ref to local alloca
        const bad3 = || {
            int a
            int* ptr = &a
            return ptr    // bad
        }
        const bad4 = || {
            int a
            int* b = &a
            c = b
            if(false) return c  // bad
            c := null
            return c    // ok
        }
        // no local alloca
        const ok1 = || {
            int* a
            return a    // ok
        }
        const ok2 = || {
            return null as int* // ok
        }
        bad1a()
        bad1b()
        bad1c()
        bad1d()
        bad2()
        bad3()
        bad4()
        ok1()
        ok2()
    }
    const structMembers = || {
        struct A(int a, int b)
        struct B(int a, int* b)
        const bad1 = || {
            A a
            return &a.b // bad
        }
        const bad2 = || {
            A a
            int* ptr = &a.a
            return ptr  // bad
        }
        const bad3 = || {
            B b
            return &b.b // bad - address of int*
        }
        const ok1 = || {
            B b
            return b // ok is value
        }
        const ok2 = || {
            B b
            return b.b  // ok - b.b is an int* value
        }
        const ok3 = || {
            B* b
            return b    // ok
        }
        bad1()
        bad2()
        bad3()
        ok1()
        ok2()
        ok3()
    }
    const tupleMembers = || {
        const bad1 = || {
            struct(int a, int b) t
            return &t.a // bad
        }
        const bad2 = || {
            struct(int a, int* b) t
            return &t.b     // bad
        }
        const ok1 = || {
            struct(int a, int* b) t
            return t.b    // ok int* value
        }
        const ok2 = || {
            struct(int a, int b) t
            return t.a   // ok
        }
        const ok3 = || {
            struct(int a, int b) t
            return t[0]     // ok
        }
        const ok4 = || {
            struct(int* a, int b) t
            return t[0]     // ok
        }
        const bad3 = || {
            struct(int* a, int b) t
            return &t[0]     // bad
        }
        bad1()
        bad2()
        bad3()
        ok1()
        ok2()
        ok3()
        ok4()
    }
    const arrayMembers = || {
        const bad1 = || {
            int[3] array
            return &array[0]    // bad
        }
        const ok1 = || {
            int[3] array
            return array[0]    // ok
        }
        const ok2 = || {
            int*[3] array
            return array[0] // ok - value
        }
        const bad2 = || {
            int*[3] array
            return &array[0] // bad
        }
        const ok3 = || {
            int* ptr = GC.alloc(3) as int*
            return ptr[1]   // ok
        }
        bad1()
        bad2()
        ok1()
        ok2()
        ok3()
    }
    const literalArrays = || {
        const bad1 = || {
            int[3] a = @arrayOf(int, 1,2,3)
            return &a           // bad
        }
        const bad2 = || {
            return &@arrayOf(int, 1,2,3)     // bad
        }
        const ok1 = || {
            return @arrayOf(int, 1,2,3)      // ok
        }
        const bad3 = || {
            return &@arrayOf(int, 1,2,3)[1]    // bad
        }
        bad1()
        bad2()
        bad3()
        ok1()
    }
    const literalTuples = || {
        const bad1 = || {
            return &(@structOf(1,2) as struct(int,int))  // bad
        }
        const ok1 = || {
            return @structOf(1,2) as struct(int,int)   // ok
        }
        bad1()
        ok1()
    }
    variables()
    structMembers()
    tupleMembers()
    arrayMembers()
    literalArrays()
    literalTuples()
}

fn arguments() {
    const one = |int* p| {

    }
    one(null)
}



