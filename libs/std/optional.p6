@module_priority(-100_000)

/**
 *
 */
pub struct Optional<T>(
    T value,
    pub bool exists)
{
    pub fn new() {
        // empty
    }
    pub fn new(T value) {
        this.exists := true
        this.value  := value
    }

    pub fn get(return T) {
        return if(this.exists) this.value else @initOf(T)
    }
    pub fn getOr(T other return T) {
        return if(this.exists) this.value else other
    }

    pub fn then(fn(T t return void) doThis return Optional<T>) {
        if(this.exists) doThis(this.value)
        return *this
    }
    pub fn else(fn(return void) doThis) {
        if(not this.exists) doThis()
    }
}