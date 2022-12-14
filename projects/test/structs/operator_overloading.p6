
struct Red(pub int a) {
    pub fn new(int a)       { this.a := a }
    pub fn reset(int value) { this.a := value }

    pub fn test() {
        this.a := 0

		assert this.operator!=(1)
		assert this.operator!=(Red(1))
		assert this.operator!=(Red*(2))

		assert this.operator==(0)
		assert this.operator==(Red(0))
		assert this.operator==(Red*(0))
    }

    // get
    pub fn operator[](int index) {
        return index*2
    }
    // set
    pub fn operator[](int index, int value) {
        this.a := index*value
    }

    // scalar comparison
    pub fn operator==(int s) { return this.a==s }
    pub fn operator!=(int s) { return this.a!=s }

    // object comparison
    pub fn operator==(Red s)  { return this.a==s.a }
	pub fn operator==(Red* s) { return this.a==s.a }
    pub fn operator!=(Red s)  { return this.a!=s.a }
	pub fn operator!=(Red* s) { return this.a!=s.a }
}

pub fn testOperatorOverloading() {
	const comparison = || {
		@pod struct C(int a) {
			pub fn operator==(C other)  { return this.a==other.a }
			pub fn operator==(C* other) { return this.a==other.a }
			pub fn operator==(int b)    { return this.a==b }
			pub fn operator!=(C other)  { return this.a != other.a }
			pub fn operator!=(C* other) { return this.a != other.a }
			pub fn operator!=(int b)    { return this.a != b }
		}
		a = C(1)
		b = C(2)
		c = C(1)
		d = C*(1)
		e = C*(10)

		assert a == c
		assert a == d
		assert a != b
		assert a != e
		assert a == 1
		assert a != 2
		assert e == 10
		assert e == C*(10)
		assert e != 11
		assert e != C*(100)

		assert 1 == a
		assert 2 != a
		assert 10 == e
		assert 11 != e
		assert C*(10) == e
		assert C*(75) != e
	}
	const comparisonAlternative = || {
		// define operator== but not operator!=
		@pod struct C(int a) {
			pub fn operator==(C other)  { return this.a==other.a }
			pub fn operator==(C* other) { return this.a==other.a }
			pub fn operator==(int b)    { return this.a==b }
		}
		a = C(22)
		b = C(40)
		c = C(22)
		d = C*(22)
		e = C*(90)

		assert a != b		// call not (a==b)
		assert a != 23		// call not (a==23)
		assert 23 != a		// call not (a==23)
		assert a != e		// call not (a==e)
		assert e != a		// call not (e==a)
	}
	const index = || {
		Red a = Red(100)
        Red b

        assert a[10] == 20              // index*2
        a[10] := 3;  assert a.a == 30    // index*value

	}
	const internal = || {
        Red r
        r.test()
    }
	const objectPtr = || {
        v  = Red*(0);    		assert v.a==0
        v2 = v.operator==(1);   assert v2==false

        // These are ptr arithmetic
        Red* v3 = v + 1;
        Red* v4 = v - 1;
    }
	comparison()
	comparisonAlternative()
	index()
	internal()
	objectPtr()
}

