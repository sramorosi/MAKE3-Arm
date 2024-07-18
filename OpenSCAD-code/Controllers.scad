// Input Control Arm Assembly and Selector Control assembly
//  Design for Human Hand to control a Robot Arm
//  last modified May 2023 by SrAmo
// The parts are designed to not require support material when 3D printing.
//
//  To make STL models for 3D printing follow these steps:
//  find "Export as STL" and remove the * (disable) suffix, 
//     then render the part (F6) (this may take some time)
//        then  Export as STL (F7)
use <ME_lib.scad> // contains forces, springs, MS modules and functions
include <Part-Constants.scad>
use <Robot_Arm_Parts_lib.scad>

/* Animation Commands to create an orbital fly-around:
$vpr = [60, 0, -30];   // view point rotation (spins the part)
$vpt = [-50,0,70];    // view point translation
$vpf = 50;          // view point field of view
$vpd = 150;         // view point distance
*/

// Parameters for Customizer:
// Joint A angle
//AA = 25; // [0:180.0]
AA = 100; //-90*sin($t*180);  // for animation
// Joint B angle
//BB = -35; // [-170:1:0.0]
BB = -50; //90*sin($t*180);  // for animation
// Turntable angle
//TT = 0; // [-90:90]
TT = 60*sin($t*90);  // for animation
// use 140 for printing, 40 for display
FACETS = 100; // [40,140]

// Draw the Input Arm Assembly?
display_assy = true;
// Draw the Selector?
display_selector = false;
// Section cut Assy at X = 0?
clip_yz = false;
// Section cut Assy at Z = 0?
clip_xy = false;

// length of full size A-B arm (mm)
LEN_AB_LARGE=350; 
// length of full size B-C arm (mm)
LEN_BC_LARGE=380; 

// For the Big Arm to move the same as the Small Arm
//  the link lengths should be of consistent scale.
SCALE = 0.15;  // scale of small to big arm

// length of A-B arm, color = plum
lenAB=SCALE*LEN_AB_LARGE;     // mm
// length of B-C arm, color = blue
lenBC=SCALE*LEN_BC_LARGE;      // mm
echo("Baby Arm lengths",SCALE=SCALE,lenAB=lenAB,lenBC=lenBC," mm");

// A joint shift Z (up), mm
A_joint_Z = 34; 
// A joint shift X (lateral), mm
A_joint_X = -9;

// Lug Diameter, mm, used by many
LUG_DIA = 22; 
// distance to the flat side from the bore
FLAT_DIST = 16;
// Main Lug Thickness, mm
MAIN_LUG_THK = 6;
OUTER_LUG_THK = 4;
POT_LUG_THK = 8;
// LUG_Z is the offset for pot removal
LUG_Z = 2;

// Slip fit hole for potentiometer shaft
POT_HOLE_DIA = 6.3; // mm
// McMaster Carr Screw No. 90380A274  to hold lugs together (quantity about 10)
SCREW_DIA = 3.3; // mm, For no. 4 plastic screw, length 0.75 inch

zbody = 5.5;  // Offset for potentiometer body, all units are mm

module screwHoles(dia=15,shrink=false) { // pair of screw holes that hold the stack together
    cylDia = shrink ? SCREW_DIA*0.76 : SCREW_DIA;
    translate([dia/2.8,-dia/2-1,0]) 
        cylinder(h=4*dia,d=cylDia,center=true,$fn=FACETS);
    translate([-dia/2.8,-dia/2-1,0]) 
        cylinder(h=4*dia,d=cylDia,center=true,$fn=FACETS);
}
*rotate([0,0,180]) screwHoles(dia=LUG_DIA);

module ScrewsInHoles(lug_dia=15,screw_dia=4,screw_len=10) { // pair of screws
    // Rounded Head Thread-Forming Screws for Plastic
    translate([lug_dia/2.8,-lug_dia/2-1,0])  Screw(length=screw_len,dia=screw_dia);
    translate([-lug_dia/2.8,-lug_dia/2-1,0]) Screw(length=screw_len,dia=screw_dia);
}

// Full round top, width = dia
module roundTopLug (dia=15,hgt=20,thk=5,bore=3,cyl=false) {  
    difference() {
            hull() {
                translate([0,0,thk/2]) cylinder(h=thk,d=dia,center=true);
                translate([0,-hgt*3/4,thk/2]) cube([dia,hgt/2,thk],center=true);
            }
        cylinder(h=4*thk,d=bore,center=true);  // remove bore
            
        if(cyl) {    
            translate([dia/1.9,-dia/3.1,0]) 
                cylinder(h=hgt*2,d=dia/3.2,center=true,$fn=FACETS);
            translate([-dia/1.9,-dia/3.1,0]) 
                cylinder(h=hgt*2,d=dia/3.2,center=true,$fn=FACETS);
        }
            
    }
}
*roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=OUTER_LUG_THK,bore=3,$fn=FACETS);  // note result if hgt < dia/2
*roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=OUTER_LUG_THK,bore=3,cyl=false,$fn=FACETS);

module roundTopLugTwo (width=20,rad=2,hgt=8,thk=5,bore=3) { // Two radius round top
    cylWidth = width/2 - rad;
    difference() {
        translate([0,0,thk/2])
            hull() {
                translate([cylWidth,0,0]) cylinder(h=thk,r=rad,center=true);
                translate([-cylWidth,0,0]) cylinder(h=thk,r=rad,center=true);
                translate([0,-hgt/2,0]) cube([width,hgt,thk],center=true);
            }
        cylinder(h=4*thk,d=bore,center=true);  // remove bore
    }
}
*roundTopLugTwo(bore=0,$fn=FACETS);  // note result if hgt < dia/2

module PotLug(dia=LUG_DIA) {  // Model of Potentiometer holder
    color("blue") difference () {// Side that holds the POT
        roundTopLug(dia=dia,hgt=FLAT_DIST,thk=POT_LUG_THK,bore=POT_HOLE_DIA,$fn=FACETS);

        translate([0,0,zbody]) P090L_pot(negative=true);// remove potentiometer interface

        screwHoles(dia=LUG_DIA);  // remove screw holes
        }
}
*rotate([0,180,0]) PotLug(); // Export as STL... F7 (quantity 2)

module NonPotLug(thk=OUTER_LUG_THK) {  // Model of Potentiometer holder
    color("green") difference() {
            union() {
            translate([0,0,MAIN_LUG_THK]) 
                roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=thk,bore=POT_HOLE_DIA,$fn=FACETS);
            translate([-LUG_DIA/2,-FLAT_DIST,0]) 
                cube([LUG_DIA,8.5,MAIN_LUG_THK],center=false);
        }
        // remove screw holes
        screwHoles(dia=LUG_DIA,shrink=true);
        
        // remove lug arc from cube
        translate([0,0,-.2]) 
            cylinder(h=MAIN_LUG_THK+.4,d=LUG_DIA*1.03,center=false,$fn=FACETS);
        
        // remove spring wave washer dish
        cylinder(h=MAIN_LUG_THK+.6,d=9.1,center=false,$fn=FACETS);
        
        // remove corner for BC arm motion
        translate([LUG_DIA/2,-LUG_DIA/2,-.2]) rotate([0,0,45])
            cube([6,6,MAIN_LUG_THK+.4],center=false);
    }
}
*rotate([0,180,0]) NonPotLug(); // Export as STL... F7 (quantity 2)

module PotCover() {
    color("cyan") 
    difference () {// Side that holds the POT
        rotate([0,180,0]) 
            translate([0,0,-OUTER_LUG_THK]) 
                roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=OUTER_LUG_THK,bore=3,cyl=false,$fn=FACETS);
        // Above was cyl=true and trans and rot not required
        // remove potentiometer interface
        translate([0,0,OUTER_LUG_THK+zbody]) P090L_pot(negative=false);
        screwHoles(dia=LUG_DIA);  // remove screw holes
        translate([0,-FLAT_DIST+2,0]) cube([LUG_DIA/2.6,10,10],center=true);
    }
}
*PotCover(); // Export as STL... F7 (quantity 2)

module PotCoverAssy() {
    PotCover();
    ScrewsInHoles(lug_dia=LUG_DIA,screw_dia=4,screw_len=19);
}
*PotCoverAssy();


module joint_visuals(cut=true) { // Use for cross section cuts of Joints
    difference() { 
        union() {
            PotLug(); 
            translate([0,0,zbody]) P090L_pot(negative=false); 
            translate([0,0,POT_LUG_THK]) NonPotLug(); // OR SELECTOR BASE
            translate([0,0,-OUTER_LUG_THK]) PotCoverAssy();
            rotate([0,0,90]) 
                translate([0,0,MAIN_LUG_THK+.2]) 
                    scale([.95,.95,.95]) 
                        AB_Arm(len = lenAB);
       }
       if (cut) translate([-20,0,0]) cube([40,80,40],center=true);  // Section Cut cube
    }
}
*joint_visuals(cut=true); // not for print

module zip_holes() {
    translate([0,3.5,0]) cylinder(h=20,d=2.5,center=true,$fn=36);
    translate([0,-3.5,0]) cylinder(h=20,d=2.5,center=true,$fn=36);
}

module AB_Arm(len=100) {
    color("plum",1) difference () {
        union() {
            translate([0,0,8]) 
                rotate([180,0,-90]) 
                difference() {
                    roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=MAIN_LUG_THK, bore=3, cyl=true,$fn=FACETS);
                // remove potentiometer interface
                translate([0,0,-LUG_Z]) scale([1.02,1.02,1.02]) rotate([0,0,180]) 
                    P090L_pot(negative=true);
            }
            
            translate([len,0,-0]) 
                rotate([0,0,-90]) PotLug(); // lug at other end
            
            // The connecting cube:
            difference() { // REMOVE CYL SO THAT 0,0 LUG JOINT UNIONS PROPERLY
                translate([LUG_DIA/1.8,-LUG_DIA/2,LUG_Z]) 
                    cube([len-LUG_DIA/.8,LUG_DIA,MAIN_LUG_THK],center=false);
                cylinder(h=40,d=8,center=true,$fn=FACETS); // for the pot
                translate([len/2.6,0,0]) zip_holes();
           }
        }
    }
}
*rotate([180,0,0]) AB_Arm(len = lenAB); // Export as STL... F7 (quantity 1)

module AB_Arm_Assy(len=100){
    AB_Arm(len=len); 
    translate([len,0,0])  rotate([0,0,-90]) {
        translate([0,0,-OUTER_LUG_THK])PotCoverAssy();
        translate([0,0,POT_LUG_THK]) NonPotLug();
    }
    translate([lenAB,0,5]) rotate([0,0,-90]) P090L_pot(negative=false);
}
*AB_Arm_Assy(len=lenAB); 

module switch(negative = false) {  //12x12x5mm Mini/Micro/Small PCB Momentary Tactile Tact Push Button Switch
    if (!negative) color("grey") {
        translate([0,0,1.5]) cube([11.5,11.5,3],center=true);
        translate([0,0,4]) cylinder(h=8,d=7,center=true);
        translate([6,2.5,-2]) cube([1,1,5],center=true);
        translate([6,-2.5,-2]) cube([1,1,5],center=true);
        translate([-6,2.5,-2]) cube([1,1,5],center=true);
        translate([-6,-2.5,-2]) cube([1,1,5],center=true);
    } else {
        translate([0,0,1.5]) cube([12,12,4],center=true);
        translate([0,0,10]) cylinder(h=20,d=8.5,center=true);
        translate([6,0,-5]) cube([2,8,12],center=true);
        translate([-6,0,-5]) cube([2,8,12],center=true);
    }
}
*switch(true,$fn=FACETS);

module BC_Arm(len=100) {
    // BC arm is designed so that it can not hyperextend (i.e. A-B-C can be inline, but not more)
    angSin = asin(0.3*LUG_DIA/len);
    //upSizeElbow = 2;
    BEND_ANG = 30; // DEG
    LEN1_RATIO = 0.2;
    len1 = len*LEN1_RATIO;
    ang1 = asin(LEN1_RATIO*sin(180-BEND_ANG));
    ang2 = 180-(180-BEND_ANG)-ang1;
    len2 = sqrt(len*len + len1*len1-2*len*len1*cos(ang2));
    //echo(ang2=ang2,len2=len2);
    color("purple",1) {
        difference() {
            translate([0,0,MAIN_LUG_THK]) rotate([180,0,0])
                dog_leg2(len1=len1,ang=BEND_ANG,len2=len2,w=LUG_DIA,t=MAIN_LUG_THK);
            // remove potentiometer interface
            translate([0,0,-LUG_Z]) scale([1.02,1.02,1.02]) P090L_pot(negative=true);
            translate([len,0,0]) cylinder(h=20,d=SCREW_DIA,center=true,$fn=FACETS);
            translate([len/3.6,-6,0]) cylinder(h=20,d=18,center=true,$fn=FACETS);
        }
    }
}
*BC_Arm(len=lenBC); // Export as STL... F7 (quantity 1)

module BC_Arm_Cap() {
    color("RED") 
    difference() {
        translate([0,0,-3]) sphere(d=LUG_DIA*1.2,$fn=FACETS);
        //cylinder(h=8,d=LUG_DIA,center=true,$fn=FACETS);
        //rotate([90,0,90]) translate([0,1,3]) switch(true,$fn=FACETS);
        cylinder(h=60,d=SCREW_DIA*.92,center=true,$fn=FACETS);
        translate([0,0,-15]) cylinder(h=10,d=SCREW_DIA*2.5,center=true,$fn=FACETS);
        translate([-26,0,0]) cube(40,center=true);
        rotate([0,0,-90]) translate([0,0,-MAIN_LUG_THK]) 
            roundTopLug(dia=LUG_DIA*1.02,hgt=LUG_DIA,thk=MAIN_LUG_THK,bore=0,$fn=FACETS);
    }
}
*rotate([0,-90,0]) BC_Arm_Cap();  // Export as STL... F7 (quantity 1)

module BC_Assy() {
    // DRAW THE BC ARM 
    translate([0,0,-OUTER_LUG_THK]) BC_Arm(len=lenBC);
    //translate([lenBC+3,0,-4.5]) rotate([90,0,90]) switch($fn=FACETS); // switch
    translate([lenBC,0,-4]) rotate([180,0,0]) BC_Arm_Cap(); // for switch
    translate([lenBC,0,5]) rotate([0,180,0]) Screw(length=10,dia=4); // Screw
}
*BC_Assy();

module Input_Arm_Assembly(B_angle = 0){
    // Display the Input Arm Assembly from the AB arm and on
    // A joint is at [0,0]
    
    AB_Arm_Assy(len=lenAB);
    
    translate([lenAB,0,12]) rotate([0,0,B_angle]) BC_Assy();
}
*Input_Arm_Assembly(); 

module TA_Fitting() { // Complex part that connects Joint T to Joint A
    color("lime") {
        difference() {
            translate([0,0,2]) 
                roundTopLug(dia=LUG_DIA,hgt=LUG_DIA/2,thk=MAIN_LUG_THK,bore=3,cyl=true,$fn=FACETS);
            // remove potentiometer interface
            translate([0,0,-LUG_Z+2]) scale([1.02,1.02,1.02]) rotate([0,0,90]) 
                P090L_pot(negative=true);
            // remove wire hole
            rotate([0,0,0]) translate([0,0,15]) 
                simpleTorus (bigR = FLAT_DIST, littleR = 5,$fn=FACETS); 

        }

        translate([-1,0,A_joint_Z-MAIN_LUG_THK]) 
            rotate([90,0,-90]) 
                NonPotLug($fn=FACETS); 
        // add gusset for strength
        translate([-LUG_DIA/2,-14.5,15.5]) rotate([45,0,0]) 
            cube([OUTER_LUG_THK-0.2,10,4.5]);
        
        difference() {
            translate([LUG_DIA/2,-LUG_DIA+2,17/2+2]) rotate([0,90,180]) 
                roundTopLugTwo(width=17,rad=3,hgt=9,thk=LUG_DIA,bore=0,$fn=FACETS);
            
            // remove wire torus
            translate([0,0,6.5])  rotate([0,30,0]) 
                simpleTorus (bigR = FLAT_DIST*1.21, littleR = 2.5,$fn=FACETS); 
            
            // remove wire cylinder
            translate([7,-17,0]) cylinder(h=50,d=6,center=true,$fn=FACETS);
            
            // lug cylinder
            translate([0,0,8]) cylinder(h=MAIN_LUG_THK*1.01,d=LUG_DIA*1.05,$fn=FACETS);

        };
    }
}
*rotate([0,-90,0]) 
    TA_Fitting(); // Export as STL... F7 (quantity 1)

module TA_assy() {
    TA_Fitting();
    
    translate([7,0,A_joint_Z-MAIN_LUG_THK]) rotate([90,0,-90]) {
        PotLug(); 
        translate([0,0,zbody]) P090L_pot(negative=false); 
        translate([0,0,-OUTER_LUG_THK]) PotCoverAssy();
    }
}
*TA_assy();

module BaseLug(dia=LUG_DIA) {  // Model of Potentiometer holder
    color("orange") 
    difference () {// Side that holds the POT
        washer(d=dia,t=POT_LUG_THK,d_pin=POT_HOLE_DIA,center=false,$fn=FACETS);
        // remove potentiometer interface
        translate([0,0,zbody]) P090L_pot(negative=true);

        // remove screw holes
        rotate([0,0,90]) {
            screwHoles(dia=LUG_DIA,shrink=true);  
            translate([0,LUG_DIA/2.5,0]) 
                cylinder(h=4*dia,d=2.5,center=true,$fn=FACETS);
        };
        // remove wire donut
        translate([3,2,4]) 
            simpleTorus (bigR = dia/1.8, littleR = 3.3,$fn=FACETS); 

    };
}
*rotate([0,180,0]) 
    BaseLug(dia=LUG_DIA*1.5); // Export as STL... F7 (quantity 1)

module BasePotCover() {
    color("SlateBlue") 
    difference () {// Side that holds the POT
        translate([0,0,-OUTER_LUG_THK]) 
            washer(d=LUG_DIA*2.2,t=2*OUTER_LUG_THK,d_pin=3,center=false,$fn=FACETS);

        // remove potentiometer interface
        rotate([0,0,90]) translate([0,0,OUTER_LUG_THK+zbody]) P090L_pot(negative=false);
        
        screwHoles(dia=LUG_DIA);  // remove screw holes

        rotate([0,0,90]) {
            translate([0,LUG_DIA/1.03,0])  
                cylinder(h=10,d=SCREW_DIA,center=true,$fn=FACETS);
            translate([0,-LUG_DIA/1.03,0]) 
                cylinder(h=10,d=SCREW_DIA,center=true,$fn=FACETS);
        };
        translate([0,LUG_DIA/2.5,0]) {
            cylinder(h=10,d=SCREW_DIA,center=true,$fn=FACETS);
            translate([0,0,-2]) cylinder(h=7,d=SCREW_DIA*2.5,center=true,$fn=FACETS);
        };
        
        // remove wire donut
        translate([0,0,-4]) 
            simpleTorus (bigR = FLAT_DIST*0.95, littleR = 5.8,$fn=FACETS); 
        // remove window for t-pot wires
        translate([-12,0,0]) cube([10,10,30],center=true);
        // remove window for wire exit
        translate([0,20,-3]) cube([20,10,10],center=true);
        // remove window for wire entrance
        rotate([0,0,60]) translate([0,-17,4]) rotate([0,-50,30]) 
        cylinder(h=26,d=9,center=true,$fn=FACETS);
        
        translate([-5,20,0]) rotate([0,0,100]) zip_holes();
    }
}
*BasePotCover(); // Export as STL... F7 (quantity 1)

module BasePotCoverAssy() {
    BasePotCover();
    ScrewsInHoles(lug_dia=LUG_DIA,screw_dia=4,screw_len=19);
    
    rotate([0,0,90]) {
        translate([0,LUG_DIA/1.03,OUTER_LUG_THK]) rotate([0,180,0]) 
        Screw(length=10,dia=4);
    translate([0,-LUG_DIA/1.03,OUTER_LUG_THK]) rotate([0,180,0]) 
        Screw(length=10,dia=4);
    };
    translate([0,LUG_DIA/2.5,0])
        Screw(length=10,dia=4);

}

module base_assy(T_angle=0) {
    // Fixed part
    rotate([0,0,0]) {
        rotate([0,0,90]) BaseLug(dia=LUG_DIA*1.5); 
        translate([0,0,zbody]) rotate([0,0,90]) P090L_pot(negative=false); 
        rotate([0,0,180]) translate([0,0,POT_LUG_THK]) 
            NonPotLug(); 
        rotate([0,0,180]) translate([0,0,-OUTER_LUG_THK]) 
            BasePotCoverAssy();
    }
    // Moving part
    rotate([0,0,T_angle]) {
        translate([0,0,MAIN_LUG_THK]) TA_assy();
    }
}
*base_assy(T_angle = 0);

module draw_assy (A_angle=0,B_angle=0,T_angle = 0) {
    // Display the input arm assembly
    // Input parameters are the angle from the input arm
    //  A and B are the angles of the potentiometers
    //  T is the turntable angle

    base_assy(T_angle = T_angle);
    
    rotate([0,0,T_angle]) // T rotation
        translate([A_joint_X,0,A_joint_Z]) // translate to A joint location
            rotate([A_angle,0,0]) // A rotation
                rotate([90,0,90]) 
                // Draw the AB arm assembly
                    Input_Arm_Assembly(B_angle);
}

*draw_assy(A_angle=160,B_angle=-165,T_angle=TT);

if (display_assy) {
    difference () {
        draw_assy(AA,BB,TT);
        if (clip_yz) // x = xcp cut 
            translate ([-201,-100,-100]) cube (200,center=false);
        if (clip_xy) // z = 0 cut 
            translate ([-100,-100,-200]) cube (200,center=false);
    }
}    

NUMBER_BUMPS = 12;

module bumpyLug(thk=2,bumps=10) {
    // lug that goes on the shaft
    difference () {
        washer(d=LUG_DIA,t=thk,d_pin=1,center=false,$fn=FACETS);
        // remove potentiometer interfaces
        translate([0,0,-3.3]) scale([1.02,1.02,1.02]) P090L_pot(negative=true);
    }
    BUMP_Y = LUG_DIA/2.8;  // bump, y location
    //BUMP_RAD = 1;
    BUMP_Z = thk;
    ang_inc = 180/(bumps-1);
    rotate([0,0,-ang_inc/2]) Rotation_Pattern(number=bumps+1,radius=BUMP_Y,total_angle=180+ang_inc) {
        translate([0,0,BUMP_Z]) rotate([90,0,90])
            linear_extrude(2.5,convexity=10) polygon(points=[[1.2,0],[0,1],[-1.2,0]]);
    }
}
module SelectorKnob(notch_rotation=0,thk=2,bumps=10) {
    color("DeepPink") {
        union() {
            rotate([0,0,notch_rotation]) bumpyLug(thk=thk,bumps=bumps);
            linear_extrude(thk,convexity=10) 
                polygon(points=[[LUG_DIA*0.2,LUG_DIA*0.2],[LUG_DIA*0.2,LUG_DIA*0.8],[0,LUG_DIA*0.6],[-LUG_DIA*0.2,LUG_DIA*0.8],[-LUG_DIA*0.2,LUG_DIA*0.2]]);
                }
            }
}
*SelectorKnob(thk=MAIN_LUG_THK-1,bumps=NUMBER_BUMPS-1); // Export as STL... F7 (quantity 1)

module bumpyBaseCover(thk=2,bumps=10) {
    BUMP_Y = LUG_DIA/1.5;  // bump, y location
    BUMP_RAD = 1;
    BUMP_Z = thk;
    ang_inc = 180/(bumps-1);
    echo(ang_inc=ang_inc);
    BasePotCover();
    rotate([0,0,1*ang_inc]) Rotation_Pattern(number=bumps-2,radius=BUMP_Y,total_angle=180-ang_inc) {
        translate([0,0,BUMP_Z]) cylinder(h=1,r=BUMP_RAD,$fn=FACETS);
    }
}
*bumpyBaseCover(thk=OUTER_LUG_THK,bumps=NUMBER_BUMPS-1); // Export as STL... F7 (quantity 1)

module BumpyBaseCoverAssy() {
    bumpyBaseCover(thk=OUTER_LUG_THK,bumps=NUMBER_BUMPS-1);
    ScrewsInHoles(lug_dia=LUG_DIA,screw_dia=4,screw_len=19);
    
    translate([LUG_DIA/1.5,0,OUTER_LUG_THK]) rotate([0,180,0]) Screw(length=10,dia=4);
    translate([-LUG_DIA/1.5,0,OUTER_LUG_THK]) rotate([0,180,0]) Screw(length=10,dia=4);
}

module NonPotLugTooth() {  // Model of Potentiometer holder
    thk = 1.5;
    extraZ = 2.0;
    color("lightgreen") difference() {
            union() {
            translate([0,0,MAIN_LUG_THK+extraZ]) 
                roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=thk,bore=POT_HOLE_DIA,$fn=FACETS);
            translate([-LUG_DIA/2,-FLAT_DIST,0]) cube([LUG_DIA,8.5,MAIN_LUG_THK+extraZ],center=false);
            translate([0,LUG_DIA/2.2,MAIN_LUG_THK+extraZ]) rotate([90,0,0])
            linear_extrude(3,convexity=10) polygon(points=[[1.5,0],[0,-1.6],[-1.5,0]]);
        }
        // remove screw holes
        screwHoles(dia=LUG_DIA,shrink=true);
    }
}
*rotate([0,180,0]) NonPotLugTooth(); // Export as STL... F7 (quantity 1)

function anim_steps(val)= (val<0.25) ? -18 : ((val<0.5) ? 0 : 18);

module SelectorAssy(ang=0) {
    PotLug(); 
    translate([0,0,zbody]) rotate([0,0,ang]) P090L_pot(negative=false); 
    translate([0,0,POT_LUG_THK]) NonPotLugTooth(); 
    translate([0,0,-OUTER_LUG_THK]) 
        BumpyBaseCoverAssy();
    translate([0,0,MAIN_LUG_THK+LUG_Z+1.5]) 
        rotate([0,0,ang]) SelectorKnob(thk=MAIN_LUG_THK-1,bumps=NUMBER_BUMPS-1); 
}
if (display_selector) {
    difference() {
        // translate([LUG_DIA*2,0,0]) 
            SelectorAssy(ang=anim_steps($t));
        if (clip_yz) // x = xcp cut 
            translate ([-200.1,-100,-100]) cube (200,center=false);
    }
}
//