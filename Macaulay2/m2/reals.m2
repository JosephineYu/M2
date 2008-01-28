--		Copyright 1993-2008 by Daniel R. Grayson

-- ImmutableType

ImmutableType = new Type of HashTable
ImmutableType.synonym = "immutable type"
globalAssignment ImmutableType

-- these types are pre-defined

RR.synonym = "real number"
CC.synonym = "complex number"
RR.texMath = ///{\mathbb R}///
CC.texMath = ///{\mathbb C}///
Number.synonym = "number"
InexactFieldFamily.synonym = "inexact field family"
InexactNumber.synonym = "inexact number"

-- built-in functions 

precision InexactNumber := precision0
precision Number := x -> infinity
precision Ring := R -> precision 0_R

lngamma = method()
lngamma ZZ := lngamma QQ := lngamma RR := x -> (
     (y,s) := lgamma x;
     if s == -1 then y + ii * numeric_(precision y) pi else y
     )

-- new types

InexactField = new Type of EngineRing
InexactField.synonym = "inexact field"
raw InexactField := R -> R.RawRing

RR.InexactField = RealField    = new Type of InexactField   ; RealField.synonym = "real field"
CC.InexactField = ComplexField = new Type of InexactField; ComplexField.synonym = "complex field"

Nothing' = Nothing					    -- maybe we'll want to rename it later...
RingFamily_* := RR -> RR#(symbol _*)
RingFamily_* = (RR,e) -> RR#(symbol _*) = e
InexactNumber' = new Type of Nothing'
RR_* = RR' = new Type of InexactNumber'
CC_* = CC' = new Type of InexactNumber'

setAttribute(CC',PrintNet,"CC" | "*"^-1)
setAttribute(RR',PrintNet,"RR" | "*"^-1)
setAttribute(CC',PrintNames,"CC_*")
setAttribute(RR',PrintNames,"RR_*")
setAttribute(InexactNumber',PrintNet,"InexactNumber" | "*"^-1)

protect back
RR'.back = RR
CC'.back = CC
new RealField of Nothing' from ZZ := memoize (
     (RealField,Nothing',prec) -> newClass(RealField,Nothing',
	  hashTable { 
	       symbol precision => prec,
	       symbol Engine => true,
	       symbol baseRings => {ZZ,QQ},
	       symbol isBasic => true,
	       symbol RawRing => rawRR prec
	       }))
new ComplexField of Nothing' from ZZ := memoize(
     (ComplexField,Nothing',prec) -> newClass(ComplexField,Nothing',
	  hashTable {
	       symbol precision => prec,
	       symbol Engine => true,
	       symbol isBasic => true,
	       symbol baseRings => {ZZ,QQ},
	       symbol RawRing => rawCC prec
	       }))
precision InexactField := R -> R.precision
InexactFieldFamily _ ZZ := (T,prec) -> new T.InexactField of T#(symbol _*) from prec -- oops...
default InexactFieldFamily := R -> R_defaultPrecision

-- lift and promote between real or complex rings

Number _ InexactFieldFamily := (x,RR) -> x_(default RR)

promote(RawRingElement,RR') := (x,R) -> new RR from x
promote(RawRingElement,CC') := (x,R) -> new CC from x
promote(RawRingElement,Number) := (x,R) -> new R from x
promote(RawRingElement,RingElement) := (x,R) -> new R from x
promote(Number,InexactNumber) := (x,RR) -> promote(x,default RR)
promote(ZZ,RR') := 
promote(QQ,RR') := 
promote(RR,RR') := (i,K) -> toRR(K.precision,i)
promote(ZZ,CC') := 
promote(QQ,CC') := 
promote(RR,CC') := 
promote(CC,CC') := (i,K) -> toCC(K.precision,i)
lift(Number,InexactNumber) := opts -> (x,RR) -> lift(x,default RR)

liftable(Number,InexactNumber) := (x,RR) -> liftable(x,default RR)
liftable(CC,RR'):= (z,RR) -> imaginaryPart z == 0
lift(CC,RR'):= opts -> (z,RR) -> (
     if imaginaryPart z == 0 then realPart z
     else if opts.Verify then error "can't lift given complex number to real number"
     )

-- lift and promote to and from other rings

numeric VisibleList := x -> apply(x,numeric)
numeric(ZZ,VisibleList) := (prec,x) -> apply(x, t -> numeric(prec,t))
numeric Number := x -> numeric(defaultPrecision, x)
numeric CC := identity
numeric RR := identity
numeric(ZZ,Number) := toRR
numeric(ZZ,CC) := toCC
infty := prec -> 1/toRR(prec,0)
numeric InfiniteNumber := infinity -> infinity#0 * infty defaultPrecision
numeric(ZZ, InfiniteNumber) := (prec,infinity) -> infinity#0 * infty prec

ZZ _ RealField :=
QQ _ RealField :=
RR _ RealField := (x,R) -> toRR(R.precision,x)
ZZ _ ComplexField :=
QQ _ ComplexField :=
RR _ ComplexField :=
CC _ ComplexField := (x,R) -> toCC(R.precision,x)

approx := (r,limit) -> (
     if r == 0 then return 0/1;
     r' := r;
     m := mutableIdentity(ZZ,2);
     while true do (
	  a := floor r';
	  columnSwap(m,0,1);
	  columnAdd(m,0,a,1);
	  r' = r' - a;
	  if r' == 0 or abs(r - m_(0,0) / m_(1,0)) < limit then return m_(0,0) / m_(1,0);
	  r' = 1/r' ;
	  ))
lift(RR,QQ) := opts -> (r,QQ) -> approx(r,abs r / 2^(precision r - 16))
lift(RR,ZZ) := opts -> (r,ZZ) -> (
     i := floor r; 
     if r == i then i 
     else if opts.Verify then error "can't lift to ZZ")
lift(CC,QQ) := lift(CC,ZZ) := opts -> (z,R) -> if imaginaryPart z == 0 then lift(realPart z, R) else if opts.Verify then error "can't lift given complex number to real number"

ring RR := x -> new RealField of RR' from precision x
ring CC := x -> new ComplexField of CC' from precision x

new RR from RawRingElement := (RRR,x) -> ( assert( RRR === RR ); rawToRR x)
new CC from RawRingElement := (CCC,x) -> ( assert( CCC === CC ); rawToCC x)

-- arithmetic operations

CC.InverseMethod = y -> conjugate y / y^2
CC ^ ZZ := BinaryPowerMethod

scan((QQ,RR,CC), F -> (
	  F // F := (x,y) -> if y == 0 then 0_F else x/y;
	  F % F := (x,y) -> if y == 0 then x else 0_F;
	  F // ZZ := (x,y) -> x // y_F;
	  F % ZZ := (x,y) -> x % y_F;
	  ))

scan((RR,CC), F -> (
	  F // QQ := (x,y) -> x // y_F;
	  F % QQ := (x,y) -> x % y_F;
	  ))

CC // RR := (x,y) -> x // y_CC;
CC % RR := (x,y) -> x % y_CC;

-- functions

conjugate CC := z -> toCC(precision z, realPart z, - imaginaryPart z)
isConstant Number := i -> true

round RR := round0
round(ZZ,RR) := (n,x) -> (
     prec := precision x;
     p := (toRR(prec,10))^n;
     toRR(prec,round(x*p)/p))

random RR := RR => opts -> x -> x * rawRandomRR precision x
random(RR,RR) := opts -> (x,y) -> x + random(y-x)
RR'.random = opts -> R -> rawRandomRR R.precision
CC'.random = opts -> C -> rawRandomCC C.precision
random RingFamily := opts -> R -> random(default R,opts)

-- algebraic operations and functions

RR.isBasic = CC.isBasic = true

InexactFieldFamily Array := (T,X) -> (default T) X
Thing ** InexactFieldFamily := (X,T) -> X ** default T

generators InexactField := opts -> R -> {}
isField InexactField := R -> true
degreeLength InexactField := R -> 0
frac InexactField := identity
numgens InexactField := R -> 0
dim InexactField := R -> 0
char InexactField := R -> 0

-- symbolic/numeric constant expressions

Constant = new Type of BasicList
pi = new Constant from { symbol pi, pi0 }
EulerConstant = new Constant from { symbol EulerConstant, mpfrConstantEuler }
ii = new Constant from { symbol ii, ConstantII }

expression Constant := c -> expression c#0
toString Constant := net Constant := c -> toString c#0
toExternalString Constant := c -> toString c#0
numeric Constant := c -> c#1 defaultPrecision
numeric(ZZ,Constant) := (prec,c) -> c#1 prec

Constant + Constant := (c,d) -> numeric c + numeric d
Constant + InexactNumber := (c,x) -> numeric(precision x,c) + x
InexactNumber + Constant := (x,c) -> x + numeric(precision x,c)
+ Constant := c -> numeric c
- Constant := c -> - numeric c
Constant - Constant := (c,d) -> numeric c - numeric d
Constant - InexactNumber := (c,x) -> numeric(precision x,c) - x
InexactNumber - Constant := (x,c) -> x - numeric(precision x,c)
Constant * Constant := (c,d) -> numeric c * numeric d
Constant * InexactNumber := (c,x) -> numeric(precision x,c) * x
InexactNumber * Constant := (x,c) -> x * numeric(precision x,c)
Constant / Constant := (c,d) -> numeric d / numeric d
Constant / InexactNumber := (c,x) -> numeric(precision x,c) / x
InexactNumber / Constant := (x,c) -> x / numeric(precision x,c)
Constant ^ Constant := (c,d) -> (numeric c) ^ (numeric d)
Constant ^ InexactNumber := (c,x) -> (numeric(precision x,c)) ^ x
InexactNumber ^ Constant := (x,c) -> x ^ (numeric(precision x,c))

Constant == Constant := (c,d) -> numeric d == numeric d
Constant == InexactNumber := (c,x) -> numeric(precision x,c) == x
InexactNumber == Constant := (x,c) -> x == numeric(precision x,c)

Constant _ Ring := (c,R) -> (numeric c)_R
Constant _ InexactFieldFamily := (x,RR) -> x_(default RR)

Constant + Number := (c,x) -> numeric c + x
Number + Constant := (x,c) -> x + numeric c
- Constant := c -> - numeric c
Constant - Number := (c,x) -> numeric c - x
Number - Constant := (x,c) -> x - numeric c
Constant * Number := (c,x) -> numeric c * x
Number * Constant := (x,c) -> x * numeric c
Constant / Number := (c,x) -> numeric c / x
Number / Constant := (x,c) -> x / numeric c
Constant ^ Number := (c,x) -> (numeric c) ^ x
Number ^ Constant := (x,c) -> x ^ (numeric c)

Constant ! := c -> (numeric c)!

-- printing

toString RealField := R -> concatenate("RR_",toString R.precision)
toString ComplexField := R -> concatenate("CC_",toString R.precision)

expression RealField := R -> new Subscript from {symbol RR, R.precision}
expression ComplexField := R -> new Subscript from {symbol CC, R.precision}
expression RR := x -> if x < 0 then new Minus from {-x} else new Holder from {x}
expression CC := z -> (
     x := realPart z;
     y := imaginaryPart z;
     if y == 0 then return expression x;
     if x == 0 then return expression y * ii;
     if y == -1 then return expression x - ii;
     if y == 1 then return expression x + ii;
     expression x + expression y * hold symbol ii)
net InexactField := R -> net expression R
net CC := z -> simpleToString z
toExternalString RR := toExternalString0
toExternalString CC := toExternalString0
InexactNumber#{Standard,Print} = x ->  (
     prec := printingPrecision;
     acc := printingAccuracy;
     printingPrecision = 0;
     printingAccuracy = -1;
     Thing#{Standard,Print} x;
     printingPrecision = prec;
     printingAccuracy = acc;				    -- sigh, what if an interrupt or an error occurred?
     );

InexactNumber#{Standard,AfterPrint} = x -> (
     << endl;                             -- double space
     << concatenate(interpreterDepth:"o") << lineNumber;
     y := class x;
     << " : " << y;
     prec := precision x;
     -- if prec =!= defaultPrecision then
     << " (of precision " << prec << ")";
     {*
     while parent y =!= Thing do (
	  y = parent y;
	  << " < " << y;
	  );
     *}
     << endl;
     )

isReal = method()
isReal RR := isReal QQ := isReal ZZ := x -> true
isReal CC := z -> imaginaryPart z == 0

acosh = method()
acosh Number := z -> log(z+sqrt(z^2-1))
asinh = method()
asinh Number := z -> log(z+sqrt(z^2+1))
acot = method()
acot Number := z -> atan(1/z)

-- Local Variables:
-- compile-command: "make -C $M2BUILDDIR/Macaulay2/m2 "
-- End:
