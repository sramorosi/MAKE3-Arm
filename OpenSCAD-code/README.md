# OpenSCAD code for MAKE3-Arm
This folder contains the OpenSCAD documents that define the MAKE3-Arm and Controllers.
 
Use these documents to create the .stl (STL or stereolithography or Standard Triangle Language) files for 3D printing. 

For more information on how to make .stl files see [making STL models from OpenSCAD](#making-stl-models-from-openscad)

Familiarity with OpenSCAD is required.

The documents are divided into assemblies, to keep the files from getting large. There are three main assembly documents, shown below, and a number of other documents that are used to make these three main documents  

## Claw_Assembly.scad

![Claw_Assy_FlyAround](/Images/Claw_Assy_FlyAround.gif)

### Claw 3D printed parts

1. rod (quantity 2), color "Blue", supports required
2. quide (quantity 2), color "Navy"
3. claw_bar (quantity 2), color "SkyBlue"
4. base (quantity 1), color "DodgerBlue"

### Claw Other Parts

1. Servo (quantity 1), model xxx, includes horn,horn screws, horn screw bushings
2. pins (quantity 4), Spring Steel Slotted Spring Pin, 5/64" Diameter, source McMaster Carr, part number yyyyy
3. screws (quantity 4), attach servo to base
4. foam window seal 

## Controllers.scad   (Input Arm Assembly controller shown)

![Controller_Arm](/Images/InputArm_FlyAround.gif)

### Arm Controller 3D printed parts

1. 
2. 

## InputArm_Make3.scad   (Selector Assembly controller shown)

![Controller-Selector](/Images/Controller-Selector.png)

## MAKE3_Assy.scad (imports Claw_Assembly.scad)

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

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
