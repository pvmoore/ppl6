

struct S(
    pub int a,
    pub int b = 1,   // This initialisation will be moved to 'new' func
    pub bool flag)
{
    pub fn new() { /*S* this*/
        // All struct var initialisers will be put in here
        // This will be called before properties are set manually during initialisation

        this.b    += 3
        this.flag := true
    }
    // rename me
    pub fn new( /*S* this,*/ int value) {
        // will call new()
        this.a := value
    }
    pub fn new( /*S* this,*/ bool flag, short sh) {
        // will call new()
        this.b    := sh
        this.flag := flag
    }
    pub fn new(float a, double b, int c) {
        // will call new()
        this.a    := a as int
        this.b    := b as int
        this.flag := c as bool
    }
    pub fn new(float a, int b) {

    }
}
struct S2() {
    // new function created automatically
}

pub fn testConstructors() {
    S s         // zero initialise
    assert s.a==0
    assert s.b==0
    assert s.flag==false

    S s2 = S()  // zero initialise
                // call new()
    assert s2.a==0
    assert s2.b==4
    assert s2.flag==true

    S* sp   // null
    S* sp2 = null
    assert sp is null

    const s3 = S(7)
    assert s3.a==7
    assert s3.b==4
    assert s3.flag==true

    const s4 = S(value:90)
    assert s4.a == 90
    assert s4.b == 4
    assert s4.flag == true

    const s5 = S(sh:3 as short, flag: false)
    assert s5.a == 0
    assert s5.b == 3
    assert s5.flag == false

    const s6 = S(b:4.2, c:0, a:9.5)
    assert s6.a == 9
    assert s6.b == 4
    assert s6.flag == false

    const s7 = S*()
    assert s7.a==0
    assert s7.b==4
    assert s7.flag==true

    const s8 = S*(8)
    assert s8.a==8
    assert s8.b==4
    assert s8.flag==true

    const s9 = S*(sh:3 as short, flag:true)
    assert s9.a == 0
    assert s9.b == 3
    assert s9.flag == true
}
