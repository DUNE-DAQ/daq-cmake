#!/usr/bin/env python

import toylibrary
from toylibrary import ValueWrapperInt, IntPrinter

from toylibrary.wind import WindUp, WindDown
from toylibrary.play import PlayInts

my_number=1

print(f"Basic int: {my_number}")

# Use C++ exposed in top level module
wrapper = ValueWrapperInt(my_number)
print(f"Wrapped int: {wrapper.GetValue()}")

printer = IntPrinter(wrapper)
print(f"Printed int:")
printer.Show()

print("")

# Use C++ exposed in wind sub-module
my_number_up = WindUp(my_number)
print(f"Wound up int: {my_number_up}")

my_number_down = WindDown(my_number)
print(f"Wound down int: {my_number_down}")

print("")

# Use C++ exposed in play sub-module
print("Playing ints without new line:")
PlayInts([my_number, my_number_up, my_number_down]) # Call PlayInts with one argument

print("Playing ints with new line:")
PlayInts([my_number, my_number_up, my_number_down], True) # Call PlayInts with two arguments
