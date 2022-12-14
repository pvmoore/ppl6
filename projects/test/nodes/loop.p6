
pub fn testLoop() {
    const whileLoop = || {
        i = 3
        count = 0
        loop( ; i>0; ) {
            i -= 1
            count += 1
        }
        assert count == 3
        assert i == 0
    }
    const forLoop = || {
        count = 0
        loop(i = 10; i>0; i-=1) {
            count += 1
        }
        assert count == 10
    }
    const forLoop2 = || {
        count  = 0
        int count2
        loop(i = 10, count2 := 10;
            i>0;
            i-=1, count2 -= 1)
        {
            count += 1
        }
        assert count  == 10
        assert count2 == 0
    }
    const withContinue = || {
        count1 = 0
        count2 = 0
        count3 = 0
        loop(int i=0; i<10; i+=1, count3+=2) {
            count1 += 1

            if(i<5) continue

            count2 += 1
        }
        assert count1 == 10
        assert count2 == 5
        assert count3 == 20
    }
    const withBreak = || {
        count1 = 0
        count2 = 0
        count3 = 0
        loop(i=10; i>0; i-=1, count3+=2) {
            count1 += 1
            if(i<5) break
            count2 += 1
        }
        assert count1 == 7
        assert count2 == 6
        assert count3 == 12
    }
    whileLoop()
    forLoop()
    forLoop2()
    withContinue()
    withBreak()
}
