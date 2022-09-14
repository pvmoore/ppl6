# Constructors Reimagined

```ppl6
class A(int a,
        int b
        int c,
        pub int d)
{
    fn new(d, int a) {
        // implicitly added => this.d := d
        // a is a normal local variable
    }
    fn doSomething(int a) {

    }
}
```
```ppl6
[pod]
struct B(int a, int b, int c) {

    // All property constructor implicitly added unless it already exists
    fn new(a,b,c) {
        new()
        this.a := a
        this.b := b
        this.c := c
    }
}
```