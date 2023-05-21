# OpenSCAD code for MAKE3-Arm
This folder contains the OpenSCAD documents that define the MAKE3-Arm and Controllers.
 
Use these documents to create the .stl (STL or stereolithography or Standard Triangle Language) files for 3D printing. 

For more information on how to make .stl files see [making STL models from OpenSCAD](#making-stl-models-from-openscad)

Familiarity with OpenSCAD is required.

The documents are divided into assemblies, to keep the files from getting large. There are three main assembly documents, shown below, and a number of other documents that are used to make these three main documents  

## Claw_Assembly.scad

![Claw_Assy_FlyAround](/Images/Claw_Assy_FlyAround.gif)

### Claw Parts - 3D printed 

1. rod (quantity 2), color blue, supports required
2. quide (quantity 2), color navy
3. claw_bar (quantity 2), color SkyBlue
4. base (quantity 1), color DodgerBlue

### Claw Parts - Other 

1. Servo (quantity 1), model xxx, includes horn,horn screws, horn screw bushings
2. pins (quantity 4), Spring Steel Slotted Spring Pin, 5/64" Diameter, source McMaster Carr, part number yyyyy
3. screws (quantity 4), attach servo to base
4. foam window seal 

## Controllers.scad   (Input Arm Assembly controller shown)

![Controller_Arm](/Images/InputArm_FlyAround.gif)

### Arm Controller Parts - 3D printed 

1. PotLug (quantity 2), color blue
2. NonPotLug (quantity 2), color green
3. PotCover (quantity 2), color cyan
4. BasePotCover (quantity 1), color SlateBlue
5. AB_Arm (quantity 1), color plum
6. BC_Arm (quantity 1), color purple
7. BC_Arm_Cap (quantity 1), color lightblue
8. TA_Fitting (quantity 1), color lime

### Arm Controller Parts - Other

1. Potentiometer (quantity 3)
2. Switch (quantity 1)

## Controllers.scad   (Selector Assembly controller shown)

![Controller-Selector](/Images/Controller-Selector.png)

### Selector Parts - 3D printed 

1. PotLug (quantity 1), color blue
2. NonPotLug (quantity 1), color green
3. bumpyBaseCover (quantity 1), color plum
4. SelectorKnot (quantity 1), color DeepPink

### Arm Controller Parts - Other

1. Potentiometer (quantity 1)

## MAKE3_Assy.scad (imports Claw_Assembly.scad)

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

### MAKE3_Assy - 3D printed

1. servo_mount (quantity 2), color blue
2. plain_guss (quantity 1), color DeepSkyBlue
3. B_gear_guss (quantity 1), color aqua
4. A_gear_lollypop (quantity 1), gear_side=true, color olive
5. A_gear_lollypop (quantity 1), gear_side=false, color olive
6. turntable_gear (quantity 1), color tomato
7. Electronics_Board (quantity 1), color palegreen

### MAKE3_Assy - Other

1. Claw Assebly from Claw_Assembly.scad
2. Tubes for AB and BC arm
3. Servos
4. Servo gears
5. Screws
6. Bearings
7. Axels
8. Arduino Leonardo
9. Adafruit Servo board
10. Spring for joint A
11. Servo block for joint C and D
12. 2 by 4 wood for base

### Making STL models from OpenSCAD

To make STL models for 3D printing follow these steps for each part to print:
1. Find the line in the code that draws the part. Remove * (disable) suffix on the line.  Note:  These lines have // FOR PRINT at the end of the line.  You are toggling on and off the parts that you want to print using the *.  You will need to toggle off the Assembly.  Do not print Assemblies.
2. Adjust parameter setting for printing, for example, set FACETS = 140, set display_assy = false.  The OpenSCAD Customizer is handy for this.
3. Render the part (F6) Note: Rendering can take much longer than Preview (F5).  Look for the progress bar on the lower right.
4. Export the rendered part as STL (F7)
5. Load the STL into your favorite slicer.  Note: you may need to perform some STL cleanup, using your favorite tool.  I use the 3D Builder tool on Windows.

### Making Animation (.gif or video) files from OpenSCAD

Familiarity with the Animation function in OpenSCAD is required.

While animation is running in OpenSCAD, check the "Dump Pictures" box below the consol window.  One picture will be created for each frame and saved in the same folder as your OpenSCAD document.

Use the free tool at EZGIF.COM [here](https://ezgif.com/maker) to make a gif or video.
