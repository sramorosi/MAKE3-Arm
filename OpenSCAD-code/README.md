# OpenSCAD code for MAKE3-Arm
This folder contains the OpenSCAD documents that define the MAKE3-Arm and Input Arm
 
Use these documents to create the .stl (STL or stereolithography or Standard Triangle Language) files for 3d printing. For more information on how this is done see [making STL models from OpenSCAD](0001)

Familiarity with OpenSCAD is required.

The documents are divided into assemblies, to keep the files from getting large. There are three main assembly documents, shown below, and a number of other documents that are used to make these three main documents  

## Claw_Assembly.scad

![Claw_Assy_FlyAround](/Images/Claw_Assy_FlyAround.gif)

## Controllers.scad   (Input Arm Assembly controller shown)

![Input Arm_Assy_FlyAround](/Images/InputArm_FlyAround.gif)

## InputArm_Make3.scad   (Selector Assembly controller *** to be shown)

## MAKE3_Assy.scad (imports Claw_Assembly.scad)

![MAKE3-Arm-gif](/Images/MAKE3_Arm_FlyAround.gif)

### Making STL models from OpenSCAD {0001}

To make STL models for 3D printing follow these steps for each part to print:
1. Find the line in the code that draws the part. Remove * (disable) suffix on the line.  Note:  These lines have // FOR PRINT at the end of the line.  You are toggling on and off the parts that you want to print using the *.  You will need to toggle off the Assembly.  Do not print Assemblies.
2. Adjust parameter setting for printing, for example, set FACETS = 140, set display_assy = false.  The OpenSCAD Customizer is handy for this.
3. Render the part (F6) Note: Rendering can take much longer than Preview (F5).  Look for the progress bar on the lower right.
4. Export the rendered part as STL (F7)
5. Load the STL into your favorite slicer.  Note: you may need to perform some STL cleanup, using your favorite tool.  I use the 3D Builder tool on Windows.

Bill of Material (i.e. what to print)... Include in the OpenSCAD document.
