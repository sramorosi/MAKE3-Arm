# OpenSCAD code for MAKE3-Arm

This folder contains the OpenSCAD documents that define the MAKE3-Arm and Controllers.

Familiarity with OpenSCAD is required, to make the files for printing and to interogate the design.
 
The OpenSCAD design files are text files that contain the code for the designs.  Use these files to export the .stl files (STL or STereoLithography or Standard Triangle Language) for 3D printing. For more information on how to make .stl files see [making STL models from OpenSCAD](#making-stl-models-from-openscad)

The objective with MAKE3 was to make the design variable-driven (the variables are mostly at the top of each file and should work with the OpenSCAD **Customizer**).

Another objective was to perform some Engineering calculations on the design, using the variables, so one can quickly see if a design will work.

Another objective was to make the 3D printed parts not require supports when printing, to speed up the printing and make accurate parts (small, accurate, fast to print).

Note: OpenSCAD is a Functional Programming Language, and as such one cannot redefine a variable once it has been set.  Most of the code is "simple" programming but for computations involving arrays it becomes more complex.

![MAKE3 Nomenclature](/Images/MAKE3_Nomenclature.jpg)

Labeled photo of the MAKE3 arm.

The next sections provide the **Bill of Materials** for the MAKE3 arm and control devices, organized by the OpenSCAD files. The files are divided into major assemblies, to keep the files from getting large. There are three major assembly documents (Claw_Assembly, Controllers, and the MAKE3_Assy) and a number of other "included" files that are used to make these three main documents ("use" is another type of included file in OpenSCAD).   Within the files, there are `modules` or `functions` that break up the code into sub-assemblies, details and other functions.

## MAKE3_Assy.scad (imports Claw_Assembly.scad)

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

GIF animation of the MAKE3 Robot Arm created in OpenSCAD. 
[See how to make gifs here](https://github.com/sramorosi/MAKE3-Arm/tree/main/OpenSCAD-code#making-animation-gif-or-video-files-from-openscad)

The Engineering calculations performed in the MAKE3_Assy file are to find the largest torque on the A, B and C servos.  From these torques a Margin of Safety (MS)calculation is performed to find out if the selected design (servo, gearing, link lengths, etc)will work (that is have a positive MS).  These torques are echoed to the console window, as shown below, and will change as the variables are changed:

```
ECHO: LEN_AB = 350, LEN_BC = 380, LEN_CD = 160, PAYLOAD_MASS = 200
ECHO: BCweight = 259.774, ABweight = 336.371, " grams"
ECHO: "B SERVO MOTOR CAPABILITY=", 250000, " gram-mm"
ECHO: "B Big Gear teeth=", 70, " B_Small Gear teeth =", 32
ECHO: "B GEARED SERVO CAPABILITY=", BGeared_Max_Torque = 546875, " gram-mm"
ECHO: "A SERVO MOTOR CAPABILITY=", 250000, " gram-mm"
ECHO: "A Big Gear teeth=", 80, " ASmall Gear teeth =", 32
ECHO: "A GEARED SERVO CAPABILITY=", AGeared_Max_Torque = 625000, " gram-mm"
ECHO: "A OUTPUT ANGLE=", 144, " DEG"
ECHO: "Turtable Big Gear teeth=", 80, " Turntable Small Gear teeth =", 32
ECHO: "TURNTABLE OUTPUT ANGLE=", 144, " DEG"
ECHO: "C SERVO", " MARGIN OF SAFETY ", MS = 4.20833, max_load = 48000, pos = 4
ECHO: "B SERVO", " MARGIN OF SAFETY ", MS = 1.10963, max_load = 259228, pos = 4
ECHO: "A SERVO - NO SPRING", " MARGIN OF SAFETY ", MS = 0.138404, max_load = 549014, pos = 4
ECHO: A_spr_torque_min = -170310, A_spr_torque_max = 218970
ECHO: "A SERVO - SPRING", " MARGIN OF SAFETY ", MS = 0.797602, max_load = 347685, pos = 9
ECHO: "A SERVO - SPRING - NO PAYLOAD", " MARGIN OF SAFETY ", MS = 2.50475, max_load = -178329, pos = 20
```

The largest moments are attempted to be found by performing the calculations on a range of positions, using `function sweep1`. The largest moment values sometime show up at unusual positions. A **static** calculation is performed at each position.  No **dynamic** calculations are performed, and because of this one should have healthy static margins.

This design has a **torsion spring** located at joint A, which helps reduce the torque on the A servo.  Above, the fourth line from the bottom shows the margin without a spring (MS = 0.13...) a small or negative MS is BAD.  With a spring MS = 0.79...  I have found with a MS less than 0.5 that the servos tend to heat up quickly, damaging the servos (I have killed many servos along the way).

Here is the **Bill of Materials**:

### MAKE3_Assy - 3D printed

1. servo_mount (quantity 3), color blue
1. plain_guss (quantity 1), color DeepSkyBlue
1. B_gear_guss (quantity 1), color aqua
1. A_gear_lollypop (quantity 1), gear_side=true, color olive
1. A_gear_lollypop (quantity 1), gear_side=false, color olive
1. turntable_gear (quantity 1), color tomato
1. Electronics_Board (quantity 1), color palegreen

### MAKE3_Assy - Purchased Hardware or other

1. Claw Assembly - See Claw_Assembly.scad
1. Tube for AB arm: 1" square x 0.065" thick Aluminum tube, 6061. This tube is stiff torsionally and the wires can run inside of it.
1. Tube for BC arm: 1" square x 0.065" thick Aluminum tube, 6061. 
1. Joint A:
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Gear, 32P, 32 Tooth, 25T 3F Spline Servo Mount Gear, from ServoCity
    4. Screws to attach servo to block, Phillips Rounded Head Thread-Forming Screws
for Plastic, 18-8 Stainless Steel, Number 4 Size, 1/2" Long
    5. Bearings for main shaft
    6. Axel, 1/4 inch bolt, or for better precision Rotary Shaft, 303 Stainless Steel, 1/4" Diameter, part no. 1257K115 from McMaster Carr
    1. Set Screw Shaft Collar for 1/4" Diameter (quantity 2), part no. 9414T6 from McMaster Carr 	
    7. Torsion Spring, 90 Degree Left-Hand Wound, 0.848" OD, 0.105" Wire Diameter,	, part no. 9271K589 from McMaster Carr
1. Joint B, same as Joint A, except no spring.
1. Joint C:
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Hub, ServoCity
    4. Screws to attach servo to block
1. Joint D:
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Block, ServoCity
1. Joint T (for turntable):
    1. Servo, 360 degree, 35 kg-cm torque, FeeTech FT6335M-360
    2. Servo Gear, 32 tooth, ServoCity
    4. Screws to attach servo to block
    5. Bearings for main shaft
    6. Main Shaft, 1/2" hex bar
1. 2 by 4 wood for base

### MAKE3_Assy - Electronics

Here is the bill of material for the electronics (minus the servos and potentiometers, which are listed with the mechanical assemblies):

1. The microprocessor is an Arduino Leonardo (Note: an Arduino Uno does not work correctly with the Adafruit Servo Shield)
1. Adafruit Servo Shield
1. Wires from controller to Arduino/Shield. The positive and ground wires can be common for all potentiometers). I have sacrificed CAT-5 Ethernet cable, which have four twisted pairs, or eight wires, so one can wire up to six potentiometers/switches along with the positive and ground wires. All 8 wires have unique colors, which makes it easy to keep track of the wires.
1. Battery - 7.4V Lipo 
1. Switch 
1. Misc. connectors for the battery and switch

## Claw_Assembly.scad

![Claw_Assy_FlyAround](/Images/Claw_Assy_FlyAround.gif)

This is the claw that attaches to the end of the robot arm. It is designed to be able to pick up items that are roughly 5 to 8 cm in size. The blue curved links are designed to lower the servo torque when the claw is closed, so the servo does not overheat when holding an object. The navy guides are designed to be clipped onto the claw_bars primarily so that 3D printing is faster.

### Claw Parts - 3D printed 

1. curved_link (quantity 2), color blue, supports required. Sometimes called "rod"
2. guide (quantity 2), color navy
3. claw_bar (quantity 2), color SkyBlue
4. base (quantity 1), color DodgerBlue

### Claw Parts - Purchased Parts

1. Servo (quantity 1), At least 180 degree, at least 25 kg-cm, model ANNIMOS DS3225MG, includes horn,horn screws, horn screw bushings
2. pins (quantity 4), Spring Steel Slotted Spring Pin, 5/64" Diameter, source McMaster Carr, part number yyyyy
3. screws (quantity 4), attach servo to base
4. foam window seal, to put on inside of guide for grip

## Controllers.scad   (Input Arm Assembly controller shown)

![Controller_Arm](/Images/InputArm_FlyAround.gif)

This is the *baby* robot arm used to control the big arm. The main design objective was to make the parts 3D printable without supports (for accuracy) so that when assembled the joints have just enough friction so that they move easily but the baby arm will also hold position when it is released.  This design accomplished that!

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

To make STL models for 3D printing follow these steps for each part that you want to print. The OpenSCAD **Customizer** is handy for changing variables prior to exporting.
1. toggle off the Assembly.  Do not print Assemblies.
```OpenSCAD
DISPLAY_ASSY = true;  // set this to false when exporting STL files
```
2. Adjust variables for printing, for example, set FACETS = 140. More facets makes the parts smoother, but takes longer to display.
```OpenSCAD
// use 140 for printing, 40 for display
FACETS = 100; // [40,140]
```
3. Toggle on and off the parts that you want to print by finding the line in the code that draws the part. Remove * (disable) suffix on the line.  Note:  These lines have // EXPORT AS STL at the end of the line.
```
*servo_mount(); // EXPORT AS STL, quantity 2.  remove the * for export
```
4. Render the part **(F6)** Note: Rendering can take much longer than Preview (F5), as in minutes.  Look for a progress bar on the lower right.
5. Export the rendered part as an STL file **(F7)**
6. Load the STL file into your favorite slicer.  Note: Occasionally you may need to perform some STL cleanup, using your favorite tool.  I use the 3D Builder tool on Windows, when I detect something not working right in the slicer.

### Making Animation (.gif or video) files from OpenSCAD

The Animation function **Animate** in OpenSCAD can be toggled on under the **View** menu.

![MAKE3 Animation Example](/Images/OpenSCAD_Animation.jpg)

While **Animate** is running, enter numbers for FPS and Steps, and check the "Dump Pictures" box juat above the console window.  One picture will be created for each frame and saved in the same folder as your OpenSCAD document.

Use the free tool at EZGIF.COM [here](https://ezgif.com/maker) to make a gif or video.  Upload all of the dumped pictures and follow the steps for making a gif.
