
pub fn testSelect() {
    const switchSelectStmt = || {
        const x = 5
        n = 0
        select(x) {
            1,2,3 : n := 1
            4     : { n := 4 }
            else  : n := 10
        }
        assert n == 10

        const val = || { return 2 }

        select(int y = 2; y) {
            1    : n := 1
            //val() : n := 2     // not a const integer
            4    : n := 4
            else : n := y
        }
        assert n == 2
    }

    const switchSelectExpr = || {
        const x = 1
        const r1 = select(x) {
            0: 0
            1: {
                a = 1
                a + 10
            }
            2: 20
            3: 30
            4: 40
            else: 100
         }
         assert r1 == 11

         const r2 = select(float f = 0.1; f < 1.0) {
            true: { 1 }
            else: { 2 }
         }
         assert r2 == 1
    }
    const boolSelectStmt = || {
        n = 0
        const FALSE = false
        select {
            2<1   : n := 1
            FALSE : n := 2
            3==2  : n := 9
            else  : n := 3
        }
        assert n == 3
    }
    const boolSelectExpr = || {
        const r2 = select {
            false: 0
            false: 1
            else: 2
        }
        assert r2 == 2

        // select the first true expression
        const r3 = select {
            true: 1
            true: 2
            else: 3
        }
        assert r3 == 1
    }
    switchSelectStmt()
    switchSelectExpr()
    boolSelectStmt()
    boolSelectExpr()
}
