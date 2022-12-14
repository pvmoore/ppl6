module ppl._1_lex.Lexer;

import ppl.internal;

final class Lexer {
private:
    Module module_;
public:
    this(Module module_) {
        this.module_ = module_;
    }
    /// FOR_IDE - if true: - include comments,
    ///                    - do not throw exceptions
    ///                    - package multiline strings 1 per line
    ///
    /// text   - the text to tokenise
    ///
    Token[] tokenise(bool FOR_IDE=false)(string text, BuildState buildState = null) {
        auto tokens    = new DynamicArray!Token(1024);
        auto buf       = new StringBuffer;
        int index      = 0;
        int indexSOL   = 0;      /// char index at start of line
        int line       = 0;
        auto startPos  = INVALID_POSITION;
        auto stack     = new Stack!int;

        if(!FOR_IDE) assert(buildState);

        ///======================================================================================
        /// Local helper functions
        ///======================================================================================
        char peek(int offset=0) {
            if(index+offset >= text.length) return 0;
            return text[index+offset];
        }
        bool isEOL() {
            return (peek()==13 && peek(1)==10) || peek()==10;
        }
        bool handleEOL() {
            if(peek()==13 && peek(1)==10) {
                /// EOL windows
                line++;
                index++;
                indexSOL = index+1;
                return true;
            } else if(peek()==10) {
                /// EOL unix/macOS
                line++;
                indexSOL = index+1;
                return true;
            }
            return false;
        }
        bool isNumber() {
            auto firstChar = buf[0];
            return firstChar =='-' || (firstChar >= '0' && firstChar <= '9');
        }
        bool isStringLiteral() {
            if(buf[0]=='\"') return true;
            if(buf.length>1 && buf[0..2] == "r\"") return true;
            if(buf.length>3 && buf[0..4] == "u16\"") return true;
            if(buf.length>3 && buf[0..4] == "u32\"") return true;
            return false;
        }
        bool isCharLiteral() {
            return buf[0]=='\'';
        }
        void addToken(TT t = TT.NONE, int length=1) {
            if(buf.length>0) {
                TT type;

                if(t.isComment() || t.isString()) type = t;
                else if(isStringLiteral())        type = TT.STRING;
                else if(isCharLiteral())          type = TT.CHAR;
                else if(isNumber())               type = TT.NUMBER;
                else type = TT.IDENTIFIER;

                assert(FOR_IDE ? true : !type.isComment());

                auto value = buf.toString().idup;
                int start  = index-cast(int)value.length;

                if(startPos!=INVALID_POSITION) {
                    // Must be a multiline string literal
                    assert(type == TT.STRING);

                    int endColumn = index-indexSOL-1;

                    tokens.add(Token.make(type, value, index-start, startPos, Position(line, endColumn)));

                    startPos = INVALID_POSITION;

                } else {
                    int startColumn = start-indexSOL;
                    int endColumn = index-indexSOL-1;

                    assert(startColumn>=0, "line = %s, column = %s, start = %s, indexSOL = %s".format(line, startColumn, start, indexSOL));

                    tokens.add(Token.make(type, value, index-start, Position(line, startColumn), Position(line, endColumn)));
                }

                buf.clear();
            }
            if(t!=TT.NONE && !t.isComment() && !t.isString()) {
                int startColumn = index-indexSOL;
                int endColumn = index-indexSOL+length-1;

                tokens.add(Token.make(t, null, length, Position(line, startColumn), Position(line, endColumn)));
            }
        }
        void addCharLiteral() {
            assert(peek()=='\'');

            addToken();

            auto col = index-indexSOL;

            buf.add(peek());
            index++;

            while(index<text.length && peek()!='\'') {
                buf.add(peek());
                if (peek()=='\\') {
                    buf.add(peek(1));
                    index++;
                }
                index++;
            }
            bool err = false;
            if(index>=text.length) {
                static if(!FOR_IDE) {
                    buildState.addError(new TokeniseError(module_, line, col, "Missing end quote '"), false);
                } else err = true;
            }
            if(!err && parseCharLiteral(buf[1..$])==-1) {
                static if(!FOR_IDE) {
                    buildState.addError(new TokeniseError(module_, line, col, "Bad character literal"), false);
                } else err = true;
            }
            if(err) {
                addToken();
                return;
            }

            assert(peek()=='\'');
            buf.add(peek());
            index++;
            addToken();
            index--;
        }
        void addStringLiteral() {
            assert(peek()=='\"');

            static if(FOR_IDE) {
                /// IDE version

                /// Handle possible prefix
                if(buf.length==1 && buf[0]=='r') {
                    /// Include the 'r' in the string
                } else {
                    addToken();
                }

                assert(peek()=='\"');
                buf.add(peek());
                index++;

                while(index<text.length && peek()!='\"') {
                    if(isEOL()) {
                        addToken(TT.STRING);
                        handleEOL();
                    } else {
                        buf.add(peek());
                        if(peek()=='\\') {
                            if(peek(1)>31) {
                                buf.add(peek(1));
                                index++;
                            }
                        }
                    }
                    index++;
                }
                if(index>=text.length) {
                    ///  We ran out of text before the end quote
                    addToken(TT.STRING);
                } else {
                    assert(peek()=='\"');
                    buf.add(peek());
                    index++;
                    addToken(TT.STRING);
                    index--;
                }
            } else {
                /// Compiler version
                auto startLine   = line;
                auto startColumn = index-indexSOL;

                /// Handle possible prefix
                if(buf.length==1 && buf[0]=='r') {
                    /// Include the 'r' in the string
                } else {
                    addToken();
                }

                assert(peek()=='\"');
                buf.add(peek());
                index++;

                bool multiline = peek()=='\"' && peek(1)=='\"';

                if(multiline) {
                    startPos = Position(line, index-1-indexSOL);
                    index+=2;

                    while(index<text.length-2 && !(peek()=='\"' && peek(1)=='\"' && peek(2)=='\"') ) {

                        if(peek()==13 && peek(1)==10) {
                            buf.add(peek());
                            line++;
                            index++;
                            indexSOL = index+1;
                        } else if(peek()==10) {
                            line++;
                            indexSOL = index+1;
                        }
                        buf.add(peek());

                        if(peek()=='\\') {
                            buf.add(peek(1));
                            index++;
                        }
                        index++;
                    }
                    index+=2;

                } else {
                    while(index<text.length && peek()!='\"') {
                        buf.add(peek());
                        if(peek()=='\\') {
                            buf.add(peek(1));
                            index++;
                        }
                        index++;
                    }
                }

                if(index>=text.length) {
                    ///  We ran out of text before the end quote
                    buildState.addError(new TokeniseError(module_, startLine, startColumn, "Missing end quote \""), false);
                }
                assert(peek()=='\"');
                buf.add(peek());
                index++;

                addToken();
                index--;
            }
        }
        void addLineComment() {
            assert(peek()=='/' && peek(1)=='/');

            addToken();

            static if(FOR_IDE) {
                /// IDE version
                stack.push(index);
                index++;
                while(index<text.length) {
                    index++;
                    if(isEOL()) {
                        buf.add(text[stack.pop()..index]);
                        addToken(TT.LINE_COMMENT);

                        handleEOL();
                        break;
                    }
                }
                if(index>=text.length) {
                    /// We ran out of text before the EOL
                    buf.add(text[stack.pop()..index]);
                    addToken(TT.LINE_COMMENT);
                }
                stack.clear();

            } else {
                /// Compiler version
                index++;
                while(index<text.length) {
                    index++;
                    if(isEOL()) {
                        handleEOL();
                        break;
                    }
                }
            }
        }
        void addMultilineComment() {
            assert(peek()=='/' && peek(1)=='*');

            addToken();

            static if(FOR_IDE) {
                /// IDE version
                stack.push(index);

                while(index<text.length) {
                    index++;

                    if(peek()=='*' && peek(1)=='/') {
                        index++;

                        assert(stack.length==1);
                        index++;

                        buf.add(text[stack.pop()..index]);
                        addToken(TT.MULTILINE_COMMENT);

                        index--;
                        break;
                    }
                    if(isEOL()) {
                        assert(stack.length==1);

                        buf.add(text[stack.pop()..index]);
                        addToken(TT.MULTILINE_COMMENT);

                        handleEOL();
                        stack.push(index+1);
                    }
                }
                if(index>=text.length) {
                    /// We ran out of text before the end of the comment
                    buf.add(text[stack.pop()..index]);
                    addToken(TT.MULTILINE_COMMENT);
                }
                stack.clear();

            } else {
                /// Compiler version
                auto startLine   = line;
                auto startColumn = index-indexSOL;

                while(index<text.length) {
                    index++;

                    if(peek()=='*' && peek(1)=='/') {
                        index++;
                        break;
                    }
                    if(isEOL()) {
                        handleEOL();
                    }
                }
                if(index>=text.length) {
                    /// We ran out of text before the end of the comment
                    buildState.addError(new TokeniseError(module_, startLine, startColumn, "Missing end of comment"), false);
                }
            }
        }
        ///=========================================================================================
        /// End of of local helper functions
        ///=========================================================================================

        for(index=0; index<text.length; index++) {
            auto ch = text[index];
            //writefln("[%s] %s", index, ch);
            switch(ch) {
                case 0:..case 32:
                    /// whitespace
                    addToken();
                    handleEOL();
                    break;
                case '#':
                    addToken(TT.HASH);
                    break;
                case '/':
                    if(peek(1)=='*') {
                        addMultilineComment();
                    } else if(peek(1)=='=') {
                        addToken(TT.DIV_ASSIGN, 2);
                        index++;
                    } else if(peek(1)=='/') {
                        addLineComment();
                    } else {
                        addToken(TT.DIV);
                    }
                    break;
                case '\'':
                    addCharLiteral();
                    break;
                case '"':
                    addStringLiteral();
                    break;
                case '*':
                    if(peek(1)=='=') {
                        addToken(TT.MUL_ASSIGN, 2);
                        index++;
                    } else {
                        addToken(TT.ASTERISK);
                    }
                    break;
                case '%':
                    if(peek(1)=='=') {
                        addToken(TT.MOD_ASSIGN, 2);
                        index++;
                    } else {
                        addToken(TT.PERCENT);
                    }
                    break;
                case '{':
                    addToken(TT.LCURLY);
                    break;
                case '}':
                    addToken(TT.RCURLY);
                    break;
                case '[':
                    if(peek(1)=='[') {
                        addToken(TT.DBL_LSQBRACKET, 2);
                        index++;
                    } else {
                        addToken(TT.LSQBRACKET);
                    }
                    break;
                case ']':
                    if(peek(1)==']') {
                        addToken(TT.DBL_RSQBRACKET, 2);
                        index++;
                    } else {
                        addToken(TT.RSQBRACKET);
                    }
                    break;
                case '(':
                    addToken(TT.LBRACKET);
                    break;
                case ')':
                    addToken(TT.RBRACKET);
                    break;
                case '<':
                    if(peek(1)=='>') {
                        addToken(TT.BOOL_NE, 2);
                        index++;
                    } else if(peek(1)=='=') {
                        addToken(TT.LTE, 2);
                        index++;
                    } else if(peek(1)=='<' && peek(2)=='=') {
                        addToken(TT.SHL_ASSIGN, 3);
                        index+=2;
                    } else if(peek(1)=='<') {
                        addToken(TT.SHL, 2);
                        index++;
                    } else {
                        addToken(TT.LANGLE);
                    }
                    break;
                case '>':
                    if(peek(1)=='=') {
                        /// >=
                        addToken(TT.GTE, 2);
                        index++;
                    } else if(peek(1)=='>' && peek(2)=='=') {
                        /// >>=
                        addToken(TT.SHR_ASSIGN, 3);
                        index+=2;
                    } else if(peek(1)=='>' && peek(2)=='>' && peek(3)=='=') {
                        /// >>>=
                        addToken(TT.USHR_ASSIGN, 4);
                        index+=3;
                    } else {
                        /// Keep '>' tokens separate so that we can parse
                        /// List<List<int>> correctly
                        /// We will need to merge tokens when determining >> and >>> operators.
                        ///
                    //} else if(peek(1)=='>' && peek(2)=='>' ) {
                    //    addToken(TT.USHR, 3);
                    //    index+=2;
                    //} else if(peek(1)=='>') {
                    //    addToken(TT.SHR, 2);
                    //    index++;
                    //} else {
                        addToken(TT.RANGLE);
                    }
                    break;
                case '=':
                    if(peek(1)=='=') {
                        addToken(TT.BOOL_EQ, 2);
                        index++;
                    } else {
                        addToken(TT.EQUALS);
                    }
                    break;
                case '!':
                    if(peek(1)=='=') {
                        addToken(TT.BOOL_NE, 2);
                        index++;
                    } else if(peek(1)=='!') {
                        addToken(TT.DBL_EXCLAMATION, 2);
                        index++;
                    } else {
                        addToken(TT.EXCLAMATION);
                    }
                    break;
                case '&':
                    if(peek(1)=='=') {
                        addToken(TT.BIT_AND_ASSIGN, 2);
                        index++;
                    } else {
                        addToken(TT.AMPERSAND);
                    }
                    break;
                case '^':
                    if(peek(1)=='=') {
                        addToken(TT.BIT_XOR_ASSIGN, 2);
                        index++;
                    } else {
                        addToken(TT.HAT);
                    }
                    break;
                case '|':
                    if(peek(1)=='=') {
                        addToken(TT.BIT_OR_ASSIGN, 2);
                        index++;
                    } else {
                        addToken(TT.PIPE);
                    }
                    break;
                case ':':
                    if(peek(1)==':') {
                        addToken(TT.DBL_COLON, 2);
                        index++;
                    } else if(peek(1)=='=') {
                        addToken(TT.COLON_EQUALS, 2);
                        index++;
                    } else {
                        addToken(TT.COLON);
                    }
                    break;
                case ';':
                    addToken(TT.SEMICOLON);
                    break;
                case ',':
                    addToken(TT.COMMA);
                    break;
                case '+':
                    if(peek(1)=='=') {
                        addToken(TT.ADD_ASSIGN, 2);
                        index++;
                    } else {
                        addToken(TT.PLUS);
                    }
                    break;
                case '-':
                    if(buf.length == 0 && peek(1).isDigit) {
                        buf.add(ch);
                    } else if(peek(1)=='=') {
                        addToken(TT.SUB_ASSIGN, 2);
                        index++;
                    } else if(peek(1)=='>') {
                        addToken(TT.RT_ARROW, 2);
                        index++;
                    } else {
                        addToken(TT.MINUS);
                    }
                    break;
                case '.':
                    if(buf.length > 0 && isNumber() && peek(1).isDigit) {
                        buf.add(ch);
                    } else {
                        addToken(TT.DOT);
                    }
                    break;
                case '?':
                    addToken(TT.QMARK);
                    break;
                case '~':
                    addToken(TT.TILDE);
                    break;
                case '$':
                    addToken(TT.DOLLAR);
                    break;
                case '@':
                    addToken(TT.AT);
                    break;
                default:
                    buf.add(ch);
                    break;
            }
        }
        addToken();
        return tokens[];
    }
}
