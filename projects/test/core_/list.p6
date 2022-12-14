
pub fn testList() {
    println("Test ... List<T>")
    println(r"hello")

    List<int> list

    assert list.isEmpty()
    assert list.length==0

    list.add(1)
        .add(2)
        .add(3)
        .add(4)
        .add(5)
        .add(6)
        .add(7)
        .add(8)
        .add(9)

    print(list.length)
    //print(list.arrayLength)

    print(list[3])
    list[3] := 90
    print(list[3])

    print(list.first())
    print(list.last())

    println("each(T):")
    list.each |a| { print(a) }

    println("each(int,T):")
    list.each |i,a| {
        print(a)
    }

    println("eachReverse(T):")
    list.eachReverse |a| {
        print(a)
    }
    println("eachReverse(int,T):")
    list.eachReverse |i, a| {
        print(a)
    }
}
