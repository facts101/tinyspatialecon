# tinyspatialecon
A tiny spatial economy

# How to run
Download and place the files tinyspatecon.wl and tinyspatecon.nb together in a single directory. Then, open the tinyspatecon.nb notebook. That's it!.

Alternatively, visit https://www.wolfram.com/player/ and download the notebook player. 

Also, you can create an account on www.wolframcloud.com, make two files named tinyspatecon.wl and tinyspatecon.nb...

# How it works
1. Generate (assume m << n)
 1.1. m vendors
 1.2. n customers
3. Decide on vendor relocation scheeme (immediate vs stepwise*)
4. Cycle over customers
 3.1. Decide if customer will shop or not
  3.1.1. Calculate distance to each vendor
  3.1.2. Decide if customer visits closest vendor or not
  3.1.3. Update selected vendor's inventory/clientele
5. Cycle over vendors
 5.1. Decide if vendor relocates (revenues vs costs ?)
  5.1.1. Decide where vendor relocates (near valuable customers ?)
  5.1.2. Relocate 
   
# What is this?
I developed this code and accompanying materials over the course of two days, as a scetch for a response to a post from account @kaushikcbasu on X on Jan 5, 2025.

The post read : "EconLesson B 
In a city shaped like an equilateral triangle people live uniformly distributed all over & buy from the nearest vendor. 
There are 2 vendors. Are there points where the vendors can locate such that no vendor can do better by unilaterally relocating?"

# Disclaimer
This code and accompanying materials are provided as is without any warranties.
All rights reserved by myself. Possible errors and ommissions are mine and mine alone.
