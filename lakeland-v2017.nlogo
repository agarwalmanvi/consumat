;;;; Author: Marco Janssen (2017) ;;;;
;;;; Extended by: Manvi Agarwal (2019) ;;;;

;;;; TODO create new agent-sets for fish and consumats ;;;;;;;;

breed [consumats consumat]
breed [fish a-fish]

globals [
  FishCatchtot
  Fish_pop
  Gold_Resource
  GoldTaxRate
  Carrying_Capacity
  Pollution
  Growth_rate
  Norm_Des_Fish_per_Cap
  WorldMFishPrice
  FishTaxRate
  FishCostPrice
  GoldMining_Ratetot
  NumDel
  NumRep
  NumSocCom
  NumIm
  ]

consumats-own [                ;;;;;;;;;;; Consumat variables ;;;;;;;;

  Miningtime                 ;; Time devoted to mining
  Fishingtime                ;; Time devoted to fishing
  MineSkill                  ;; Skill level in mining
  Fish_Catch                 ;;
  FishSkill                  ;; Skill level in fishing
  Desired_Catch              ;;
  FishDemand                 ;; Demand level for fish
  expcatch                   ;;
  ExpFinance                 ;; what's the diff b/w expfinance and exp_finance?
  Locpop_Finance             ;; Finance level of local population (?)
  Locpop_income              ;; Income level of local population (?)
  Locpop_incomeGross         ;; Gross income level of local population (?)
  Shortage_Costs             ;; Variable not used anywhere!
  LNSa_exis                  ;; Level of need satisfaction from existence
  LNSa_taste                 ;; Level of need satisfaction from taste
  LNSa_iden                  ;; Level of need satisfaction from identity
  LNSa_leis                  ;; Level of need satisfaction from leisure
  exp_finance                ;; Expected finance level
  exp_foodPC                 ;; Expected food level
  exp_identity               ;; Expected identity
  FishCom                    ;;
  MaxBuyFish                 ;; Max no. of fish an agent can buy
  Catch_Com                  ;;
  Shortage_Cost              ;; Fish shortage cost
  Supply_Income              ;; Income from fish supply (diff between demand and catch)
  LNS                        ;; Level of need satisfaction
  Food_PC                    ;; (?)
  Uncertainty                ;; Uncertainty level
  GoldMining_Rate            ;; Gold mining rate
  ActFishSkill               ;; Actual fishing skill : no. of fish caught per unit time
  desMiningtime              ;; Variable to store mining time as calculated for next iteration in decisionmaking procedure
  desFishingtime             ;; Variable to store fishing time as calculated for next iteration in decisionmaking procedure

  ]
patches-own []

fish-own [                   ;; none of these vars have been used yet!
  ymax                       ;; defines the area within which the fish can swim
  ymin                       ;;  bcoz the fish cannot swim on the land part!
  xmax
  xmin
  yinit                      ;; x and y coords when initialized the fish
  xinit
]

to setup
  clear-all
  set Fish_pop 100
  set Carrying_Capacity 100
  set Gold_Resource 100
  set GoldTaxRate 15
  set Growth_rate 0.1
  set FishCostPrice 1
  set WorldMFishPrice 5 * FIshCostPrice

  create-consumats num_consumats [                         ;; define init values for agents
    set FishDemand 0.2
    set MineSkill 0.05 / num_consumats        ;; does not change (all agents have an equal level of mining skill)
    set FishSkill 0.1 / num_consumats         ;; does not change (all agents have an equal level of fishing skill)
    set Miningtime 0.2
    set Fishingtime 0.6
    set Locpop_Finance 3
    set LNSa_exis 0.05
    set LNSa_taste 0.45
    set LNSa_iden 0.3
    set LNSa_leis 0.2
    set expcatch FishSkill * Fish_pop
    set Fish_Catch expcatch
    set color orange                           ;; set consumat color to orange
    setxy random-pycor -16                     ;; the consumat appears at the bottom of the window
    set heading 0                              ;; faces north
    set shape "person"                         ;; and is shaped like a person
  ]

  create-fish Fish_pop [
    fd 4                                       ;; fish form a circle around the centre
    set color green                            ;; green in colour
    set shape "fish"                           ;; and are shaped like fish
  ]

  ask patches [
    ifelse pycor > -15
    [
      set pcolor blue                   ;; patches on top section turn blue (water)
    ]
    [
      set pcolor brown                   ;; patches in bottom section turn brown (land)
    ]
  ]

  reset-ticks
end

to go

  decisionmaking

  ask consumats [
    fd random 4
    rt random 10
    fd random 4
    rt random 10
    fd random 4
    rt random 10
    fd random 4
    rt random 10
    fd random 4
    rt random 10
    fd random 4
    rt random 10
    fd random 4
  ]

  fishdynamics

  ask consumats [                                                               ;; for each agent
    ifelse mean [Locpop_Finance] of consumats > 0                               ;; if finance level of local population is not 0
    [set exp_identity Locpop_Finance / mean [Locpop_Finance] of consumats]      ;; calculate new expected identity level
    [set exp_identity 0]

    ifelse exp_identity >= 0 and Food_PC >= 0                                 ;; if expected identity and food_pc are both more than 0
    [                                                                         ;; set new LNS to weighted multiplication of satisfaction of set of needs
      set LNS ((1 - exp (-0.005 * (Food_PC))) ^ LNSa_exis) * ((1 - exp( - 5 * Locpop_Finance)) ^ LNSa_taste) * ((1 - exp( 0 - exp_identity)) ^ LNSa_iden) * ((1 - exp( - 2 * (1 - Fishingtime - Miningtime))) ^ LNSa_leis)
    ]
    [set LNS 0]                                                               ;; otherwise set LNS to 0

    if ExpCatch > 0                                                           ;; Calculate new level of uncertainty
    [
      ifelse ((ExpCatch - ActFishSkill) / ExpCatch > Umax)
      [set Uncertainty 1]
      [set Uncertainty 0]
    ]

  ]

  tick

end

to decisionmaking                               ;;;;;;; Calculate mining time and fishing time for each agent ;;;;;;;;;

  ;;;  (following counters used only in this round of decision making) ;;;
  set NumDel 0                                           ;; counter for how many agents will do deliberate behaviour
  set NumRep 0                                           ;; counter for how many agents will do repetition behaviour
  set NumSocCom 0                                        ;; counter for how many agents will do social comparison behaviour
  set NumIm 0                                            ;; counter for how many agents will do imitation behaviour

  ask consumats [                   ;; for every agent
    let bestFT 0                  ;; best fishing time obtained thus far
    let bestMT 0                  ;; best mining time obtained thus far
    let expLNS 0                  ;; expected level of need satisfaction
    let FT 0                      ;; fishing time
    let MT 0                      ;; mining time
    let maxLNS 0                  ;; max level of need satisfaction obtained thus far
    let expMaxBuyFish 0           ;; expected max no. of fish an agent can buy
    let expFish_Catch 0           ;; expected number of fish the agent can catch

    ;;;;;;;;;;;;;;;;;;;; decide for each agent what behaviour they will perform ;;;;;;;;;;;;;;;;;;;;;;;;;;

    ifelse LNS < LNSmin [                               ;; if agent's level of need satisfaction is lower than the minimum i.e. agent is dissatisfied

      ifelse Uncertainty = 0 [                          ;; and agent's uncertainty is low

        ;;;;;;; Deliberation ;;;;;;;;

        set NumDel NumDel + 1                           ;; increment counter for deliberate agents

        while [FT < 0.9]                                ;; cycle through different values of FT and MT via grid search
        [                                               ;; to obtain the best combination such that it gives the highest
          set MT 0                                      ;; expected level of need satisfaction

          while [(MT + FT) < 0.9]
          [
            set expMaxBuyFish (Locpop_Finance + MT * (1 - GoldTaxRate)) / WorldMFishprice          ;; calculate expected max no. of fish that agent can buy

            ;;;;;;; Calculate expected food level ;;;;;;;

            set expFish_Catch FT * FishSkill * Fish_pop                   ;; expected no. of fish agent can catch
            ifelse expFish_Catch < FishDemand [                           ;; if expected fish catch is less than fish demand
              ifelse expMaxBuyFish > (FishDemand - expFish_Catch)              ;; and if expected no. of bought fish can close the gap b/w fish demand and expected fish catch
              [set exp_foodPC FishDemand]                                      ;; .... do something with exp_foodPC ....
              [set exp_foodPC expFish_Catch + MaxBuyFish]                      ;; .... otherwise, do something else ....
            ]
            [set expFish_Catch FishDemand]                                ;; if expected fish catch is more than fish demand, set expected fish catch to fish demand, and leave exp_foodPC unchanged (?)

            ;;;;;; Calculate expected finance ;;;;;

            set exp_finance Locpop_Finance + (1 - GoldTaxRate / 100) *  MineSkill * MT * Gold_Resource + (1 - FishTaxRate / 100) * (FT * ActFishSkill - FishDemand)   ;; calculate expected finances
            if (FT * FishSkill * Fish_pop) < FishDemand                                                         ;; if fishing demand is not met by agent's fishing alone -> decline in expected finance (?)
            [
              ifelse expMaxBuyFish > (FishDemand - FT * FishSkill * Fish_pop)                                     ;; if expMaxBuyFish can close the gap between the demand and the agent's fish catch
              [set exp_finance exp_finance - WorldMFishPrice * (FishDemand - FT * FishSkill * Fish_pop)]          ;; reduce exp_finance by buying price of fish difference
              [set exp_finance exp_finance - MaxBuyFish * WorldMFishPrice]                                        ;; if it cannot close the gap, then reduce exp_finance by buying price of max no. of fish agent can buy
            ]

            ;;;;; Calculate expected identity ;;;;;;

            ifelse mean [Locpop_Finance] of consumats > 0                                 ;; if avg finance level of local population is more than 0
            [set exp_identity exp_finance / mean [Locpop_Finance] of consumats]           ;; set exp_identity to normalized exp_finance wrt local pop's avg finance level
            [set exp_identity 1]                                                        ;; if avg finance level of local population is less than 0, set exp_identity to 1

            ;;;;;;;; Aggregate expected finances, food needs, and identity to obtain expected level of need satisfaction ;;;;;;;;;;;;

            ifelse ((exp_finance >= 0) and (exp_foodPC >= 0) and (exp_identity >= 0))     ;; if all three are more than 0, calculate expLNS accordingly
            [
              set expLNS ((1 - exp (-0.005 * (exp_foodPC))) ^ LNSa_exis) * ((1 - exp( - 5 * exp_finance)) ^ LNSa_taste) * ((1 - exp( 0 - exp_identity)) ^ LNSa_iden) * ((1 - exp( - 2 * (1 - FT - MT))) ^ LNSa_leis)
            ]
            [set expLNS 0]                                  ;; otherwise, set it to 0

            if expLNS > maxLNS                              ;; if expected LNS is more than maximum LNS
            [ set maxLNS expLNS                             ;; update maxLNS
              set bestMT MT                                 ;; update bestMT
              set bestFT FT ]                               ;; update bestFT
             set MT MT + 0.1                                ;; go to next iteration with MT incremented by 0.1
          ]
          set FT FT + 0.1                                   ;; go to next iteration with FT incremented by 0.1
        ]
        set desMiningtime bestMT                            ;; set new mining and fishing times with obtained values
        set desFishingtime bestFT
      ]

      [ ;;;;;; Social comparison ;;;;;;                     ;; agent level of need satisfaction is low and uncertainty is high
        set NumSocCom NumSocCom + 1                         ;; increment counter of social comparison agents
        let fs FishSkill                                    ;; temp variable for agent's level of fishing skill
        let ms MineSkill                                    ;; temp variable for agent's level of mining skill
        set desMiningtime mean [Miningtime] of consumats with [abs(FishSkill - fs) < 0.05 and abs(MineSkill - ms) < 0.05]     ;; set new mining and fishing time to avg of
        set desFishingtime mean [Fishingtime] of consumats with [abs(FishSkill - fs) < 0.05 and abs(MineSkill - ms) < 0.05]   ;; old values of agent sub-population
                                                                                                                            ;; (based on similarity of fishing skill and mining skill)
      ]
    ]
    [
      ifelse Uncertainty = 0
      [ ;;;;; Repetition ;;;;;;                               ;; agent level of need satisfaction is high and uncertainty is low
        ;; x_{j,t} = x_{j,t-1}
        set NumRep NumRep + 1                                 ;; increment counter for repetitive agents
        set desMiningtime Miningtime                          ;; set new mining time and fishing time
        set desFishingtime Fishingtime                        ;; to the previous values of this agent
      ]
      [ ;;;; Imitation ;;;;;                                 ;; agent level of need satisfaction is high and uncertainty is high
        set NumIm NumIm + 1                                  ;; increment counter for imitative agents
        set desMiningtime mean [Miningtime] of consumats       ;; set new mining time and fishing time to the average
        set desFishingtime mean [Fishingtime] of consumats     ;; of the old values of the agent population
      ]
    ]
  ]

  ;;;;;;;;;;; make changes ;;;;;;;;;;;;;;

  ask consumats [
    set Miningtime desMiningtime                             ;; set mining time and fishing time based on the behaviour chosen for each agent
    set Fishingtime desFishingtime
  ]
end



to fishdynamics                                 ;;;;;;; Calculate local and global variables, esp fish population and gold resource left ;;;;;;;;

  ask consumats [                                                                                     ;; For each agent:

    set GoldMining_Rate MineSkill * Miningtime * Gold_Resource                                      ;; Calculate gold mining rate

    set Expcatch ActFishSkill                                                                       ;;
    set FishCom Fishingtime * expcatch - FishDemand                                                 ;; what's fishcom?
    set Desired_Catch FishDemand + FishCom                                                          ;; Calculate desired catch
    if Desired_Catch < 0 [set Desired_Catch 0]

    set MaxBuyFish (Locpop_Finance + GoldMining_Rate * (1 - GoldTaxRate)) / WorldMFishprice         ;; Calculate max no. of fish agent can buy

    set Fish_Catch Fishingtime * FishSkill * Fish_pop * random-normal 1 0.05                        ;; Calculate no. of fish agent can catch
    if Fish_Catch < 0 [set Fish_Catch 0]

    ;;;;;;;; Calculate food_pc ;;;;;;;;;;

    ifelse Fish_Catch < FishDemand
    [                                                                       ;; if fish catch is less than fish demand
      ifelse MaxBuyFish > (FishDemand - Fish_Catch)                         ;; and agent can buy more fish than the diff b/w demand and catch
      [set Food_PC FishDemand]                                              ;; set food_pc to fish demand
      [set Food_PC Fish_Catch + MaxBuyFish]                                 ;; if fish catch is less than fish demand, set food_pc to catch + bought fish (which is less than demand)
    ]
    [set Food_PC FishDemand]                                                ;; if fish catch is more than fish demand, set food_pc to fish demand (?)

    ;;;;;;;; Calculate Actual fishing skill ;;;;;;;;

    ifelse Fishingtime > 0                                           ;; if fishing time is more than 0
    [set ActFishSkill Fish_Catch / Fishingtime]                      ;; set actual fishing skill to no. of fish caught per unit time
    [set ActFishSkill 0]                                             ;; otherwise, set to 0

    ; Finance

    set ExpFinance   Locpop_Finance + GoldMining_Rate * (1 - GoldTaxRate / 100) + (1 - FishTaxRate / 100) * FishCom * WorldMFishPrice

    ;;;;;;; Calculate supply income, gross income, and income ;;;;;;;

    ifelse Fish_Catch < FishDemand                                         ;; if fish catch is less than demand
    [set Supply_Income 0]                                                  ;; agent doesn't gain anything
    [set Supply_Income (Fish_Catch - FishDemand) * WorldMFishPrice]        ;; otherwise, agent gets income from surplus fish acc. to world mkt fish price

    set Locpop_IncomeGross   GoldMining_Rate + Supply_Income               ;; Calculate gross income

    set Locpop_Income  (1 - GoldTaxRate / 100) *  GoldMining_Rate + (1 - FishTaxRate / 100) * Supply_Income    ;; Calculate income (after taxes on fish and gold)

    ;;;;;;;;; Calculate shortage cost ;;;;;;;;;;

    ifelse Fish_Catch < FishDemand                                         ;; if fish catch is less than demand
    [
      ifelse MaxBuyFish > (FishDemand - Fish_Catch)                        ;; and agent can buy more fish than the diff b/w demand and catch
      [set Shortage_Cost WorldMFishPrice * (FishDemand - Fish_Catch)]      ;; set shortage cost acc to how many fish the agent can buy
      [set Shortage_Cost MaxBuyFish * WorldMFishPrice]                     ;;
    ]
    [set Shortage_Cost 0]                                                  ;; if fish catch is more than demand, set shortage cost to 0

    ;;;;;;;;; Calculate local population finance level ;;;;;;;;

    set Locpop_Finance Locpop_Finance + Locpop_Income - Shortage_Cost
    if Locpop_Finance < 0 [set Locpop_Finance 0]

  ]

  set FishCatchtot sum [Fish_Catch] of consumats                                          ;; set total fish catch of agent population to sum of fish catches of individual agents
  set GoldMining_Ratetot sum [GoldMining_Rate] of consumats                               ;; set total gold mining rate of agent population to sum of gold mining rates of individual agents

  set Gold_Resource Gold_Resource - GoldMining_Ratetot                                  ;; adjust gold resource by subtracting the total amount of gold extracted by agent population

  set Pollution (GoldMining_Ratetot / 100) + (1 - removalrate) * Pollution              ;; calculate pollution caused by gold mining

  set Carrying_Capacity 100 * (1 - Pollution)                                           ;; the level of pollution changes the carrying capacity of the lake

  set Fish_pop Fish_pop + Growth_rate * Fish_pop * ( 1 - Fish_pop / Carrying_Capacity) - FishCatchtot          ;; update the fish population

end
@#$#@#$#@
GRAPHICS-WINDOW
350
10
787
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
6
10
75
43
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
86
11
153
44
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

SLIDER
8
64
182
97
num_consumats
num_consumats
0
100
16.0
1
1
NIL
HORIZONTAL

PLOT
766
463
966
613
Pollution
NIL
NIL
0.0
10.0
0.0
1.0E-5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot Pollution"

BUTTON
165
12
228
45
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
108
180
141
Season_Length
Season_Length
0
1
0.8
0.01
1
NIL
HORIZONTAL

PLOT
118
464
340
613
Fishcatch
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [plot Fishcatchtot]"

PLOT
970
163
1273
314
Time
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Fishing" 1.0 0 -16777216 true "" "plot mean [Fishingtime] of turtles"
"Mining" 1.0 0 -13345367 true "" "plot mean [Miningtime] of turtles"

PLOT
344
464
557
613
finance
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [Locpop_Finance] of turtles"

PLOT
562
464
762
614
LNS
NIL
NIL
0.0
100.0
0.0
1.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [LNS] of turtles"

SLIDER
8
193
180
226
LNSmin
LNSmin
0
1
0.55
0.01
1
NIL
HORIZONTAL

SLIDER
8
236
180
269
Umax
Umax
0
1
0.41
0.01
1
NIL
HORIZONTAL

PLOT
970
318
1274
487
Resources
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Fish" 1.0 0 -14070903 true "" "plot Fish_pop"
"Gold" 1.0 0 -7500403 true "" "plot Gold_Resource"

SLIDER
8
150
180
183
removalrate
removalrate
0
1
0.01
0.01
1
NIL
HORIZONTAL

PLOT
969
10
1272
160
Cognitive Process
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Deliberation" 1.0 0 -13791810 true "" "plot NumDel"
"Repetition" 1.0 0 -13840069 true "" "plot NumRep"
"Social Comp" 1.0 0 -5298144 true "" "plot NumSocCom"
"Imitation" 1.0 0 -1184463 true "" "plot NumIm"

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
NetLogo 6.0.1
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
