/* ROBOT ARM CONTROL SOFTWARE FOR MAKE3 ROBOT ARM
 *  By, SrAmo, May 2023
 *  Written for an Arduino Leonardo and an Adafruit Servo Shield.
 */
#include <Adafruit_PWMServoDriver.h>

#define SERVO_FREQ 50 // Analog servos run at ~50 Hz updates, from Adafruit
#define RADIAN 57.2957795  // number of degrees in one radian
#define RAMP_START_DIST 50 // distance at which velocity ramp-down begins (mm) used in velocity control
#define ZERO_DIST 0.5     // value used to determine if distance is zero (mm)

// STATES (or programs)  Controlled by the selector potentiometer
//#define S_SERIAL 0      // enter a serial command from serial.input
#define S_TELEOP_1 1   
#define S_AUTO_2   2 
#define S_TELEOP_3 3 
#define S_TELEOP_4 4
#define S_AUTO_5 5   // wait above block
#define S_AUTO_6 6   // block stack sequence
#define S_AUTO_7 7   // block to block stack sequence
#define S_TELEOP_8 8   
#define S_TELEOP_9 9  
#define S_AUTO_10 10 

// HAND MODES control how the end of the arm can operate (joints C and D)
// Note: For each loop the arm C point is obtained (from multiple methods) and angles A, B and T are solved (inverse kinematics)
#define HM_CD_LOC 0
#define HM_CD_ABS 1
#define HM_C_LOC_D_ABS 2
#define HM_C_ABS_D_LOC 3
#define HM_CD_AIM 4
#define HM_NONE 5  // No Hand Mode is applied

/*
 *  COMMAND CODES: All codes are integers
 *  Feed rate is in mm per second.
 *  Angle rate is in Degrees per second.
 *  Angles given in Degrees.  Locations in mm.
 */
#define SIZE_CMD_ARRAY 5  // NUMBER OF VARIABLES PER COMMAND. 

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
//#define K_C_LOC 12    // C local move           {angle rate, target angle}
//#define K_C_ABS 13    // C Absolute Angle Mode, {angle rate, target angle}
//#define K_D_LOC 14    // D local move           {angle rate, target angle}
//#define K_D_ABS 15     // D Absolute Angle Mode {angle rate, target angle}

// GEOMETRY OF ARM:
#define LEN_AB 350.0     // Length of Input AB arm in mm
#define LEN_BC 380.0     // Length of Input BC arm in mm
#define FLOOR -140.0     // Distance from A joint to Floor in mm (-140 mm claw, -50 with camera)
#define S_CG_X 150.0    // offset from joint C to G in X.  180 is a claw value,  90 is GoPro
#define S_CG_Y -38.0     // offset from joint C to G in Y.  -38 is GoPro
#define S_CG_Z 0.0     // offset from joint C to G in Z.  40 is Claw.  0 is GoPro
 /*  STRUCTURES FOR MATH, SERVOS, POTENTIOMETERS, JOINTS, and ARM  */
struct point {float x,y,z;}; 
struct line {struct point p1 , p2; };

struct potentiometer {
  int analog_pin; // Arduino analog pin number (0 - 5)
  int low_mv; // low voltage value, from 0 (0 Volts) to 1023 (5 Volts)
  float low_ang; // corresponding angle at low voltage, in radians
  int high_mv; // high voltage value, from 0 (0 Volts) to 1023 (5 Volts)
  float high_ang; // corresponding angle at high voltage, in radians
  // Note: low and high values do not need to be  at the extreems
  //  Tip:  Pick low and high angles that are easy to read/set/measure
  //      Values outside of the low and high will be extrapolated
};

struct servo {
  // Values are pulse width in microseconds (~400 to ~2400--SERVOS SHOULD BE TESTED)
  // 270 deg servo, gets 290 deg motion with 400 to 2500 microsecond range
  // 180 deg servo, gets 160 deg motion with 500 to 2800 microsecond range
  uint8_t digital_pin; // Adafruit digital pin number
  int low_ms; // low microsecond value, from about 500 to 2400
  float low_ang; // corresponding angle at low microsecond, in radians
  int high_ms; // high microsecond value, from about 500 to 2400
  float high_ang; // corresponding angle at high microsecond, in radians
}; 

struct joint {
  potentiometer pot; // Sub structure which contains static pot information
  servo svo; // Sub structure which contains the static servo information
  int pot_value;  // current potentiometer value in millivolts
  float pot_angle; // Potentiometer arm angle, if used, in radians
  float current_angle; // last issued command for angl, in radians
  float target_angle;  // where the angle should end up, in radians
  float target_velocity;  // radians per millisecond
};

struct digiSwitchStruct {  // structure for physical button switch connected to a digital input pin
  int inputPin = 5;
  boolean isOn = false;  // each time the button is pushed the value is toggled
  int delayMS = 500;     // delay time to avoid switch bounce, in milliseconds
  unsigned long timerStart; // timer variable for the delay, se we don't use delay() in loop
};


struct arm {  // as in Robot Arm
  int state; // The different ways that the arm can be controlled. Set by S potentiometer
  int mode; // The mode in which the arm runs, primarily the end effector (C and D joints)
  int n; // current active index in the command array
  int loopCount;  // for command looping (using K_GOTO), this keeps track of the loop number  
  boolean initialize;  //  for initializing commands
  unsigned long prior_mst; // clock time (microseconds) prior loop 
  unsigned long dt; // delta loop time in ms
  unsigned long timerStart; // timer, for delays
  float feedRate; // feed rate for point moves, in mm/sec (converted to /microsec)
  point current_pt; // current (C or G) point 
  point target_pt;  // target C or G point
  point aim_pt;   // aiming point 
  float line_len;  // calculated distance from current_pt to target_pt
  joint jA;
  joint jB;
  joint jC;
  joint jD;
  joint jCLAW;
  joint jT;
};

struct command {unsigned long arg[SIZE_CMD_ARRAY];}; // was int

struct sequence {  // An array of commands
  int nuHm_cmds;
  command cmd[];  // undefined array length
};

// Path of Servo Angles.  Stored as integer to minimize memory usage.  Scale by at least 1000 for smooth results
#define PATH_SIZE 20   // was 20
#define ANGLE_SCALE 1000   // used to store radians in integer format (radian*SCALE)
struct pathAngles {
  int a[PATH_SIZE];
  int b[PATH_SIZE];
  int c[PATH_SIZE];
  int d[PATH_SIZE];
  int t[PATH_SIZE];        
};

//   GOBAL VARIABLES 
arm make3; 
joint jS;  // selector pot
digiSwitchStruct clawSwitch;  // holds data for the claw push button switch
pathAngles pathA; // for storing pre-computed servo angles

sequence seQ = {2,{{0,0,0,0,0},
//                {0,0,0,0,0}, 
//                {0,0,0,0,0},
//                {0,0,0,0,0},
//                {0,0,0,0,0},
//                {0,0,0,0,0},
//                {0,0,0,0,0},
//                {0,0,0,0,0},
//                {0,0,0,0,0},
//                {0,0,0,0,0},
//                {0,0,0,0,0},
                {0,0,0,0,0}}}; 
                           
// called this way, it uses the default address 0x40
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();

// SETTERS,  INITIALIZERS
potentiometer initPot(int pin, int lowmv, float lowang, int highmv, float highang) {
  // initPot(pin,lowmv,lowang,highmv,highang)
  // Note: low and high values do not need to be  at the extreems
  struct potentiometer pot;
  pot.analog_pin = pin;
  pot.low_mv = lowmv;
  pot.low_ang = lowang;
  pot.high_mv = highmv;
  pot.high_ang = highang;
  return pot;
}

servo initServo(int pin, float lowang, int lowms, float highang, int highms) {
  // initServo(pin,lowang,lowms,highang,highmv)
  // Note: low and high values do not need to be  at the extreems
  struct servo svo;
  svo.digital_pin = pin;
  svo.low_ang = lowang;
  svo.low_ms = lowms;
  svo.high_ang = highang;
  svo.high_ms = highms;
  return svo;
}

void initJoint(joint & jt, float initial_angle) {
  // Sets initial joint values
  // Note: can't read physical servo angle, so servos can jump on startup
  jt.current_angle = initial_angle;
  jt.target_angle = initial_angle;
  jt.target_velocity = 60.0/RADIAN/1000.0;  // default initial velocity, radians per microsecond
}

void initArm(arm & the_arm, point pt) { // starting point for arm
  // initialize arm structure
  the_arm.state = 0;
  the_arm.mode = HM_CD_ABS;  
  the_arm.n = -1;  // first command, USE -1 TO INDICATE NOT RUNNING A COMMAND
  the_arm.loopCount = 0;
  the_arm.initialize = true;  
  the_arm.prior_mst = millis();
  the_arm.dt = 10;  
  the_arm.timerStart = millis();
  the_arm.feedRate = 250.0;  
  the_arm.current_pt = pt;
  the_arm.target_pt = pt;
  the_arm.aim_pt = pt;
  the_arm.aim_pt.x = the_arm.aim_pt.x + 300.0;
  the_arm.line_len = 0.0;
}

void initSwitch(digiSwitchStruct & theSwitch,int pin, int delay) {
  theSwitch.inputPin = pin;
  theSwitch.isOn = false;
  theSwitch.delayMS = delay;
  theSwitch.timerStart = 0;
}

void checkSwitch(digiSwitchStruct & theSwitch) { // checks if the switch has been pressed and sets isOn variable
  int reading = digitalRead(theSwitch.inputPin);
  int deltaTime = millis() - theSwitch.timerStart;
  if ((reading == 0) && (deltaTime > theSwitch.delayMS)) { // check is switch has toggled
    theSwitch.isOn = !theSwitch.isOn;
    theSwitch.timerStart = millis(); // timer is done, reset
  }
}

float getCang(float a_angle, float b_angle, float fixed_c_angle) { // returns joint angle C, using A and B
  // Assumes that you want an absolute (fixed) C angle
  return -a_angle - b_angle + fixed_c_angle;
}

//  ###############  MATH FUNCTIONS ###########################
float floatMap(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

point rot_pt_x(point p1, float a) { // Rotate p1 about X axis by a radians
  point p2;
  p2.x = p1.x;
  p2.y = p1.y*cos(a)-p1.z*sin(a);
  p2.z = p1.y*sin(a)+p1.z*cos(a);
  return p2;
}

point rot_pt_y(point p1, float a) { // Rotate p1 about Y axis by a radians
  point p2;
  p2.x = p1.x*cos(a)-p1.z*sin(a);
  p2.y = p1.y;
  p2.z = p1.x*sin(a)+p1.z*cos(a);
  return p2;
}

point rot_pt_z(point p1, float a) { // Rotate p1 about Z axis by a radians
  point p2;
  p2.x = p1.x*cos(a)-p1.y*sin(a);
  p2.y = p1.x*sin(a)+p1.y*cos(a);
  p2.z = p1.z;
  return p2;
}

point add_pts(point p1, point p2) {
  point p3;
  p3.x = p1.x+p2.x;   p3.y = p1.y+p2.y;   p3.z = p1.z+p2.z;
  return p3;
}
float ptpt_dist(point p1, point p2) {
  return  sqrt(pow(p1.x-p2.x,2.0)+pow(p1.y-p2.y,2.0)+pow(p1.z-p2.z,2.0) );
}

point pt_on_line(float s, float dist, point p1, point p2) { // point along line s from p1
  point new_pt;
  float ratio;
  ratio = s / dist; 
  new_pt.x = ratio*(p2.x-p1.x) + p1.x;
  new_pt.y = ratio*(p2.y-p1.y) + p1.y;
  new_pt.z = ratio*(p2.z-p1.z) + p1.z;
  return new_pt;
}

void inverseArmKin(point c, float l_ab, float l_bc, point & angles) {
  // Given robot arm Ground-Turtable-AB-BC, where Turntable and A are [0,0,0]
  // The location of joint C (point c) and the lengths AB (l_ab) and BC (l_bc) are specified
  // The joints A,B are on a turntable with rotation T parallel to Z through A
  // With T_angle = 0, then joints A & B are parallel to the Y axis
  // Calculate the angles given pt C ***Inverse Kinematics***
  // RETURNS angles (array of TYPE point) with [A_angle,B_angle,T_angle] in radians
  //
  // Inverse Kinematics is a few trig formulas
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

  // CONVERT 3D POINT TO A 2D POINT, FOR SOLVING THE INVESE KINEMATICS
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

void inverseArmKin2D(point c, float l_ab, float l_bc, point & angles) {
  // Given robot arm Ground-Turtable-AB-BC, where Turntable and A are [0,0,0]
  // The location of joint C (point c) and the lengths AB (l_ab) and BC (l_bc) are specified
  // The joints A,B are on a turntable with rotation T parallel to Z through A
  // With T_angle = 0, then joints A & B are parallel to the Y axis
  // Calculate the angles given pt C ***Inverse Kinematics***
  // RETURNS angles (array of TYPE point) with [A_angle,B_angle,0] in radians
  //
  // Inverse Kinematics is a few trig formulas
  // A Reference to the math is here: https://appliedgo.net/roboticarm/
  //
  float c_len, sub_angle1, sub_angle2;

  angles.z = 0.0;  // 2D, this is always zero

  c_len = sqrt(pow((c.x),2)+pow(c.z,2));   // XZ plane
  // Check for near zero values to prevent bad math, arm clashes
  if (c_len < 2.0) {  // 2 mm
    c.x = 2.0;
    c_len = 2.0;
  } 

  // THIS IS THE 2D INVESE KINEMATIC MATH
  if (c_len < l_ab+l_bc) {
    // case where robot arm can reach
    sub_angle1 = atan2(c.z,c.x);
    sub_angle2 = acos((pow(c_len,2)+pow(l_ab,2)-pow(l_bc,2))/(2*c_len*l_ab));
    angles.x = sub_angle1 + sub_angle2;
    angles.y = acos((pow(l_bc,2)+pow(l_ab,2)-pow(c_len,2))/(2*l_bc*l_ab))-180.0/RADIAN;
  } else {
    // case where robot arm can not reach point... 
    angles.x = atan2(c.z,c.x); // a angle point in direction to go
    angles.y = 0.0; // b is straight
  } 
}

/*
point anglesToC(float a, float b, float t, float l_ab, float l_bc){  // Forward Kinematics
  // Apply translations and rotations to get the C point
  point pB,pC, pTemp;
  pB.x = l_ab;   pB.y = 0.0;  pB.z = 0.0;
  pC.x = l_bc;   pC.y = 0.0;  pC.z = 0.0;
  pTemp = rot_pt_y(pC,b);  // rotate b
  pC = add_pts(pB,pTemp);  // add to AB arm
  pTemp = rot_pt_y(pC,a); // rotate a
  pC = rot_pt_z(pTemp,t);  // rotate turntable
  return pC;
}  */

//  Forward Kinematics, Apply translations and rotations to get point G
//  Used by Teleoperated only
point anglesToG(float a, float b, float t, float c, float d, float l_ab, float l_bc, float sCGx, float sCGy) {
  point pB,pC, pG, pTemp;
  
  pB.x = l_ab;   pB.y = 0.0;  pB.z = 0.0;
  pC.x = l_bc;   pC.y = 0.0;  pC.z = 0.0;
  pG.x = sCGx;   pG.y = sCGy;  pG.z = 0.0;

  pTemp = rot_pt_x(pG,d);  // rotate point G about d
  pG = rot_pt_y(pTemp,c);  // rotate c
  pTemp = add_pts(pC,pG);  // add G to BC arm
  pG = rot_pt_y(pTemp,b);  // rotate b
  pTemp = add_pts(pB,pG);     // add to AB arm
  pG = rot_pt_y(pTemp,a); // rotate a
  pTemp = rot_pt_z(pG,t);  // rotate turntable
  return pTemp;
}  
point pointGtoPointC(point pG,float c, float d, float sCGx, float sCGy) {
  point plocalG,pTemp;  
  plocalG.x = -sCGx;   plocalG.y = -sCGy;  plocalG.z = 0.0;
  pTemp = rot_pt_x(plocalG,d);  // rotate point G about d
  plocalG = rot_pt_y(pTemp,c);  // rotate c
  pTemp = add_pts(plocalG,pG);  // add 
  return pTemp;  
}
void pot_map(joint & jt) { // Map a potentiometer value in millivolts to an angle
  // map(value, fromLow, fromHigh, toLow, toHigh), USES INTEGER MATH
  // NOTE: SCALE ANGLES (RADIANS) UP THEN DOWN TO GET PRECISION FROM POT VALUES
  jt.pot_angle = map(jt.pot_value, jt.pot.low_mv, jt.pot.high_mv, jt.pot.low_ang*1000, jt.pot.high_ang*1000) / 1000.0; 
  jt.target_angle = jt.pot_angle;  // assume that the two are equal for now, RADIANS
}

float servo_map(joint & jt) { // Map current joint angle to the servo microsecond value
  return floatMap(jt.current_angle, jt.svo.low_ang, jt.svo.high_ang, jt.svo.low_ms, jt.svo.high_ms);
}

// Move Current toward Target at given RateLimit (no units)
// Used in Teleoperated only
float rateLimitMove(float Target, float Current, float RateLimit) { 
  float delta, newV=0;
  delta = Target-Current;
  if (abs(delta) > abs(RateLimit)) { // rate limit the move
      if (delta > 0 ) { 
        newV = Current + abs(RateLimit);  
      } else if (delta < 0)  {
        newV = Current - abs(RateLimit);  
      };
  } else {
    newV = Current + delta;
  }
  return newV;
}

// Move current point C toward target_pt at given feed rate (mm/sec)
// Parameter is arm Structure, and it is modified
// Used in Teleoperated only
void updateArmPtC(arm & the_arm) { 
  float moveDist,newFeedRate,distC;
  the_arm.line_len = ptpt_dist(the_arm.current_pt,the_arm.target_pt);
  if (the_arm.line_len > ZERO_DIST) { // not at target point, compute a new current point
    // decrease the feedrate when the current pt x,y component is close to global 0,0.  To stop the rocking dynamics. 
    distC = sqrt(pow(the_arm.current_pt.x,2)+pow(the_arm.current_pt.y,2));
    newFeedRate = the_arm.feedRate;
      if (distC < 100) newFeedRate = newFeedRate*((distC+50)/150);  // Ramp down around global 0,0
      if (the_arm.line_len < RAMP_START_DIST) { // decrease velocity at end for pick and place
        newFeedRate = the_arm.feedRate*(the_arm.line_len/RAMP_START_DIST);  // scale down
      } else {
        newFeedRate = the_arm.feedRate;  // keep using the current feedrate
      };
    moveDist = newFeedRate/1000.0 * (the_arm.dt); // dist(mm) = feed rate(mm/ms)*dt(ms)  
    the_arm.current_pt = pt_on_line(moveDist,the_arm.line_len, the_arm.current_pt,the_arm.target_pt);
  }
}

/*
void logPoint(arm & the_arm) {  // Use for debugging paths
  Serial.print(make3.state);
  Serial.print(",cmdNo=");
  Serial.print(make3.n);        
  Serial.print(",");
  Serial.print(make3.prior_mst);        
  Serial.print(",");
  Serial.print(make3.dt);        
  Serial.print(",");
  Serial.print("CRNT PT,");
  Serial.print(the_arm.current_pt.x);
  Serial.print(",");
  Serial.print(the_arm.current_pt.y);
  Serial.print(",");
  Serial.print(the_arm.current_pt.z);
  Serial.print(",AIM PT,");
  Serial.print(the_arm.aim_pt.x);
  Serial.print(",");
  Serial.print(the_arm.aim_pt.y);
  Serial.print(",");
  Serial.print(the_arm.aim_pt.z);
  
  Serial.print(",jA_CRNT_ANG,");
  Serial.print(the_arm.jA.current_angle*RADIAN,1);
  Serial.print(",jB_CRNT_ANG,");
  Serial.print(the_arm.jB.current_angle*RADIAN,1);
  Serial.print(",jC_CRNT_ANG,");
  Serial.print(the_arm.jC.current_angle*RADIAN,1);
  Serial.print(",jD_CRNT_ANG,");
  Serial.print(the_arm.jD.current_angle*RADIAN,1);
  
  Serial.print(",TRGT PT,");
  Serial.print(the_arm.target_pt.x);
  Serial.print(",");
  Serial.print(the_arm.target_pt.y);
  Serial.print(",");
  Serial.print(the_arm.target_pt.z);
  Serial.println(",");
}
void logCmds(sequence & the_cmds, char *string) { // use for debugging
  Serial.println("logCmds");
  int i;
  for (int i=0;i<the_cmds.nuHm_cmds;++i) {
    Serial.print(string);
    Serial.print(i); 
    for (int j=0;j<SIZE_CMD_ARRAY;++j) {
      Serial.print(",");
      Serial.print(the_cmds.cmd[i].arg[j]); 
    }
    Serial.println("."); 
  }
} 
*/
void logData(joint jt,char jt_letter) { // Use for Initial Calibration of Potentiometers and Servos
  Serial.print(make3.state);
  Serial.print(",cmdNo=");
  Serial.print(make3.n);        
  Serial.print(",");
  Serial.print(make3.prior_mst);        
  Serial.print(",");
  Serial.print(make3.dt);        
  Serial.print(",");
  Serial.print(jt_letter);
  Serial.print(", p_value,");
  Serial.print(jt.pot_value);
  Serial.print(", Pang,");
  Serial.print(jt.pot_angle*RADIAN,1);
  Serial.print(",crnt_ang,");
  Serial.print(jt.current_angle*RADIAN,1);
  Serial.print(",trgt_ang,");
  Serial.print(jt.target_angle*RADIAN,1);
  Serial.print(",Servo (microsec),");
  Serial.print(servo_map(jt));
  //Serial.print(",target_vel (DEG/SEC),"); 
  //Serial.print(jt.target_velocity*RADIAN*1000.0,1);
  Serial.println(".");
}  //
void logGeneral() { // use for general debugging
  Serial.print("STATE,");
  Serial.print(make3.state);
  Serial.print(",armMODE,");
  Serial.print(make3.mode);
  // Serial.print(",LOOP,");
  // Serial.print(make3.loopCount);
  // Serial.print(",cmdNo=");
  // Serial.print(make3.n);
  // if (make3.n < seQ.nuHm_cmds) {
  //   Serial.print(",arg[0]=");
  //   Serial.print(seQ.cmd[make3.n].arg[0]);          
  // }
  Serial.print(",clawSwitch,");
  Serial.print(clawSwitch.isOn);
  //Serial.print(",lineLen,");
  //Serial.print(make3.line_len);
  Serial.print(",dt=");
  Serial.println(make3.dt);        
}
void printPoint(point the_pt,char letter) {
  Serial.print(letter);
  Serial.print(",");
  Serial.print(the_pt.x);
  Serial.print(",");
  Serial.print(the_pt.y);
  Serial.print(",");
  Serial.println(the_pt.z);
} //
  
boolean runCommand(arm & the_arm, sequence  & the_seq, int idx) { // TRUE if DONE, FALSE is NOT DONE
  static point center,final_g;      // must be static
  static float currentLen, stepLen, rad, sweep;  // must be static
  static int numberLoops = 1;
  static boolean liftPath = false;
  static int liftValue = 0;
  int index;
  command the_cmd;    
  the_cmd = the_seq.cmd[idx]; // pull out the one command from the sequence

  switch (the_cmd.arg[0]) {    // command
    case 0:  // ZERO command must do nothing!
      return true;
      break;
    case K_TIMER: // DELAY (timer)
      if ((millis()-the_arm.timerStart) > the_cmd.arg[1]) {
        return true;
      } else  return false;
      break;
    case K_ORBIT_Z:  // point G orbits in an xy plane, a point on xz plane
      if (the_arm.initialize) {  
        the_arm.feedRate = (float)the_cmd.arg[1];  // FIRST ARG is mm per sec
        center = {(float)the_cmd.arg[2],0.0,the_arm.target_pt.z};  // SECOND ARG is the X center of orbit
        rad = (float)the_cmd.arg[3];  // THIRD ARG is RADIUS, between ~10 and 1000 mm
        sweep = (float)the_cmd.arg[4]; // FOURTH ARG is SWEEP ANGLE, between 90 and 270, or -90 to -270 degrees
        final_g = path_orbit_xy(pathA,center,rad,sweep);  // Build the orbit path
        //print_pathAngles(pathA);
        the_arm.line_len = abs(arcLen(sweep,rad));  // STORE THE ARC LENGTH... THIS WILL BE OFF DUE TO ARC FLATS
        currentLen = 0.0;
        stepLen = the_arm.feedRate/100.0; // mm per loop.   MATH NOT RIGHT.  ASSUMES A CONSTANT LOOP SPEED
        the_arm.initialize = false;  // don't execute setup again
      }
      if (currentLen > the_arm.line_len) {  // DONE WITH ORBIT
        the_arm.target_pt = final_g;        
        the_arm.current_pt = the_arm.target_pt;        
        the_arm.initialize = true;        
        return true;
      } else { // step through the path list and return false to keep the next command from running
        the_arm.jA.current_angle = getPA(pathA, 1, currentLen,the_arm.line_len);
        the_arm.jB.current_angle = getPA(pathA, 2, currentLen,the_arm.line_len);
        the_arm.jC.current_angle = getPA(pathA, 3, currentLen,the_arm.line_len);
        the_arm.jD.current_angle = getPA(pathA, 4, currentLen,the_arm.line_len) + 180.0/RADIAN;
        the_arm.jT.current_angle = getPA(pathA, 5, currentLen,the_arm.line_len);
        //Serial.print("currentLen,");
        //Serial.println(currentLen,2);
        currentLen = currentLen + stepLen;        
        return false;
      }  
      break;
    case K_LINE_G:  // pt to pt line of POINT G.  Set aim point with AIM command, PRIOR to this command.
      if (the_arm.initialize) {  
        the_arm.feedRate = (float)the_cmd.arg[1];
        final_g = {(float)the_cmd.arg[2],(float)the_cmd.arg[3],(float)the_cmd.arg[4]};  // final_g is the final point
        the_arm.line_len = ptpt_dist(the_arm.current_pt,final_g);  // store the length of the move
        if (the_arm.line_len > ZERO_DIST) { // move required
          // Build the path. Stored in global pathA
          path_line(pathA,{the_arm.current_pt.x,the_arm.current_pt.y,the_arm.current_pt.z},final_g,the_arm.aim_pt,liftPath,liftValue); 
          currentLen = 0.0;
          stepLen = the_arm.feedRate/100.0; // mm per loop.  ASSUMES A CONSTANT LOOP SPEED
          the_arm.initialize = false;  // don't execute setup again
        } else { // no move required, go to next command
          currentLen = 2.0*ZERO_DIST; // this will finish the command
        }
      }
      if (currentLen > the_arm.line_len) {  // DONE WITH COMMAND.  Update current position.
        the_arm.target_pt = final_g;        
        the_arm.current_pt = the_arm.target_pt;        
        the_arm.line_len = 0.0;         // reset
        the_arm.timerStart = millis();  // reset
        the_arm.initialize = true;        
        return true;
      } else { // step through the path list and return false to keep the next command from running
        the_arm.jA.current_angle = getPA(pathA, 1, currentLen,the_arm.line_len);
        the_arm.jB.current_angle = getPA(pathA, 2, currentLen,the_arm.line_len);
        the_arm.jC.current_angle = getPA(pathA, 3, currentLen,the_arm.line_len);
        the_arm.jD.current_angle = getPA(pathA, 4, currentLen,the_arm.line_len);
        the_arm.jT.current_angle = getPA(pathA, 5, currentLen,the_arm.line_len);
        currentLen = currentLen + stepLen;        
        return false;
      }
      break;
    case K_GOTO:  // to be made more robust
      if (the_arm.loopCount < numberLoops) { // only read the command the first time
        the_arm.n = the_cmd.arg[1]-1;  //  arg 1 is the command number to go to
        numberLoops = the_cmd.arg[2];  //  arg 2 is the number of loops to execute
        the_arm.loopCount = the_arm.loopCount + 1;
        return true;
      }
      break;      
    case K_COMBINE: 
      index = the_cmd.arg[1];
      center.x = the_cmd.arg[2];
      center.y = the_cmd.arg[3];
      center.z = the_cmd.arg[4];
      the_seq.cmd[index].arg[2] = the_seq.cmd[index].arg[2] + center.x;  
      the_seq.cmd[index].arg[3] = the_seq.cmd[index].arg[3] + center.y;  
      the_seq.cmd[index].arg[4] = the_seq.cmd[index].arg[4] + center.z;  
      return true;
      break;
    case K_LIFT: 
      index = the_cmd.arg[1];
      if (index == 0) liftPath = false;
      if (index == 1) liftPath = true;
      liftValue = the_cmd.arg[2];
      return true;
      break;
    /*case K_C_LOC:  // Move C servo to a local angle
      // arg[1] is the velocity C, DEG per Second
      if (the_cmd.arg[1] < 10) the_cmd.arg[1] = 10; // NO Negatives or Zeros
      the_arm.jC.target_velocity = the_cmd.arg[1]/RADIAN/1000.0;
      the_arm.jC.target_angle = the_cmd.arg[2]/RADIAN;  // arg[2] is NEW ANGLE FOR C
      the_arm.mode = HM_CD_LOC;      
      return true;
      break;  
    case K_C_ABS:  // move C servo relative to ground (absolute)
      // arg[1] is the velocity C, DEG per Second
      if (the_cmd.arg[1] < 10) the_cmd.arg[1] = 10; // NO Negatives or Zeros
      the_arm.jC.target_velocity = the_cmd.arg[1]/RADIAN/1000.0;
      the_arm.jC.target_angle = the_cmd.arg[2]/RADIAN;  // arg[2] is NEW ANGLE FOR C
      the_arm.mode = HM_C_ABS_D_LOC;      
      return true;
      break; 
    case K_D_LOC:  // D servo
      // arg[1] is the velocity D, DEG per Second
      if (the_cmd.arg[1] < 10) the_cmd.arg[1] = 10; // NO Negatives or Zeros
      the_arm.jD.target_velocity = the_cmd.arg[1]/RADIAN/1000.0;
      the_arm.jD.target_angle = the_cmd.arg[2]/RADIAN;  // arg[2] is NEW ANGLE FOR D
      the_arm.mode = HM_C_ABS_D_LOC;      
      return true;
      break; 
    case K_D_ABS:  // move D servo relative to ground (absolute)
      // arg[1] is the velocity D, DEG per Second
      if (the_cmd.arg[1] < 10) the_cmd.arg[1] = 10; // NO Negatives or Zeros
      the_arm.jD.target_velocity = the_cmd.arg[1]/RADIAN/1000.0;
      the_arm.jD.target_angle = the_cmd.arg[2]/RADIAN;  // arg[2] is NEW ANGLE FOR D
      the_arm.mode = HM_CD_ABS;      
      return true;
      break; */
    case K_CLAW:  // CLAW servo {rate,angle,delay}
      // arg[1] is the claw velocity, DEG per Second
      if (the_cmd.arg[1] < 10) the_cmd.arg[1] = 10; // NO Negatives or Zeros
      the_arm.jCLAW.target_velocity = the_cmd.arg[1]/RADIAN/100.0;
      the_arm.jCLAW.target_angle = the_cmd.arg[2]/RADIAN;  // arg[2] is NEW ANGLE FOR Claw
      if ((millis()-the_arm.timerStart) > the_cmd.arg[3]) { // arg[3] is the delay in milliseconds
        return true;
      } else  return false;
      break;
//    case K_LINE_C: // line move, from C current_pt to given C target_pt  NEEDS UPDATE
      /*if (the_arm.initialize) {
        the_arm.feedRate = the_cmd.arg[1];
        the_arm.target_pt.x = the_cmd.arg[2];
        the_arm.target_pt.y = the_cmd.arg[3];
        the_arm.target_pt.z = the_cmd.arg[4];
        the_arm.line_len = ptpt_dist(the_arm.current_pt,center);  // STORE THE LENGTH
        the_arm.initialize = false;
      }
      if (the_arm.line_len < ZERO_DIST) {  // lINE IS DONE
        the_arm.initialize = true;
        return true;
      } else { // return false to keep the next command from running
        return false;
      } */
//      break;
    case K_AIM:
      the_arm.mode = HM_CD_AIM;      
      the_arm.aim_pt.x = the_cmd.arg[1];
      the_arm.aim_pt.y = the_cmd.arg[2];
      the_arm.aim_pt.z = the_cmd.arg[3];
      return true;      
      break;
    case K_END:      
      the_arm.n = 999;
      return true;
      break;      
    default:
      return true;
      break;          
  } // end switch   
  return false;
}
float getPA(pathAngles & the_path, int theAngle, float dist, float totalDist) { // get Path Angle
  // Get one angle (theAngle) from pathAngles array, at dist along path
  float realIndexDist;  // 
  int index;
  index = (PATH_SIZE-1)*(int)dist/(int)totalDist;  // integer division causes truncation
  realIndexDist = (dist/totalDist)*(float)(PATH_SIZE-1.0);  // compute realIndexDist
  if (index > PATH_SIZE-2) index = PATH_SIZE-2; // check if index is too large
  if (realIndexDist >= (float)PATH_SIZE-1.0) realIndexDist = (float)PATH_SIZE-1.001;
  switch (theAngle) {
    case 1:  // angle a
      return floatMap(realIndexDist,(float)index,(float)(index+1.0),(float)the_path.a[index]/ANGLE_SCALE,(float)the_path.a[index+1]/ANGLE_SCALE);
      break;
    case 2:  // angle b
      return floatMap(realIndexDist,(float)index,(float)(index+1.0),(float)the_path.b[index]/ANGLE_SCALE,(float)the_path.b[index+1]/ANGLE_SCALE);
      break;
    case 3:  // angle C
      return floatMap(realIndexDist,(float)index,(float)(index+1.0),(float)the_path.c[index]/ANGLE_SCALE,(float)the_path.c[index+1]/ANGLE_SCALE);
      break;
    case 4:  // angle d
      return floatMap(realIndexDist,(float)index,(float)(index+1),(float)the_path.d[index]/ANGLE_SCALE,(float)the_path.d[index+1]/ANGLE_SCALE);
      break;
    case 5:  // angle t
      return floatMap(realIndexDist,(float)index,(float)(index+1),(float)the_path.t[index]/ANGLE_SCALE,(float)the_path.t[index+1]/ANGLE_SCALE);
      break;
    default:  // bogus angle index entered.  return 0
      return  0.0;
      break;      
  }
}
float arcLen(float arcSize,float rad) {  // Arcsize in DEGREES,  rad is in mm
  return (arcSize/360) * 2.0  * (180.0 / RADIAN) * rad;
}
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

void setCmd(command & cmd, int v0, int v1, int v2, int v3, int v4) {
  cmd.arg[0] = v0;
  cmd.arg[1] = v1;
  cmd.arg[2] = v2;
  cmd.arg[3] = v3;
  cmd.arg[4] = v4;
}
/*
void getCmdSerial(command & cmd) { // read command from serial port
  // If cmd[0] = 0 then command has NOT been read
  int i;
  cmd.arg[0] = 0;
  if (Serial.available() > 0){
    for (i=0;i<SIZE_CMD_ARRAY;++i) cmd.arg[i] = 0;  // initialize
    i=0; // reset
    while (Serial.available() > 0) {
      cmd.arg[i] = Serial.parseInt(); // get available ints
      ++i;
    }    
    // print the command
    Serial.print("Command: ");
    for (i=0;i<SIZE_CMD_ARRAY;++i) {
      Serial.print(cmd.arg[i]);
      Serial.print(",");
    }
    Serial.println("END");
  }
}
*/
point path_orbit_xy(pathAngles & the_pathA,point center,int rad, float sweepAng) {  
  // Build a G-point Orbit path about point center, symetric about y=0 plane    
  // Assumes that the C joint if pointing down (-90 degrees)
  // Makes the D joint point at the center of the arc (so if camera were mounted it would orbit around an object)
  //  sweepAng is in DEGREES and should be from 90 to 270 or -90 to -270
  //  the arc sweep is symmetric about x/z plane
  // path increments (~velocity) are set by a sine wave function.
  // Note:  the arm  Jumps to first position
  int i;  
  float current_angle; // radians
  //float angIncrement, sinAngInc; // radians  
  point angles;
  point c,g;
  float g_dist, cg_vect_ang;
  float a, sinAngInc, start_angle;

  start_angle = (180.0 - sweepAng/2.0) / RADIAN;  // compute initial angle
  //angIncrement = (sweepAng/ RADIAN) / (PATH_SIZE-1);

  a = -90.0/RADIAN;  // Initialize Sine Wave Function
  sinAngInc = (180.0/RADIAN)/(PATH_SIZE-1);

  g.z = center.z;
  c.z = g.z + S_CG_X;  // since c joint is rotated -90, then x becomes z

  for(i=0;i<PATH_SIZE;++i) {
    current_angle = ((sin(a)+1.0)/2.0)*(sweepAng/ RADIAN) + start_angle;

    //printPoint(g,'g');
    //Serial.print("current_ang=");
    //Serial.print(current_angle*RADIAN,1);
    //Serial.print(",  a=");
    //Serial.println(a*RADIAN,1);

    g.x = center.x + rad*cos(current_angle);  // point d traces the arc
    g.y = center.y + rad*sin(current_angle);
    g_dist = ptpt_dist({0,0,0},{g.x,g.y,0});  // g distance from origin, xy only
    cg_vect_ang = asin(g.y/g_dist) + asin(-S_CG_Y/g_dist) + 90.0/RADIAN;  // TRICKY TRIG HERE
    c.x = g.x - S_CG_Y*cos(cg_vect_ang); // compute the C point
    c.y = g.y - S_CG_Y*sin(cg_vect_ang);   
    inverseArmKin(c,LEN_AB,LEN_BC,angles); // feed c to the inverse function
    the_pathA.a[i] = angles.x*ANGLE_SCALE;   // CONVERT TO INTEGER AND DEGREES FOR OPENSCAD SIMULATION
    the_pathA.b[i] = angles.y*ANGLE_SCALE;
    the_pathA.c[i] = getCang(angles.x,angles.y,-90.0/RADIAN)*ANGLE_SCALE;
    the_pathA.d[i] = (angles.z - current_angle)*ANGLE_SCALE;   // D NEEDS 180 DEG PHASE SHIFT FOR ARM.  OK FOR OPENSCAD
    the_pathA.t[i] = angles.z*ANGLE_SCALE;

    a = a + sinAngInc;
  }
  return g;  // return the final point
}
//
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
    //printPoint(g,'g');
    //Serial.print("a=");
    //Serial.println(a*RADIAN,1);

    g_dist = ptpt_dist({0,0,0},{g.x,g.y,0});  // g distance from origin, xy only
    cg_vect_ang = asin(g.y/g_dist) + asin(-S_CG_Y/g_dist) + 90.0/RADIAN;  // TRICKY TRIG HERE
    c.x = g.x - S_CG_Y*cos(cg_vect_ang); // account for the S_CG_Y offset in both x and y
    c.y = g.y - S_CG_Y*sin(cg_vect_ang);   

    if (liftMiddle) c.z = g.z + S_CG_X + cos(a)*lift;  // add the lift function
    else c.z = g.z + S_CG_X;        // don't add the lift function (straight line path)

    inverseArmKin(c,LEN_AB,LEN_BC,angles); // feed c to the inverse function
    the_pathA.a[i] = angles.x*ANGLE_SCALE;   // SCALE RADIANS AND STORE AS INTEGER
    the_pathA.b[i] = angles.y*ANGLE_SCALE;
    the_pathA.c[i] = getCang(angles.x,angles.y,-90.0/RADIAN)*ANGLE_SCALE;
    // USE AIM POINT TO FIND D ANGLE
    d_aim_angle = atan2((aim.y-g.y),(aim.x-g.x));
    the_pathA.d[i] = (angles.z - d_aim_angle)*ANGLE_SCALE;
    the_pathA.t[i] = angles.z*ANGLE_SCALE; 

    a = a + angIncrement;
  }
}
/*
void print_pathAngles(pathAngles & the_pathA) {  // Print servo angle path for OpenSCAD
  int i;  
  Serial.print("[");
  for(i=0;i<PATH_SIZE;++i) {
    Serial.print("[");
    Serial.print((float)the_pathA.a[i]/ANGLE_SCALE*RADIAN,1);
    Serial.print(",");
    Serial.print((float)the_pathA.b[i]/ANGLE_SCALE*RADIAN,1);
    Serial.print(",");
    Serial.print((float)the_pathA.c[i]/ANGLE_SCALE*RADIAN,1);
    Serial.print(",");
    Serial.print((float)the_pathA.d[i]/ANGLE_SCALE*RADIAN,1);
    Serial.print(",");
    Serial.print((float)the_pathA.t[i]/ANGLE_SCALE*RADIAN,1);
    Serial.println("],");
  }
}  
*/
void setup() {  // setup code here, to run once:
  pinMode(13,OUTPUT); // LED on Arduino board
  digitalWrite(13,HIGH); // Turn the LED on

  // Initialize the Selector Override Jumper
  // If Jumper between digital 8 & grnd then read returns 0, otherwise 1
  pinMode(8, INPUT);
  digitalWrite(8,HIGH);  // use the built in pull-up resistor

  // Initialize the push button switch
  initSwitch(clawSwitch,5,500);
  pinMode(clawSwitch.inputPin, INPUT);
  digitalWrite(clawSwitch.inputPin,HIGH);  // use the built in pull-up resistor

  Serial.begin(115200); // baud rate
  //delay(2500);  // serial output needs a Big (2500) delay if one wants output during setup

  pwm.begin();
  /*  Adafruit sevo library
   * In theory the internal oscillator (clock) is 25MHz but it really isn't
   * that precise. You can 'calibrate' this by tweaking this number until
   * you get the PWM update frequency you're expecting!
   */
  pwm.setOscillatorFrequency(27000000);
  pwm.setPWMFreq(SERVO_FREQ);  // Analog servos run at ~50 Hz updates
  
  // TUNE POTENTIOMETER LOW AND HIGH VALUES
  // FORMAT: initPot(pin,lowmv,lowang,highmv,highang)
  make3.jA.pot = initPot(1 ,905,  0/RADIAN, 112, 180/RADIAN); // 
  make3.jB.pot = initPot(5 ,500,-90/RADIAN, 908,  0/RADIAN); // good  was 1
  //jC.pot = initPot(3 , 116,-90/RADIAN, 903, 90/RADIAN); // C will not have a pot on Make3
  //make3.jD.pot = initPot(2 ,250, 90/RADIAN, 747, -90/RADIAN); 
  make3.jT.pot = initPot(0 ,894, 90/RADIAN, 127, -90.0/RADIAN); // 3/18/2023, fixed sign   was 4
  //make3.jCLAW.pot = initPot(3 , 250,-50/RADIAN, 750, 50/RADIAN);  // input arm is limited to 250 to 750
  jS.pot = initPot(2 , 0, 0/RADIAN, 1023, 280/RADIAN);  // to tune    was 5

  // TUNE SERVO LOW AND HIGH VALUES
  // FORMAT: initServo(pin,lowang,lowms,highang,highms)
  make3.jA.svo = initServo(0,  7.0/RADIAN, 505, 90.0/RADIAN, 1551); // set 6/6/2023
  make3.jB.svo = initServo(1, 0.0/RADIAN, 500,-175.0/RADIAN, 2320); // good  
  make3.jC.svo = initServo(2, -90.0/RADIAN, 927, 0.0/RADIAN, 1410); // set 3/7/2023
  make3.jD.svo = initServo(3,  -90.0/RADIAN,  811, 90.0/RADIAN, 2054); // good.  Can travel from -135 to 135 deg
  make3.jCLAW.svo = initServo(4, -45.0/RADIAN,  500, 45.0/RADIAN, 2000); // 45 DEG = FULL OPEN, -45 = FULL CLOSE
  make3.jT.svo = initServo(5,  70.0/RADIAN,  2347, -70.0/RADIAN, 465); // 6/6/2023  Servo range is about -70 to 70 deg.

  // INITIALIZE ANGLES FOR ARM
  initJoint(make3.jA, 100.0/RADIAN);  
  initJoint(make3.jB,  -130.0/RADIAN);
  initJoint(make3.jC,  -70.0/RADIAN);
  initJoint(make3.jD,   0.0/RADIAN);
  initJoint(make3.jT,   0.0/RADIAN); 
  initJoint(make3.jCLAW,  17.0/RADIAN); 

  initArm(make3,{LEN_BC/2, 0.0, LEN_AB});
  make3.state = 1; 
  
  digitalWrite(13,LOW); // Turn the LED off

  make3.current_pt = path_orbit_xy(pathA,{400,0,200},200,180.0);
  //print_pathAngles(pathA);  
  }

void stateLoop(arm & the_arm) { // Call this Function at the top of main loop()
  // This is "setup" for each state
  // checks for a change in state and runs the setup for that state  
  static int old_state = -1;  // should force initialize first pass

  #define BLOCKZ -120  // This is the D point to pick a block off of the floor

  int jumperValue = digitalRead(8); // If Jumper between digital 8 & grnd then this returns 0, otherwise 1

  if (jumperValue) {  // ONLY CHECK SELECTOR IF NO JUMPER
    jS.pot_value = analogRead(jS.pot.analog_pin);  // read the selector
    the_arm.state = (jS.pot_value-7)/79; // convert to an integer from  0 to 12
    // pot values are in the range of 100 to 920
    if (the_arm.state != old_state){
      switch (the_arm.state) {
        /*case S_SERIAL: 
          the_arm.n = 0; // reset command pointer
          break; */
        case S_AUTO_2:  // EXAMPLE OF ORBIT COMMAND
          the_arm.n = 0; // reset command pointer
          the_arm.loopCount = 0;   
          #define ORBIT_RAD 300
          setCmd(seQ.cmd[0],K_LIFT,0,0,0,0);         // turn lift off
          setCmd(seQ.cmd[1],K_LINE_G,100,ORBIT_RAD+200,ORBIT_RAD,the_arm.target_pt.z);  // move to start
          setCmd(seQ.cmd[2],K_ORBIT_Z,  100, ORBIT_RAD+200,ORBIT_RAD,180); // orbit, also sets the aim mode
          setCmd(seQ.cmd[3],K_TIMER,1000,0,0,0);    // 1 second delay
          setCmd(seQ.cmd[4],K_ORBIT_Z,  150, ORBIT_RAD+200,ORBIT_RAD,-180); // orbit back the other way
          setCmd(seQ.cmd[5],K_END,0,0,0,0); 
          break;
        case S_AUTO_5:  // PREPARE FOR FIRST BLOCK GRAB
          the_arm.n = 0; // reset command pointer
          the_arm.loopCount = 0;
          the_arm.mode = HM_CD_AIM;   // K_LINE does not set aim mode
          make3.aim_pt.x = 250; make3.aim_pt.y =-5000; make3.aim_pt.z = 100;
          setCmd(seQ.cmd[0],K_LIFT,0,0,0,0);          // turn lift off
          setCmd(seQ.cmd[1],K_LINE_G,300,250,200,BLOCKZ+50);  // move to start
          setCmd(seQ.cmd[2],K_CLAW,  200,-15,500,0); // open claw and wait
          setCmd(seQ.cmd[3],K_END,0,0,0,0); 
          break;      
        case S_AUTO_6:  // GRAB BLOCKS FROM FLOOR AND STACK
          the_arm.n = 0; // reset command pointer
          the_arm.loopCount = 0;
          the_arm.mode = HM_CD_AIM; // K_LINE does not set aim mode
          make3.aim_pt.x = 250; make3.aim_pt.y =-5000; make3.aim_pt.z = 100;
          setCmd(seQ.cmd[0],K_LIFT,1,100,0,0);  // toggle on the z-lift for paths
          setCmd(seQ.cmd[1],K_LINE_G,50,250,200,BLOCKZ);  // move down, first block pickup
          setCmd(seQ.cmd[2],K_LINE_G,300,250,200,BLOCKZ);  // move down, first block pickup
          setCmd(seQ.cmd[3],K_CLAW,  200,45,400,0); // close claw
          setCmd(seQ.cmd[4],K_LINE_G,300,250,-200,BLOCKZ);  // move right
          setCmd(seQ.cmd[5],K_CLAW,  200,-45,400,0); // open claw
          setCmd(seQ.cmd[6],K_COMBINE,4, 0, 0, 51);
          setCmd(seQ.cmd[7],K_GOTO,2,5,0,0);  // go to command 1 and loop 5+1 = 6 times
          //setCmd(seQ.cmd[8],K_LINE_G,50,250,-200,BLOCKZ+7*50);  // move UP
          setCmd(seQ.cmd[8],K_LIFT,0,0,0,0);  // toggle z-lift off
          setCmd(seQ.cmd[9],K_END,0,0,0,0); 
          break;      
        case S_AUTO_7: //  MOVE FROM LEFT BLOCK STACK TO RIGHT BLOCK STACK
          the_arm.n = 0; // reset command pointer
          the_arm.loopCount = 0;
          the_arm.mode = HM_CD_AIM; // K_LINE does not set aim mode
          make3.aim_pt.x = 250; make3.aim_pt.y =-5000; make3.aim_pt.z = 100;
          setCmd(seQ.cmd[0],K_LIFT,1,100,0,0);  // toggle on the z-lift for paths
          setCmd(seQ.cmd[1],K_CLAW,  200,45,400,0); // close claw
          setCmd(seQ.cmd[2],K_LINE_G,300,250,200,BLOCKZ);  // move to left
          setCmd(seQ.cmd[3],K_CLAW,  200,-45,400,0); // open claw 
          setCmd(seQ.cmd[4],K_LINE_G,300,250,-200,80);  // move to right
          setCmd(seQ.cmd[5],K_COMBINE,4, 0, 0, -51);  // subtract from move right
          setCmd(seQ.cmd[6],K_COMBINE,2, 0, 0, 51);  // add to move left
          setCmd(seQ.cmd[7],K_GOTO,1,5,0,0);  // go to command 1 and loop
          setCmd(seQ.cmd[8],K_LINE_G,150,250,0,200); // finish in the middle 
          setCmd(seQ.cmd[9],K_LIFT,0,100,0,0);  // toggle z-lift off
          setCmd(seQ.cmd[10],K_END,0,0,0,0); 
          break; 
        case S_AUTO_10:  // TBD
          break;      
        case S_TELEOP_1:
        case S_TELEOP_3:
        case S_TELEOP_4:
        case S_TELEOP_8:
        case S_TELEOP_9:  // ALL OF THE TELEOP INITIALIZE THE SAME
          the_arm.n = 0; // reset command pointer
          the_arm.loopCount = 0;
          the_arm.mode = HM_CD_ABS;
          make3.jC.target_angle = -90.0/RADIAN;     
          make3.jD.target_angle = 0.0/RADIAN;
          the_arm.feedRate = 250.0;  // mm per second
          break;      
      }
    }
  } else {
    the_arm.state = 4;  // hardcode jumper state to 4
  }
  old_state = the_arm.state;
}

void updateJointBySpeed(joint & jt, unsigned long dt) {
  // NOTE dt is in milliseconds
  float radps;  // radians per millisecond
  radps = (jt.target_angle-jt.current_angle)/dt;  // full move speed
  if (radps > jt.target_velocity) {
    jt.current_angle += jt.target_velocity*dt;
  } else  if (radps < -jt.target_velocity) {
    jt.current_angle -= jt.target_velocity*dt;
  } else {
    jt.current_angle = jt.target_angle; // done
  }
}

void loopTime(arm & the_arm) { // Keep track of Loop time.  Used for regulating servo speeds.
  unsigned long mst;  
  mst = millis();
  the_arm.dt = mst - the_arm.prior_mst; // loop time, milliseconds
  the_arm.prior_mst = mst;
  if (the_arm.dt > 30) {   // Check that dt (delta time) is in reasonable range
    the_arm.dt = 30;
  } else if (the_arm.dt < 2) {
    the_arm.dt = 1;
  }
}

void loopUpdateWrist (arm & the_arm) { // Call this Function AFTER A B T JOINTS HAVE BEEN UPDATED
  // HAND MODES.  Solve for joints C and D
  static point ctemp = {0,-S_CG_Y,0};  // G CENTER (CAMERA) RELATIVE TO C, USED IN AIM
  point c1;    // USED IN AIM
  switch(the_arm.mode) {
    case HM_CD_LOC:
      updateJointBySpeed(the_arm.jC, the_arm.dt);  
      updateJointBySpeed(the_arm.jD, the_arm.dt);  
    break;
    case HM_CD_ABS:
      the_arm.jC.current_angle = getCang(the_arm.jA.current_angle,the_arm.jB.current_angle,the_arm.jC.target_angle);
      the_arm.jD.current_angle = the_arm.jT.current_angle + the_arm.jD.target_angle;   
    break;
    case HM_C_LOC_D_ABS:
      updateJointBySpeed(the_arm.jC, the_arm.dt);  
      the_arm.jD.current_angle = the_arm.jT.current_angle - the_arm.jD.target_angle;     
    break;
    case HM_C_ABS_D_LOC:
      the_arm.jC.current_angle = getCang(the_arm.jA.current_angle,the_arm.jB.current_angle,the_arm.jC.target_angle);
      updateJointBySpeed(the_arm.jD, the_arm.dt);  
    break;
    case HM_CD_AIM: // computes C and D from current and aim points and uses angles as absolute 
      if (the_arm.current_pt.z < LEN_AB) the_arm.jC.target_angle = - 90.0/RADIAN; 
      else the_arm.jC.target_angle = 90.0/RADIAN;
      //  c1 point represents the camera offset from the c point
      c1 = rot_pt_z(ctemp,the_arm.jT.current_angle-90.0/RADIAN);  // ROTATE CAMERA/G POINT BY THE ARM/TURNTABLE ANGLE
      the_arm.jD.target_angle = atan2(the_arm.aim_pt.y-the_arm.current_pt.y-c1.y,the_arm.aim_pt.x-the_arm.current_pt.x-c1.x);
      the_arm.jC.current_angle = getCang(the_arm.jA.current_angle,the_arm.jB.current_angle,the_arm.jC.target_angle);
      the_arm.jD.current_angle = the_arm.jT.current_angle - the_arm.jD.target_angle;     
    break;
    case HM_NONE:
    break;    
  }
}

void blink() { // Blink the built in LED to measure the HeartBeat (speed) of the Loop
  // loop speed between 7 to 15 ms. Increase to 40 counts per blink to make easier to count
  static int counterLEDblink = 0;
  if (counterLEDblink < 20) {
    digitalWrite(13,HIGH); // Turn the LED on
  } else if (counterLEDblink < 40) { 
    digitalWrite(13,LOW); // Turn the LED off
  } else {
    counterLEDblink = 0; // reset counter
  }
  counterLEDblink ++; 
}

void loop() {  //########### MAIN LOOP ############
  //static command cmd = {0,0,0,0,0};  // used in Serial Read
  //static boolean runningCmd = false; // toggle for serial read
  point angles;  // used by inverseArmKin
  point c_pt;

  stateLoop(make3);  // checks for state change

  loopTime(make3); // Capture cycle time
  
  switch (make3.state) {
    case S_AUTO_2: 
    case S_AUTO_5:
    case S_AUTO_6:
    case S_AUTO_7:
      readCommands(make3,seQ); // read a sequence of commands and act accordingly
      updateJointBySpeed(make3.jCLAW, make3.dt);  // update Claw joint
      break; 
    case S_TELEOP_1: 
    case S_TELEOP_3:
    case S_TELEOP_4: 
    case S_TELEOP_8:
    case S_TELEOP_9:
      make3.jA.pot_value = analogRead(make3.jA.pot.analog_pin);  // read joint A
      make3.jB.pot_value = analogRead(make3.jB.pot.analog_pin);  // read joint B
      //make3.jD.pot_value = analogRead(make3.jD.pot.analog_pin);  // read D wrist
      make3.jT.pot_value = analogRead(make3.jT.pot.analog_pin);  // read the turntable
      //make3.jCLAW.pot_value = analogRead(make3.jCLAW.pot.analog_pin);  // read joint Claw
    
      pot_map(make3.jA);      // get A angle
      pot_map(make3.jB);      // get B angle
      //pot_map(make3.jD);      // Wrist
      pot_map(make3.jT);      // Get Turntable angle
      //pot_map(make3.jCLAW);   // get Claw angle

      checkSwitch(clawSwitch);
      if (clawSwitch.isOn) make3.jCLAW.current_angle = 45.0/RADIAN;
      else make3.jCLAW.current_angle = -10.0/RADIAN;
      make3.jCLAW.target_angle = make3.jCLAW.current_angle; // for Claw, target should always equal current

      // Convert Input Arm angles to Robot Arm Point G (gripper)
      // UPDATE:  removed the Turntable Angle, (set it to always be zero)
      make3.target_pt = anglesToG(make3.jA.pot_angle , make3.jB.pot_angle, 0.0 , make3.jC.current_angle , make3.jD.current_angle , LEN_AB , LEN_BC , S_CG_X , S_CG_Y);

      // Move current point C toward target_pt at given feed rate (mm/sec)
      updateArmPtC(make3);   
      c_pt = pointGtoPointC(make3.current_pt,make3.jC.target_angle,make3.jD.target_angle,S_CG_X,S_CG_Y);
      
      // FIND JOINTS A B T from POINT C
      // UPDATE:  Make 2D version, without Turntable
      inverseArmKin2D(c_pt,LEN_AB,LEN_BC,angles);    
      make3.jA.current_angle = angles.x; //  A 
      make3.jB.current_angle = angles.y;  // local B

      // UPDATE: SET DIRECT TO POT ANGLE??? OR MAKE SMOOTH UPDATE METHOD
      make3.jT.current_angle = rateLimitMove(make3.jT.pot_angle , make3.jT.current_angle , 0.006); // angles.z;  //  T
      
      loopUpdateWrist(make3);  // HAND JOINT UPDATE 
      updateJointBySpeed(make3.jC, make3.dt);  
      updateJointBySpeed(make3.jD, make3.dt);  

      // HARD LIMIT to keeps the claw from contacting BC arm
      if (make3.current_pt.z > (LEN_AB) ) make3.jC.target_angle = (-90.0+ 45.0*(make3.current_pt.z-(LEN_AB))/(LEN_BC-40))/RADIAN; 
      else make3.jC.target_angle = -90.0/RADIAN;

      break;
    default:  // unspecified state should do nothing
      break;
  }

  // FLOOR HARD LIMITS
  if (make3.current_pt.z < (FLOOR+15) ) make3.current_pt.z = FLOOR+15;  // this keeps the arm from doing a pushup
  
  //  Serial Output for Initial Calibration.  One line for each servo.  Turn on one at a time:
  //logData(make3.jA,'A');  // Use logData for Initial Calibration of Potentiometer and Servo A
  //logData(make3.jB,'B');  // Use logData for Initial Calibration of Potentiometer and Servo B
  //logData(make3.jC,'C');  // Use logData for Initial Calibration of Servo C
  //logData(make3.jD,'D');  // Use logData for Initial Calibration of Servo D
  //logData(make3.jT,'T');  // Use logData for Initial Calibration of Potentiometer and Servo T

  // Serial Output  for debugging:
  //logPoint(make3);  // Use for debugging paths
  logGeneral();  // Use for general debugging

  blink();  // blinks the led on the arduino board

  // Convert the .current_angle(s) to PWM signal and send 
  pwm.writeMicroseconds(make3.jA.svo.digital_pin, servo_map(make3.jA)); // Adafruit servo library
  pwm.writeMicroseconds(make3.jB.svo.digital_pin, servo_map(make3.jB)); // Adafruit servo library
  pwm.writeMicroseconds(make3.jC.svo.digital_pin, servo_map(make3.jC)); // Adafruit servo library
  pwm.writeMicroseconds(make3.jD.svo.digital_pin, servo_map(make3.jD)); // Adafruit servo library
  pwm.writeMicroseconds(make3.jCLAW.svo.digital_pin, servo_map(make3.jCLAW)); // Adafruit servo library
  pwm.writeMicroseconds(make3.jT.svo.digital_pin, servo_map(make3.jT)); // Adafruit servo library
  //
} // END OF MAIN LOOP
