# MAKE3-Arm

This repository contains the complete design for the MAKE3 Robot Arm, controller, and the code to control the arm (both remote control and programmable).  This is intended to be a low-cost (less than US $ 200), Do it yourself (mostly 3D printed or made with common shop tools), remote controlled robot arm. It can be used for delivering candy to kids without getting too close (i.e. prevent germ spreading), stacking/unstacking things for fun, and as a learning tool whereby you learn by making.

The design files are in the folder [OpenSCAD-code](/OpenSCAD-code), and are written in [OpenSCAD](https://openscad.org/).

The control code files are in the folder [MAKE3](/MAKE3).  and are written in [Arduino C](https://www.arduino.cc/).
 
## MAKE3 Arm Assembly

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

![MAKE3 Nomenclature](/Images/MAKE3_Nomenclature.jpg)

[Video of MAKE3 robot arm](https://www.wevideo.com/view/3040378114)

## MAKE3 Specification

1. The arm has a total reach of about 73 cm. The AB arm is 35 cm and the BC arm is 38 cm.
2. The position accuracy at the claw is about plus or minus 0.7 cm. This is based on the angular accuracy of the servos times the gearing and the arm lengths.
3. The arm can lift objects up to 300 grams. A 12 oz can is about 350 grams.
4. There are no sensors on the MAKE3

## Teaching Objectives

This project is intended as a low cost teaching tool to describe how to design, build and analyze a robot arm.  Some objectives are to teach things such as:

1. Mechanical design of joints (strong, robust, accurate)
2. Principles of Statics (forces and torques/moments)
3. Inverse Kinematics-trigonometry to get angles from a desired point.
4. Controlling multiple servos (multiple synchronized servos)


