module ppl._2_parse.ParseHelper;

import ppl.internal;

final class ParseHelper {
public:
    ///
    /// "<" param { "," param } ">"
    ///
    static bool isTemplateParams(Tokens t, int offset, ref int endOffset) {
        assert(t.peek(offset).kind == TT.LANGLE);

        bool result = false;
        t.markPosition();
        int startOffset = t.index();
        t.next(offset);

        outer:while(!result) {
            /// <
            if(t.kind() != TT.LANGLE) break;
            t.next();

            /// param
            if(t.kind() != TT.IDENTIFIER) break;
            t.next();

            while(t.kind() != TT.RANGLE) {
                /// ,
                if(t.kind() != TT.COMMA) break outer;
                t.next();

                /// param
                if(t.kind() != TT.IDENTIFIER) break outer;
                t.next();
            }

            /// >
            if(t.kind() != TT.RANGLE) break;

            result = true;
        }
        endOffset = t.index() - startOffset;
        t.resetToMark();
        return result;
    }
    ///
    /// "|" [ params ] "|" "{"
    ///
    static bool isLambdaParams(Tokens t, ASTNode node, int offset) {
        assert(t.peek(offset).kind == TT.PIPE);

        /// "|" "|" must be a lambda
        if(t.peek(offset+1).kind == TT.PIPE) return true;

        /// id      [ , | ]
        /// type id [ , | ]

        auto typeDetector = t.module_.typeDetector;
        offset++;

        while(true) {

            int end = typeDetector.endOffset(t, node, offset);
            if(end!=-1) {
                /// type
                offset += end+1;
            }

            if(t.peek(offset).kind != TT.IDENTIFIER) return false;
            offset++;

            auto tt = t.peek(offset).kind;
            if(tt==TT.PIPE) return true;
            if(tt!=TT.COMMA) return false;

            /// comma
            offset++;
        }
    }
}
