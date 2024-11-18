extends Node
## scoring constants

## how much score to give by cut unit area
var SCORE_BY_UNIT_AREA = 1
## how much bonus score to award for no rank
var NO_RANK = 0
## how much bonus score to award for a D rank
var D_RANK = 1_000
## how much bonus score to award for a C rank
var C_RANK = 2_000
## how much bonus score to award for a B rank
var B_RANK = 5_000
## how much bonus score to award for an A rank
var A_RANK = 10_000
## how much bonus score to award for an S rank
var S_RANK = 20_000
## bonus multiplier for a cutting plane that produced more than one cut
var MULTIPLE_CUT_BONUS_MULTIPLIER = 1.5
## how much bonus core to award for each leftover circle cut
var CIRCLE_CUT_BONUS = 100
## how much bonus score to award for each leftover gomory cut
var GOMORY_CUT_BONUS = 500
## how much bonus score to award for each leftover split cut
var SPLIT_CUT_BONUS = 500