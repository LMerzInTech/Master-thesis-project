;; (c) Laura Merz, 2019
;; Automation-induced Reshoring: An Agent-based Model of the German Manufacturing Industry


breed [ firms firm ]   ;; defines agentset and agent


globals [   ;; general parameters accessible by all agents from across the world
  high-skilled-labour-ratio ]   ;; ratio of high-skilled labour required for production


firms-own [   ;; parameters relevant to agents only
  working-capital   ;; difference between a firm's current assets and liabilities
  budget-for-labour-costs   ;; allocated budget for covering labour wages
  raw-material-costs   ;; allocated amount covering raw material costs
  firm-size   ;; defines the size of the firms depending on their working capital
  offshored?   ;; label reporting whether production is offshored or not
  reshored?   ;; label reporting whether production has been reshored or not
  max-level-of-automation    ;; maximum level of attainable efficiency of automated production
  level-of-automation    ;; current level of efficiency of automated production
  actual-low-skilled-labour-ratio   ;; calculated ratio accounting for the level of automation which has already replaced low-skilled jobs
  actual-high-skilled-labour-ratio   ;; calculated ratio accounting for the level of automation which has already replaced high-skilled jobs
  robots   ;; afforded amount of robots utilised for production
  low-skilled-labour   ;; afforded number of low-skilled labour employed for production in Germany
  high-skilled-labour   ;; afforded number of high-skilled labour employed for production in Germany
  low-skilled-labour-abroad   ;; afforded number of low-skilled labour employed for offshored production
  high-skilled-labour-abroad   ;; afforded number of high-skilled labour employed for offshored production
  human-labour   ;; number of human labour units employed for production in Germany
  human-labour-abroad   ;; number of human labour units employed for offshored production
  labour-units   ;; total number of all labour units employed or utilised for production in Germany
  labour-units-abroad   ;; total number of all labour units employed or utilised for offshored production
  actual-labour-costs   ;; actual budget covering labour wages
  automation-costs   ;; actual budget covering robot utilisation (e.g. energy bill)
  output   ;; amount of produced goods if production is located in Germany
  output-abroad    ;; amount of produced goods if production is offshored
  revenue   ;; total income received by selling produced goods if production is located in Germany
  revenue-abroad   ;; total income received by selling produced goods if production is offshored
  r&d-investment   ;; allocated investment in R&D if production is located in Germany
  r&d-investment-abroad   ;; allocated investment in R&D if production is offshored
  foreign-surcharges   ;; allocated surcharges if production is offshored (e.g. shipping costs or import tariffs)
  relocation-costs   ;; allocated costs required in case of relocation
  profit   ;; net financial gain at the end of a business cycle if production is in Germany
  profit-abroad   ;; net financial gain at the end of a business cycle if production is offshored
]


to setup
  clear-all   ;; resets all global variables to zero
  clear-all-plots   ;; resets every plot in the model
  setup-economy   ;; creates the geography of the modelled world divided into Germany in the North and abstracted countries of the global South
  setup-industry   ;; creates the initial configuration of firms within the manufacturing industry
  reset-ticks   ;; resets the tick counter to zero
end


to setup-economy
  ask patches with [ pycor > 0 ] [
    set pcolor 98 ]   ;; colours Germany in a shade of blue
  ask patches with [ pycor = 0 ] [
    set pcolor white ]   ;; colours the equator white
  ask patches with [ pycor < 0 ] [
  set pcolor 48 ]   ;; colours abstracted countries of the global South in a shade of yellow
  create-firms number-of-firms   ;; defines the total number of firms representing the modelled economy [see: slider on interface]
end


to setup-industry
  setup-firms   ;; defines the initial parameter values of firms
  offshoring   ;; defines the initial number of offshored firms
  tech-state-of-the-art   ;; states the firms' technological state of the art
  costs-calculation   ;; divides the working capital into raw material costs and the budget allocated for labour wages
  human-vs-robot   ;; defines the ratios of low-skilled human labour, high-skilled human labour, and robots required for production
  employment   ;; calculates the type of labour units employed or utilised
  output-calculation   ;; calculates the amount of produced goods
  revenue-calculation   ;; calculates the total income received by selling produced goods
  r&d-calculation   ;; calculates the particular share of revenue invested in R&D
  profit-calculation   ;; calculates the net financial gain at the end of a business cycle
  firms-size-ratio   ;; defines the size of the firms
end


to go   ;; let's simulate!
  ask firms [
    ifelse ( offshored? = false ) [   ;; stocktaking of working capital
      set working-capital working-capital - raw-material-costs - actual-labour-costs - automation-costs + profit ] [   ;; working capital of the coming business cycle is calculated by deducting last time periods' liabilities from the assets
      set working-capital working-capital - raw-material-costs - actual-labour-costs - automation-costs + profit-abroad ] ]   ;; applies in case of offshored production
  technological-progress   ;; efficiency of automated production increases proportional to R&D investment
  costs-calculation
  human-vs-robot
  employment
  output-calculation
  revenue-calculation
  r&d-calculation
  profit-calculation
  location-decision   ;; states the conditions of decision-making concerning relocation
  firms-size-ratio
  bankruptcy   ;; states the conditions leading to bankruptcy
  tick   ;; advances the tick counter by one time period
  if ticks = 100 [ stop ]   ;; defines the length of each simulation run
end


to-report random-between [ min-num max-num ]   ;; auxiliary code
   report random-float (max-num - min-num) + min-num
end


to setup-firms
  ask firms [
    set working-capital random 1000   ;; initial seed capital is a random value between >0 and <1000
    set max-level-of-automation 0 + random-float 1 ]   ;; maximum level of attainable efficiency in automation is defined as a fixed random value between >0 and <1
end


to offshoring
  ask firms [
    set offshored? false   ;; initially all firms report that they have not offshored
    set reshored? false   ;; no firm has initially reshored
    let offshored-firms ( min-n-of ( count firms * ( share-of-offshored-firms / 100 ) ) firms [ max-level-of-automation ] )   ;; firms with a lower attainability of automation have a higher incentive to offshore where manual labour is cheaper [see: slider on interface]
      ask offshored-firms [
        setxy random-xcor random-between ( -10 ) -1   ;; spreads firms randomly on the map abroad
        set offshored? true ] ]   ;; reports production location
  ask firms with [ offshored? = false ] [
    setxy random-xcor random-between ( 10 ) 1 ]   ;; spreads firms randomly on the map of Germany
end


to tech-state-of-the-art
  ask n-of ( count firms * ( share-of-automated-firms / 100 ) ) firms [   ;; initial share of firms already utilising robots [see: slider on interface]
    set level-of-automation random-between ( 0.01 ) max-level-of-automation ]   ;; current efficiency of automated production is a random value between >0 and the specified maximum attainable level of automation
  ask firms [
    set color scale-color orange level-of-automation 0 1 ]   ;; dark colour shading depicts a low level of automation wheareas a light orange stands for high levels of automation
end


to technological-progress
  ask firms with [ offshored? = false ] [
    ifelse ( ( level-of-automation + r&d-investment ) < max-level-of-automation ) [   ;; R&D investment cannot increase the level of automation beyond its maximum attainable level
      set level-of-automation level-of-automation + r&d-investment ] [   ;; level of automation rises in proportion to the R&D investment
      set level-of-automation max-level-of-automation  ] ]  ;; current level of automation has reached the maximum attainable level
  ask firms with [ offshored? = true ] [
    ifelse ( ( level-of-automation + r&d-investment-abroad ) < max-level-of-automation ) [   ;; applies in case of offshored production
      set level-of-automation level-of-automation + r&d-investment-abroad ] [
      set level-of-automation max-level-of-automation  ] ]
  ask firms [
    set color scale-color orange level-of-automation 0 1 ]
end


to costs-calculation
  ask firms [
    set raw-material-costs working-capital * ( share-of-raw-material-costs / 100 )   ;; allocates the amount covering raw material costs by a defined share [see: slider on interface]
    set budget-for-labour-costs working-capital - raw-material-costs ]   ;; allocates budget for covering labour wages
end


to-report share-of-labour-costs   ;; auxiliary code [see: monitor on interface]
  report ceiling ( 100 - share-of-raw-material-costs )   ;; reports the percentage of working capital allocated for covering labour wages [see: slider on interface]
end


to human-vs-robot
  ask firms [
    set high-skilled-labour-ratio 1 - low-skilled-labour-ratio   ;; calculates the ratio of high-skilled labour in proportion to a defined ratio of low-skilled labour [see: slider and monitor on interface]
    ifelse ( level-of-automation >= robots-kill-jobs-threshold ) [   ;; technological threshold at which robots eliminate all low-skilled jobs [see: slider on interface]
      set actual-low-skilled-labour-ratio 0   ;; applies in case the threshold is reached as all low-skilled labour becomes obsolete
      set actual-high-skilled-labour-ratio 1 - level-of-automation ] [   ;; applies in case the threshold is reached as labour is then shared between high-skilled labour and robots
    set actual-low-skilled-labour-ratio ( 1 - level-of-automation ) * low-skilled-labour-ratio   ;; accounts for the level of automation which has already replaced human low-skilled jobs
    set actual-high-skilled-labour-ratio ( 1 - level-of-automation ) * high-skilled-labour-ratio ] ]   ;; accounts for the level of automation which has already replaced human high-skilled jobs
end


;floor = reports the largest integer less than or equal to the number as a decimal number would not be realistic here as the unit of measurment are people
to employment
  ask firms [   ;; the ratios determine the varying shares of the three different types of labour units
    let budget-for-robots budget-for-labour-costs * level-of-automation   ;; allocated budget for covering robot costs
    let budget-for-low-skilled-labour budget-for-labour-costs * actual-low-skilled-labour-ratio   ;; allocated budget for covering low-skilled labour wages
    let budget-for-high-skilled-labour budget-for-labour-costs * actual-high-skilled-labour-ratio   ;; allocated budget for covering high-skilled labour wages
    set robots floor ( budget-for-robots / robot-costs )   ;; afforded amount of robots utilised for production
    set low-skilled-labour floor ( budget-for-low-skilled-labour / wages-low-skilled-labour )   ;; afforded number of low-skilled labour employed for production in Germany [see: slider on interface]
    set high-skilled-labour floor ( budget-for-high-skilled-labour / wages-high-skilled-labour )   ;; afforded number of high-skilled labour employed for production in Germany [see: slider on interface]
    set human-labour low-skilled-labour + high-skilled-labour   ;; number of human labour units employed for production in Germany
    set labour-units robots + low-skilled-labour + high-skilled-labour   ;; number of total labour units utilised for production in Germany
    set low-skilled-labour-abroad floor ( budget-for-low-skilled-labour / wages-low-skilled-labour-abroad )   ;; afforded number of low-skilled labour employed for offshored production [see: slider on interface]
    set high-skilled-labour-abroad floor ( budget-for-high-skilled-labour / wages-high-skilled-labour-abroad )   ;; afforded number of high-skilled labour employed for offshored production [see: slider on interface]
    set human-labour-abroad low-skilled-labour-abroad + high-skilled-labour-abroad   ;; number of human labour units employed for offshored production
    set labour-units-abroad robots + low-skilled-labour-abroad + high-skilled-labour-abroad ]   ;; number of total labour units utilised for offshored production
  ask firms [
    ifelse ( offshored? = false ) [
      set actual-labour-costs (   ;; actual budget covering labour wages for production in Germany [see: slider on interface]
        low-skilled-labour * wages-low-skilled-labour ) + (
        high-skilled-labour * wages-high-skilled-labour )
      set automation-costs   ;; actual budget covering robot utilisation for production in Germany [see: slider on interface]
        robots * robot-costs ] [
      set actual-labour-costs (   ;; actual budget covering labour wages for offshored production [see: slider on interface]
        low-skilled-labour-abroad * wages-low-skilled-labour-abroad ) + (
        high-skilled-labour-abroad * wages-high-skilled-labour-abroad )
      set automation-costs   ;; actual budget covering robot utilisation for offshored production [see: slider on interface]
        robots * robot-costs ] ]
end


to output-calculation
  ask firms [
      set output (
        human-labour * labour-productivity ) + (   ;; amount of output human labour employed in Germany produce per time step [see: slider on interface]
        robots * robot-productivity )   ;; amount of output a robot produces per time step [see: slider on interface]
       set output-abroad (
        human-labour-abroad * labour-productivity ) + (   ;; amount of output human labour employed abroad produce per time step [see: slider on interface]
        robots * robot-productivity ) ]
end


to revenue-calculation
  ask firms [
    set revenue output * sales-price-per-product   ;; total income received by selling produced goods to a global sales price if production is located in Germany [see: input on interface]
    set revenue-abroad output-abroad * sales-price-per-product ]   ;; total income received by selling produced goods to a global sales price if production is offshored [see: input on interface]
end


to r&d-calculation
  ask firms [
    set r&d-investment revenue * ( share-for-r&d-investment / 100 )   ;; allocated investment in R&D if production is located in Germany [see: slider on interface]
    set r&d-investment-abroad revenue-abroad * ( share-for-r&d-investment / 100 )   ;; allocated investment in R&D if production is offshored [see: slider on interface]
    if level-of-automation = max-level-of-automation [   ;; if the current level of automation reaches its maximum attainable level...
      set r&d-investment 0   ;; ...investment in R&D is no longer needed
      set r&d-investment-abroad 0 ] ]   ;; applies in case of offshored production
end


to profit-calculation
  ask firms [
    set foreign-surcharges revenue-abroad * ( share-for-foreign-surcharges / 100 )   ;; defined percentage of revenue which is additionally required if production is offshored (e.g. shipping costs or import tariffs) [see: slider on interface]
    set profit revenue - r&d-investment   ;; calculates the net financial gain at the end of a business cycle if production is in Germany
    set profit-abroad revenue-abroad - r&d-investment-abroad - foreign-surcharges ]   ;; calculates the net financial gain at the end of a business cycle if production is offshored
end


to location-decision
  ask firms with [ offshored? = false ] [
    set relocation-costs ( share-for-relocation-costs / 100 ) * profit   ;; defined percentage of profit required in case of offshoring production [see: slider on interface]
    if ( profit < ( profit-abroad - relocation-costs ) ) [   ;; if the profit when producing in Germany is smaller than the profit the firm could have generated abroad despite taking relocation costs into account...
      move-to one-of patches with [ pcolor = 48 and not any? turtles-here ]   ;; ...then the firm decides to offshore
      set offshored? true   ;; reports the offshoring decision
      set reshored? false ] ]   ;; reports that no decision for reshoring was taken
  ask firms with [ offshored? = true ] [
    set relocation-costs ( share-for-relocation-costs / 100 ) * profit-abroad   ;; defined percentage of profit required in case of reshoring production [see: slider on interface]
    if ( profit-abroad < ( profit - relocation-costs ) ) [   ;; if the profit when producing abroad is smaller than the profit the firm could have generated in Germany despite taking relocation costs into account...
      move-to one-of patches with [ pcolor = 98 and not any? turtles-here ]   ;; ...then the firm decides to reshore
      set offshored? false   ;; reports that no decision for offhoring was taken
      set reshored? true ] ]   ;; reports the reshoring decision
end


to firms-size-ratio
  ask firms [
    set firm-size "medium"   ;; the firms which are not particularly low or high in working capital are of medium size
    set size 1
    set shape "house" ]
  ask ( max-n-of ( number-of-firms * 0.1 ) firms [ working-capital ] ) [
    set firm-size "large"   ;; the 10 % firms with the highest value of working capital are large in size
    set size 1.5
    set shape "house" ]
  ask ( min-n-of ( number-of-firms * 0.3 ) firms [ working-capital ] ) [
    set firm-size "small"   ;; the 30 % firms with the lowest value of working capital are small in size
    set size 0.5
    set shape "house" ]
end


to bankruptcy
  ask firms [
    if working-capital <= 10 [ die ] ]   ;; firms become bankrupt after reaching a specified threshold and are then no longer part of the economy
end


to-report total-working-capital   ;; auxiliary code: monitors the total working capital of all firms [see: plot on interface]
  report ( sum [ working-capital ] of firms )
end


to-report working-capital-of-firms   ;; auxiliary code: monitors the working capital of firms in Germany [see: plot on interface]
  report ( sum [ working-capital ] of firms with [ offshored? = false ] )
end


to-report working-capital-of-firms-abroad   ;; auxiliary code: monitors the working capital of offshored firms [see: plot on interface]
  report ( sum [ working-capital ] of firms with [ offshored? = true ] )
end


to-report percentage-of-firms   ;; auxiliary code: monitors the % of firms in Germany [see: monitor on interface]
  report ( ( count firms with [ ycor > 0 ] ) / count firms ) * 100
end


to-report percentage-of-firms-abroad   ;; auxiliary code: monitors the % of offshored firms [see: monitor on interface]
  report ( ( count firms with [ ycor < 0 ] ) / count firms ) * 100
end


to-report small-firm-size   ;; auxiliary code: monitors the number of small-sized firms [see: monitor on interface]
  report ( ( count firms with [ firm-size = "small" ] ) / count firms ) * 100
end


to-report medium-firm-size   ;; auxiliary code: monitors the number of medium-sized firms [see: monitor on interface]
  report ( ( count firms with [ firm-size = "medium" ] ) / count firms ) * 100
end


to-report large-firm-size   ;; auxiliary code: monitors the number of large-sized firms [see: monitor on interface]
  report ( ( count firms with [ firm-size = "large" ] ) / count firms ) * 100
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
561
362
-1
-1
16.333333333333332
1
10
1
1
1
0
1
1
1
-10
10
-10
10
0
0
1
ticks
30.0

BUTTON
9
78
209
187
Setup
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

SLIDER
9
10
209
43
number-of-firms
number-of-firms
0
500
100.0
1
1
NIL
HORIZONTAL

MONITOR
562
10
846
55
Firms in Germany (in %)
round percentage-of-firms
17
1
11

MONITOR
562
124
846
169
Offshored firms (in %)
round percentage-of-firms-abroad
17
1
11

BUTTON
154
44
209
77
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
562
306
846
488
Geographic location of firms
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
"Germany" 1.0 0 -5516827 true "" "plot percentage-of-firms"
"Offshored" 1.0 0 -526419 true "" "plot percentage-of-firms-abroad"

SLIDER
562
56
846
89
wages-low-skilled-labour
wages-low-skilled-labour
0
100
11.0
1
1
p.a.
HORIZONTAL

SLIDER
562
204
846
237
wages-low-skilled-labour-abroad
wages-low-skilled-labour-abroad
0
100
10.0
1
1
p.a.
HORIZONTAL

MONITOR
9
188
209
233
% of low-income firms
round small-firm-size
17
1
11

MONITOR
9
235
209
280
% of medium-income firms
round medium-firm-size
17
1
11

MONITOR
9
282
209
327
% of high-income firms
round large-firm-size
17
1
11

BUTTON
9
44
153
77
Go once
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
210
363
561
396
share-of-raw-material-costs
share-of-raw-material-costs
0
99
50.0
0.1
1
%
HORIZONTAL

SLIDER
562
170
846
203
share-of-offshored-firms
share-of-offshored-firms
0
100
8.0
1
1
%
HORIZONTAL

SLIDER
562
238
846
271
wages-high-skilled-labour-abroad
wages-high-skilled-labour-abroad
0
100
11.0
1
1
p.a.
HORIZONTAL

SLIDER
562
90
846
123
wages-high-skilled-labour
wages-high-skilled-labour
0
100
12.0
1
1
p.a.
HORIZONTAL

SLIDER
562
557
846
590
robot-costs
robot-costs
0
100
20.0
0.1
1
per year
HORIZONTAL

SLIDER
210
557
561
590
share-for-r&d-investment
share-for-r&d-investment
0
100
1.0
0.1
1
%
HORIZONTAL

SLIDER
562
272
846
305
share-for-foreign-surcharges
share-for-foreign-surcharges
0
100
1.0
0.1
1
%
HORIZONTAL

SLIDER
210
443
561
476
low-skilled-labour-ratio
low-skilled-labour-ratio
0
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
562
591
846
624
robots-kill-jobs-threshold
robots-kill-jobs-threshold
0
1
0.8
0.1
1
NIL
HORIZONTAL

TEXTBOX
852
491
1002
510
Automation
15
74.0
1

SLIDER
210
591
561
624
share-for-relocation-costs
share-for-relocation-costs
0
100
1.0
0.1
1
%
HORIZONTAL

TEXTBOX
10
630
206
668
Industry-specifics
15
74.0
1

TEXTBOX
850
126
1000
145
Foreign economy
15
74.0
1

TEXTBOX
850
12
1000
31
German economy
15
74.0
1

SLIDER
562
523
846
556
robot-productivity
robot-productivity
0
10
10.0
1
1
product x 1 robot = output
HORIZONTAL

INPUTBOX
9
557
209
624
sales-price-per-product
20.0
1
0
Number

MONITOR
210
397
561
442
share-of-labour-costs (in %)
share-of-labour-costs
17
1
11

MONITOR
210
477
561
522
high-skilled-labour-ratio
precision high-skilled-labour-ratio 1
17
1
11

SLIDER
210
523
561
556
labour-productivity
labour-productivity
0
10
1.0
1
1
product x 1 labour = output
HORIZONTAL

SLIDER
562
489
846
522
share-of-automated-firms
share-of-automated-firms
0
100
29.0
1
1
%
HORIZONTAL

PLOT
9
329
209
556
Working capital of firms
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
"default" 1.0 0 -526419 true "" "plot working-capital-of-firms-abroad"
"pen-1" 1.0 0 -5516827 true "" "plot working-capital-of-firms"
"pen-2" 1.0 0 -7500403 true "" "plot total-working-capital"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(My pseudocode description:

Initial (SETUP):
The world is divided in the global North (green) and the global South (yellow). The agents in this model are FIRMS. 
The amount of created FIRMS can be decided on through a slider on the interface.
Industrial robots are not very productive. 
According to recent data, about 25% of FIRMS are initially offshored in the global South. 3% are automated and have their production in the global North. 
There is a chooser called OUTPUT.
	If the OUTPUT is LOW, the firm is coloured light orange. 
	If the OUTPUT is MEDIUM, the firm is coloured orange. 
	If the OUTPUT is HIGH, the firm is coloured intensely orange. 

Iterative (GO):
Technological progress increases with eyery tick, which means that the FIRMS-OWN variable Q (efficiency of automation) increases by 4%.
The share of firms utilising automation to produce increases with rising Q.
Offshoring production declines.
Production making use of unskilled labour at home declines.
When Q rises, the wage for unskilled labour declines.
But there is more and better paid high-skilled labour induced through reshoring.
With increasing Q and an increased share of automated firms, the stock of intermediates in final goods production increases, which induces GDP and high-skill wages to rise. 
Measure for reshoring at the macro level: Rt = (DIt/FIt) - (DIt-1/FIt-1); restriction is Rt > 0
Positive association between reshoring and labour market conditions (employment, hours worked, earnings) of high-skilled labour.

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

As a result of the opposing trends concerning wages of low- and high-skill labour, inequality increases.

With ongoing technological progress, a positive association between robots and reshoring can be expected. Further, a negative association between reshoring and low-skilled wages but a positive association between reshoring and high-skilled wages is likely.

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

Experiments:
Rise of tariffs (from 5 to 10 percent)
	No effect on low-skill labour at home
	More automation at home
	Mild decline of high-skill labour at home
	Average productivity of firms declines
	Aggregate stock of intermediate goods declines
	Mild negative effect on the productivity of complementing high-skill labour

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="20190430" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>sum [capital] of firms</metric>
    <metric>sum [capital] of firms with [offshored? = false]</metric>
    <metric>sum [capital] of firms with [offshored? = true]</metric>
    <metric>mean [level-of-automation] of firms</metric>
    <metric>mean [level-of-automation] of firms with [offshored? = false]</metric>
    <metric>mean [level-of-automation] of firms with [offshored? = true]</metric>
    <metric>count firms with [level-of-automation = max-level-of-automation]</metric>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="4"/>
      <value value="12"/>
      <value value="20"/>
      <value value="28"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="8"/>
      <value value="24"/>
      <value value="40"/>
      <value value="56"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190507 share-for-relocation-costs" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="0.9"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Initial setting" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190507 share-for-foreign-surcharges" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190507 wages-labour-abroad" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <steppedValueSet variable="wages-low-skilled-labour-abroad" first="0" step="5" last="100"/>
    <steppedValueSet variable="wages-high-skilled-labour-abroad" first="0" step="10" last="200"/>
  </experiment>
  <experiment name="20190508 Share of relocation cost threshold at 1.5%" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="0.1"/>
      <value value="1.4"/>
      <value value="1.5"/>
      <value value="1.6"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 share-for-relocation-costs" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="0.1"/>
      <value value="0.9"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="10"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-costs">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 robot-costs" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="robot-costs">
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 robots-kill-jobs-threshold" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <steppedValueSet variable="robots-kill-jobs-threshold" first="0.1" step="0.1" last="1"/>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-costs">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 robot-productivity" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="robot-productivity">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-costs">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 Initial parameter setting" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-costs">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 share-for-foreign-surcharges" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="robot-costs">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="0.1"/>
      <value value="0.9"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 sales-price-per-product" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="robot-costs">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="1"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 wages-labour-abroad" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="1"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="1"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-costs">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="20190511 wages-labour-at-home" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count firms</metric>
    <metric>count firms with [offshored? = false]</metric>
    <metric>count firms with [offshored? = true]</metric>
    <metric>[level-of-automation] of firms</metric>
    <metric>[level-of-automation] of firms with [offshored? = false]</metric>
    <metric>[level-of-automation] of firms with [offshored? = true]</metric>
    <metric>[capital] of firms</metric>
    <metric>[capital] of firms with [offshored? = false]</metric>
    <metric>[capital] of firms with [offshored? = true]</metric>
    <enumeratedValueSet variable="robots-kill-jobs-threshold">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-abroad">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-for-raw-material">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-raw-material-costs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-at-home">
      <value value="1"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-offshored-firms">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-high-skilled-labour-abroad">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-productivity">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-foreign-surcharges">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-r&amp;d-investment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="low-skilled-labour-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-firms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="labour-productivity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-for-relocation-costs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-costs">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-low-skilled-labour-at-home">
      <value value="1"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sales-price-per-product">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-of-automated-firms">
      <value value="29"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
