# Robot Arm Control Code for MAKE3-Arm

This folder contains the Arduino Robot Arm control software for the MAKE3-Arm.

It is written in the C programming language (not C++).  Variables have been grouped into structures using `struct`, to help organize the code.

An understanding of how microcontrollers works is required. Specifically there is an initialization function `setup()` and a repeating `loop()` function. For good robot arm performance it is important to let `loop()` loop as fast as possible. Slow loop can make the arm response jerky and potentially introduce unsteady dynamics. For reference, the MAKE3 runs about 15 milliseconds/loop while in remote control, and about 9 milliseconds/loop while in programmed mode.

The code is written to control the main arm using the control Input Arm and the Selector. See folder [OpenSCAD-code](/OpenSCAD-code) for the design of these two control devices.

## Main Loop

Here is a **snapshot** of the main loop. The global variable `make3` is a `struct` that holds arm data. The AUTO or programmed mode uses function `readCommands` and there will be more on that later.  The TELE or remote control mode has a number of steps that make the movements smooth which are:

1. First the potentiometers are read from the input control arm
2. Second the point at the end of the arm is calculated from the potentiometer angles, which is the new target point
3. Third the updateArmPtC function is called to move the current point toward the target point in a controlled move.  More on the later.
4. Fourth, the joint angles are then solved for the desired current point using the Inverse Kinematics function
5. Finally, the angles are sent to servo to make the arm move.  This is common for both AUTO and TELE.

```c++
void loop() {  //########### MAIN LOOP ############
  point angles;  // used in TELEOP by inverseArmKin
  point c_pt;    // used in TELEOP

  stateLoop(make3);  // checks for state change

  loopTime(make3); // Capture cycle time
  
  switch (make3.state) {
    case S_AUTO_2: 
    case S_AUTO_5:
    case S_AUTO_6:
      readCommands(make3,seQ); // read a sequence of commands and act accordingly
      updateJointBySpeed(make3.jCLAW, make3.dt);  // update Claw joint
      break; 
    case S_TELEOP_1: 
    case S_TELEOP_3:
      make3.jA.pot_value = analogRead(make3.jA.pot.analog_pin);  // read joint A
      make3.jB.pot_value = analogRead(make3.jB.pot.analog_pin);  // read joint B
      make3.jT.pot_value = analogRead(make3.jT.pot.analog_pin);  // read the turntable
    
      pot_map(make3.jA);      // get A angle
      pot_map(make3.jB);      // get B angle
      pot_map(make3.jT);      // Get Turntable angle

      make3.target_pt = anglesToG(make3.jA.pot_angle,make3.jB.pot_angle,make3.jT.pot_angle,make3.jC.current_angle,make3.jD.current_angle,LEN_AB,LEN_BC,S_CG_X,S_CG_Y);

      updateArmPtC(make3);   // Move current_pt toward target_pt at given feed rate (mmps)
      c_pt = pointGtoPointC(make3.current_pt,make3.jC.target_angle,make3.jD.target_angle,S_CG_X,S_CG_Y);
      
      inverseArmKin(c_pt,LEN_AB,LEN_BC,angles);    // FIND JOINTS A B T from POINT C
      make3.jA.current_angle = angles.x; //  A 
      make3.jB.current_angle = angles.y;  // local B
      make3.jT.current_angle = angles.z;  //  T
      
      break;
  }
  // Convert the .current_angle(s) to PWM signal and send 
  pwm.writeMicroseconds(make3.jA.svo.digital_pin, servo_map(make3.jA)); // Adafruit servo library
  pwm.writeMicroseconds(make3.jB.svo.digital_pin, servo_map(make3.jB)); // Adafruit servo library
  pwm.writeMicroseconds(make3.jT.svo.digital_pin, servo_map(make3.jT)); // Adafruit servo library
  //
} // END OF MAIN LOOP
```
## Highest level program control, using the Selector

The Selector lets you pick one of multiple different programs for the arm

![Controller-Selector](/Images/Controller-Selector.gif)

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

The remote control steps were outlined above in the Main Loop discussion. The function that provide smooth remote arm control is `updateArmPtC(arm & the_arm)` The function has three main features that provide the control: 

1. There is a linear velocity limit `feedRate` on the movement of Joint C. This is implemented in the function updateArmPtC shown below.  The code keeps track of the Current C point, and when the user moves the control arm, a new Target C point is calculated.  The function limits how fast the arm can move from current to target. This prevent rapid movements of the arm when it is extended, which is when the most damage could occure.

2. The velocity is further decrease when the distance from current to target point is < RAMP_START_DIST (~50 mm), using this formula:  `newFeedRate = the_arm.feedRate * (the_arm.line_len/RAMP_START_DIST); `  This helps with the fine movements when picking and placing.

3. To prevent a bad rocking dynamic when the arm is pointed close to straight up, the velocity is further decreased.  This is done by looking at the 2D (xy plane) current-target point distance, and if it is close (<100 mm) to 0,0 then `Vnew = Vmax x ((dist + 50) / 150)`. 

Here is a **snapshot** of updateArmPtC:

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

Here is a **snapshot** of `readCommands`. At the moment, there is a global array of fixed length that holds commands.

```c++
#define SIZE_CMD_ARRAY 5  // NUMBER OF VARIABLES PER COMMAND 
struct command {int arg[SIZE_CMD_ARRAY];};

struct sequence {  // An array of commands
  int nuHm_cmds;
  command cmd[];  // undefined array length
};

sequence seQ = {4,{{0,0,0,0,0},
                {0,0,0,0,0}, 
                {0,0,0,0,0},
                {0,0,0,0,0}}}; 

void readCommands(arm & the_arm, sequence & the_seq) {  // read through commands
  if (the_arm.n > the_seq.nuHm_cmds || the_arm.n >= 999) {  // DONE RUNNING ARRAY OF COMMANDS
    return;  
  } else {
    if (runCommand(the_arm, the_seq, the_arm.n)) { // true = done = go to the next command
      the_arm.n = the_arm.n + 1; // go to the next command line
      the_arm.line_len = 0.0;    // initialize line length
      the_arm.timerStart = millis();  // for timed commands
    };
    return;
  };
}
```

## EXAMPLE PROGRAM

Programs are initialized when the loop sees a new state that is an AUTO state. The initialization is done in the function `stateLoop(arm & the_arm)' Below is a **snapshot** from stateloop of a program to move to a point and get ready pick up something.  This is the method by which one programs the arm.

```c++
      case S_AUTO_5:  // PREPARE FOR FIRST BLOCK GRAB
        the_arm.n = 0; // reset command pointer
        the_arm.loopCount = 0;
        the_arm.mode = HM_CD_AIM;   // K_LINE does not set aim mode
        make3.aim_pt.x = 250; make3.aim_pt.y =-5000; make3.aim_pt.z = 100;
        setCmd(seQ.cmd[0],K_LIFT,0,0,0,0);          // turn lift off
        setCmd(seQ.cmd[1],K_LINE_G,300,250,200,-50);  // move to start
        setCmd(seQ.cmd[2],K_CLAW,  200,-15,500,0); // open claw and wait
        setCmd(seQ.cmd[3],K_END,0,0,0,0); 
        break;      
```

## Electronics used in the MAKE3

The microprocessor is an Arduino Leonardo, with an Adafruit Servo Shield.

The controller is wired to the arm using sacrificed CAT-5 eithernet cable.

The potentiometers in the controller are ...




