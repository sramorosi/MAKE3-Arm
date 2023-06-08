# MAKE3-Arm

This repository contains the complete design for the MAKE3 Robot Arm, controller, and the code to control the arm (both remote control and programmable).  This is intended to be a low-cost (less than US $ 250), do it yourself (mostly 3D printed or made with common shop tools), remote controlled robot arm. It can be used for stacking/unstacking things for fun, delivering things without getting too close, as a learning tool whereby you learn by making, and much more.

The design files are in the folder [OpenSCAD-code](/OpenSCAD-code) and are written in [OpenSCAD](https://openscad.org/).  This page contains the **Bill of Materials** for making the MAKE3 Robot Arm, along with notes about what drove the design.

The control code files are in the folder [MAKE3](/MAKE3) and are written in [Arduino C](https://www.arduino.cc/). This page contains information about how the code works and how to calibrate the code for your MAKE3 Robot Arm.
 
## MAKE3 Arm Assembly

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

GIF animation of the MAKE3 Robot Arm created in OpenSCAD. 

![MAKE3 Nomenclature](/Images/MAKE3_Nomenclature.jpg)

Labeled photo of the MAKE3 arm.

You can watch a video of the MAKE3 robot arm [here](https://www.wevideo.com/view/3040378114)

## MAKE3 Specification

1. The arm has a total reach of about 73 cm. The AB arm is 35 cm and the BC arm is 38 cm.
1. The position accuracy at the claw is about plus or minus 0.7 cm. This is based on the angular accuracy of the servos times the gearing and the arm lengths.
1. The arm can lift objects up to 200 grams.
1. There are no sensors on the MAKE3

## Teaching Objectives

This project is intended as a low cost teaching tool to describe how to design, build and analyze a robot arm.  Some teaching objectives are:

1. Mechanical design of joints (strong, robust, accurate)
1. Principles of Statics (forces and torques/moments)
1. How to create smooth remote control motion
1. How to synchronize control of multiple servos
1. How to make programmed motions fast and smooth
1. How to use trigonometry to get arm angles from a desired point - Inverse Kinematics


