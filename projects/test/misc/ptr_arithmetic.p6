
pub fn testPtrArithmetic() {
    struct Alpha(int a, byte b)             // 8 bytes
    @packed struct Beta(int a, byte b)   // 5 bytes

    byte* a   = 0 as byte*          ; assert a as long==0
    short* b  = 2 as short*         ; assert b as long==2
    int* c    = 4 as int*           ; assert c as long==4
    long* d   = 8 as long*          ; assert d as long==8
    float* e  = 4 as float*         ; assert e as long==4
    double* f = 8 as double*        ; assert f as long==8
    Alpha* g  = 9 as Alpha*         ; assert g as long==9
    Beta* h   = 10 as Beta*         ; assert h as long==10

    // +/-
    byte* a2 = a+1      ; assert a2 as long==1
    byte* a3 = a2-1     ; assert a3 as long==0
                        ; assert (a3+2) as long==2  // ptr + int
                        ; assert (1+a3) as long==1  // int + ptr

    short* b2 = b+1     ; assert b2 as long==4
    short* b3 = b2-1    ; assert b3 as long==2

    int* c2 = c+1         ; assert c2 as long==8
    const c3 = c2-1       ; assert c3 as long==4

    const d2 = d+1        ; assert d2 as long==16
    const d3 = d2-1       ; assert d3 as long==8

    const e2 = e+1        ; assert e2 as long==8
    const e3 = e2-1       ; assert e3 as long==4

    const f2 = f+1        ; assert f2 as long==16
    const f3 = f2-1       ; assert f3 as long==8

    const g2 = g+1        ; assert g2 as long==17
    const g3 = g2-1       ; assert g3 as long==9

    const h2 = h+1        ; assert h2 as long==15
    const h3 = h2-1       ; assert h3 as long==10

    // += / -=
    byte* a4 = a // 0
    a4 += 3             ; assert a4 as long==3
    a4 -= 1             ; assert a4 as long==2

    short* b4 = b // 2
    b4 += 3             ; assert b4 as long==8
    b4 -= 1             ; assert b4 as long==6

    int* c4 = c // 4
    c4 += 3             ; assert c4 as long==16
    c4 -= 1             ; assert c4 as long==12

    long* d4 = d // 8
    d4 += 3             ; assert d4 as long==32
    d4 -= 1             ; assert d4 as long==24

    float* e4 = e // 4
    e4 += 3             ; assert e4 as long==16
    e4 -= 1             ; assert e4 as long==12

    double* f4 = f // 8
    f4 += 3             ; assert f4 as long==32
    f4 -= 1             ; assert f4 as long==24

    Alpha* g4 = g // 9
    g4 += 3             ; assert g4 as long==24+9
    g4 -= 1             ; assert g4 as long==16+9

    Beta* h4 = h  // 10
    h4 += 3             ; assert h4 as long==15+10
    h4 -= 1             ; assert h4 as long==10+10

    // odd address
    double* z = 1 as double*
    z += 1                      ; assert z as long == 9
}
