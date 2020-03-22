# Backpack Error Minimal Reproducer

This is a minimal reproducer for a problem with backpack. The code is taken
from a larger codebase where the goal was to use backpack to create a unified
interface to arrays using backpack. At a high level, what's going on is that
we bridge the gap between `ByteArray#` and `Array#`. The problem, beyond just
these type constructors are of different arity, is that for `ByteArray#`, we
want a module instantiation per element type (one for `Word8`, one for
`Word16`, etc.), but for `Array#`, we want a single instantiation for all
types. The libraries `vector` and `array` both have their own ways of
resolving this dilema. This library (the full, original version) takes
a novel approach: one vector type per runtime representation.
 
There are private libraries in this packages. Those that end in `indef`
are indefinite libraries:

* `internal`: Defines `PrimArray` for use elsewhere.
* `indef` (sigs: `Element`, `Array`; modules: `Vector`): Most general interface to vectors. The indefinite `Vector`
  module has been stripped of its contents since they are not needed
  to demonstrate the problem. It originally had functions for monomorphic
  mapping, searching for an element matching a predicate, etc.
* `prim-indef` (sigs: `Element`, `Representation; modules: `Vector`) and
  `prim-internal-indef` (sigs: `Representation`; modules: `PrimArray`):
  Logically, there is just one thing going on here, but this has to be
  broken into two libraries because of staging restrictions imposed by
  backpack. The idea is that functions that operate over a range of elements
  have the same implementation for all unboxed types. Given a element width,
  the entire `Array` signature that `indef` needs can be computed by just
  scaling indices and lengths by the width.
* `imp`: Stuff for instantiating the vector of 8-bit words.
* public library: instantiation and nothing else

All of the components compile except for the very last instantiation in the
public library. With `cabal build --ghc-options '-ddump-if-trace'`, we get:

```
... tons of logs removed for clarity
Need decl for M
Considering whether to load PrimArray {- SYSTEM -}
Reading interface for vex-minimal-reproducer-0.1.0.0:PrimArray;
    reason: Need decl for M
readIFace /home/amartin/Development/vex-minimal-reproducer/dist-newstyle/build/x86_64-linux/ghc-8.8.3/vex-minimal-reproducer-0.1.0.0/l/prim-internal-indef/build/prim-internal-indef/PrimArray.hi
updating EPS_
typecheckIfaceForInstantiate
Declaration for write#:
  Can't find interface-file declaration for type constructor or class M
    Probable cause: bug in .hi-boot file, or inconsistent .hi file
    Use -ddump-if-trace to get an idea of which file caused the error
```

What could be going wrong? Here are the results of my investigation. There are
in fact two `PrimArray.hi` files (hiding the common prefix for clarity):

* `l/prim-internal-indef/build/prim-internal-indef/PrimArray.hi` (the one GHC refers to before the error message)
* `l/prim-internal-indef/vex-minimal-reproducer-0.1.0.0-inplace-prim-internal-indef+J7do11KMUepGGTcyBtjCEm/build/vex-minimal-reproducer-0.1.0.0-inplace-prim-internal-indef+J7do11KMUepGGTcyBtjCEm/PrimArray.hi`

Did GHC (or cabal-install) pick the wrong one? I don't think so, but I'm not
sure. That's one thing that could be wrong. Another strange thing is that
dumping the bad `.hi` file with `ghc --show-iface` gives us:

```
...
exports:
  uninitialized#
  {Representation.R}
  M
...
import  -/  Data.Kind f01322821e2f26fcae5acb5ba49a7c2b
import  -/  GHC.Exts 897193d0fd1119ce5ca51fc9c3a52139
import  -/  Prelude da95a9c2922bf32d9c5d41a7d791ffaa
import  -/  Internal 790012c64bf93c91a4a4b37dfba88a4d
import  -/  Representation a95b04f78a778be62dc4a507a39bf42f
  exports: e2d1a91e967a42e62786ffaa61802405
  R 992c391f01f907c59b0ace2f8ba6cf73
  width d96913fe187f775e77f718a3dbf51b09
aed23b24830e2525100b81675a96b522
  $trModule :: GHC.Types.Module
  {- Never levity-polymorphic -}
efd33cfa9631508cd195142527dd0601
  type M =
    Internal.MutablePrimArray :: * -> TYPE {Representation.R} -> *
adc2e0eb8fbcaf0480e58bb213f9f436
  uninitialized# ::
    GHC.Prim.Int#
    -> GHC.Prim.State# s -> (# GHC.Prim.State# s, M s a #)
  {- Never levity-polymorphic -}
...
```

So, `M` is in fact exported by `PrimArray.hi`. Weird. That's all I've
got for now.
