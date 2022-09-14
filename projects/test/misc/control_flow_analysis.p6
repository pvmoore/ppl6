

pub fn controlFlowAnalysis() {
    a = cfa_f1()
}

extern fn rand(return int)

fn flipflop() { return rand() > 5 }

fn cfa_f1(return int) {
    if(a=0; flipflop()) return a

    // comment the next line
    return 0
}