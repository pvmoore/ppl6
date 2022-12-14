
import imports::imports

struct Thing(int value) {
    fn new(int value) { this.value := value }
}

struct M1() {
    pub fn foo(Thing a) {
        return 10
    }
    pub fn foo<T>(T a) {
        return 20
    }
    pub fn foo<A,B>(A a, B b) {
        return 30
    }
    pub fn foo0<A>(int a, int b, struct(A,A) c) {
        return 40
    }
    pub fn foo0<A>(int a, fn(A,A return A) b) {
        return 50
    }
    pub fn bar() {
        // calls foo(float)
        assert 10 == this.foo(Thing(1))

        // calls this.foo<double>
        assert 20 == this.foo<double>(4.5)
        // calls this.foo<int,float>
        assert 30 == this.foo<int, float>(1,2.0)

        // calls foo<double>(double)
        assert 20 == this.foo(3.1d)
        // calls foo<int,int>(int,int)
        assert 30 == this.foo(1,2)

        // foo()     // Not found
        //this.foo()  // No 0 arg func or template

        assert 1 == func<byte>(1 as byte)   // calls func<byte>(byte)
        assert 2 == func(1 as byte)          // calls func(float)

        // implicit
        assert 40 == this.foo0(1, 1, @structOf(1,1) )
        assert 50 == this.foo0(1, |int a, int b| {return a+b} )
    }
}

struct M2 <T>(pub T t) {
    pub fn foo<F>(F a) {
        return 100
    }
    pub fn foo<A,B>(A a, B b) {
        return 101
    }
    pub fn foo(float f) {
        return 102
    }
}
//struct BadTemplate <int> {}

pub fn testTemplateFunctions() {
    const globals = || {
        // templated function
        assert 1 == func<int>(3)
        assert 1 == func<float>(3.1)
        assert 3 == func<int,double>(1,2.2)
        // untemplated function
        assert 2 == func(3.2)

        // imported templated function
        assert 200 == tfunc<bool>(true)
        assert 202 == tfunc<double,float>(1.0,2.0)
        // imported untemplated function
        assert 201 == tfunc(3.1)
    }
    const structs = || {
        M1 m = M1()
        // templated function
        assert 20 == m.foo<double>(3.1d)
        assert 20 == m.foo<byte>(4 as byte)
        assert 30 == m.foo<double,int>(2.1, 4)
        // m.foo(Thing)
        assert 10 == m.foo(Thing(1))

        // can bar to test struct->struct funcs
        m.bar()

        // templated struct
        M2<double> m2 = M2<double>()
        assert 100 == m2.foo<short>(18 as short)
        assert 101 == m2.foo<bool,int>(false,2)
        assert 102 == m2.foo(4.3)

        // imported struct
        m3 = M3<int>()
        assert 270 == m3.foo(2)
        assert 271 == m3.foo<float>(3.1, 3)
        assert 272 == m3.foo<int,bool>(6,true)
    }
    const implicitStandard = || {
        // there is no func(double)
        // but there is a func<T>(T)
        assert 1 == func(40.0d)
        assert 3 == func(true, false)

        //func(1,2,3)   // No template exists with 3 args
        //func()        // No 0 arg func or template

        // calls func<int>(int*)
        int* a
        assert 4 == func<int>(a)

        assert 5 == func2(1, 1, @structOf(1,1) ) // <int>(int,int,[int,int])
        assert 5 == func2<float>(1,1, @structOf(1.1, 2.2) )

        assert 6 == func2(1, |float a, float b| {return a+b})   // <float>(int,{float,bool}*)
        assert 6 == func2<byte>(2 as byte, |byte a, byte b| {return 1 as byte})

        assert 7 == func3(@arrayOf(int, 1,2), 3d) // func3<int,double>(int[2])
        assert 7 == func3<float,bool>(@arrayOf(float, 1.1,2.2), true)
    }
    const implicitStruct = || {
        M1 m1

        // there is no foo(float)
        // call template foo<T>(T)
        assert 20 == m1.foo(3.1)

        // call template foo<A,B>(A,B)
        assert 30 == m1.foo(1, true)

        //m1.foo(1,2,3) // No template exists with 3 args
        //m1.foo()      // No 0 arg func or template


    }
    //badTemplate = <M1> {}

    globals()
    structs()
    implicitStandard()
    implicitStruct()
}

fn func<T>(T a) {
    return 1
}
fn func<T>(T* a) {
    return 4
}
fn func<A,B>(A a, B b) {
    return 3
}
fn func2<A>(int a, int b, struct(A,A) c) {
    return 5
}
fn func2<A>(int a, fn(A,A return A) c) {
    return 6
}
fn func3<A,B>(A[2] a, B b) {
    return 7
}
fn func(float a) {
    return 2
}
