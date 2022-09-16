module ppl.version_;

public:

enum VERSION = "6.5.0";

/*

6.5.0 -

6.4.0 - Use Filepath, Filename and Directory in Config
        Added requirement that constructor calls with more than one argument must use named arguments

6.3.0 - Remove files from the target directory before compiling
        Change attribute syntax from '--pod' to '@pod'

6.2.0 - Don't add null check for this.* if we are inside a struct/class method
        Remove 'var'
        Rename Token 'type' property to 'kind' which is less ambiguous
        Add 'toSrcString' method to Type for use in template inference
        Move folding code from ResolveModule to FoldModule
        Refactor BuildState. Move parse/resolve/fold to a new class ParseResolveFoldPass

6.1.0 - Remove Access enum, add 'isPublic' property to various classes

6.0.0 - Initial clone from PPL3.
        Add YamlConfigReader (config file is now yml format)
        Remove toml configuration
        Write .ast files without Logger timings and add syntax highlighting extension for them.
        Fix bug where class members could not be reassigned: this.a := a caused check failure

░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒░▒▓▒

  TODO - TODO - TODO - TODO - TODO - TODO - TODO - TODO - TODO - TODO - TODO - TODO - TODO - TODO

░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓

    -- Use github wiki

    -- Can't make any further progress when the arg name is wrong but the function can be found
       We need a better error message for this:
    ```
    return string(ptr: list.ptr(), offset: 0, length: list.length)

    Couldn't make any further progress
        core::string[line 0] DOT: Dot [type=?]
        core::string[line 0] CALL: Call 'new'
    ```



  -- Remove const and add var|mut for mutable variables
     This may benefit from the 'name : Type' enhancement
     How do we handle struct/class members that are assigned in the constructor and then become const?
     This assignment should be allowed if it is in a constructor?

  -- Add type to be explicitly set after the variable name ie a:int = 3

  -- Add unsigned integers (ubyte,ushort,uint and ulong)

  // Implement LiteralMap @mapOf(string,int, key:value, key:value)

  - Create C backend. Put source files in c/ directory.

  - Add UFCS (Do default arguments before this)

  - enum flags E {} allow &,|,^ operations but no other on these
    Normal enums don't allow any arithmetic

  - allow names in function types?
  - allow function/constructor default values?

  - why are we adding function import proxies to module and not to an import node?
    [Use ModuleAlias for imported functions and structs]

  // We need to add any struct/enum etc to the template module as a reference
      (I don't remember what this one is about)

  - Add formatted string f"My name is ${name}, age ${04f:age}"
  - Implement raw strings which don't interpret backslash escapes r"string"

  - Add checks if boundsChecks=true

  - Use fast math option when generating code
  - Ensure only basic optimisations get done if we are in DEBUG mode

  - allow code blocks eg.
  b = {
      // statements
      final expression implicitly supplies any result
  }
    This may make groovy-style method parameters ambiguous

  - lambda captures?
  - fat pointers?


  - Change to constructors? Maybe remove constructors and use static functions to create
    instances. Keep the simple POD construction unless explicitly disabled for a class/struct
    eg. A.new(123)
    Also, constructors for structs might not be a good idea anyway. Maybe these should always
    be PODs.
        1) Structs are always POD - remove POD attribute
        1a) This implies - Structs only have default new() constructor and are constructed
            as MyStruct(a: 1, b:2)


TODO Compiler:

    - Add integration tests folder and create a script to run through all tests in the folder,
      asserting compiler errors.

    - Add coroutine intrinsics eg. @coroPrelude, @coroHandle, @coroSuspend, @coroResume


    - Cache debug ir, optimised ir and bc for modules. Store keyed by a sha1 of the
      program args and the update timestamp.


    - Rename loop to for?
    - Fold for/loop (wait for syntax change?)

    ** Change 'loop' to 'for' eg.
        - for(i in 0..10) {}
        - for(i in @range(0,10,1)) {}
            struct Range<T>(T start, T end, T step)

TODO Lib:
    - Create a work-stealing thread pool in libs/core or libs/std using coroutines
    - Implement @mapOf, @listOf



TODO Known bugs:
(Check that these are still bugs to be fixed)

- ParseExpression/ParseConstructor
    If the type is an alias we may not know at that point whether or not it is a ptr.
    We should write the constructor code in ResolveConstructor instead after the type is resolved.

- Infinite struct should not be allowed:

    struct A {
        A a
    }

- Cryptic IR generation error produced:

    var c = A::ONE
    assert c.value = 1      // = instead of ==

- Assert this

    struct A {
        foo {
            assert this     // <--- error
        }
    }

- Should be able to determine type of null
    func {
        if(int a=0; true) return &a
        return null // <--- int*
    }

-   Determine type of null here:
    call(null)

-   config.enableOptimisation = false produces link errors

-   fn indexOf(string s) {
        indexOf(s, 0)   // this.indexOf(s,0) works
    }

 */
