extensions [sound]

globals []
breed [males male]
breed [females female]
turtles-own [age energy fighting-ability intragroup-tolerance intergroup-tolerance kin-tolerance group-number home-base adult? genes mother father]
patches-own [penergy fertile? terminal-growth]
females-own [male-mate]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-patches;
  setup-groups;
  reset-ticks
end

to setup-patches
  ask patches [ set fertile? false set penergy 0 ] ;; initialize
  ask n-of (patch-abundance * count patches) patches [ set fertile? true ] ;; abundance
  ask n-of (patch-patchiness * count patches) patches [ ifelse count neighbors with [fertile?] > 3 [ set fertile? true ] [ set fertile? false ] ] ;; patchiness
  ask patches with [fertile?] [ set terminal-growth 1 + random patch-max-energy - 1  set penergy terminal-growth] ;; energy
  ask patches [ set-patch-color ] ;; color
end

to setup-groups
  let groupCount 0
  while [groupCount < initial-group-count] [
    let groupPatch one-of patches
    create-males initial-number-males [ initialize-male nobody nobody groupCount groupPatch ]
    create-females initial-number-females [ initialize-female nobody nobody groupCount groupPatch ]
    set groupCount groupCount + 1;
  ]
end

to initialize-genes
  let i 0;
  while [i < 16] [
    set genes replace-item i genes one-of ["a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"]
    set i i + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; GO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ask patches [ grow-patches set-patch-color ]
  ask turtles [ move compete eat ]
  ask turtles with [breed = females] [ mate reproduce ]
  ask turtles [ check-death update-life-history ]
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; INITIALIZE PRIMATE FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to initialize-male [m f groupNo startPatch]
  set size 2.0;
  set shape "triangle";
  initialize-primate m f groupNo startPatch
end

to initialize-female [m f groupNo startPatch]
  set size 1.5;
  set shape "circle";
  initialize-primate m f groupNo startPatch
end

to initialize-primate [m f groupNo startPatch]
  set label-color white;
  set energy random 50;
  set age random life-expectancy;
  set home-base startPatch;
  set genes "aaaaaaaaaaaaaaaa";
  set group-number groupNo;
  set xcor [pxcor] of startPatch;
  set ycor [pycor] of startPatch;
  ifelse m = nobody or f = nobody
     [ initialize-genes
       set fighting-ability ((random 100) / 100)
       set intragroup-tolerance ((random 100) / 100)
       set intergroup-tolerance ((random 100) / 100)
       set kin-tolerance ((random 100) / 100)]
     [ set-genes m f
       set mother m
       set father f
       set-fighting-ability
       set-intragroup-tolerance
       set-intergroup-tolerance
       set-kin-tolerance]
  set adult? false;
  update-life-history;
end

to set-genes [m f]
  let i 0;
  while [i < 16] [ ifelse random 100 < 50 [
      set genes replace-item i genes item i [genes] of m ] [
      set genes replace-item i genes item i [genes] of f ]
      set i i + 1 ]
end

to set-fighting-ability
  set fighting-ability (([fighting-ability] of mother + [fighting-ability] of father) / 2);
end

to set-intragroup-tolerance
  set intragroup-tolerance (([intragroup-tolerance] of mother + [intragroup-tolerance] of father) / 2);
end

to set-intergroup-tolerance
  set intergroup-tolerance (([intergroup-tolerance] of mother + [intergroup-tolerance] of father) / 2);
end

to set-kin-tolerance
  set kin-tolerance (([kin-tolerance] of mother + [kin-tolerance] of father) / 2);
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; PRIMATE FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move

  let bestPatch patch-here;
  let bestPatchValue 1;
  let meTurtle self;

  foreach [self] of patches with [distance myself < perception-range] [ ?1 ->

    ;; FOOD
    let foodValue [penergy] of ?1 * (1 - ([energy] of meTurtle / max-energy)) * ( 1 - (distance meTurtle / perception-range));

    ;; CONSPECIFIC
    let conspecificList [self] of turtles-on ?1;
    let conspecificValue 1;
    let groupValue 1;
    foreach conspecificList [ ??1 ->
      ifelse [group-number] of ??1 != [group-number] of meTurtle [
         set conspecificValue conspecificValue + ( 1 - (distance meTurtle / perception-range))
      ] [
         set groupValue groupValue + (distance meTurtle / perception-range)
      ]
    ]

    ;; HOME RANGE
    let homeValue (1 - ([distance [home-base] of meTurtle] of ?1 / 100)) * (distance [home-base] of meTurtle / 100)


    ;; MATES
    let mateValue 1;
    foreach conspecificList [ ??1 ->
      if [breed] of ??1 = females and [breed] of meTurtle = males [
        set mateValue mateValue + ( 1 - (distance meTurtle / perception-range))
      ]
    ]

    ;; PREDATORS
    ;;if is-turtle? male [
    ;;  foreach conspecificList [
    ;;    set mateValue mateValue + ( 1 - ([distance self] of ? / perception-range))
    ;;  ]
    ;;]

    ;; TOTAL
    let patchValue homeValue + foodValue + mateValue - conspecificValue + groupValue;

    if patchValue > bestPatchValue [ set bestPatchValue patchValue  set bestPatch ?1 ]
  ]

  move-to-patch bestPatch;

end

to move-to-patch [to-patch]
    set energy energy - energy-cost-per-step
    face to-patch
    rt random-float 20
    lt random-float 20
    fd 1
end

to compete
  foreach [self] of turtles-here [ ?1 ->
    ask ?1 [ set energy energy - ([fighting-ability] of myself) * aggression-cost]
  ]
  foreach [self] of turtles-on neighbors [ ?1 ->
    ask ?1 [ set energy energy - ([fighting-ability] of myself) * aggression-cost]
  ]
end

to mate
  let potential-mates males with [patch-here = [patch-here] of myself]
  if any? potential-mates [
    set male-mate one-of potential-mates;
  ]
end

to eat
  set energy energy + food-eaten-per-step
  set penergy penergy - food-eaten-per-step
  if penergy < 0 [ set penergy 0 ]
end

to reproduce
  if energy > (birth-cost + energy-cost-per-step) [
    if male-mate != 0 and male-mate != nobody [
       set energy energy - birth-cost
       ifelse random 100 < 50 [ hatch-males 1 [ initialize-male myself [male-mate] of myself group-number patch-here]]
                              [ hatch-females 1 [ initialize-female myself [male-mate] of myself group-number patch-here]]
    ]
  ]
end

to update-life-history
  set age age + 1
  if age < age-at-maturity [ set adult? false set color group-number * 10 + 7 ] ; youth
  if age = age-at-maturity [ ] ; transfer
  if age > age-at-maturity [ set adult? true set color group-number * 10 + 5] ; adult
  if age > life-expectancy [ die ] ; die
end

to check-death
  if energy < 0 [ die ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; PATCH FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to grow-patches
  ifelse fertile? [ if penergy + patch-growth-rate < terminal-growth [ set penergy penergy + patch-growth-rate ]] [ set penergy 0 ]
end

to set-patch-color
  set pcolor scale-color green penergy (patch-max-energy + 20) -10;
end
@#$#@#$#@
GRAPHICS-WINDOW
400
32
862
495
-1
-1
4.5
1
14
1
1
1
0
1
1
1
-50
50
-50
50
1
1
1
ticks
30.0

SLIDER
7
140
182
173
initial-number-males
initial-number-males
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
7
182
182
215
initial-number-females
initial-number-females
0
100
8.0
1
1
NIL
HORIZONTAL

BUTTON
8
28
77
61
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
90
28
157
61
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
886
322
1202
519
populations
time
 b
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"males" 1.0 0 -13791810 true "" "plot count males"
"females" 1.0 0 -5825686 true "" "plot count females"

MONITOR
888
260
959
305
# males
count males
3
1
11

MONITOR
963
260
1045
305
# females
count females
3
1
11

TEXTBOX
10
321
150
340
Entity settings
11
0.0
0

TEXTBOX
11
223
163
241
Patch Settings
11
0.0
0

SLIDER
193
240
365
273
patch-growth-rate
patch-growth-rate
0
10
0.57
.01
1
NIL
HORIZONTAL

SLIDER
13
241
185
274
patch-abundance
patch-abundance
0
1
0.7
.01
1
NIL
HORIZONTAL

SLIDER
13
280
185
313
patch-patchiness
patch-patchiness
0
1
0.09
0.01
1
NIL
HORIZONTAL

SLIDER
193
280
365
313
patch-max-energy
patch-max-energy
0
100
24.0
1
1
NIL
HORIZONTAL

INPUTBOX
14
343
169
403
perception-range
2.0
1
0
Number

SLIDER
8
98
182
131
initial-group-count
initial-group-count
0
50
14.0
1
1
NIL
HORIZONTAL

SLIDER
180
384
352
417
birth-cost
birth-cost
0
1000
170.0
10
1
NIL
HORIZONTAL

SWITCH
13
411
172
444
female-transfer?
female-transfer?
1
1
-1000

SWITCH
13
450
172
483
male-transfer?
male-transfer?
1
1
-1000

SLIDER
180
343
352
376
max-energy
max-energy
0
1000
900.0
10
1
NIL
HORIZONTAL

TEXTBOX
11
78
161
96
Initialization Settings
11
0.0
1

SLIDER
179
424
351
457
food-eaten-per-step
food-eaten-per-step
0
50
17.0
1
1
NIL
HORIZONTAL

INPUTBOX
196
81
351
141
age-at-maturity
75.0
1
0
Number

INPUTBOX
201
159
356
219
life-expectancy
300.0
1
0
Number

SLIDER
179
467
351
500
energy-cost-per-step
energy-cost-per-step
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
195
28
367
61
aggression-cost
aggression-cost
0
100
9.0
1
1
NIL
HORIZONTAL

PLOT
893
35
1093
185
plot 1
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [fighting-ability] of turtles"

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
setup
set grass? true
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
