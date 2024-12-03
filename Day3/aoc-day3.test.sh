#! /bin/sh

testEmptyMemory() {
  result=`rockstar aoc-day3.rock`
  assertEquals "0" "${result}"
}

testMul1by1() {
  result=`rockstar aoc-day3.rock "mul(1,1)"`
  assertEquals "1" "${result}"
}

testMul2by1() {
  result=`rockstar aoc-day3.rock "mul(2,1)"`
  assertEquals "2" "${result}"
}

testMul2by2() {
  result=`rockstar aoc-day3.rock "mul(2,2)"`
  assertEquals "4" "${result}"
}

testMul10by2() {
  result=`rockstar aoc-day3.rock "mul(10,2)"`
  assertEquals "20" "${result}"
}

testMul10by2WithCorruptedMemoryBefore() {
  result=`rockstar aoc-day3.rock "&*mul(10,2)"`
  assertEquals "20" "${result}"
}

testMul10by2WithCorruptedMemoryAfter() {
  result=`rockstar aoc-day3.rock "&*mul(10,2)%&"`
  assertEquals "20" "${result}"
}

testMulWithSpacesShouldDoNothing() {
  result=`rockstar aoc-day3.rock "mul ( 2 , 4 )"`
  assertEquals "0" "${result}"
}

testMulWithMidMulCorruptionShouldDoNothing() {
  result=`rockstar aoc-day3.rock "mul(!2,4)"`
  assertEquals "0" "${result}"
}

testMultipleMuls() {
  result=`rockstar aoc-day3.rock "mul(2,4)mul(3,3)"`
  assertEquals "17" "${result}"
}

testCompletelyMalformed() {
  result=`rockstar aoc-day3.rock "mul[2,4]"`
  assertEquals "0" "${result}"
}

testMixOfValidAndMalformed() {
  result=`rockstar aoc-day3.rock "xmul(2,4)%&mul[3,7]"`
  assertEquals "8" "${result}"
}

testGreedyMalformedMul() {
  result=`rockstar aoc-day3.rock "mul(2,4)mul[3,7]mul(2,4)"`
  assertEquals "16" "${result}"
}


# Load shUnit2.
. shunit2