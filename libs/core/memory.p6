// This module should be first
@module_priority(-1_000_000)

pub alias Destructor = fn(void*)

struct tgc_ptr_t(
    void* ptr,
    int flags,
    long size,
    long hash,
    Destructor dtor
)
struct tgc_t(
    void* bottom,
    int paused,
    long* minptr,
    long* maxptr,
    tgc_ptr_t* items,
    tgc_ptr_t* frees,
    double loadfactor, double sweepfactor,
    long nitems, long nslots, long mitems, long nfrees
)

extern fn tgc_start(tgc_t* gc, void* stk)
extern fn tgc_stop(tgc_t* gc)
extern fn tgc_pause(tgc_t* gc)
extern fn tgc_resume(tgc_t* gc)
extern fn tgc_run(tgc_t* gc)

extern fn tgc_alloc      (tgc_t* gc, long size return void*)
extern fn tgc_calloc     (tgc_t* gc, long num, long size return void*)
extern fn tgc_realloc    (tgc_t* gc, void* ptr, long size return void*)
extern fn tgc_alloc_opt  (tgc_t* gc, long size, int flags, Destructor dtor return void*)
extern fn tgc_calloc_opt (tgc_t* gc, long num, long size, int flags, Destructor dtor return void*)
extern fn tgc_free       (tgc_t* gc, void* ptr)

extern fn tgc_set_flags (tgc_t* gc, void* ptr, int flags)
extern fn tgc_get_flags (tgc_t* gc, void *ptr return int)

extern fn tgc_get_size (tgc_t* gc, void* ptr return long)

extern fn tgc_set_dtor ( tgc_t* gc, void* ptr, Destructor dtor)
extern fn tgc_get_dtor ( tgc_t* gc, void* ptr return Destructor)

// todo - This needs to be thread-local
tgc_t gc

pub struct GC(
    static long numAllocs,
    static long numFrees,
    static long totalAlloced)
{
    fn hello() {

    }
    fn there() {
        this.hello()
    }
    pub static fn start() {
        int local
        tgc_start(&gc, &local)
    }
    pub static fn stop() {
        tgc_stop(&gc)
    }
    pub static fn collect() {
        tgc_run(&gc)
    }
    pub static fn alloc(long size) {
        GC.numAllocs    += 1
        GC.totalAlloced += size
        return tgc_alloc(&gc, size)
    }
    pub static fn alloc(long size, Destructor d) {
        GC.numAllocs    += 1
        GC.totalAlloced += size
        return tgc_alloc_opt(&gc, size, 0, d)
    }
    pub static fn calloc(long size) {
        GC.numAllocs    += 1
        GC.totalAlloced += size
        return tgc_calloc(&gc, 1, size)
    }
    pub static fn calloc(long size, Destructor d) {
        GC.numAllocs    += 1
        GC.totalAlloced += size
        return tgc_calloc_opt(&gc, 1, size, 0, d)
    }
    pub static fn realloc(void* ptr, long size) {
        return tgc_realloc(&gc, ptr, size)
    }
    pub static fn free(void* ptr) {
        GC.numFrees += 1
        tgc_free(&gc, ptr)
    }
    pub static fn getSize(void* ptr) {
        return tgc_get_size(&gc, ptr)
    }
    pub static fn dump() {
        println("")
        println("")
        println("== GC Stats =====================")
        print("Num allocs ... "); print(GC.numAllocs); print(" ("); print(GC.totalAlloced/1); println(" bytes)")
        print("Num Frees .... "); println(GC.numFrees)
        println("=================================")
    }
}

pub fn new() {

}

