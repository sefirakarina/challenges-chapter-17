;the layout of this model is based on Traffic Grid Model by Uri Wilensky
;https://theconversation.com/how-long-are-you-infectious-when-you-have-coronavirus-135295
; https://www.savings.com.au/savings-accounts/average-savings-australia
; https://www.homeloanexperts.com.au/mortgage-calculators/living-expenses-calculator/#:~:text=Living%20cost%20in%20Australia%20for,a%20family%20of%204%3A%20%245%2C378
;https://www.worldometers.info/coronavirus/country/australia/ -  by the time I work on this the overall death out of 100% infected is 3%

; Sefira Karina / s3766199

globals
[
  roads
  grid-x-inc
  grid-y-inc
  stores
  workPlaces
  deathCount
  time
  days
  overallTime

  infectedToday
  recoverToday

  recoveryNum
  lastInfected
  beta
  overallContagiousDays
  overallInfectedDaysToday
  gamma
  r0
  avgRecoveryRate

  infectedNew

  lockdownSet?
]

turtles-own [
  infected?    ;; has the person been infected with the disease?
  infectedDays
  contagiousDays
  contagious?
  infectionStatus
  occupation
  house
  occupationPlace
  wealth
  salary
  travelChance
  infectedDay
  go-today?
  fired?
  destination
]


;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all



  setup-globals
  setup-patches

  set-default-shape turtles "person"
  make-turtles
  set-plot
  infect
  set-go-today
  setup-wealth-graph

  set lockdownSet? false


  reset-ticks
end

to set-plot

  set-current-plot "wealth"
  set-current-plot-pen "wealth-pen"
  set-plot-pen-mode 2
  set-plot-x-range 0 num-people
  set-plot-y-range 0 80000

end

to-report rand100

  report random 100

end



to make-turtles

  create-turtles num-people [


    set infected? false
    setxy random-xcor random-ycor

    let locations patches with [
      pcolor = 38 and any? neighbors with [ pcolor = white ]
    ]


    set house one-of locations

    ask house[set pcolor 136]

    set wealth (min-starting-wealth + random (max-starting-wealth - min-starting-wealth))

    set salary (min-income-per-day + random (max-income-per-day - min-income-per-day))

    set occupation "worker"
    set fired? false

    set travelChance healthy-travel-chance

    set infectedDays 0
    set contagiousDays 0
    set contagious? false
    set infectionStatus "N/A"

    set occupationPlace one-of workPlaces


    move-to house

    set color green
  ]

end


to setup-globals
  set grid-x-inc world-width / 1
  set grid-y-inc world-height / 8

  set overallInfectedDaysToday 0
  set recoverToday 0
  set infectedToday 0

  set days 1
  set time 1
  set overallTime 1

  set r0 0
  set recoveryNum 0
  set lastInfected 0
  set overallContagiousDays 0

  set infectedToday 0
  set deathCount 0
  set infectedNew 0

end

to setup-patches
  ask patches [
    set pcolor brown + 3
  ]
  ;; initialize the global variables that hold patch agentsets
  set roads patches with [
    (floor ((pxcor + max-pxcor - floor (grid-x-inc - 1)) mod grid-x-inc) = 0) or
    (floor ((pycor + max-pycor) mod grid-y-inc) = 0)
  ]


  ask roads [ set pcolor white ]

  setup-stores
  setup-workPlaces
end



to setup-workPlaces
  set workPlaces n-of workSpaces patches with [
    pcolor = 38 and any? neighbors with [ pcolor = white ]
  ]
  ask workPlaces [set pcolor 115 ]


  ask workPlaces[
     ask patches in-radius 1[
      if(pcolor != white)[
        set pcolor 115
      ]
    ]
  ]

  set workPlaces patches with [pcolor = 115 ]
end

to setup-stores
  set stores n-of stores-num patches with [
    pcolor = 38 and any? neighbors with [ pcolor = white ]
  ]
  ask stores [set pcolor 67 ]

end


to infect
  ask n-of num-infected turtles [
;    set infectedToday num-infected

    set infected? true
    set infectedDays random 23

    ifelse(infectedDays < 15 and infectedDays > 2 and random 2 = 0)[set infectionStatus "incubation" set color black set contagious? false][set infectionStatus "symptoms" set color red set contagious? true]
    if(infectedDays > 14)[set infectionStatus "symptoms" set color red set contagious? true]

    set lastInfected num-infected
;    set color black
;    set infectedDay 1
;    set infectionStatus "incubation"

  ]
end


to setup-wealth-graph
  ask turtles[
    set-plot-pen-color green
    plotxy who wealth
  ]

end

to update-dayTime

  set overallTime (overallTime + 1)


  if(time = 24)[
    set days (days + 1)
    set time 0
    update-r0
    update-infection


    update-wealth

    set-go-today


  ]
  if(time != 24)[
    set time (time + 1)
  ]

end



;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;



to go
  update-lockdown
  spread-infection
  move
  update-dayTime
  tick
end

; choose random number between 0 & 1, return if rand = 0 or not
to-report true?
  report random 2 = 0
end


to update-lockdown

  let settingsSet? false


  ask turtles[

    if(lockdown = true and lockdownSet? = false)[
;      https://www.theguardian.com/business/2020/jun/18/australia-loses-227000-more-jobs-taking-coronavirus-unemployment-to-71
      if(random-float 100 <= 7.1)[
        set fired? true
       ]
      set settingsSet? true
    ]
    if(lockdown = false)[set fired? false set lockdownSet? false]
 ]

  if(settingsSet? = true)[set lockdownSet? true]

end


to update-infection
;  https://www.health.gov.au/news/australian-health-protection-principal-committee-ahppc-coronavirus-covid-19-statements-on-14-may-2020#:~:text=The%20median%20incubation%20period%20for,14%20days%20of%20infection.
;  There is no new evidence that indicates the quarantine period should be reduced.
;  The median incubation period for COVID-19 is 4.9 – 7 days, with a range of 1 – 14 days.
;  Most people who are infected will develop symptoms within 14 days of infection.
;  Testing early in the incubation period before symptoms have developed may not detect infection,
;  and a negative test result cannot be used to release individuals from quarantine prior to the
;  outer range of the incubation period, which is 14 days.

  ask turtles[


    if(infected?)[

      let deathRand
      random 100

      if(infectedDays > 24 and random 100 < 3)[
        set deathCount (deathCount + 1)
        die
      ]

      if(infectedDays > 24 and true?)
      [
        set overallContagiousDays (overallContagiousDays + infectedDays)
        set overallInfectedDaysToday (overallInfectedDaysToday + infectedDays)
        set recoverToday (recoverToday + 1)
        set color green
        set infectedDays 0
        set contagiousDays 0
        set contagious? false
        set infected? false
        set recoveryNum (recoveryNum + 1)
        set travelChance healthy-travel-chance
        set infectionStatus "N/A"

      ]


      if(infectedDays > 4 and infectedDays < 14 and infectionStatus = "incubation" and true?)[
        set infectionStatus "symptoms"
        set color red

        set travelChance symtons-stage-travel-chance

        set contagious? true
;        set contagiousDays (contagiousDays + 1)
      ]
      if(infectedDays = 11 and  infectionStatus = "incubation")[
        set contagious? true
;        set contagiousDays (contagiousDays + 1)
;        set travelChance random 40
      ]
      if(infectedDays = 14 and  infectionStatus = "incubation") [
        set infectionStatus "symptoms"
        set color red
        set travelChance symtons-stage-travel-chance
        set contagious? true
;        set contagiousDays (contagiousDays + 1)
      ]

      if(infected?)[set infectedDays (infectedDays + 1)]
      if(contagious?)[set contagiousDays (contagiousDays + 1)]



    ]
  ]

end

to update-r0

   if(lastInfected != 0)[
    set beta (infectedNew / lastInfected)
  ]

  if(infectedNew = 0 or lastInfected = 0)[ set beta 0]

  if(recoverToday != 0 )[
    set avgRecoveryRate (overallInfectedDaysToday / recoverToday)
    ;  The recovery rate is always the inverse of the infectious period.

    set gamma (1 / avgRecoveryRate)
  ]



  if(beta != 0 and gamma != 0)[

    set r0 (beta / gamma)
  ]

  if(beta = 0 or gamma = 0)[set r0 0]

  set lastInfected count turtles with [ infected? ]
  set infectedNew 0
  set infectedToday 0
  set recoverToday 0
  set overallInfectedDaysToday 0


end

to spread-infection

  let infectedBefore count turtles with [ infected? ]

  ask turtles with [ infected? ] [

    if(masks = false or (masks = true and random-float 100 < 1.5))[

      if(contagious? and [pcolor] of patch-here != 136)[

        ask turtles-here [

          if(infected? = false)[
            set infected? true
            set color black
            set infectedDay days
            set infectionStatus "incubation"
            set travelChance incubation-stage-travel-chance
            set contagious? false
            set infectedNew (infectedNew + 1)
          ]

        ]
      ]


    ]



  ]

end

;;;;;;;;;;;;;;
;;; Layout ;;;
;;;;;;;;;;;;;;


to set-go-today

   ask turtles[

    ifelse(rand100 < travelChance)[set go-today? true][set go-today? false]
    if(travelChance = 0)[set go-today? false]
    if(lockdown)[
      ifelse(rand100 < lockdown-travel-chance )[set go-today? true][set go-today? false]
      set destination one-of stores
    ]
  ]

end

to move


    ask turtles[

      if(go-today? = true and lockdown = false)[


        if(occupation = "worker")[
          if(time > 8  and time < 17)[

            let choices neighbors with [ pcolor = brown + 3 or pcolor = white ]
            let choice min-one-of choices [ distance [ occupationPlace ] of myself ]

            ifelse(distance occupationPlace  < 5 or choice = nobody)[face occupationPlace fd 1][face choice fd 3]
            if(distance occupationPlace  < 4)[move-to occupationPlace]

          ]
          if(time > 17)[
            let choices neighbors with [ pcolor = brown + 3 or pcolor = white ]
            let choice min-one-of choices [ distance [ house ] of myself ]

            ifelse(distance house  < 5 or choice = nobody)[face house fd 1][face choice fd 3]
            if(distance house  < 4)[move-to house]
          ]

        ]

      ]

     if(lockdown = true and go-today? = true)[

      if(time > lockdown-min-travel-hours and time < lockdown-max-travel-hours - 3)[

        if(destination = nobody or destination = 0)[set destination one-of stores]

        let choices neighbors with [ pcolor = brown + 3 or pcolor = white ]
        let choice min-one-of choices [ distance [ destination ] of myself ]

        ifelse(distance house  < 5 or choice = nobody)[face destination fd 1][face choice fd 3]
        if(distance destination  < 4)[move-to destination]
      ]

      if(time >= lockdown-max-travel-hours - 3 )[
        let choices neighbors with [ pcolor = brown + 3 or pcolor = white ]
        let choice min-one-of choices [ distance [ house ] of myself ]

        ifelse(distance house  < 5 or choice = nobody)[face house fd 1][face choice fd 3]
        if(distance house  < 4)[move-to house]
      ]
    ]

      if(lockdown = true or go-today? = false)[
        if(patch-here != house)[
            face house
            fd 1
          ]
      ]
    ]


end

to update-wealth

  ask turtles[

    let wealthBefore wealth
    let income 0

    if(go-today? = true and fired? = false and lockdown = false)[

      set wealth (wealth + salary)
      set income salary

    ]
    if(fired? = false and lockdown = true)[

      set wealth (wealth + salary)
      set income salary

    ]
    if(fired? = true and jobKeeperPayment = true)[
      set wealth (wealth + payment-amount)
      set income payment-amount
    ]



    let randSpending (min-spending-per-day + random(max-spending-per-day - min-spending-per-day))


    let newWealth (wealth - randSpending)

    ifelse(newWealth < 0)[set wealth 0 ][set wealth newWealth]

;    clear-plot
;    set-plot
    ifelse(wealthBefore < wealth) [set-plot-pen-color green][set-plot-pen-color red]

;    set-plot-pen-color green
    plotxy who wealth

  ]

end

to-report incubation-travels
  ifelse((count turtles with [ infectionStatus = "incubation" ]) > 0)
  [report ((count turtles with [ infectionStatus = "incubation" and go-today? = true]) / (count turtles with [ infectionStatus = "incubation" ]) ) * 100]
  [report 0]

end


to-report symptons-travels
  ifelse((count turtles with [ infectionStatus = "symptoms" ]) > 0)
  [report ((count turtles with [ infectionStatus = "symptoms" and go-today? = true]) / (count turtles with [ infectionStatus = "symptoms" ]) ) * 100]
  [report 0]

end

to-report symptoms-count
  ifelse((count turtles with [ infectionStatus = "symptoms" ]) > 0)
  [report ((count turtles with [ infectionStatus = "symptoms"]))]
  [report 0]

end

to-report incubation-count
  ifelse((count turtles with [ infectionStatus = "incubation" ]) > 0)
  [report ((count turtles with [ infectionStatus = "incubation"]))]
  [report 0]

end


to wiggle  ;; turtle procedure
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
end


to do-layout
  layout-spring turtles with [ any? link-neighbors ] links 0.4 6 1
  display  ;; so we get smooth animation
end

;; This procedure allows you to run the model multiple times
;; and measure how long it takes for the disease to spread to
;; all people in each run. For more complex experiments, you
;; would use the BehaviorSpace tool instead.
to my-experiment
  repeat 10 [
    set num-people 50
    setup
    while [ not all? turtles [ infected? ] ] [ go ]
    print ticks
  ]
end


; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
390
50
1272
564
-1
-1
12.32
1
10
1
1
1
0
1
1
1
-35
35
-20
20
1
1
1
ticks
30.0

BUTTON
10
50
90
85
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
95
50
175
85
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
180
105
370
138
num-people
num-people
2
500
358.0
1
1
NIL
HORIZONTAL

BUTTON
180
50
260
85
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
5
105
175
138
num-infected
num-infected
0
num-people
57.0
1
1
NIL
HORIZONTAL

PLOT
20
480
325
635
Percentage of infected people
Day
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"people" 1.0 0 -5298144 true "" "plotxy overallTime (count turtles with [ infected? ] / count turtles) * 100"

MONITOR
20
425
107
470
Infected now
count turtles with [ infected? ]
3
1
11

MONITOR
1380
30
1450
75
time
time
17
1
11

MONITOR
1300
30
1370
75
days
days
17
1
11

TEXTBOX
390
570
540
696
Locations:\npurple - work places\npink - houses\ngreen - stores\n\nPeople:\ngreen - non infected\nblack - incubation\nred - symptoms\n
11
0.0
1

MONITOR
1295
240
1397
285
total Recovered
recoveryNum
17
1
11

PLOT
1295
80
1495
230
R0 over hours
NIL
NIL
0.0
20.0
0.0
0.5
true
true
"" ""
PENS
"R0" 1.0 0 -16777216 true "" "plotxy overallTime r0"

MONITOR
1705
90
1762
135
beta
beta
17
1
11

MONITOR
1650
240
1707
285
gamma
gamma
17
1
11

MONITOR
1555
30
1630
75
R0
r0
4
1
11

SLIDER
5
150
177
183
workSpaces
workSpaces
10
150
100.0
1
1
NIL
HORIZONTAL

SWITCH
5
250
107
283
lockdown
lockdown
1
1
-1000

SWITCH
5
200
108
233
masks
masks
1
1
-1000

PLOT
505
630
1845
830
wealth
NIL
NIL
0.0
300.0
0.0
1000.0
true
false
"" ""
PENS
"wealth-pen" 1.0 0 -7500403 true "" ""

SWITCH
5
365
162
398
jobKeeperPayment
jobKeeperPayment
0
1
-1000

SLIDER
180
365
352
398
payment-amount
payment-amount
0
200
136.0
1
1
NIL
HORIZONTAL

MONITOR
1785
145
1877
190
NIL
infectedNew
17
1
11

MONITOR
1410
240
1497
285
NIL
recoverToday
17
1
11

SLIDER
550
580
722
613
min-spending-per-day
min-spending-per-day
0
500
57.0
1
1
NIL
HORIZONTAL

SLIDER
735
580
907
613
max-spending-per-day
max-spending-per-day
0
500
48.0
1
1
NIL
HORIZONTAL

SLIDER
930
580
1102
613
min-income-per-day
min-income-per-day
0
500
145.0
1
1
NIL
HORIZONTAL

SLIDER
1115
580
1287
613
max-income-per-day
max-income-per-day
0
1000
264.0
1
1
NIL
HORIZONTAL

SLIDER
1295
580
1467
613
min-starting-wealth
min-starting-wealth
5000
50000
7000.0
1
1
NIL
HORIZONTAL

PLOT
1310
300
1750
495
percentage of people who travel that day
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"healthy" 1.0 0 -13840069 true "" "plotxy days ((count turtles with [ infected? = false and go-today? = true]) / (count turtles with [ infected? = false]) ) * 100"
"incubation" 1.0 0 -16777216 true "plotxy days ((count turtles with [ infectionStatus = \"incubation\" and go-today? = true]) / (count turtles with [ infectionStatus = \"incubation\" ]) ) * 100" "plotxy days incubation-travels"
"symptons" 1.0 0 -2674135 true "plotxy days symptons-travels" "plotxy days symptons-travels"

SLIDER
1480
580
1652
613
max-starting-wealth
max-starting-wealth
0
1000000
100000.0
1
1
NIL
HORIZONTAL

INPUTBOX
1435
510
1600
570
incubation-stage-travel-chance
50.0
1
0
Number

INPUTBOX
1305
510
1425
570
healthy-travel-chance
100.0
1
0
Number

INPUTBOX
1610
510
1770
570
symtons-stage-travel-chance
50.0
1
0
Number

MONITOR
1750
30
1822
75
total death
deathCount
17
1
11

MONITOR
1700
145
1777
190
NIL
lastInfected
17
1
11

MONITOR
1510
240
1622
285
NIL
avgRecoveryRate
17
1
11

MONITOR
1460
30
1542
75
NIL
overallTime
17
1
11

PLOT
1495
80
1695
230
R0 per days
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
"default" 1.0 0 -16777216 true "" "plotxy days r0"

SLIDER
185
150
357
183
stores-num
stores-num
10
50
21.0
1
1
NIL
HORIZONTAL

INPUTBOX
5
290
135
350
lockdown-travel-chance
30.0
1
0
Number

SLIDER
115
200
307
233
lockdown-min-travel-hours
lockdown-min-travel-hours
1
24
7.0
1
1
NIL
HORIZONTAL

SLIDER
115
245
312
278
lockdown-max-travel-hours
lockdown-max-travel-hours
17
23
22.0
1
1
NIL
HORIZONTAL

MONITOR
165
295
242
340
fired people
count turtles with [fired? = true]
17
1
11

PLOT
15
645
325
815
Infected number per category
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
"incubation" 1.0 0 -16777216 true "" "plotxy overallTime incubation-count"
"symptoms" 1.0 0 -2674135 true "" "plotxy overallTime symptoms-count"

MONITOR
1655
30
1732
75
NIL
lastInfected
17
1
11

MONITOR
195
425
262
470
symptoms
count turtles with [ infectionStatus = \"symptoms\"]
17
1
11

MONITOR
115
425
185
470
incubation
count turtles with [ infectionStatus = \"incubation\"]
17
1
11

TEXTBOX
795
10
945
36
COVID-19 Model \nSefira / s3766199
11
0.0
1

@#$#@#$#@
## ACKNOWLEDGMENT

This model is from Chapter Six of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## WHAT IS IT?

This model explores the spread of disease in a number of different conditions and environments. In particular, it explores how making assumptions about the interactions of agents can drastically affect the results of the model.

## HOW IT WORKS

The SETUP procedure creates a population of agents. Depending on the value of the VARIANT chooser, these agents have different properties. In the NETWORK variant they are linked to each other through a social network. In the MOBILE and ENVIRONMENTAL variants they move around the landscape. At the start of the simulation, NUM-INFECTED of the agents are infected with a disease.

The GO procedure spreads the disease among the agents. In the case of the NETWORK variant this is along the social network links. In the case of the MOBILE or ENVIRONMENTAL variant, the disease is spread to nearby neighbors in the physical space. In the case of the ENVIRONMENTAL variant the disease is also spread via the environment. Finally, if the variant is either the MOBILE or ENVIRONMENTAL variant then the agents move.

## HOW TO USE IT

The NUM-PEOPLE slider controls the number of people in the world.

The VARIANT chooser controls how the infection spreads.

NUM-INFECTED controls how many individuals are initially infected with the disease.

The CONNECTIONS-PER-NODE slider controls how many connections to other nodes each node tries to make in the NETWORK variant.

The DISEASE-DECAY slider controls how quickly the disease leaves the current environment.

To use the model, set these parameters and then press SETUP.

Pressing the GO ONCE button spreads the disease for one tick. You can press the GO button to make the simulation run until all agents are infected.

The REDO LAYOUT button runs the layout-step procedure continuously to improve the layout of the network.

## THINGS TO NOTICE

How do the different variants affect the spread of the disease?

In particular, look at how the different parameters of the model influence the speed at which the disease spreads through the population. For example, in the "mobile" variant, the population (NUM-PEOPLE) clearly seem to be the main driving force for the speed of infection. Is that the case for the other two variants as well? Some suggestions of parameters to vary are given below under THINGS TO TRY.

Another thing that you may have noticed is that, in the "network" variant, there are cases where the disease will not spread to all people. This happens when the network has more than one [components](https://en.wikipedia.org/wiki/Connected_component_%28graph_theory%29) (isolated nodes, or groups of nodes that are not connected with the rest of the network) and that not all components get infected with the disease right from the start. NetLogo's [network extension](http://ccl.northwestern.edu/netlogo/docs/nw.html) has [a primitive](http://ccl.northwestern.edu/netlogo/docs/nw.html#weak-component-clusters) that can help you identify the components of a network.

## THINGS TO TRY

Set different values for the DISEASE-DECAY slider and run the ENVIRONMENTAL variant. How does the DISEASE-DECAY slider affect the results?

Similarly, set different values for the CONNECTIONS-PER-NODE slider and run the NETWORK variant. How does the CONNECTIONS-PER-NODE slider affect the results?

If you open the BehaviorSpace tool, you will see that we have a defined a few experiments that can be used to explore the behavior of the model more systematically. Try these out, and look at the data in the resulting CSV file. Are those results similar to what you obtained by manually playing with the model parameters? Can you confirm that using your favorite external analysis tool?

## EXTENDING THE MODEL

Can you think of additional variants and parameters that could affect the spread of a disease?

At the moment, in the environmental variant of the model, patches are either infected or not. DISEASE-DECAY allows you to set how long they stay infected, but they are fully contagious until they suddenly stop being infected. Do you think it would be more realistic to have their infection level decline gradually? The probability of a person catching the disease from a patch could become smaller as the infection level decreases on the patch. If you want to make the model look really nice, you could vary the color of the patch using the [`scale-color`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#scale-color) primitive.

## RELATED MODELS

NetLogo is very good at simulating the spread of epidemics, so there are a few disease transmission model in the library:

- HIV
- Disease Solo
- Disease HubNet
- Disease Doctors HubNet
- epiDEM Basic
- epiDEM Travel and Control
- Virus on a Network

Some communication models are also very similar to disease transmission ones:

- Communication T-T Example
- Communication-T-T Network Example
- Language Change

## NETLOGO FEATURES

One particularity of this model is that it combines three different "variants" in the same model. The way this is accomplished in the code of the model is fairly simple: we have a few `if`-statements making the model behave slightly different, depending on the value of the VARIANT chooser.

A more interesting element is the **Infection vs. Time** plot. In the "mobile" and "network" variants, the plot is the same: we simply plot the number of infected persons. In the "environmental" variant, however, we want to plot an additional quantity: the number of infected patches. To achieve that, we use the "Plot update commands" field of our plot definition. Just like the "Pen update commands", these commands run every time a plot is updated (usually when calling [`tick`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#tick)). In this case, we use the [`create-temporary-plot-pen`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#create-temporary-plot-pen) primitive to make sure that we have a pen for the number of infected patches, and actually plot that number:

```
if variant = "environmental" [
  create-temporary-plot-pen "patches"
  plotxy ticks count patches with [ p-infected? ] / count patches
]
```

One nice thing about this NetLogo feature is that the temporary plot pen that we create is automatically added to the plot's legend (and removed from the legend when the plot is cleared, when calling [`clear-all`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#clear-all)).

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W., Wilensky, U. (2008).  NetLogo Spread of Disease model.  http://ccl.northwestern.edu/netlogo/models/SpreadofDisease.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Rand, W., Wilensky, U. -->
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="population-density" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="variant">
      <value value="&quot;mobile&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="connections-per-node">
      <value value="4.1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-people" first="50" step="50" last="200"/>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-decay">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="degree" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles with [infected?]</metric>
    <enumeratedValueSet variable="num-people">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="connections-per-node" first="0.5" step="0.5" last="4"/>
    <enumeratedValueSet variable="disease-decay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variant">
      <value value="&quot;network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="environmental" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="connections-per-node">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="disease-decay" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="variant">
      <value value="&quot;environmental&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-and-decay" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="variant">
      <value value="&quot;environmental&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="disease-decay" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-people" first="50" step="50" last="200"/>
    <enumeratedValueSet variable="connections-per-node">
      <value value="4"/>
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
1
@#$#@#$#@
