
pub fn testIf() {
    const ifStatements = || {
        i = 0

        if(true) {
            i := 1
        } else {
            i := 2
        }
        assert i == 1

        if(1 < 0.5) {
            i := 3
        } else if(1 < 1.5) {
            i := 4
        } else {
            i := 5
        }
        assert i == 4
    }
    const ifExpressions = || {
        r = if(true) 3 else 4
        assert r == 3
        assert @typeOf(r) is int

        const t = || { return true }
        const f = || { return false }

        r := if(2>=3) 5 else if(4<3) 6 else 8
        assert r == 8

        r := if(true) 1 else if(true) 2 else 3
        assert r == 1

        r := if(t()) if(t()) 1 else 0 else 2
        assert r == 1
    }
    const initExpression = || {
        int r

        if(a = 1; a > 2) {
            r := a + 0
        } else {
            r := a + 1
        }
        assert r == 2

        const w = if(float f = 3.0; @typeOf(f) is float) {
            f
        } else {
            f + 1.0
        }
        assert w == 3.0

        const x =
            if(a = false; a) 1 else
            if(bool b = true; b) {
                    2
            } else 3
        assert x == 2
    }
    const multipleInitExpr = || {
        int a = 0
        r = false
        if(b = 0, a := 1; a==1) {
            r := true
        }
        assert r

        const c = if(const b=0, float f = 3.0; b==0 and f==3.0) 1 else 2
        assert c == 1
    }
    const shadowing = || {
        if(true) {
            a = 1
        } else {
            a = 2
        }
        a = 3
    }
    ifStatements()
    ifExpressions()
    initExpression()
    multipleInitExpr()
    shadowing()
}
