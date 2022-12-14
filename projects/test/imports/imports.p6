
import imports::imports2
import imp = imports::imports4

pub fn testImports() {
	println("testImports()")
	const func = || { return -1 }
	assert -1 == func()

	assert 1 == imp.func()
	assert 2 == imp.func2<int>(2)
	assert 2 == imp.func2(2.1)

	alias Wabbit  = imp.Rabbit
	alias Wabbits = imp.Rabbit*
	Wabbit wabbit
	Wabbits wabbits

	imp.Rabbit rabbit
	imp.Rabbit* rabbits
	const rabbit2 = imp.Rabbit()
	assert @typeOf(rabbit2) is imp.Rabbit

	assert 12 == imp.Rabbit.b
	assert 11 == imp.Rabbit.bar(1)

	alias Wadger  = imp.Badger<int>
	alias Wadgers = imp.Badger<float>*
	Wadger wadger
	Wadgers wadgers
	assert @typeOf(wadger) is imp.Badger<int>
	assert @typeOf(wadgers) is imp.Badger<float>*

	assert 22 == imp.Badger<int>.b
	assert 21 == imp.Badger<int>.bar(10)
	assert 23 == imp.Badger<double>.baz<bool>(3.1, true)

	//imp.Badger<int>().a = 80        // can not modify
	//imp.Badger<float>.b = 81      // can not modify

	//const rabbitC = imp.Rabbit().c	// rabbit.c is private
	//const rabbitD = imp.Rabbit.d		// rabbit.d is private static

	br1 = imp.Badger<int>.b   == 80
	br2 = imp.Badger<float>.b == 81.0

	imp.Skunk<imp.Rabbit*> skunkRabbit
	imp.Skunk<imp.Rabbit*>* skunkRabbit2

	const skr = imp.Skunk<imp.Rabbit>.a
}

pub struct Dog(pub int age)
pub struct Cat(pub bool isGinger)
pub struct Bat(pub float size)
pub struct Pig(pub int weight)
pub struct Wolf(pub bool isGrey)
pub struct Rose <T>(pub T a)

pub alias AnInt = int
pub alias IntPtrPtr = IntPtr*
pub alias ANiceRose = OrangeRose
pub alias BlueRose = RedRose<bool>

pub fn importedFunc() {

}

// global function templates
pub fn tfunc<T>(T a) {
    return 200
}
pub fn tfunc<A,B>(A a, B b) {
    return 202
}
pub fn tfunc(float f) {
    return 201
}

pub struct M3 <T>(
    pub T t)
{
    pub fn foo(T a) {
        return 270
    }
    pub fn foo<A>(A a, T t) {
        return 271
    }
    pub fn foo<A,B>(A a, B b) {
        return 272
    }
}

pub class Gremlin() {

}
pub alias ImportedGargoyle = Gargoyle
pub alias ImportedGargoyle2 = Gargoyle*