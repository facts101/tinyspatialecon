BeginPackage["TinySpatialEconomy`"]

Equilateral::usage="Triangle[Equilateral[s]] is an equilateral triangle with side length s.";

Isosceles::usage="Triangle[Isosceles[b,h]] is an isosceles triangle by base length b and height h.";

Vanilla::usage="Circle[Vanilla[r]] is a simple circle with radius r.";

Elipse::usage="Circle[Elipse[a,b]] is an elipse with semi-axes a and b.";

Vanilla::usage="Rectangle[Vanilla[s]] a square with side length s.";

Vanilla::usage="Rectangle[Vanilla[b,h]] is a rectangle with base s and height h.";

RandomPoints::usage="RandomPoints[shape,h[args],n,boundary,overlap,tolExp] generates n random points within shape[h[args]].";

ShapeGraphics::usage="ShapeGraphics[shape,h[args],pivots,points] generates Graphics for shape[h[args]] and associated lists of points.";

Economy::usage="Economy[shape,h[args],nvendors,ncustomers,probShopQ,probVisit,boundary,overlap,stepwise,maxSteps,olapTolExp,tolExp_] generates a list of Graphics using ShapeGraphics.";

shapeOptions::usage="shapeOptions[] generates a list of numbered rules corresponding to available shapes.";

controlOptions::usage="controlOptions is an Association.";

parameterOptions::usage="parameterOptions is an Association.";


Begin["`Private`"]

(* an equilateral triangle with side length s *)
Equilateral/:Triangle[Equilateral[s_]]:=Triangle[{{0,0},{s,0},{s/2,Sqrt[3] s/2}}]

(* an isosceles triangle by base length b and height h *)
Isosceles/:Triangle[Isosceles[b_,h_]]:=Triangle[{{0,0},{b,0},{b/2,h}}]

(* a simple circle with radius r *)
Vanilla/:Circle[Vanilla[r_]]:=Disk[{0,0},r]

(* an elipse with semi-axes a and b *)
Elipse/:Circle[Elipse[a_,b_]]:=Disk[{0,0},{a,b}]

(* a square with side length s *)
Vanilla/:Rectangle[Vanilla[s_]]:=Rectangle[{0,0},{s,s}]

(* a rectangle with base s and height h *)
Vanilla/:Rectangle[Vanilla[b_,h_]]:=Rectangle[{0,0},{b,h}]

(* generates unique random points within a shape *)
uniqueRandomPoints[s_,n_,tolExp_:-5]:=Module[{bag={},break=False,delta,pt},
delta=10^tolExp;
While[Length[bag]<n,
pt=RandomPoint[s];
(* EuclideanDistance discriminates between points *)
Do[break=False;If[EuclideanDistance[pt,elem]<delta,break=True;Break[]],{elem,bag}];
If[Not[break],bag=Flatten[{bag,{pt}},1]]
];
bag
]

(* generates random points within a shape *)
randomPoints[s_,n_,boundary_:False,overlap_:True,tolExp_:-5]:=Module[{},
Switch[{boundary,overlap},
(* allow unique interior points *)
{False,False},uniqueRandomPoints[s,n,tolExp],
(* allow interior points that might overlap *)
{False,True},RandomPoint[s,n],
(* allow unique boundary points *)
{True,False},uniqueRandomPoints[RegionBoundary[s],n,tolExp],
(* allow only boundary points that might overlap *)
{True,True},RandomPoint[RegionBoundary[s],n],
_,$Failed
]
]

(* generates random points within shape[h[args]] *)
RandomPoints[shape_,h_[args__],n_,boundary_:False,overlap_:False,tolExp_:-5]:=Module[{t=shape[h[args]]},
Switch[shape,
Triangle,randomPoints[t,n,boundary,overlap,tolExp],
Circle,randomPoints[t,n,boundary,overlap,tolExp],
Rectangle,randomPoints[t,n,boundary,overlap,tolExp],
_,$Failed
]
]

(* generates Graphics for shape[h[args]] and associated lists of points *)
ShapeGraphics[shape_ ,h_[args__],pivots_,points_]:=Graphics[{
{EdgeForm[Orange],FaceForm[LightBlue],shape[h[args]]},
{LightOrange,PointSize[Medium],Point[points]},
{Red,PointSize[Medium],Point[pivots]},
MapIndexed[{Darker@Red,Text[#2[[1]],#1,{1,-1}]}&,pivots]//Apply[Sequence]
},ImageSize->Small]

(*
	Notes;
	1. Generate (assume m << n);
		1.a. m vendors;
		1.b. n customers;
	2. Decide on vendor relocation scheeme (immediate vs stepwise);
	3. Cycle over customers;
		3.a. Decide if customer will shop or not;
			3.a.i. Calculate distance to each vendor;
			3.a.ii. Decide if customer visits closest vendor or not;
			3.a.iii. Update selected vendor's inventory/clientele;
	4. Cycle over vendors;
		4.a. Decide if vendor relocates (revenues vs costs?);
			4.a.i. Decide where vendor relocates (near valuable customers?);
			4.a.ii. Relocate 
*)

(* generates a list of Graphics using ShapeGraphics *)
Economy[shape_,h_[args__],nvendors_:2,ncustomers_:250,probShopQ_:.75,probVisit_:.99,boundary_:False,overlap_:False,stepwise_:False,maxSteps_:99,olapTolExp_:-5,tolExp_:-5]:=Module[{step=0,continue=True,tol=10^tolExp,m=nvendors,n=ncustomers,vendors,customers,customer,shopQ,shopQs={},dists={},dist,visitQs={},visitQ,locations={},hist={},i,infinities,purchases,prev,tmp},

(* locations of vendors & customers *)
{vendors,customers}={RandomPoints[shape,h[args],m,False,False,olapTolExp],RandomPoints[shape,h[args],n,boundary,overlap,olapTolExp]};

infinities=ConstantArray[Infinity,m];

(* last available orders per vendor *)
prev=(#->{}&)/@vendors//Association;

hist={vendors};

While[
continue&&step<maxSteps,

(* cycle over customers & decide if customer will shop or not *)
shopQs=Array[(RandomReal[]<probShopQ&),n];

{dists,visitQs}=Transpose@MapThread[(
{shopQ,customer}={#1,#2};
If[shopQ,{(* calculate distance to each vendor *)
EuclideanDistance[customer,#]&/@vendors,
(* decide if customer visits closest vendor or not *)
RandomReal[]<probVisit},{infinities,$Failed}])&,{shopQs,customers}];

(* update purchases for vendors *)
purchases=MapThread[(
{customer,visitQ,dist}={#1,#2,#3};
If[Not[FailureQ[visitQ]],
If[visitQ,
{i}=PositionSmallest[dist];customer->vendors[[i]],
customer->RandomChoice[vendors]
],customer->$Failed])&,{customers,visitQs,dists}];

(* latest purchases per vendor ie <|vendor -> {clients}...|> *)
tmp=GroupBy[purchases,Last->First];

(* decide where each vendor wants to relocate *)
locations=(
purchases=tmp[#];
If[Not[MissingQ[purchases]],
If[Length[purchases]>Length[prev[#]],
(* relocate to the general direction of more purchases *)
prev[#]=purchases;#->Mean[purchases],
#->#
],
#->#
]
)&/@vendors;

(* relocate vendors *)
If[Not[stepwise],
(* do the immediate relocation *)
vendors=(vendors/.locations);hist=Flatten[{hist,{vendors}},1],

(* TODO: do the stepwise relocation *)
$Failed
];

continue=Through[{Most/*Last,Last}[hist]]//Transpose/*(EuclideanDistance@@@#&)/*Map[#>tol&]/*Apply[And];

step+=1;
];

(ShapeGraphics[shape,h[args],{##},customers]&)@@@hist

]

(* generates a list of numbered rules corresponding to available shapes *)
shapeOptions[]:=shapeOptions[]=Module[{iso=Triangle[Isosceles[1,2]],eq=Triangle[Equilateral[1]],cir=Circle[Vanilla[1]],eli=Circle[Elipse[3,2]],sq=Rectangle[Vanilla[1]],rect=Rectangle[Vanilla[3,2]],shapes,controls,slider},
shapes={eq,iso,cir,eli,sq,rect}//Map[(Graphics[{FaceForm[LightBlue],EdgeForm[{Orange}],#},ImageSize->10]&)];
Thread[Range[Length[shapes]]->shapes]
]

controlOptions=<|
"shape"-><|"long"->"shape","hint"->"The geometry to use for the simulation"|>,
"onBoundary"-><|"long"->"onBoundary","hint"->"Use only the boundary of the geometry for customers"|>,
"allowOverlap"-><|"long"->"allowOverlap","hint"->"Customer locations might not be unique"|>,
"olapTolExp"-><|"long"->"olapTolExp","hint"->"Customer locations less than 10^olapTolExp distance are considered identical"|>,
"vendors"-><|"long"->"vendors","hint"->"Number of vendors"|>,
"customers"-><|"long"->"customers","hint"->"Number of customers"|>,
"probShop"-><|"long"->"probShop","hint"->"Probability a Customer decides to shop"|>,
"probVisit"-><|"long"->"probVisit","hint"->"Probability a Customer visits nearest vendor"|>,
"maxSteps"-><|"long"->"maxSteps","hint"->"Maximum number of allowed iterations"|>,
"tolExp"-><|"long"->"tolExp","hint"->"Vendor locations less than 10^tolExp distance are considered identical"|>,
"stepwise"-><|"long"->"stepwise","hint"->"Method for vendor relocation"|>
|>;

parameterOptions=<|
1-><|"side"-><|"long"->"side","hint"->"Side of equilateral triangle"|>|>,
2-><|
"base"-><|"long"->"base","hint"->"Base of isosceles triangle"|>,
"height"-><|"long"->"height","hint"->"Height of isosceles triangle"|>
|>,
3-><|"rad"-><|"long"->"rad","hint"->"Circle radius"|>|>,
4-><|
"hside"-><|"long"->"hside","hint"->"Horizontal semi-axis of elipse"|>,
"vside"-><|"long"->"vside","hint"->"Vertical semi-axis of elipse"|>
|>,
5-><|"side"-><|"long"->"side","hint"->"Side of square"|>|>,
6-><|
"base"-><|"long"->"base","hint"->"Base of rectangle"|>,
"height"-><|"long"->"height","hint"->"Height of rectangle"|>
|>
|>;

(*
This code and accompanying materials are provided as is without any warranties.

I developed this code and accompanying materials over the course of two days,
as a scetch for a response to a post from account @kaushikcbasu on X on Jan 5, 2025.

The post read: "EconLesson B 
In a city shaped like an equilateral triangle people live uniformly distributed all over & buy from the nearest vendor. 
There are 2 vendors. Are there points where the vendors can locate such that no vendor can do better by unilaterally relocating?"

All rights reserved by myself. Possible errors and ommissions are mine and mine alone.

X: @databacked101
email: mind.the.facts.101@gmail.com
*)

End[]

EndPackage[]