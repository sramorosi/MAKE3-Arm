# Robot Arm Control Code for MAKE3-Arm

This folder contains the Arduino Robot Arm control software for the MAKE3-Arm.

It is written in the C programming language (not C++).  Variables have been grouped into structures using `struct`, to help organize the code.

An understanding of how microcontrollers works is required. Specifically there is an initialization function `setup()` and a repeating `loop()` function. For good robot arm performance it is important to let `loop()` loop as fast as possible. Loop times of 20 millisecods or less are good.  Loop times of 50 milliseconds or more are bad and will make the arm response jerky and potentially introduce unsteady dynamics.

The code is written to control the main arm using the control Input Arm and the Selector. See folder [OpenSCAD-code](/OpenSCAD-code) for the design of these two control devices.

## Highest level program control, using the Selector

The Selector lets you pick one of ten different programs for the arm

![Controller-Selector](/Images/Controller-Selector.png)

There are two main modes by which one can control the Arm:

1. Remote Control (teleoperated or TELE) using the Control Arm
2. Programmably (autonomously or AUTO) using command sequences within the code

The different program modes (TELE or AUTO) are choosen using the Selector and are called STATES, which are defined by constants in the code. The following code block shows a few of the constants.

```c++
// STATES (or programs)  Controlled by the selector potentiometer.
#define S_TELEOP_1 1   
#define S_AUTO_2   2 
#define S_TELEOP_3 3 
```

## TELE (remote control) code outline

To provide smooth remote arm control the code has three main features: 

1. There is a linear velocity limit `feedRate` on the movement of Joint C. This is implemented in the function updateArmPtC shown below.  The code keeps track of the Current C point, and when the user moves the control arm, a new Target C point is calculated.  The function limits how fast the arm can move from current to target. This prevent rapid movements of the arm when it is extended, which is when the most damage could occure.

2. The velocity is further decrease when the distance from current to target point is < RAMP_START_DIST (~50 mm), using this formula:  `newFeedRate = the_arm.feedRate * (the_arm.line_len/RAMP_START_DIST); `  This helps with the fine movements when picking and placing.

3. To prevent a bad rocking dynamic when the arm is pointed close to straight up, the velocity is further decreased.  This is done by looking at the 2D (xy plane) current-target point distance, and if it is close (<100 mm) to 0,0 then `Vnew = Vmax x ((dist + 50) / 150)`. 

### updateArmPtC code, called once every loop()

```c++
void updateArmPtC(arm & the_arm) { // Moves current point C toward target_pt at given feed rate (mm/sec)
  float moveDist,newFeedRate,distC;
  the_arm.line_len = ptpt_dist(the_arm.current_pt,the_arm.target_pt);
  // cut the feedrate when the current pt x,y component is close to zero.  To stop the rocking dynamics. 
  distC = sqrt(pow(the_arm.current_pt.x,2)+pow(the_arm.current_pt.y,2));
  newFeedRate = the_arm.feedRate;
    if (distC < 100) newFeedRate = newFeedRate*((distC+50)/150);  // Ramp down math
    if (the_arm.line_len < RAMP_START_DIST) {
      newFeedRate = the_arm.feedRate*(the_arm.line_len/RAMP_START_DIST);  // scale down based on distance
    } else {
      newFeedRate = the_arm.feedRate;  // keep using the current feedrate
    };
  moveDist = newFeedRate/1000.0 * (the_arm.dt); // dist(mm) = feed rate(mm/ms)*dt(ms)  
  the_arm.current_pt = pt_on_line(moveDist,the_arm.line_len, the_arm.current_pt,the_arm.target_pt);
}
```

## AUTO (programmable) code outline

The autonomous **Programming Commands** are defined by constants. These commands are shown below:

```c++
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




