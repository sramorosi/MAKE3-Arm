# OpenSCAD code for MAKE3-Arm

This folder contains the OpenSCAD documents that define the MAKE3-Arm and Controllers.
 
Use these documents to create the .stl (STL or stereolithography or Standard Triangle Language) files for 3D printing. For more information on how to make .stl files see [making STL models from OpenSCAD](#making-stl-models-from-openscad)

Familiarity with OpenSCAD is required. Keep in mind that OpenSCAD is a Functional Programming Language, and as such one cannot redefine a variable once it has been set.

![MAKE3 Nomenclature](/Images/MAKE3_Nomenclature.jpg)

This is a photo of the MAKE3 arm, along with the names of some things.

The next sections provide the bill of materials for the MAKE3 arm and control devices, organized by the OpenSCAD documents. The documents are divided into assemblies, to keep the files from getting large. There are three main assembly documents (Claw_Assembly, Controllers, MAKE3_Assy) and a number of other "included" documents that are used to make these three main documents.

## MAKE3_Assy.scad (imports Claw_Assembly.scad)

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

This is a .gif animation created in OpenSCAD. [How to make gifs](https://github.com/sramorosi/MAKE3-Arm/tree/main/OpenSCAD-code#making-animation-gif-or-video-files-from-openscad)

The OpenSCAD design files are text files that contain the code for making the designs. The objective was to make the design variable-driven (the variables are mostly at the top of each file and should work with the "customizer"). Another objective was to calculate the torque on the A and B servos to find out if a design will work.  These torques are echoed to the console window, as shown, and will change as the variables are changed:

```
ECHO: LEN_AB = 350, LEN_BC = 380, LEN_CD = 160, PAYLOAD_MASS = 200
ECHO: BCweight = 259.774, ABweight = 336.371, " grams"
ECHO: "A SERVO MOTOR CAPABILITY=", AMotor_Max_Torque = 250000, " gram-mm"
ECHO: "A Big Gear teeth=", 70, " ASmall Gear teeth =", 32
ECHO: "A GEARED SERVO CAPABILITY=", AGeared_Max_Torque = 437500, " gram-mm"
ECHO: "A OUTPUT ANGLE=", 822.857, " DEG"
ECHO: "B SERVO MOTOR CAPABILITY=", Motor_Max_Torque = 250000, " gram-mm"
ECHO: "B Big Gear teeth=", 70, " Small Gear teeth =", 32
ECHO: "B GEARED SERVO CAPABILITY=", Geared_Max_Torque = 437500, " gram-mm"
ECHO: "C moment", " MARGIN OF SAFETY ", MS = 4.20833, max_load = 48000, pos = 4
ECHO: "B SERVO " MARGIN OF SAFETY ", MS = 0.687701, max_load = 259228, pos = 4
ECHO: "A SERVO - NO SPRING", " MARGIN OF SAFETY ", MS = -0.203117, max_load = 549014, pos = 4
ECHO: A_spr_torque_min = -170310, A_spr_torque_max = 218970
ECHO: "A SERVO - SPRING", " MARGIN OF SAFETY ", MS = 0.258321, max_load = 347685, pos = 9
ECHO: "A SERVO - SPRING - NO PAYLOAD", " MARGIN OF SAFETY ", MS = 1.45333, max_load = -178329, pos = 20
```

The maximum moments are attempted to be found by performing the calculations on a range of positions, using `function sweep1` Maximum/minimum values sometime show up at unusual positions. A **static** calculation is performed at each position.  No **dynamic** calculations are performed, and because of this one should have healthy static margins.

Another objective of the design was to make the 3D printed parts not require supports when printing, to speed up the printing.  

Here is the bill of materials:

### MAKE3_Assy - 3D printed

1. servo_mount (quantity 2), color blue
2. plain_guss (quantity 1), color DeepSkyBlue
3. B_gear_guss (quantity 1), color aqua
4. A_gear_lollypop (quantity 1), gear_side=true, color olive
5. A_gear_lollypop (quantity 1), gear_side=false, color olive
6. turntable_gear (quantity 1), color tomato
7. Electronics_Board (quantity 1), color palegreen

### MAKE3_Assy - Purchased Hardware or other

1. Claw Assembly - See Claw_Assembly.scad
2. Tube for AB arm: 1" square x 0.065" thick Aluminum tube, 6061, Length = CAD length plus 1"
3. Tube for BC arm: 1" square x 0.065" thick Aluminum tube, 6061, Length = CAD length plus 1"
4. Joint A:
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Gear, 32 tooth, ServoCity
    4. Screws to attach servo to block
    5. Bearings for main shaft
    6. Axel
    7. Spring for joint A
5. Joint B:
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Gear, 32 tooth, ServoCity
    4. Screws to attach servo to block
    5. Bearings for main shaft
    6. Axel
6. Joint C:
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Hub, ServoCity
    4. Screws to attach servo to block
6. Joint B:
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Block, ServoCity
12. 2 by 4 wood for base

### MAKE3_Assy - Electronics

1. Battery - 7.4V Lipo 
2. Arduino Leonardo
3. Adafruit Servo board
4. Switch 

## Claw_Assembly.scad

![Claw_Assy_FlyAround](/Images/Claw_Assy_FlyAround.gif)

This is the claw that attaches to the end of the robot arm. It is designed to be able to pick up items that are roughly 5 to 8 cm in size. The blue curved links are designed to lower the servo torque when the claw is closed. The navy guides are designed to be clipped onto the claw_bars primarily so that 3D printing is faster.

### Claw Parts - 3D printed 

1. curved_link (quantity 2), color blue, supports required. Sometimes called "rod"
2. guide (quantity 2), color navy
3. claw_bar (quantity 2), color SkyBlue
4. base (quantity 1), color DodgerBlue

### Claw Parts - Purchased Parts

1. Servo (quantity 1), At least 180 degree, at least 25 kg-cm, model ANNIMOS DS3225MG, includes horn,horn screws, horn screw bushings
2. pins (quantity 4), Spring Steel Slotted Spring Pin, 5/64" Diameter, source McMaster Carr, part number yyyyy
3. screws (quantity 4), attach servo to base
4. foam window seal 

## Controllers.scad   (Input Arm Assembly controller shown)

![Controller_Arm](/Images/InputArm_FlyAround.gif)

### Input Arm Controller Parts - 3D printed 

1. PotLug (quantity 2), color blue
2. NonPotLug (quantity 2), color green
3. PotCover (quantity 2), color cyan
4. BasePotCover (quantity 1), color SlateBlue
5. AB_Arm (quantity 1), color plum
6. BC_Arm (quantity 1), color purple
7. BC_Arm_Cap (quantity 1), color lightblue
8. TA_Fitting (quantity 1), color lime

### Input Arm Controller Parts - Purchased Parts

1. Potentiometer (quantity 3)
2. Switch (quantity 1)

## Controllers.scad   (Selector Assembly controller shown)

![Controller-Selector](/Images/Controller-Selector.gif)

### Selector Parts - 3D printed 

1. PotLug (quantity 1), color blue
2. NonPotLugTooth (quantity 1), color lightgreen
3. bumpyBaseCover (quantity 1), color plum
4. SelectorKnot (quantity 1), color DeepPink

### Selector Parts - Purchased Parts

1. Potentiometer (quantity 1)



### Making STL models from OpenSCAD

To make STL models for 3D printing follow these steps for each part to print. The OpenSCAD **Customizer** is handy for changing variables prior to exporting.
1. toggle off the Assembly.  Do not print Assemblies.
```OpenSCAD
DISPLAY_ASSY = true;  // set this to false when exporting STL files
```
1. Find the line in the code that draws the part. Remove * (disable) suffix on the line.  Note:  These lines have // EXPORT AS STL at the end of the line.  You are toggling on and off the parts that you want to print using the 
```
*servo_mount(); // EXPORT AS STL, quantity 2.  remove the * for export
```
2. Adjust parameter setting for printing, for example, set FACETS = 140
```OpenSCAD
// use 140 for printing, 40 for display
FACETS = 100; // [40,140]
```
3. Render the part **(F6)** Note: Rendering can take much longer than Preview (F5).  Look for the progress bar on the lower right.
4. Export the rendered part as STL **(F7)**
5. Load the STL into your favorite slicer.  Note: Occasionally you may need to perform some STL cleanup, using your favorite tool.  I use the 3D Builder tool on Windows, when I detect something not working right in the slicer.

### Making Animation (.gif or video) files from OpenSCAD

Familiarity with the Animation function in OpenSCAD is required.

![MAKE3 Animation Example](/Images/OpenSCAD_Animation.jpg)

While animation is running in OpenSCAD, check the "Dump Pictures" box below the console window.  One picture will be created for each frame and saved in the same folder as your OpenSCAD document.

Use the free tool at EZGIF.COM [here](https://ezgif.com/maker) to make a gif or video.
