module ppl.ast.stmt.Statement;

import ppl.internal;

abstract class Statement : ASTNode {

    final string lineStr() {
        return line() !=-1 ? " [line=%s]".format(line()) : "";
    }
}