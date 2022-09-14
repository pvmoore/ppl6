
pub fn testString() {
    println("testString")
    const emptyString = || {
        string s
        assert s.isEmpty()
        assert s.length==0
        assert s.ptr() as long == 0

        //s.length = 1 // readonly
    }
    const basicString = || {
        string s = "hello"
        assert not s.isEmpty()
        assert s.length==5
    }
    const indexing = || {
        string s = "hello"
        assert s[0]=='h'
        assert s[1]=='e'
        assert s[2]=='l'
        assert s[3]=='l'
        assert s[4]=='o'
        // s[1] = 'f' // not allowed
    }
    const equals = || {
        string a = "hello"
        string b = "hello"
        string c = "hello2"

        assert a == "hello"
        assert a == b
        assert a != c and b != c
    }
    const indexOf = || {
        string s = "hello"
        assert s.indexOf('l')==2
        assert s.indexOf('o')==4
        assert s.indexOf('z')==-1

        assert s.indexOf('o', 0) == 4
        assert s.indexOf('o', 1) == 4
        assert s.indexOf('o', 3) == 4
        assert s.indexOf('o', 4) == 4
        assert s.indexOf('o', 5) == -1
        assert s.indexOf('o', -1) == -1

        assert s.indexOf("ll") == 2
        assert s.indexOf("o") == 4
        assert s.indexOf("hello") == 0
        assert s.indexOf("") == -1

        assert s.indexOf("ll", -1) == -1
        assert s.indexOf("ll", 0) == 2
        assert s.indexOf("ll", 1) == 2
        assert s.indexOf("ll", 2) == 2
        assert s.indexOf("ll", 3) == -1
    }
    const startsWith = || {
        string s = "hello"
        assert s.startsWith('h')
        assert not s.startsWith('z')

        assert s.startsWith("h")
        assert s.startsWith("he")
        assert s.startsWith("hel")
        assert s.startsWith("hell")
        assert s.startsWith("hello")
        assert not s.startsWith("hello2")
    }
    const endsWith = || {
        string s = "hello"
        assert s.endsWith('o')
        assert not s.endsWith('z')

        assert s.endsWith("o")
        assert s.endsWith("lo")
        assert s.endsWith("llo")
        assert s.endsWith("ello")
        assert s.endsWith("hello")
        assert not s.endsWith("1hello")
    }
    const contains = || {
        string s = "hello"

        assert s.contains('h')
        assert s.contains('e')
        assert s.contains('l')
        assert s.contains('o')
        assert not s.contains('z')


    }
    emptyString()
    basicString()
    indexing()
    equals()
    indexOf()
    startsWith()
    endsWith()
    contains()
}
