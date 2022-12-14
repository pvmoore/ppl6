
import imports::imports

pub class C1(
    pub int a,
    pub static int b)
{
    pub fn print() {

    }
    pub static fn foo() {}
}

alias A1 = C1
alias A2 = C1*
alias A3 = Gremlin
alias A4 = ImportedGargoyle
alias A5 = ImportedGargoyle2
alias A6 = ImportedGargoyle*

pub fn testClasses() {

    // C1 is a pointer by default
    // C1() should return heap allocated pointer
    C1 c1 = C1()

    //A2 a2 = A2()  // Constructing C1* not allowed

    assert @isClass(C1)
    assert not @isStruct(C1)
    assert @isPointer(C1)
    assert @isPointer(@typeOf(c1))
    assert @pointerDepth(C1) == 1

    assert @isPointer(A1)
    assert @isClass(A1)
    assert not @isStruct(A1)

    assert @isPointer(A2)
    assert @pointerDepth(A2) == 2

    assert @isClass(A3)
    assert @isPointer(A3)
    assert @pointerDepth(A3) == 1

    assert @isClass(A4)
    assert @isPointer(A4)
    assert @pointerDepth(A4) == 1

    assert @isClass(A5)
    assert @isPointer(A5)
    assert @pointerDepth(A5) == 2

    assert @isClass(A6)
    assert @isPointer(A6)
    assert @pointerDepth(A6) == 2

    const c2 = &c1  // C1*
    const c3 = *c2  // C1

    //const c0 = *c1    // Dereferencing class to a value not allowed

    //const c2 = *c0    // Cannot dereference value to ptr depth -1
}