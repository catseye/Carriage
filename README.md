Carriage
========

This is the long-missing reference distribution for Carriage.

The following text was adapted from [the esowiki entry on Carriage](https://esolangs.org/wiki/Carriage),
which is in the public domain.

- - - -

**Carriage** is a concatenative programming language designed by Chris Pressey
in mid-November 2012.  It is the result of trying to devise a "pure"
concatenative language, i.e. one where the rule "concatenation = function
composition" is taken to be strictly literal and universal (with no exceptions
such as allowing nested quoted programs.) It falls short of
that goal somewhat, but it has some mildly unusual properties, so it is presented
here as an esoteric programming language.

Note that this article describes Carriage version 0.1.  It will not be version 1.0
until the author assures himself that there are no more instructions that are needed
to write simple programs, and no fatal flaws.

### State

The state of a Carriage program is a stack of unbounded size.  Each element on
the stack may be of one of three types:

*   an unbounded integer
*   a function which takes stacks to stacks
*   an instruction symbol

### Syntax

Carriage defines nine instruction symbols.  Each instruction symbol has an
interpretation as a function which takes stacks to stacks.

Any sequence of instructions (including an entire Carriage program) has two
interpretations:

*   the *code interpretation*, which is the composition of the functions
    represented by each of the instruction symbols, in the manner of
    concatenative languages.  For example, if the instruction symbol `A`
    has the interpretation f(s), and the instruction symbol `B` has the
    interpretation g(s), then the sequence `AB` has the interpretation
    g(f(s)). A sequence of length zero is taken to be the identity function.
*   the *data interpretation*, where the sequence of instruction symbols
    is taken to be a stack of instruction symbols, with the first symbol
    in the sequence at the bottom of the stack.  A sequence of length
    zero is taken to be an empty stack.

Whitespace has no meaning; the code interpretation of whitespace is the
identity function, and the data interpretation does not introduce any
instruction symbol onto the stack.  However, attempting to take the code
interpretation of any other symbol which is not defined by Carriage
will cause the program to explode.

### Semantics

Evaluation of a Carriage program can be summed up in one sentence: The
function which the program represents under the code interpretation is
applied to the stack which the program represents under the data interpretation.

The result of executing a Carriage program is always either the stack to
which the initial stack was mapped by the function, or an explosion.

The instruction symbols defined by Carriage are listed below.  The functions
to which they are mapped by the interpretation function are described in
operational terms for simplicity of explanation, but they are really
functions which take stacks to stacks.

* `1` ("one") pushes the integer 1 onto the stack.

* `~` ("pick") pops an integer n off the stack, then copies the element which is n (zero-based) positions deep in the stack, and pushes that copy onto the stack.  If n is negative or greater than the size of the stack or not an integer, the program explodes.  If the element to be copied is an instruction symbol, the program explodes.

* `\\` ("swap") pops an element a off the stack, then pops an element b off the stack, then pushes a back onto the stack, then pushes b back onto the stack.

* `$` ("pop") pops an element off the stack and discards it.

* `#` ("size") counts the number of elements into an integer k then pushes k onto the stack.

* `+` ("add") pops an integer a off the stack, then pops an integer b off the stack, then pushes the sum (a + b) onto the stack.  If either a or b is not an integer, the program explodes.

* `-` ("sub") pops an integer a off the stack, then pops an integer b off the stack, then pushes the difference (b - a) onto the stack.  If either a or b is not an integer, the program explodes.

* `@` ("slice") pops an integer k off the stack, then pops an integer p off the stack.  It then copies k instruction symbols from the stack into a sequence, starting at stack position p, zero-based, measured from the bottom of the stack.  It then applies the code interpretation to this sequence to obtain a function.  It then pushes this function onto the stack.  If k or p is not an integer, or k is less than 0, or k is greater than 0 and either p or p+(k-1) refers to some position not inside the stack proper, or k is greater than 0 and any of the elements between p and p+(k-1) inclusive are not instruction symbols, the program explodes.

* `!` ("apply") pops a function f off the stack and applies f to the stack to obtain a new stack.  If f is not a function the program explodes.

If the stack is empty any time an attempt is made to pop something off of it, the program explodes.

### Examples

#### Basic Stack Manipulation

As a simple example, the Carriage program

   111-~+

will be turned into a function which we might spell out in, say, Erlang, as

   fun(S) -> add(pick(sub(one(one(one(S))))))

which will be applied to a stack

   (fun(S) -> add(pick(sub(one(one(one(S)))))))(["1","1","1","-","~","+"])

which could be stated more succinctly as

   add(pick(sub(one(one(one(["1","1","1","-","~","+"]))))))

and whose evaluation could be depicted as

   add(pick(sub(one(one(["1","1","1","-","~","+",1])))))
   add(pick(sub(one(["1","1","1","-","~","+",1,1]))))
   add(pick(sub(["1","1","1","-","~","+",1,1,1])))
   add(pick(["1","1","1","-","~","+",1,0]))
   add(["1","1","1","-","~","+",1,1])

finally evaluating to the result stack

   ["1","1","1","-","~","+",2]

(Note that stacks are being depicted bottom-to-top.  I realize that's not how you'd typically
implement them as lists in a functional language.  Please just ignore that detail.)

#### Function Creation and Application

The previous example does not really demonstrate the power of the language.  For that,
we need to show how apply, and more importantly slice, work.  Take the program

    11+$11+111+@!

The result stack of evaluating this program is

    ["1","1","+","$","1","1","+","1","1","1","+","@","!",3]

The interpretation of the first four instruction symbols is just the
identity function (create 2 then pop it, leaving the stack as it was.)

The next seven instruction symbols leave [2,1,2] on the stack.

The slice instruction then pops k = 2, p = 1, and retrieves a sequence of
2 instruction symbols from the stack starting from position 1 (that is, the element
on top of the bottom element of the stack.)  We can
see that that sequence is `1+`.  It then applies the code interpretation
to that sequence to get a function (which pops a value off a stack and
pushes the successor of that value back onto the stack) and it pushes
this function onto the stack, which now looks like this:

    [...,"!",2,<fn>]

Finally, the apply instruction pops the function, and applies it to the
stack: the 2 is popped, 1 is added to it, and the result, 3, is pushed
back on.

##### Note on "slice"

We note that slice has the practical effect of ''delimiting'' some part
of the program into a "subroutine" of sorts.  However, there are some
unusual consequences here.

One is that these "subroutines" may overlap.

Another is that these "subroutines" may be of variable size, as k need
not be a constant.  This may be used to affect a conditional of sorts.
(k is allowed to be zero, in which case the slice is a zero-length
sequence whose interpretation is the identity function.)

Another is that, in a terminating and non-exploding program, every
"subroutine" must be evaluated at least once -- because the entire
program is turned into a single function (which is applied to the
initial stack) and this single function contains all of its possible
subroutines.

In the above example, we anticipated this, and wrote our "subroutine" so that
the first time it is evaluated, it has no effect.  In fact, through
lucky coincidence, if we remove it from the program, the second and
third instruction symbols are still `1` and `+`, so we didn't need to
go to such lengths.  But this is in general not the case.

Note also that the restriction on the pick instruction, that it not be
able to pick instruction symbols from the stack, was introduced to
prevent construction of new "subroutines" which did not exist in the
original program.  (Instruction symbols can still be popped and swapped,
but these modifications to the "program on the stack" are quite minor.)

Note also that, despite being a concatenative language, and thus supposedly
mathematically pleasing, evaluating a "subfunction" with slice and apply
has a distinctly machine-language feel to it (similar perhaps to [Aubergine][]
and [Cfluviurrh][]), what with the absolute indexes into the stack and all.
One small saving grace is that adding whitespace to the program does *not*
change the indexes of the "subroutines".

#### Infinite Loop

    111-@11-~!$11111++++11-~@11-~!

Explanation:

    111-@

Push identity function (zero-length slice at position 1) onto the stack.

    11-~!

Duplicate object on the stack and apply it.  (This is our subfunction.)

    $

Remove identity function from the stack.

    11111++++11-~@

Push our subfunction (slice at position 5 with length 5) onto the stack.

    11-~!

Duplicate object on the stack and apply it.  This applies our subfunction, with our subfunction already on the stack; so the subfunction will duplicate it, then apply its copy, ad infinitum.  (A cleverer implementation might be able to use this last snippet of code ''as'' the subfunction.)

### See also

*   [the esowiki entry on Carriage](https://esolangs.org/wiki/Carriage) for more
    analysis and examples, including a Truth-machine, and open questions regarding
    the status of this language.
*   [Carriage.hs](https://esolangs.org/wiki/Carriage/Carriage.hs), a quick-and-dirty
    implementation in Haskell.  (which is actually the reference implementation now, okay)
*   [Carriage.ml](https://esolangs.org/wiki/Carriage/Carriage.ml), an implementation in Ocaml.
*   [Equipage][], the "purely concatenative" language that
    Carriage might've been, had the author not been so concerned about quoting at the time.
*   [Wagon][], yet another "purely concatenative" language by the same author, trying to
    capture control flow in being "second-order concatenative", and not quite succeeding.

[Aubergine]: https://catseye.tc/node/Aubergine
[Cfluviurrh]: https://catseye.tc/node/Cfluviurrh
[Equipage]: https://catseye.tc/node/Equipage
[Wagon]: https://catseye.tc/node/Wagon
