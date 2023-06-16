# Robot Arm Control Code for MAKE3-Arm

This folder contains the Arduino Robot Arm control software for the MAKE3-Arm.

It is written in the C programming language (it does not use C++ objects).  Variables have been grouped into structures using `struct`, to help organize the code.

An understanding of how microcontrollers work is required. Specifically there is an initialization function `setup()` and a repeating `loop()` function. For good robot arm performance it is important to let `loop()` loop as fast as possible. Slow loops can make the arm response jerky and potentially introduce unsteady dynamics. For reference, the MAKE3 runs about 14 milliseconds/loop while in remote control, and about 9 milliseconds/loop while in programmed mode.

The MAKE3 Robot Arm is driven by servos. Servos take **position** command as their input. With the MAKE3, the servo commands are being given (written) every loop!

## Top Level Operation of MAKE3 Arm

There are two basic ways to control the arm. The first is by **remote control** (also called TELEOPERATED), which is the easiest to get working. The second is 
**programmed mode** (also called AUTONOMOUS), which takes more coding and is described further down.

The code is written to control the main arm using the control **Input Arm** and the **Selector**. See folder [OpenSCAD-code](/OpenSCAD-code) for the design of these two control devices.   To avoid using the Selector (recommended for first setup), **add a jumper between analog I/O port 8 and Ground**. This tells the code to stay in TELEOPERATED mode.

The **Input Arm** (or baby arm) is scaled down version of the MAKE3 arm, but it only has joints A, B and T (turntable); it only has potentiometers for these three joints.  The Input Arm also has a **button to control the Claw**, which toggles the claw open and closed.

### Wrist Servos, C and D

The wrist servos, C and D, are always controlled by code (not by an input potentiometer).  In general, the code makes the C servo always point straight down (-90 degrees in global C angle sence). This is done by the function `getCang` shown below.  D is likewise made to **aim** the Claw in a global angle sence. 

```c++
float getCang(float a_angle, float b_angle, float fixed_c_angle) { // returns joint angle C, using A and B
  // Assumes that you want an absolute (fixed) C angle
  return -a_angle - b_angle + fixed_c_angle;
}
```

Having C and D controlled by code makes the arm much easier to operate.

## Calibration of your MAKE3 Arm 

Once a new MAKE3 Robot Arm is completely built, the **first step** is to determine constants for Potentiometers and Servos. These are set in the `setup()` function.
I recommend using a servo tester to get the initial range of motion correct before hooking the servos up the the Arduino/Shield. The calibration involves mapping physical potentiometer angles to millivolt readings and servo angles to microsecond (PWM pulse width) readings.

```c++
void setup() {  // setup code here, to run once:
  // TUNE POTENTIOMETER LOW AND HIGH VALUES
  // FORMAT: initPot(pin,lowmv,lowang,highmv,highang)
  make3.jA.pot = initPot(1 ,905,  0/RADIAN, 112, 180/RADIAN); 
  make3.jB.pot = initPot(5 ,500,-90/RADIAN, 908,  0/RADIAN); 
  make3.jT.pot = initPot(0 ,894, 90/RADIAN, 127, -90.0/RADIAN); 
  jS.pot = initPot(2 , 0, 0/RADIAN, 1023, 280/RADIAN); 

  // TUNE SERVO LOW AND HIGH VALUES
  // FORMAT: initServo(pin,lowang,lowms,highang,highms)
  make3.jA.svo = initServo(0,  7.0/RADIAN, 505, 90.0/RADIAN, 1551);
  make3.jB.svo = initServo(1, 0.0/RADIAN, 500,-175.0/RADIAN, 2320);
  make3.jC.svo = initServo(2, -90.0/RADIAN, 927, 0.0/RADIAN, 1410);
  make3.jD.svo = initServo(3,  -90.0/RADIAN,  811, 90.0/RADIAN, 2054); 
  make3.jCLAW.svo = initServo(4, -45.0/RADIAN,  500, 45.0/RADIAN, 2000); 
  make3.jT.svo = initServo(5,  70.0/RADIAN,  2347, -70.0/RADIAN, 465); 

```

At the end of the main loop there are some telemetry functions (that write values to Serial Output) to help with the callibration:

```c++
  //  Serial Output for Initial Calibration.  One line for each servo.  Turn on one at a time:
  //logData(make3.jA,'A');  // Use logData for Initial Calibration of Potentiometer and Servo A
  //logData(make3.jB,'B');  // Use logData for Initial Calibration of Potentiometer and Servo B
  //logData(make3.jC,'C');  // Use logData for Initial Calibration of Servo C
  //logData(make3.jD,'D');  // Use logData for Initial Calibration of Servo D
  //logData(make3.jT,'T');  // Use logData for Initial Calibration of Potentiometer and Servo T

  // Serial Output  for debugging:
  //logPoint(make3);  // Use for debugging paths
  //logGeneral();  // Use for general debugging
```

## The Main Loop

Here is a **snapshot** of the main loop. The global variable `make3` is a `struct` that organizes the arm data. In the middle of the code the statement `switch (make3.state)` uses the **state** to execute different lines. The state is controlled by the selector. [See section on selector](https://github.com/sramorosi/MAKE3-Arm/tree/main/MAKE3#highest-level-program-control-using-the-selector) 

The TELE state is more complex than one might expect. The TELE method is shown below, in the snapshot of the `loop()`. It is further explained below.

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

There are two basic states:
1. The TELE or remote control mode has a number of steps used to make the movements smooth. See the code below the line `case S_TELEOP_3:`  This is the flow:
    1. The potentiometers are read from the input control arm using `analogRead` and mapped to angles using `pot_map`
    2. The point at the end of the arm is calculated from the potentiometer angles using `anglesToG`. This becomes the new target point
    3. The `updateArmPtC` function moves the current point toward the target point in a controlled move.  See [TELE code](https://github.com/sramorosi/MAKE3-Arm/tree/main/MAKE3#tele-remote-control-code-outline)
    4. The joint angles are then solved for the desired current point using the Inverse Kinematics function `inverseArmKin`. 
    5. Finally, the angles are sent to servo to make the arm move using `pwm.writeMicroseconds`.  This is common for both AUTO and TELE (is outside of the switch scope)
1. The AUTO or programmed mode uses function `readCommands` and there is more on that [here](https://github.com/sramorosi/MAKE3-Arm/tree/main/MAKE3#auto-programmable-code-outline)

## TELE (remote control) code outline

The remote control steps were outlined above in the Main Loop discussion. The function that provide smooth remote arm control is `updateArmPtC(arm & the_arm)` The function has three main features that provide the control: 

1. There is a linear velocity limit `feedRate` on the movement of the end of the arm. This is implemented in the function updateArmPtC shown below.  The code keeps track of the Current C point, and when the user moves the control arm, a new Target C point is calculated.  The function limits how fast the arm can move from current to target. This prevents rapid movement of the arm when it is extended, which is when the most damage could occur.

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

## Highest level program control, using the Selector

The Selector lets you pick one of multiple different programs for the arm

![Controller-Selector](/Images/Controller-Selector.gif)

There are two main modes by which one can control the Arm:

1. Remote Control (teleoperated or TELE) using the Control Arm
2. Programmably (autonomously or AUTO) using command sequences within the code

The different program modes (TELE or AUTO) are chosen using the Selector and are called **states**, which are defined by constants in the code. The following code block shows a few of the state constants.

```c++
// STATES (or programs)  Controlled by the selector potentiometer.
#define S_TELEOP_1 1   
#define S_AUTO_2   2 
#define S_TELEOP_3 3 
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

Here is a **snapshot** of `readCommands`. At the moment, there is a global 2D array of fixed length `seQ` that holds commands.

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

## Example AUTO Program

Programs are initialized when the loop sees a new state that is an AUTO state. The initialization is done in the function `stateLoop(arm & the_arm)` Below is a **snapshot** from stateloop of a program to move to a point and get ready pick up something.  This is the method by which one programs the arm.

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

### How K_LINE_G works in AUTO

The K_LINE_G command moves the arm grabber point **G** from one point to another point along a linear path, usually.  There is an option to **lift** the arm between the points. The function `path_line` **builds an array of robot arm angles**, on the fly, that will move the arm smoothly from start to end point. Here is a snapshot of the code:

```c++
void path_line(pathAngles & the_pathA,point start,point end, point aim,boolean liftMiddle,int lift) {  
  // Build a G-point path from start to end, and aligns D-angle to aim at point aim
  // Path increments (equivalent to velocity) are sized by a sine wave from 0 to 180 deg, to minimize accelerations
  // ASSUMES THAT THE C JOINT IS -90 DEG ABSOLUTE (POINTING DOWN)
  //   since c joint is rotated -90, then S_CG_X is added to z 
  // ASSUMES THAT S_CG_Z IS ZERO (G POINT IS ALONG AXIS OF D SERVO)
  // If boolean liftMiddle == true then function (zLift = cos(a)*lift) is added to c.z 
  int i;  
  point angles;  // used to receive angles from IK
  point c,g;
  float g_dist, cg_vect_ang, d_aim_angle,lineLen,travel,a,angIncrement;

  lineLen = ptpt_dist(start,end);  // 3d distance from point start to end
  travel = 0.0;  // initialize travel
  angIncrement = (180.0/RADIAN)/(PATH_SIZE-1);  // set angle increment
  a = -90.0/RADIAN;   // initialize SINE WAVE FUNCTION
  for(i=0;i<PATH_SIZE;++i) {
    travel = (sin(a)+1.0)*lineLen/2.0;  // distance traveled, SINE WAVE FUNCTION
    g = pt_on_line(travel,lineLen,start,end);

    g_dist = ptpt_dist({0,0,0},{g.x,g.y,0});  // g distance from origin, xy only
    cg_vect_ang = asin(g.y/g_dist) + asin(-S_CG_Y/g_dist) + 90.0/RADIAN;  // TRICKY TRIG HERE
    c.x = g.x - S_CG_Y*cos(cg_vect_ang); // account for the S_CG_Y offset in both x and y
    c.y = g.y - S_CG_Y*sin(cg_vect_ang);   

    if (liftMiddle) c.z = g.z + S_CG_X + cos(a)*lift;  // add the lift function
    else c.z = g.z + S_CG_X;        // don't add the lift function (straight line path)

    inverseArmKin(c,LEN_AB,LEN_BC,angles); // feed c to the inverse function
    the_pathA.a[i] = angles.x*ANGLE_SCALE;   // SCALE RADIANS AND STORE AS INTEGER
    //the_pathA.a[i] = a*ANGLE_SCALE;   // SCALE RADIANS AND STORE AS INTEGER
    the_pathA.b[i] = angles.y*ANGLE_SCALE;
    the_pathA.c[i] = getCang(angles.x,angles.y,-90.0/RADIAN)*ANGLE_SCALE;
    // USE AIM POINT TO FIND D ANGLE
    d_aim_angle = atan2((aim.y-g.y),(aim.x-g.x));
    the_pathA.d[i] = (angles.z - d_aim_angle)*ANGLE_SCALE;
    the_pathA.t[i] = angles.z*ANGLE_SCALE; 

    a = a + angIncrement;
  }
}
```

K_ORBIT works in a similar method to K_LINE_G, except that the path on the xy plane is an arc, and the aiming of the claw is toward the arc center.

## Inverse Kinematics Function, used in TELE and AUTO

The code for the Inverse Kinematincs function is shown here:

```c++
void inverseArmKin(point c, float l_ab, float l_bc,point & angles) {
  // Given robot arm Ground-Turtable-AB-BC, where Turntable and A are [0,0,0]
  // The location of joint C (point c) and the lengths AB (l_ab) and BC (l_bc) are specified
  // The joints A,B are on a turntable with rotation T parallel to Z through A
  // With T_angle = 0, then joints A & B are parallel to the Y axis
  // Calculate the angles given pt C ***Inverse Kinematics***
  // returns an array (TYPE point) with [A_angle,B_angle,T_angle] in radians
  //
  // Inverse Kinematics is not much more than a few tri formulas
  // A Reference to the math is here: https://appliedgo.net/roboticarm/
  //
  float c_len, sub_angle1, sub_angle2;
  point c_new;
  static float tAngMemory = 0.0;  //  NEEDS TO BE STATIC

  // Check for near negative x values to prevent bad math, arm clashes
  if (c.x < 2.0) {  // 2 mm
    c.x = 2.0;
    angles.z = tAngMemory/1.3;  // ease the transition toward zero turntable angle
  } else {
    angles.z = atan2(c.y,c.x);   // turntable angle, compute with pos x
  }
  tAngMemory = angles.z;

  // CONVERT THE 3D POINT PROBLEM TO A 2D PROBLEM, FOR SOLVING THE INVESE KINEMATICS
  c_new = rot_pt_z(c,-angles.z); // rotate the point c onto the XZ plane using turntable angle
  c_len = sqrt(pow((c_new.x),2)+pow(c_new.z,2));   // XZ plane, reuse variable c_len

  // THIS IS THE 2D INVESE KINEMATIC MATH
  if (c_len < l_ab+l_bc) {
    // case where robot arm can reach
    sub_angle1 = atan2(c_new.z,c_new.x);
    sub_angle2 = acos((pow(c_len,2)+pow(l_ab,2)-pow(l_bc,2))/(2*c_len*l_ab));
    angles.x = sub_angle1 + sub_angle2;
    angles.y = acos((pow(l_bc,2)+pow(l_ab,2)-pow(c_len,2))/(2*l_bc*l_ab))-180.0/RADIAN;
  } else {
    // case where robot arm can not reach point... 
    angles.x = atan2(c_new.z,c_new.x); // a angle point in direction to go
    angles.y = 0.0; // b is straight
  } 
}
```
