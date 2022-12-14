module ppl._1_lex.Tokens;

import ppl.internal;

final class Tokens {
private:
    Token[] tokens;
    int pos = 0;
    Stack!int marks;
    Attribute[] attributes;
public:
    Module module_;
    bool isTemplateExpansion;    // true if these tokens have been added as a template expansion
    bool isPublic;

    this(Module module_, Token[] tokens) {
        this.module_  = module_;
        this.tokens   = tokens;
        this.marks    = new Stack!int;
        this.isPublic = false;
        reset();
    }
    auto reuse(Module module_, Token[] tokens) {
        this.module_ = module_;
        this.tokens  = tokens;
        return reset();
    }
    auto reset() {
        this.pos = 0;
        this.marks.clear();
        this.isPublic = false;
        return this;
    }
    void setLength(int len) {
        if(tokens.length > len) {
            tokens.length = len;
        }
    }
    //=======================================
    void markPosition() {
        marks.push(pos);
    }
    void resetToMark() {
        pos = marks.pop();
    }
    void discardMark() {
        marks.pop();
    }
    //=======================================
    void setAccessPublic(bool isPublic) {
        this.isPublic = isPublic;
    }
    //=======================================
    void addAttribute(Attribute a) {
        attributes ~= a;
    }
    Attribute[] getAttributesAndClear() {
        auto copy = attributes.dup;
        attributes.length = 0;
        return copy;
    }
    //=======================================
    int index()    { return pos; }
    int line()     { return get().line; }
    int column()   { return get().column; }
    TT kind()      { return get().kind; }
    string value() { return get().value; }

    Token get() {
        if(pos >= tokens.length) return NO_TOKEN;
        return tokens[pos];
    }
    Token[] opSlice() {
        return tokens;
    }
	Token[] opSlice(ulong from, ulong to) {
        return tokens[from..to];
    }
    Token peek(int offset) {
        if(pos+offset < 0 || pos+offset >= tokens.length) return NO_TOKEN;
        return tokens[pos+offset];
    }
    int length() {
        return tokens.length.as!int;
    }
    bool isKeyword(string k) {
        return kind()==TT.IDENTIFIER && value()==k;
    }
    bool isKind(TT k) {
        return kind() == k;
    }
    bool isOneOf(TT[] kinds...) {
        auto ky = kind();
        foreach(k; kinds) if(k==ky) return true;
        return false;
    }
    bool onSameLine(int offset = 0) {
        auto a = peek(offset).line;
        auto b = peek(offset-1).line;
        return a!=-1 && b!=-1 && a==b;
    }
    //=======================================
    void next(int numToMove=1) {
        pos += numToMove;
    }
    void prev(int numToMove=1) {
        pos -= numToMove;
    }
    void skip(TT t) {
        if(kind()!=t) module_.addError(this, "Expecting %s".format(t.toString()), false);
        next();
    }
    void skip(string kw) {
        if(value()!=kw) module_.addError(this, "Expecting %s".format(kw), false);
        next();
    }
    void expect(string[] keywords...) {
        foreach(kw; keywords) if(value()==kw) return;
        module_.addError(this, "Expecting one of %s".format(keywords), false);
    }
    void expect(TT[] kinds...) {
        foreach(k; kinds) if(kind()==k) return;
        module_.addError(this, "Expecting one of %s".format(kinds.toString()), false);
    }
    void dontExpect(TT[] kinds...) {
        foreach(k; kinds) if(kind()==k) {
            module_.addError(this, "Not expecting %s".format(k), false);
        }
    }
    bool hasNext() {
        return pos < tokens.length;
    }
    int find(TT t) {
        int offset = 0;
        while(pos+offset < tokens.length) {
            if(peek(offset).kind==t) return offset;
            offset++;
        }
        return -1;
    }
    ///
    /// Find a Token kind in the current scope. If the scope ends by reaching
    /// an unopened close bracket of any type then it will return -1;
    ///
    int findInScope(TT t, int offset=0) {
        int cbr = 0, sqbr = 0, br = 0;
        while(pos+offset < tokens.length) {
            auto ty = peek(offset).kind;
            if(cbr+sqbr+br==0 && ty==t) return offset;
            switch(ty) {
                case TT.LBRACKET: br++; break;
                case TT.RBRACKET: if(--br<0) return -1; break;
                case TT.LCURLY: cbr++; break;
                case TT.RCURLY: if(--cbr<0) return -1; break;
                case TT.LSQBRACKET: sqbr++; break;
                case TT.RSQBRACKET: if(--sqbr<0) return -1; break;
                default: break;
            }
            offset++;
        }
        return -1;
    }
    ///
    /// Find any of keywords in the current scope. If the scope ends by reaching
    /// an unopened close bracket of any type then it will return -1;
    ///
    int findInScope(Set!string keywords) {
        int offset = 0;
        int cbr = 0, sqbr = 0, br = 0;
        while(pos+offset < tokens.length) {
            auto tok = peek(offset);
            auto ty  = tok.kind;
            if(cbr+sqbr+br==0 && ty==TT.IDENTIFIER && keywords.contains(tok.value)) return offset;
            switch(ty) {
                case TT.LBRACKET: br++; break;
                case TT.RBRACKET: if(--br<0) return -1; break;
                case TT.LCURLY: cbr++; break;
                case TT.RCURLY: if(--cbr<0) return -1; break;
                case TT.LSQBRACKET: sqbr++; break;
                case TT.RSQBRACKET: if(--sqbr<0) return -1; break;
                default: break;
            }
            offset++;
        }
        return -1;
    }
    bool scopeContains(TT t) {
        return findInScope(t) !=-1;
    }
    ///
    /// Returns the offset of the closing bracket.
    /// Assumes we are currently at the opening bracket or before it.
    /// Returns -1 if the end bracket is not found.
    ///
    int findEndOfBlock(TT brtype, int startOffset=0) {
        auto open  = brtype;
        auto close = open==TT.LBRACKET   ? TT.RBRACKET   :
                     open==TT.LSQBRACKET ? TT.RSQBRACKET :
                     open==TT.LCURLY     ? TT.RCURLY     :
                     open==TT.LANGLE     ? TT.RANGLE     : TT.NONE;
        assert(close!=TT.NONE, "brtype=%s".format(brtype));
        int braces = 0;
        for(int offset=startOffset; pos+offset < tokens.length; offset++) {
            auto kind = peek(offset).kind;
            if(kind==open) {
                braces++;
            } else if(kind==close) {
                braces--;
                if(braces==0) return offset;
            }
        }
        return -1;
    }
}
