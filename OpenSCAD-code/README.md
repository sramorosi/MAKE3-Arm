# OpenSCAD Code for MAKE3-Arm
This folder contains the OpenSCAD documents that define the MAKE3-Arm
 
Use these documents to create the .stl files for 3d printing.

Familiarity with OpenSCAD is required.

To make STL models for 3D printing follow these steps for each part to print:
1. Find the line in the code that draws the part. Remove * (disable) suffix on the line.  Note:  These lines have // FOR PRINT at the end of the line.  You are toggling on and off the parts that you want to print using the *.  You will need to toggle off the Assembly.  Do not print Assemblies.
2. Adjust parameter setting for printing, for example, set FACETS = 140, set display_assy = false.  The OpenSCAD Customizer is handy for this.
3. Render the part (F6) Note: Rendering can take much longer than Preview (F5).  Look for the progress bar on the lower right.
4. Export the rendered part as STL (F7)
5. Load the STL into your favorite slicer.  Note: you may need to perform some STL cleanup, using your favorite tool.  I use the 3D Builder tool on Windows.

Bill of Material (i.e. what to print)... Include in the OpenSCAD document.