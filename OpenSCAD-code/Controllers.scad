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

// Animation Commands to create an orbital fly-around:
$vpr = [60, 0, -30];   // view point rotation (spins the part)
$vpt = [-40,0,80];    // view point translation
$vpf = 50;          // view point field of view
$vpd = 180;         // view point distance
//

// Parameters for Customizer:
// Joint A angle
//AA = 25; // [0:180.0]
AA = 90*sin($t*180);  // for animation
// Joint B angle
//BB = -35; // [-170:1:0.0]
BB = 90*sin($t*180);  // for animation
// Turntable angle
//TT = 0; // [-90:90]
TT = 60*sin($t*90);  // for animation
// use 140 for printing, 40 for display
FACETS = 40; // [40,140]

// Draw the Input Arm Assembly?
display_assy = true;
// Draw the Selector?
display_selector = true;
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
A_joint_Z = 40; 
// A joint shift X (lateral), mm
A_joint_X = -9;

// Lug Diameter, mm, used by many
LUG_DIA = 22; 
// distance to the flat side from the bore
FLAT_DIST = 20;
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

//################### PART LIB FUNCTIONS AND MODULES
module washer(d=20,t=2,d_pin=10,center=true){
    // model washer on xy plane at 0,0,0 of diameter d, hole size of d_pin
    // t is thickness
    difference(){
        cylinder(t,d=d,center=center);  // outside
        cylinder(3*t,d=d_pin,center=true);  // subtract bore
    };
}
*washer($fn=FACETS); 

module rounded_cube(size=[20,30,10],r=5,center=true) {
    // Create a rounded cube in the xy plane, flat on the Z ends
    // Creates 4 cylinders and then uses hull
    
    xp=center ? size[0]/2-r : size[0]-r;
    yp=center ? size[1]/2-r : size[1]-r;
    xn=center ? -xp : r;
    yn=center ? -yp : r;
    z=center ? 0 : size[2]/2;

    hull() {
        translate([xp,yp,z]) cylinder(h=size[2],r=r,center=true);
        translate([xp,yn,z]) cylinder(h=size[2],r=r,center=true);
        translate([xn,yp,z]) cylinder(h=size[2],r=r,center=true);
        translate([xn,yn,z]) cylinder(h=size[2],r=r,center=true);       
    }  
}
*rounded_cube(center=false,$fn=FACETS); 

L_pot_shaft = 13.1;  // P090 shaft length above the body (mm)
zbody = 5.5;  // all units are mm

module P090L_pot (negative=false) {
// The P090L (Style L) has the three pins off of the side
// Digi-key part no. P090S-04F20BR10K or P090S-14T20BR10K
// https://www.digikey.com/en/products/detail/tt-electronics-bi/P090S-04F20BR10K/2408853 
// https://www.mouser.com/ProductDetail/BI-Technologies-TT-Electronics/P090S-14T20BR10K
// Solder the wires to the pins (need solid connection). Pins can be easily bent.
// Cut off connectors to reduce installation volume with small diagonal cutters.
// negative false = model a potentiometer for display
// negative true = model to be used with a difference() in another model
    
    ss = negative ? 1.0: 0.97;  // if negative == false then scale down
    // constants
    zbDif = zbody+1;  // make body bigger for difference()

    scale([ss,ss,ss]){ // scale down the model for display
        color("green") if (!negative) { // potentiometer for display
            translate([0,0,-zbody/2]) cube([10,12,zbody],center=true);
            // two cylinders on backside, drawn larger than real
            translate([0,-8.5/2,-zbody]) cylinder(h=4,d=3,center=true,$fn=FACETS);
            translate([0,8.5/2,-zbody]) cylinder(h=4,d=3,center=true,$fn=FACETS);

        } else {         // potentiometer for difference()
            translate([0,0,-zbDif/2]) cube([10,12.5,zbDif],center=true);
            translate([0,-12.5,-zbDif/2]) cube([10,20,zbDif],center=true);
        }
        
        cylinder(h=2,d=7.2,center=true,$fn=FACETS); // ring around the shaft
        
        // two cylinders around the shaft
        translate([2.7,-3.8,0]) cylinder(h=2,d=3,center=true,$fn=FACETS);
        translate([-2.7,3.8,0]) cylinder(h=2,d=3,center=true,$fn=FACETS);
        
    
        // shaft F-Type
        color("darkslategrey") 
            difference () {
                translate([0,0,L_pot_shaft/2]) 
                    cylinder(h=L_pot_shaft,d=6.2,center=true,$fn=FACETS);
                // 1.55 was 1.45, increased to make assembly easier
                translate ([-5,-L_pot_shaft-1.55,5]) cube(L_pot_shaft,center=false); // key
        }
        // pins (3)
        zpin = -4;
        translate([0,-11,zpin]) elect_pin();
        translate([-3,-11,zpin]) elect_pin();
        translate([3,-11,zpin]) elect_pin();
    }
     
    module elect_pin() { // 1 mm diamater electric pin
        cube([1.5,10,0.5],center=true);
    }
}
*P090L_pot(negative=false); 

//######################################################## //
module screwHoles(dia=15,shrink=false) { // pair of screw holes that hold the stack together
    cylDia = shrink ? SCREW_DIA*0.9 : SCREW_DIA;
    translate([dia/2.8,-dia/2-4,0])  cylinder(h=4*dia,d=cylDia,center=true,$fn=FACETS);
    translate([-dia/2.8,-dia/2-4,0]) cylinder(h=4*dia,d=cylDia,center=true,$fn=FACETS);
}
module roundTopLug (dia=15,hgt=20,thk=5,bore=3) {  // Full round top, width = dia
    difference() {
        translate([0,0,thk/2])
            hull() {
                cylinder(h=thk,d=dia,center=true);
                translate([0,-hgt/2,0]) cube([dia,hgt,thk],center=true);
            }
        cylinder(h=4*thk,d=bore,center=true);  // remove bore
    }
}
*roundTopLug(dia=20,hgt=5,bore=0,$fn=FACETS);  // note result if hgt < dia/2

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

module PotLug() {  // Model of Potentiometer holder
    color("blue") difference () {// Side that holds the POT
        roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=POT_LUG_THK,bore=POT_HOLE_DIA,$fn=FACETS);

        translate([0,0,zbody]) P090L_pot(negative=true);// remove potentiometer interface

        screwHoles(dia=LUG_DIA);  // remove screw holes
        }
}
*rotate([0,180,0]) PotLug(); // Export as STL... F7 (quantity 4)

module NonPotLug(thk=OUTER_LUG_THK,notch=false) {  // Model of Potentiometer holder
    color("green") difference() {
            union() {
            translate([0,0,MAIN_LUG_THK]) 
                roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=thk,bore=POT_HOLE_DIA,$fn=FACETS);
            translate([-LUG_DIA/2,-FLAT_DIST,0]) cube([LUG_DIA,8.5,MAIN_LUG_THK],center=false);
            if (notch) translate([0,LUG_DIA/2.2,MAIN_LUG_THK]) rotate([90,0,0])
            linear_extrude(3,convexity=10) polygon(points=[[1.5,0],[0,-1.2],[-1.5,0]]);
        }
        // remove screw holes
        screwHoles(dia=LUG_DIA,shrink=true);
    }
}
*NonPotLug();

module PotCover() {
    color("Cyan") 
    difference () {// Side that holds the POT
        roundTopLug(dia=LUG_DIA,hgt=FLAT_DIST,thk=OUTER_LUG_THK,bore=3,$fn=FACETS);
        // remove potentiometer interface
        translate([0,0,OUTER_LUG_THK+zbody]) P090L_pot(negative=false);
        screwHoles(dia=LUG_DIA);  // remove screw holes
        translate([0,-FLAT_DIST,0]) cube([LUG_DIA/2.6,10,10],center=true);
    }
}
*PotCover(); // STL (2)

module BasePotCover() {
    color("SlateBlue") 
    difference () {// Side that holds the POT
        roundTopLug(dia=LUG_DIA*1.7,hgt=FLAT_DIST,thk=OUTER_LUG_THK,bore=3,$fn=FACETS);
        // remove potentiometer interface
        translate([0,0,OUTER_LUG_THK+zbody]) P090L_pot(negative=false);
        
        screwHoles(dia=LUG_DIA);  // remove screw holes

        translate([LUG_DIA/1.5,0,0])  cylinder(h=10,d=SCREW_DIA,center=true,$fn=FACETS);
        translate([-LUG_DIA/1.5,0,0]) cylinder(h=10,d=SCREW_DIA,center=true,$fn=FACETS);
    }
}
*BasePotCover(); // STL (1)

module joint_visuals(cut=true) { // Use for cross section cuts of Joints
    difference() { 
        union() {
            PotLug(); 
            translate([0,0,zbody]) P090L_pot(negative=false); 
            translate([0,0,POT_LUG_THK]) NonPotLug(); // OR SELECTOR BASE
            translate([0,0,-OUTER_LUG_THK]) PotCover();
            rotate([0,0,90]) translate([0,0,MAIN_LUG_THK+.2]) scale([.95,.95,.95]) 
                AB_Arm(len = lenAB);
       }
       if (cut) translate([-20,0,0]) cube([40,80,40],center=true);  // Section Cut cube
    }
}
*joint_visuals(cut=true); // not for print

module AB_Arm(len=100) {
    color("plum",1) difference () {
        union() {
            translate([0,0,8]) rotate([180,0,-90]) difference() {
                    roundTopLug(dia=LUG_DIA,hgt=LUG_DIA,thk=MAIN_LUG_THK,bore=3,$fn=FACETS);
                // remove potentiometer interface
                translate([0,0,-LUG_Z]) scale([1.02,1.02,1.02]) rotate([0,0,180]) 
                    P090L_pot(negative=true);
            }
            
            translate([len,0,-0]) 
                rotate([0,0,-90]) PotLug(); // lug at other end
            
            // The connecting cube:
            difference() { // REMOVE CYL SO THAT 0,0 LUG JOINT UNIONS PROPERLY
                translate([0,-LUG_DIA/2,LUG_Z]) 
                    cube([len-LUG_DIA/1.2,LUG_DIA,MAIN_LUG_THK],center=false);
                cylinder(h=40,d=8,center=true,$fn=FACETS); // for the pot
           }
        }
    }
}
*rotate([180,0,0]) AB_Arm(len = lenAB); // Export as STL... F7 (quantity 1)

module AB_Arm_Assy(len=100){
    AB_Arm(len=len); 
    translate([len,0,0])  rotate([0,0,-90]) {
        translate([0,0,-OUTER_LUG_THK])PotCover();
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
//switch(true,$fn=FACETS);

module BC_Arm_model(len=100) {
    // BC arm is designed so that it can not hyperextend (i.e. A-B-C can be inline, but not more)
    angSin = asin(LUG_DIA/len);
    color("purple",1) {
        // lug at 0,0
        difference() {
            rotate([0,0,180]) 
                roundTopLug (dia=LUG_DIA,hgt=LUG_DIA,thk=MAIN_LUG_THK,bore=3);
            // remove potentiometer interface
            translate([0,0,-LUG_Z]) scale([1.02,1.02,1.02]) P090L_pot(negative=true);
        }
        
        // lug at extreme end.  To hold push button switch
        translate([len,0,0]) 
            difference() {
                rotate([0,0,-90-angSin]) 
                 roundTopLug(dia=LUG_DIA*0.85,hgt=len+4,thk=MAIN_LUG_THK,bore=SCREW_DIA,$fn=FACETS);
                rotate([90,0,90]) translate([0,-1,3]) switch(true,$fn=FACETS);
            } 
        
        translate([0,LUG_DIA,3]) cylinder(h=MAIN_LUG_THK,d=LUG_DIA,center=true,$fn=FACETS);
    }
}
*BC_Arm_model(len=lenBC);
*rotate([180,0,0]) BC_Arm_model(len=lenBC); // Export as STL... F7 (quantity 1)

module BC_Arm_Cap() {
    color("lightblue") difference() {
        translate([0,0,4]) cylinder(h=8,d=LUG_DIA*0.85,center=true,$fn=FACETS);
        rotate([90,0,90]) translate([0,1,3]) switch(true,$fn=FACETS);
        cylinder(h=20,d=SCREW_DIA*.92,center=true,$fn=FACETS);
    }
}
*rotate([180,0,0]) BC_Arm_Cap();  // Export as STL... F7 (quantity 1)

module BC_Assy() {
    // DRAW THE BC ARM 
    translate([0,0,-OUTER_LUG_THK]) BC_Arm_model(len=lenBC);
    translate([lenBC+3,0,-4.5]) rotate([90,0,90]) switch($fn=FACETS); // switch
    translate([lenBC,0,-4]) rotate([180,0,0]) BC_Arm_Cap(); // switch
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
                roundTopLug (dia=LUG_DIA,hgt=LUG_DIA/2,thk=MAIN_LUG_THK,bore=3,$fn=FACETS);
            // remove potentiometer interface
            translate([0,0,-LUG_Z+2]) scale([1.02,1.02,1.02]) rotate([0,0,180]) 
                P090L_pot(negative=true);
        }

        translate([-1,0,A_joint_Z-MAIN_LUG_THK]) rotate([90,0,-90]) NonPotLug(); 
        
        translate([LUG_DIA/2,-LUG_DIA+3,20.5/2+2]) rotate([0,90,180]) 
            roundTopLugTwo (width=20.5,rad=3,hgt=8,thk=LUG_DIA,bore=0,$fn=FACETS);
    }
}
*rotate([0,-90,0]) TA_Fitting(); // Export as STL... F7 (quantity 1)

module TA_assy() {
    TA_Fitting();
    
    translate([7,0,A_joint_Z-MAIN_LUG_THK]) rotate([90,0,-90]) {
        PotLug(); 
        translate([0,0,zbody]) P090L_pot(negative=false); 
        translate([0,0,-OUTER_LUG_THK]) PotCover();
    }
}

module base_assy(T_angle=0) {
    // Fixed part
    rotate([0,0,180]) {
        PotLug(); 
        translate([0,0,zbody]) P090L_pot(negative=false); 
        translate([0,0,POT_LUG_THK]) NonPotLug(); 
        translate([0,0,-OUTER_LUG_THK]) BasePotCover();
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
        translate([0,0,-LUG_Z]) scale([1.02,1.02,1.02]) P090L_pot(negative=true);
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
                polygon(points=[[LUG_DIA*0.2,LUG_DIA*0.2],[0,LUG_DIA*.8],[-LUG_DIA*0.2,LUG_DIA*0.2]]);
                }
            }
}
*SelectorKnob(thk=MAIN_LUG_THK-1,bumps=NUMBER_BUMPS-1); // Export as STL... F7 (quantity 1)

module bumpyBaseCover(thk=2,bumps=10) {
    BUMP_Y = LUG_DIA/1.5;  // bump, y location
    BUMP_RAD = 1;
    BUMP_Z = thk;
    ang_inc = 180/(bumps-1);
    BasePotCover();
    rotate([0,0,ang_inc]) Rotation_Pattern(number=bumps-2,radius=BUMP_Y,total_angle=180-2*ang_inc) {
        translate([0,0,BUMP_Z]) cylinder(h=1,r=BUMP_RAD,$fn=FACETS);
    }
}
*bumpyBaseCover(thk=OUTER_LUG_THK,bumps=NUMBER_BUMPS-1); // Export as STL... F7 (quantity 1)

*rotate([0,180,0]) NonPotLug(thk=1.3,notch=true); // Export as STL... F7 (quantity 1)

module SelectorAssy(ang=0) {
    PotLug(); 
    translate([0,0,zbody]) P090L_pot(negative=false); 
    translate([0,0,POT_LUG_THK]) NonPotLug(thk=1.3,notch=true); 
    translate([0,0,-OUTER_LUG_THK]) 
        bumpyBaseCover(thk=OUTER_LUG_THK,bumps=NUMBER_BUMPS-1);
    translate([0,0,MAIN_LUG_THK+LUG_Z]) 
        SelectorKnob(thk=MAIN_LUG_THK-1,bumps=NUMBER_BUMPS-1); 
}
if (display_selector) {
    difference() {
        translate([LUG_DIA*2,0,0]) SelectorAssy();
        if (clip_yz) // x = xcp cut 
            translate ([-200.1+LUG_DIA*2,-100,-100]) cube (200,center=false);
    }
}
//