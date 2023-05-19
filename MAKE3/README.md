# Robot Arm Control Code for MAKE3-Arm

This folder contains the Arduino Robot Arm control software for the MAKE3-Arm.

It is written in the C programming language (not C++).  

The code is written to control the main arm using the control Input Arm and the Selector. See folder [OpenSCAD-code](/OpenSCAD-code) 

## Control Code Outline

With the Selector, one can control the Arm either by 

1. Remote Control, or Teleoperated, using the Control Arm
2. Programmably, or Autonomously, using command sequences within the code

The different modes (TELE or AUTO) are choosen using the Selector and are called STATES, which are defined by constants in the code. The following code block shows a few of the constants.

```
// STATES (or programs)  Controlled by the selector potentiometer.
#define S_SERIAL 0      // enter a serial command from serial.input
#define S_TELEOP_1 1   
#define S_AUTO_2 2 
#define S_TELEOP_3 3 
```

The autonomous **Programming Commands** are defined by constants. These commands are shown below:

```
// Synchronous commands (completes command before next command is sent) -- see runCommand
#define K_TIMER 1    // timer {milliseconds}
#define K_LINE_G 3   // line move to new G point {feed rate, x,y,z}     PATH METHOD
#define K_ORBIT_Z 4  // G point circular orbit  {feed rate, x-center(mm),radius(mm),angle_sweep(deg)}
                     //  angle_sweep should be between 90 and 270. Motion will be CCW.  If negative, motion will be CW 
// Asynchronous commands (does not wait to be completed)
#define K_AIM 5     // Turns on AIM mode. The aiming point is the parameters {x,y,z}
#define K_LIFT 6    // Turns on or off the z-lift mode for the K_LINE_G command.  parameters = {0=off, 1=on;  z-lift amount(mm)}
#define K_GOTO 9    // Go back to given command line {command line number} 
#define K_COMBINE 10 // combines given x y z values with an existing command
#define K_CLAW 11   // claw local move      {angle rate, target angle}
#define K_END 99   // indicates to stop running commands
```

## EXAMPLE PROGRAMS

A program to move to a point and pick up a block is shown:


## Electronics used in the MAKE3

The microprocessor is an Arduino Leonardo, with an Adafruit Servo Shield.

The controller is wired to the arm using sacrificed CAT-5 eithernet cable.

The potentiometers in the controller are ...




