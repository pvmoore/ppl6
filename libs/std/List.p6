@module_priority(-100_000)

pub struct List <T>(
    T* array,
    int arrayLength,
    pub int length)
{
    pub fn new(int reserve) {
        this.expand(reserve)
    }

    pub fn ptr() {
        return this.array
    }
    pub fn isEmpty() {
        return this.length==0
    }
    pub fn add(T value) {
        this.expand(1)
        this.array[this.length] := value
        this.length += 1
        return this
    }
    pub fn operator[] (int index) {
        return this.array[index]
    }
    pub fn operator[] (int index, T value) {
        this.array[index] := value
    }
    pub fn operator== (List<T> other) {
        if(this.length != other.length) return false
        return memcmp(this.array, other.array, this.length*@sizeOf(T))==0
    }
    pub fn first() {
        assert this.length > 0
        return this.array[0]
    }
    pub fn last() {
        assert this.length > 0
        return this.array[this.length-1]
    }
    pub fn each(fn(T return void) closure) {
        loop(i = 0; i<this.length; i+=1) {
            closure(this.array[i])
        }
    }
    pub fn each(fn(int, T return void) closure) {
        loop(i = 0; i<this.length; i+=1) {
            closure(i,this.array[i])
        }
    }
    pub fn eachReverse(fn(T return void) closure) {
        loop(i = this.length-1; i>=0; i-=1) {
            closure(this.array[i])
        }
    }
    pub fn eachReverse(fn(int, T return void) closure) {
        loop(i = this.length-1; i>=0; i-=1) {
            closure(i, this.array[i])
        }
    }
    pub fn removeAt(int index) {
        // todo
        assert false
    }
    pub fn insertAt(int index, T value) {
        // todo
        assert false
        return this
    }
    pub fn clear() {
        this.length := 0
        return this
    }
    pub fn pack() {
        // todo
        assert false
        return this
    }
    pub fn reversed() {
        const copy = List<T>(this.length)
        loop(dest = 0, src = this.length-1; src>=0; src -= 1) {
            copy.array[dest] := this.array[src]
        }
        return copy
    }
    fn expand(int required) {
        if(required < 1) return

        if(not this.array) {
            this.arrayLength := required + 7
            this.array       := malloc(this.arrayLength*@sizeOf(T)) as T*
            assert this.array
        } else if(this.length+required > this.arrayLength) {
            this.arrayLength := (this.length+required) * 2
            this.array       := realloc(this.array, this.arrayLength*@sizeOf(T)) as T*
            assert this.array
        }
    }
}
