# MAKE3-Arm

This repository contains the complete design for the MAKE3 Robot Arm, controller, and the code to control the arm (both remote control and programmable).  This is intended to be a low-cost (less than US $ 200), Do it yourself (mostly 3D printed or made with common shop tools), remote controlled robot arm. It can be used for delivering candy to kids without getting too close (i.e. prevent germ spreading), stacking/unstacking things for fun, and as a learning tool whereby you learn by making.

The design files are in the folder [OpenSCAD-code](/OpenSCAD-code), and are written in [OpenSCAD](https://openscad.org/).

The control code files are in the folder [MAKE3](/MAKE3).  and are written in [Arduino C](https://www.arduino.cc/).
 
## MAKE3 Arm Assembly

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

[Video of MAKE3 robot arm](https://www.wevideo.com/view/3040378114)

## Teaching Objectives

This project is intended as a low cost teaching tool to describe how to design, build and analyze a robot arm.  Some objectives are to teach things such as:
1. Inverse Kinematics (getting servo angles from a desired point)
2. Controlling multiple servos (multiple synchronized servos)
3. Principles of Statics (forces and torques/moments)
4. Mechanical design of servo joints that provides strength and control (robust)


