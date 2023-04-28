// Input Arm Assembly
//  Design for Human Hand to drive a Robot Arm
//  last modified May 2023 by SrAmo
//
//  To make STL models for 3D printing follow these steps:
//  find "FOR PRINT" and remove * (disable) suffix, 
//     then render the part (F6) (this may take some time)
//        then  Export as STL (F7)

/* Animation Commands to create an orbital fly-around:
$vpr = [100, 0,$t * 360];   // view point rotation (spins the part)
$vpt = [0,0,50];    // view point translation
$vpf = 70;          // view point field of view
$vpd = 180;         // view point distance
*/

// Parameters for Customizer:
// Joint A angle
AA = 5; // [0:170.0]
// Joint B angle
BB = 0; // [-170:1:0.0]
// Turntable angle
TT = 0; // [-90:90]
// use 140 for printing, 40 for display
FACETS = 140; // [40,140]

// Draw the Input Arm Assembly?
display_assy = true;
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

widthAB = 15; // mm

// A joint shift Z (up), mm
A_joint_Z = 25; 
// A joint shift X (lateral), mm
A_joint_X = 4;

THK_TURNTABLE = 6;
DIA_TURNTABLE = 60;

// Potentiometer support dimensions
// Outer Body Diameter, mm
DIA_OUTER_LUGS = 22; 
// Inner Lug Diameter, mm
DIA_INNER_LUGS = 22;
// Inner Lug Thickness, mm
THK_INNER_LUGS = 8;
THK_OUTER_LUG_TWO = 3;
THK_OUTER_LUG_ONE = 7;
LUG_Z = 2;
RAD_LUGS = DIA_INNER_LUGS/2.5;
Y_INNER_EXTRA = 0.4*DIA_OUTER_LUGS;

DIA_POT_SHAFT = 6.4; 

//################### PART LIB FUNCTIONS AND MODULES
module washer(d=20,t=2,d_pin=10,center=true){
    // model washer on xy plane at 0,0,0 of radius r
    // t is thickness (centered about z=0)

    difference(){
        cylinder(t,d=d,center=center);  // outside
        cylinder(3*t,d=d_pin,center=true);  // subtract bore
    };
}
*washer($fn=50);  // DO NOT PRINT

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
*rounded_cube(center=false,$fn=48);   // DO NOT PRINT

lenPin=7; // P090 electrical pin length constant
L_pot_shaft = 13.1;  // P090 shaft length above the body

module P090L_pot (negative=false) {
    // units are mm
    // The P090L (Style L) has the three pins off of the side
    // Solder the wires to the pins (need solid connection)
    // Cut off connectors to reduce installation volume
    // negative false = model a potentiometer for display
    // negative true = model to be used with a difference() in another model
    
    ss = negative ? 1.0: 0.97;  // if negative false then scale down
    // constants
    zbody = 5.1;
    zb = zbody+1;
    zpin = -4;

    scale([ss,ss,ss]){ // scale down the model for display
        color("green") if (!negative) { // potentiometer for display
            translate([0,0,-zbody/2]) cube([10,12,zbody],center=true);
            // two bumps on backside
            translate([0,-8.5/2,-zbody]) cylinder(h=2,d=1.2,center=true,$fn=20);
            translate([0,8.5/2,-zbody]) cylinder(h=2,d=1.2,center=true,$fn=20);

        } else {         // potentiometer for difference()
            translate([0,0,-zb/2]) cube([10,12.5,zb],center=true);
            translate([0,-12.5,-zb/2]) cube([10,20,zb],center=true);
        }
        
        cylinder(h=2,d=7.2,center=true,$fn=48); // ring around the shaft
        
        // two bumps around the shaft
        translate([2.7,-3.8,0]) cylinder(h=2,d=2.5,center=true,$fn=24);
        translate([-2.7,3.8,0]) cylinder(h=2,d=2.5,center=true,$fn=24);
        
    
        // shaft F-Type
        color("darkslategrey") 
            difference () {
                translate([0,0,L_pot_shaft/2]) 
                    cylinder(h=L_pot_shaft,d=6.2,center=true,$fn=48);
                // 1.55 was 1.45, increased to make assembly easier
                translate ([-5,-L_pot_shaft-1.55,5]) cube(L_pot_shaft,center=false); // key
        }
        // pins (3)
        translate([0,7,zpin]) elect_pin();
        translate([-2.5,7,zpin]) elect_pin();
        translate([2.5,7,zpin]) elect_pin();
    }
     
    module elect_pin() {
        // 1 mm diamater electric pin
        rotate([90,0,0]) translate([0,0,lenPin/2]) cylinder(h=lenPin,r=.5,$fn=8);
    }
}
*P090L_pot(negative=true);  // DO NOT PRINT

//######################################################## //

module pot_joint(lug_two = true) {
    // Model of Potentiometer holder
    difference () {
        if (lug_two) { // Side without the POT  
            union() {
                
            translate([0,-Y_INNER_EXTRA/2, THK_INNER_LUGS+LUG_Z+THK_OUTER_LUG_TWO/2]) 
                rounded_cube(size=[DIA_OUTER_LUGS,DIA_OUTER_LUGS+Y_INNER_EXTRA,THK_OUTER_LUG_TWO],r=RAD_LUGS,center=true,$fn=FACETS);
            translate([0,-DIA_OUTER_LUGS/2-Y_INNER_EXTRA/2, THK_INNER_LUGS/2+LUG_Z+THK_OUTER_LUG_TWO/2]) 
                cube(size=[DIA_OUTER_LUGS,Y_INNER_EXTRA,THK_INNER_LUGS+THK_OUTER_LUG_TWO],center=true,$fn=FACETS);
            }
        } else {   // Side that holds the POT
            union() {
                translate([0,-Y_INNER_EXTRA/2,-THK_OUTER_LUG_ONE/2+LUG_Z]) 
                    rounded_cube(size=[DIA_OUTER_LUGS,DIA_OUTER_LUGS+Y_INNER_EXTRA,THK_OUTER_LUG_ONE],r=RAD_LUGS,center=true,$fn=FACETS);
            translate([0,-DIA_OUTER_LUGS/2-Y_INNER_EXTRA/2, -THK_OUTER_LUG_ONE/2+LUG_Z]) 
                cube(size=[DIA_OUTER_LUGS,Y_INNER_EXTRA,THK_OUTER_LUG_ONE],center=true,$fn=FACETS);
            }

        }
        // remove potentiometer interface-- BUILT AROUND THIS
        P090L_pot(negative=true);
        
        // remove screw holes
        translate([DIA_OUTER_LUGS/3,-DIA_OUTER_LUGS/2-Y_INNER_EXTRA/2,0]) 
                cylinder(h=50,d=2.5,center=true,$fn=FACETS);
        translate([-DIA_OUTER_LUGS/3,-DIA_OUTER_LUGS/2-Y_INNER_EXTRA/2,0]) 
                cylinder(h=50,d=2.5,center=true,$fn=FACETS);
        
        // remove potentiometer shaft hole locking features
        cylinder(h=40,d=DIA_POT_SHAFT,center=true,$fn=FACETS); 

    }
}
BUMP_Y = -DIA_INNER_LUGS/2.5;  // friction bump, y location
BUMP_RAD = 2.5;
BUMP_Z = 2*BUMP_RAD - 1.0;

module lug_joint() {
    // lug that goes on the shaft
    difference () {
        translate([0,0,THK_INNER_LUGS/2+LUG_Z]) washer(d=DIA_INNER_LUGS,t=THK_INNER_LUGS,d_pin=1,$fn=FACETS);
        // remove potentiometer interfaces
        scale([1.02,1.02,1.02]) P090L_pot(negative=true);
    }
    // bump to add some friction in the joint
    translate([0,BUMP_Y,BUMP_Z]) rotate([90,0,0]) cylinder(h=BUMP_RAD,r=BUMP_RAD,center=true,$fn=FACETS);
    translate([0,-BUMP_Y,BUMP_Z]) rotate([90,0,0]) cylinder(h=BUMP_RAD,r=BUMP_RAD,center=true,$fn=FACETS);
}
*lug_joint();  // not for print

module C_End_Knob_model(notch_rotation=0,KNURL_X = 12, KNURL_Y=9) {
    // KNURL_Y SHOULD BE LESS THAN KNURL_X
    color("DeepPink") {
        difference () {
            union() {
                translate([0,0,THK_INNER_LUGS/2+LUG_Z]) {
                    washer(d=DIA_INNER_LUGS,t=THK_INNER_LUGS,d_pin=1,$fn=FACETS);
                // finger point rounded_cube(size=[x,y,z],r=rad,center=true)
                translate([KNURL_X/2,0,0]) {
                    cylinder(h=THK_INNER_LUGS,r=KNURL_Y/2,center=true,$fn=FACETS);
                    // Add knurl
                    Rotation_Pattern(number=12,radius=KNURL_Y/2,total_angle=360)
                            cylinder(h=THK_INNER_LUGS,d=1,center=true,$fn=FACETS);
                    }
                }
            }
            // remove potentiometer interfaces
            scale([1.02,1.02,1.02]) 
                rotate([0,0,notch_rotation]) P090L_pot(negative=true);
        }
        // bump to add some friction in the joint
        translate([0,BUMP_Y,BUMP_Z]) rotate([90,0,0]) cylinder(h=BUMP_RAD,r=BUMP_RAD,center=true,$fn=FACETS);
        translate([0,-BUMP_Y,BUMP_Z]) rotate([90,0,0]) cylinder(h=BUMP_RAD,r=BUMP_RAD,center=true,$fn=FACETS);
    }
}
*C_End_Knob_model(notch_rotation=-90,KNURL_X = 20, KNURL_Y = 6);  // FOR_PRINT
*C_End_Knob_model(notch_rotation=-90,KNURL_X = 12, KNURL_Y = 9);  // FOR_PRINT

module Pot_Cover_model() {
    
    thk_cover = THK_OUTER_LUG_TWO; 
    z_offset = -THK_OUTER_LUG_ONE + LUG_Z -thk_cover/2;
    
    color("Cyan",1) translate([0,0,z_offset]) {
        difference() {
            union() {
                washer(d=DIA_OUTER_LUGS,t=thk_cover,d_pin=2,$fn=FACETS);
                translate([0,-DIA_OUTER_LUGS/2,0]) 
                    cube([DIA_OUTER_LUGS,DIA_OUTER_LUGS,thk_cover],center=true);
                translate([0,-DIA_OUTER_LUGS-thk_cover/2,THK_OUTER_LUG_ONE/2 - thk_cover/2]) 
                    cube([DIA_OUTER_LUGS,thk_cover,THK_OUTER_LUG_ONE],center=true);
            }
            // screw holes
            translate([DIA_OUTER_LUGS/3,-DIA_OUTER_LUGS/2-Y_INNER_EXTRA/2,0]) 
                cylinder(h=50,d=2.5,center=true,$fn=FACETS);
            translate([-DIA_OUTER_LUGS/3,-DIA_OUTER_LUGS/2-Y_INNER_EXTRA/2,0]) 
                cylinder(h=50,d=2.5,center=true,$fn=FACETS);
            // two holes for pot
            translate([0,-8.5/2,1]) cylinder(h=6,d=2.4,center=true,$fn=20);
            translate([0,8.5/2,1]) cylinder(h=6,d=2.4,center=true,$fn=20);
        }
    }
}
*translate([0,0,-THK_OUTER_LUG_TWO]) Pot_Cover_model(); // FOR_PRINT

module Selector_base () {
    DETENT_R = 10;
    pot_joint(lug_two = false);
    translate([0,0,3]) Rotation_Pattern(number=12,radius=DETENT_R,total_angle=270)
        sphere(d=2,$fn=FACETS);
    translate([0,DIA_OUTER_LUGS/2,-A_joint_Z/2+2]) rotate([90,0,0]) {
        difference() {
            cube([50,A_joint_Z+2,4],center=true);
            // screw holes
            Rotation_Pattern(number=2,radius=20,total_angle=360)
                    cylinder(h=10,d=3,center=true,$fn=FACETS);
        }
    }
}
*Selector_base(); // FOR_PRINT

module joint_visuals(cover=true,cut=true) {
    difference() { // Use for visulization of Pot Joints
        union() {
            color("blue") pot_joint(lug_two = true); 
            
            color("green") pot_joint(lug_two = false); // OR SELECTOR BASE
            *Selector_base();
            
            scale([0.98,0.98,0.98]) lug_joint();    // OR C_END_KNOB
            *scale([0.98,0.98,0.98]) C_End_Knob_model(notch_rotation=0,KNURL_X = 16, KNURL_Y = 14);
            
            P090L_pot(negative=false); 
            if (cover) Pot_Cover_model();
       }
       if (cut) translate([-20,0,0]) cube([40,80,40],center=true);  // Section Cut cube
    }
}
*joint_visuals(cover=true,cut=true); // not for print

module AB_Arm_model(len=100) {
    color("plum",1) difference () {
        union() {
            rotate([0,0,180]) lug_joint(); // lug at 0,0
            
            translate([len,0,-THK_OUTER_LUG_TWO]) 
                rotate([0,0,-90]) 
                    pot_joint(lug_two = true); // lug at other end
            
            // The connecting cube:
            difference() { // REMOVE CYL SO THAT 0,0 LUG JOINT UNIONS PROPERLY
                translate([0,-DIA_INNER_LUGS/2,LUG_Z]) 
                    cube([len-DIA_OUTER_LUGS/1.2,DIA_INNER_LUGS,THK_INNER_LUGS],center=false);
                cylinder(h=40,d=8,center=true,$fn=FACETS); // for the pot
           }
        }
        // remove hole for wire
        //translate([len-20,5,10]) cylinder(h=20,r=2,center=true,$fn=FACETS);
    }
}
module AB_Arm_model2(len=100) {
    color("Orchid",1)
        translate([len,0,-THK_OUTER_LUG_TWO]) 
            rotate([0,0,-90]) 
                pot_joint(lug_two = false);
}
module AB_Arm_Assy(len=100){
    *AB_Arm_model(len=len); 
    *AB_Arm_model2(len=len);
    translate([len,0,-THK_OUTER_LUG_TWO]) 
        rotate([0,0,-90]) joint_visuals(cover=true,cut=false);
            *Pot_Cover_model();
}
*AB_Arm_Assy(len=lenAB);  // Not for print

*AB_Arm_model(len=lenAB);  // FOR_PRINT
*rotate([0,0,90]) AB_Arm_model2(len=0);  // FOR_PRINT

module BC_Arm_model(len=100,width=10) {
    difference() {
        union() {
            lug_joint(); // lug
            difference() {
                translate([-DIA_INNER_LUGS/2,0,3.2]) 
                    cube([DIA_INNER_LUGS,DIA_INNER_LUGS,THK_INNER_LUGS],center=false);
                cylinder(h=40,d=8,center=true);
            }
            // Cubes that connect the two ends
            translate([-20,width/4+7,3.2]) cube([50,width-4,THK_INNER_LUGS],center=false);
            translate([30,width/4,3.2]) cube([len-38,width,THK_INNER_LUGS],center=false);
            *translate([len-DIA_OUTER_LUGS/2-3,width/4,-THK_INNER_LUGS/2]) cube([8,width,THK_INNER_LUGS*1.6],center=false);
            
            *translate([len,width*3/4,-THK_INNER_LUGS/2-.1]) 
                rotate([0,0,-90]) pot_joint(lug_two = true);
        }
    }
}
*BC_Arm_model(len=lenBC,width=widthAB); // FOR PRINT 
/* NOT PRESENTLY USED
module add_on_pot_joint() {
    // Angle for add-on pot lug screws
    ang_add = 64;
    color("Peru") {
        // Potentiometer holder
        difference () {
            union() {
                translate([0,0,2.9]) washer(d=DIA_OUTER_LUGS,t=THK_INNER_LUGS*2+0.5,d_pin=1,$fn=FACETS);
            }
            // remove potentiometer interfaces
            P090L_pot(negative=true);
            // screw holes for cover
            Rotation_Pattern(number=2,radius=DIA_OUTER_LUGS/2.7,total_angle=360)
                    cylinder(h=50,d=2.5,center=true,$fn=FACETS);
            // screw holes to hold add-on to BC arm
            rotate([0,0,-90-ang_add/4]) 
                Rotation_Pattern(number=2,radius=DIA_OUTER_LUGS/2.5,total_angle=ang_add)
                    cylinder(h=50,d=2.5,center=true,$fn=FACETS);
            // remove the area for the knob to move
            translate([0,DIA_OUTER_LUGS/1.8,THK_INNER_LUGS-1]) 
                cube([DIA_OUTER_LUGS,DIA_OUTER_LUGS,THK_INNER_LUGS+0.5],center=true);
            translate([0,0,THK_INNER_LUGS-.75]) 
                cylinder(h=THK_INNER_LUGS+1,d=DIA_INNER_LUGS*1.05,center=true,$fn=FACETS);
        }
    }
}
*add_on_pot_joint();  // FOR PRINT
*rotate([0,0,90]) C_End_Knob_model(notch_rotation=-90);
*/
// BC Assembly
module BC_Assy(C_angle=0) {
    // DRAW THE BC ARM 
    color("lightblue",1) BC_Arm_model(len=lenBC,width=widthAB);
    }
*BC_Assy(90);  // Not for print

module Input_Arm_Assembly(B_angle = 0){
    // Display the Input Arm Assembly from the AB arm and on
    // A joint is at [0,0], Second joint is at [length,0]
    
    // DRAW THE AB ARM
    rotate([180,0,0]) AB_Arm_Assy(len=lenAB);
    translate([lenAB,0,4]) rotate([180,0,90]) Pot_Cover_model();
    translate([lenAB,0,4]) rotate([180,0,90]) P090L_pot(negative=false);
    
    translate([lenAB,0,-10]) rotate([0,0,B_angle]) BC_Assy(0);
}
*Input_Arm_Assembly();  // Not for print

module base_assy(T_angle=0) {
    // Fixed part
    joint_visuals(cover=true,cut=false); // not for print
    
    // Moving part
    rotate([0,0,T_angle]) {
        translate([0,0,A_joint_Z]) rotate([0,90,0]) joint_visuals(cover=true,cut=false); // not for print
    }
}
*base_assy(T_angle = 0);  // not for print

*difference () { // DIFFERENCE FOR VIEWING SECTION CUT
    base_assy(T_angle = 90);
    translate([-50,0,-50]) cube([100,100,100],center=false); // SECTION CUT
}

module draw_assy (A_angle=0,B_angle=0,T_angle = 0) {
    // Display the input arm assembly.
    //  This module is not for printing.
    // Input parameters are the angle from the input arm
    //  A and B are the angles of the potentiometers
    //  T is the turntable angle

    base_assy(T_angle = T_angle);
    
    rotate([0,0,T_angle]) // T rotation
        translate([A_joint_X,0,A_joint_Z+THK_TURNTABLE/2]) // translate to A joint location
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
    *translate([0,-100,0]) rotate([-90,0,90]) {
        C_End_Knob_model(notch_rotation=-90);
        Selector_base();
        P090L_pot(negative=false);
    }
}    