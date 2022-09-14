@module_priority(-900_000)

pub struct Sequence<T>() {

    pub fn hasNext() { return false }
    pub fn next() { return @initOf(T) }
}