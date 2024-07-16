// Robot Arm Parts Object Library
//  Started on 4/6/2020 by SrAmo
//  last modified May 2023 by SrAmo
//use <Pulley-GT2_2.scad>
include <Part-Constants.scad>

// use 140 for printing, 40 for display
FACETS = 40; // [40,140]

module simpleTorus (bigR = 10, littleR = 2) {
    rotate_extrude(convexity = 10)
    translate([bigR, 0, 0])
    circle(r = littleR);
}
simpleTorus($fn = FACETS);

module csk(d=10) {  // Create a countersink (cone)
    rotate_extrude(angle=360,convexity=4) 
        polygon(points=[[0,0],[0,-d],[d,0]]);
}
*csk();

module hole_pair (x = 50,y=10,d=hole_M3,h=20,csk=false) {
    // make a pair of holes that are y appart, 
    // at x location. holes are parallel to the Z axis
    // Created for zip tie holes
    $fn=$preview ? 16 : 32; // minimum angle fragment
    translate ([x,-y/2,0]) cylinder(h=h,d=d,center=true);
    translate ([x,y/2,0]) cylinder(h=h,d=d,center=true);
    if(csk) {
        translate ([x,-y/2,h/2]) csk(d=d*1.2);
        translate ([x,y/2,h/2]) csk(d=d*1.2);
    }
}
*hole_pair(csk=true);

module hole_pair_2D (x = 50,y=10,d=hole_M3) {
    // 2D version of hole pair
    // make a pair of holes that are y appart, 
    // at x location. holes are parallel to the Z axis
    // Created for zip tie holes
    $fn=$preview ? 16 : 32; // minimum angle fragment
    translate ([x,-y/2,0]) circle(d=d);
    translate ([x,y/2,0]) circle(d=d);
}

module Cbore_Screw_Hole(d=3,h=21,cb_d=7,cb_h=2) {
    // Hole for a screw with counter bore, to hid the head
    $fn=$preview ? 16 : 32; // minimum angle fragment
    translate([0,0,h/2-0.1])cylinder(h=h,d=d,center=true);
    translate([0,0,-cb_h/2]) cylinder(h=cb_h,d=cb_d,center=true);
}
*Cbore_Screw_Hole(d=3,h=16,cb_d=7,cb_h=2);

module filled_donut(t=10,d=50, r = 2) {
    // t = donut thickness,   d = donut diameter, r = fillet radius
    // Fillet radius must be less than d/4.
    $fn=$preview ? 20 : 72; 
    if (r < d/4) {
        hull() {
        translate([0,0,t/2-r]) 
            rotate_extrude(convexity = 10) translate([(d/2)-r/2, 0, 0]) 
                circle(r = r);
        translate([0,0,-t/2+r]) 
            rotate_extrude(convexity = 10) translate([(d/2)-r/2, 0, 0]) 
                circle(r = r);
        }
    } else {
        echo("ERROR in Filled Donut. Fillet radius must be less than d/4");
    }
}
*filled_donut();

module zip_tie_holes (arm_l = 10,arm_w=1,zip_hole_d = hole_M3) {
    rotate([90,0,0]) {
        translate ([.15*arm_l,.35*arm_w,-arm_w]) cylinder(h=4*arm_w,d=zip_hole_d,center=true);
        translate ([.15*arm_l,.65*arm_w,-arm_w]) cylinder(h=4*arm_w,d=zip_hole_d,center=true);
        translate ([.5*arm_l,.35*arm_w,-arm_w]) cylinder(h=4*arm_w,d=zip_hole_d,center=true);
        translate ([.5*arm_l,.65*arm_w,-arm_w]) cylinder(h=4*arm_w,d=zip_hole_d,center=true);
        translate ([.85*arm_l,.35*arm_w,-arm_w]) cylinder(h=4*arm_w,d=zip_hole_d,center=true);
        translate ([.85*arm_l,.65*arm_w,-arm_w]) cylinder(h=4*arm_w,d=zip_hole_d,center=true);
    }
}
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
*rounded_cube(center=false,$fn=48);

module lug (r=1,w=3,h=2,t=.2,d=0) {
    // Create a lug part on the xy plane, thickness t from z=0
    //   base is on y=0 and has width w
    //   center of lug is at [0,h] with radius r
    opp=(w-2*r)/2;
    ang=atan2(opp,h);
    y=h+r*sin(ang);
    x=r*cos(ang);
    difference() {
        union () {
            translate([0,h,t/2])   
                cylinder(h=t,r=r,center=true);
    
            linear_extrude(height = t, convexity=10)
                polygon(points=[[-w/2,0],[w/2,0],[x,y],[-x,y],[-w/2,0]]);
        }
        if (d != 0) translate([0,h,t/2])  
            cylinder (h=3*t,d=d,center=true);
    }
}
module simple_link (l=50,w=5,t=4,d=1,cored=0) {
    // Simple two force link, normal to xy plane, pointing x
    // l=Lenth, w=Width, t=Thickness, d=Pin bore Diameter, cored = Core diameter
    $fa=$preview ? 6 : 1; // minimum angle fragment
    difference () {
        hull () {
            cylinder (h=t,d=w,center=false);
            translate([l,0,0])
                cylinder (h=t,d=w,center=false);
        }
        if (d != 0) {
            cylinder (h=3*t,d=d,center=true);
            translate([l,0,0])
                cylinder (h=3*t,d=d,center=true);
        }     
        if (cored != 0) {
            translate([0,0,t/2]) rotate([0,90,0]) 
                cube([cored,cored,3*l],center=true);
                //cylinder (h=3*l+2*w,d=cored,center=true);
        }     
    }
}
*simple_link();

module dog_leg2(len1=50,ang=90,len2=50,w=15,t=15) {
    // Create a Dog Leg Link on the xy plane, along x axis
    // Lugs at both ends
    // Angles between 0 and 90 only
    // First length is len1, turn is ang, second length is len2
    // Thickness is t, positive z from zero
    // Width is w
    // Sharp knee is better for printing
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=0.02; // minimum size of fragment (default is 2)
    if (ang>=0 && ang <=90) {
        dx = len1 + len2*cos(ang); // x of end of leg
        dy = len2*sin(ang);      // y of end of leg
        Pdist = sqrt(len1*len1+len2*len2);
        xtra=tan(ang/2)*(w/2);
        chmf = 0.03*Pdist;  // inside chamfer size
        rotAng = atan2(dy,dx);
        rotate([0,0,-rotAng]) translate ([0,0,0]) 
            union () {
                translate([0,-w/2,0]) // first leg
                    cube([len1+xtra,w,t],center=false);
                cylinder(h=t,d=w,center=false); // rounded end len1
                translate([len1,0,0])   // second leg
                    rotate([0,0,ang])
                        translate([-xtra,-w/2,0])
                            cube([len2+xtra,w,t],center=false);
                translate([dx,dy,0])   // rounded end len2
                    cylinder(h=t,d=w,center=false);
                // add inside chamfer
                color("yellow") 
                linear_extrude(height=t,convexity=10) 
                    polygon([[len1,0],
                        [len1-xtra-chmf,w/2],
                        [len1-xtra+chmf,w/2+chmf*sin(ang)]]);
        }
    }
}
dog_leg2();

module dog_leg (len1=10,ang=45,len2=5,w=2,t=1) {
    // Create a Dog Leg part on the xy plane, along x axis
    // First length is len1, turn is ang, second length is len2
    // Thickness is t, positive z from zero
    // Width is w
    // Sharp knee is better for printing
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=0.02; // minimum size of fragment (default is 2)
    dx = len1 + len2*cos(ang); //x of end of leg
    dy = len2*sin(ang);      // y of end of leg
    Pdist = sqrt(dx*dx+dy*dy);
    xtra=tan(ang/2)*(w/2);
    len1xtra=len1-xtra;
    chmf = 0.02*Pdist;  // inside chamfer size
    translate ([0,-dy,0]) 
        union () {
        translate([0,-w/2,0]) // first leg
            cube([len1+xtra,w,t],center=false);
        translate([len1,0,0])   // second leg
            rotate([0,0,ang])
                translate([-xtra,-w/2,0])
                    cube([len2+xtra,w,t],center=false);
        translate([dx,dy,0])   // rounded end
            cylinder(h=t,d=w,center=false);
        linear_extrude(height=t,convexity=10) // add inside chamfer
            polygon([[len1xtra,w/2],
            [len1xtra-chmf,w/2],
            [len1xtra+chmf,w/2+chmf*tan(ang)],
            [len1xtra+chmf,w/2],
            [len1xtra,w/2]]);
    }
}
*dog_leg();
module fancy_dog_leg (len1=50,ang=45,d2=20,w=15,t=25,d_pin=1,wall=3) {
    // Create dog leg with center and pin-holes removed
    // padeye is the same thing as a lug 
    // The padeyes will fit a pin of diameter d_pin
    // wall is the wall thickness of the link
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=0.1; // minimum size of fragment (default is 2)
    dx = len1 + d2*cos(ang);
    dy = d2*sin(ang);
    t_inside = t-2*wall; // z direction
    w_inside = w-2*wall; // y direction
    clevis_r = (d2<w) ? w : d2/1 ;
    fillet_r = t/3;
    difference() {
        dog_leg(len1,ang,d2,w,t);
        
        translate([dx,0,-t/2])   // hole for pin
            cylinder(h=t*2,d=d_pin,center=false);
        
        // remove rounded cube to make clevis
        translate([dx-1.05*w,w,t_inside+wall])   
            rotate([-15,90,-90])
            rounded_cube([t_inside,4*w_inside,len1+d2],fillet_r,center=false);
    }
}
module hollow_offset_link (length=50,d_pin=2,w=10,t=10,offset=5,ang=45,wall=2) {
    // Create a Hollow Offset Link on xy plane along the X axis 
    // First joint is at [0,0], Second joint is at [length,0]
    // padeye is the same thing as a lug 
    // The padeyes will fit a pin of diameter d_pin
    // link width is w (y dimension), constant along length of part
    // thickness is t, positive z from zero
    // offset is the distance down from the x axis
    // ang is the dog leg angle
    // wall is the wall thickness of the link
    
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=0.1; // minimum size of fragment (default is 2)
    d2 = offset/sin(ang);   // length of second dog leg segment
    d1 = length/2 - d2*cos(ang); // length of first dog leg segment
    fillet_r = t/4;        
    difference () {
        translate ([length/2,0,0])
            rotate ([0,0,180]) // flip the offset up
            union () {
                fancy_dog_leg (d1,ang,d2,w,t,d_pin,wall);
                mirror ([1,0,0]) // make a mirror copy
                    fancy_dog_leg (d1,ang,d2,w,t,d_pin,wall);
            }
        // subtract the long hole
        translate([length/2,offset,w/2])
            rotate([0,90,0])
            cylinder(h=length,d=w/2,center=true);
        // subtract the zip tie holes    
        zip_tie_holes (arm_l=length,arm_w=w);
    }
}

module fork (l_fork=2,d_fork=0.2) {
    $fa=$preview ? 6 : 1; // minimum angle fragment
    difference() {
        cylinder(h=l_fork,d1=6*d_fork/4,d2=3*d_fork/4,center=true);
        translate([-d_fork/2,-d_fork*1.5,0])
            rotate([-5,0,0])
                cube([d_fork,d_fork,l_fork],center=false);
    }
}
module servo_connection(len=100,t1=2,t2=38) {  // Sub module
    // Compliant Beam that connects Claw to Servo
    
    module subtract_1 () { // profile of links to servo
        linear_extrude(height = t2, convexity=10)
        polygon(points=[[0,0],[-len/5,-poly_z/2],[-len/1.2,-poly_z],[-len*2,-poly_z],[-len*2,t2/2],[0,0]]);
    }  
    
    poly_z = t2/2;   
    servo_lug_h = len/2.2; // Smooth transition to lug. manage the stress at the lug.
    len2 = len-hole_servo_bushing;

    difference () {
        union() {
            // Link to the servo
            translate ([servo_lug_h-len,0,0]) rotate ([0,0,90])
                lug (r=1.5*hole_servo_bushing,w=t1,h=servo_lug_h,t=t2,d=hole_servo_bushing,$fn=32);
            translate([-len+hole_servo_bushing,-t1/2,0]) 
                linear_extrude(height=t2, convexity=10) 
                    polygon(points=[[len2,3*t1],[len2-t1,t1],[0,t1],[0,0],[len2-t1,0],[len2,-2*t1]]);
        }
        // subtract lug features
        translate ([0,-t2/2,0]) rotate ([-90,0,0]) subtract_1();
        //translate ([0,link_adjust+t2,t2]) rotate ([90,0,0]) subtract_1();
    }
}
*translate([0,0,50]) servo_connection(len=52,t1=2,t2=25);

module curved_beam(rot1 = 180, radOfCurve = 20, t1 = 5, t2 = 10) {
    // curved beam
    rotate_extrude(angle=rot1,convexity = 20)
        translate([radOfCurve, 0, 0])
            square([t1,t2],center=false); // on X,Z plane
}
*curved_beam(rot1 = 135, $fn=64);


module pulley(r=2,t=.5,d_pin=0.25,d_grv=0.25,round=true){
    // Create pulley on xy plane at 0,0,0 of radius r
    // t is thickness (centered about z=0)
    // Add option for V-groove 4/22/2020
    $fa=$preview ? 6 : 1; // minimum angle fragment

    difference(){
        cylinder(t,r=r,center=true);  // outside of pulley
        
        // subtract bore
        cylinder(2*t,d=d_pin,center=true);
        
        // subtract outside groove 
        pulley_groove(r=r,d_grv=d_grv,round=round);
    };

}
module pulley_groove(r=2,d_grv=0.25,round=true){
    // Create pulley groove on xy plane at 0,0,0 of radius r
    // Add option for V-groove 4/22/2020
    $fa=$preview ? 6 : 1; // minimum angle fragment

    // subtract outside groove 
    rotate_extrude(convexity = 10)
        if (round) {  // draw a round groove
            translate([r, 0, 0])
            circle(d = d_grv);
        } else {   // draw a V-groove
            translate([r,0,0]) 
            hull () {
                translate([-d_grv/4,0,0])
                    circle(d=d_grv/2);
                translate([d_grv/2,0,0])                    square([d_grv,d_grv],center=true);
            }
        }
}
module washer(d=20,t=2,d_pin=10,center=true){
    // model washer on xy plane at 0,0,0 of radius r
    // t is thickness (centered about z=0)

    difference(){
        cylinder(t,d=d,center=center);  // outside
        
        // subtract bore
        cylinder(3*t,d=d_pin,center=true);
    };
}
*washer(d_pin=0,$fn=FACETS);

module RoundedWasher(d=20,t=2,d_pin=10,fillet=3) {
    difference() {
        hull() {
            translate([0,0,t-fillet]) 
                rotate_extrude(convexity = 10)
                translate([d/2 - fillet, 0,0])
                    circle(r = fillet);
            translate([0,0,-t+fillet]) 
                rotate_extrude(convexity = 10)
                translate([d/2 - fillet, 0,0])
                    circle(r = fillet);
        }
        translate([-d*2,-d*2,-d*4]) cube(d*4);
    }
}
*RoundedWasher(d=20,t=3,fillet=2,$fn=FACETS);

module tension_spring(from=[10,0,0],to=[20,30,20],wire_dia=0.5,od=2,coils=10,ends=true){
    // Create a tenstion spring
    // LINEAR EXTRUDE DOES NOT PRODUCE TRUE COIL
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=wire_dia/2; // minimum size of fragment (default is 2)
    vec=to - from;
    length=norm(vec);
    dx = vec[0];
    dy = vec[1];
    dz = vec[2];

    if (length != 0) {  // check for non zero vector
        
        // These are the angles needed to rotate to correct direction
        ay = 90 - atan2(dz, sqrt(dx*dx + dy*dy));
        az = atan2(dy, dx);
        angles = [0, ay, az];
        
        translate (from) 
        rotate (angles) 
        linear_extrude(height=length,center=false,convexity=10,twist = coils*360)
            translate([od/2, 0, 0]) circle(d = wire_dia);  
        
        if (ends) { // draw spheres at the ends, for debugging
            translate (from) sphere(d=wire_dia);
            translate (to) sphere(d=wire_dia);
        }
    } else {
        echo("MODULE TENSION_SPRING; small spring = ",slength," or render");
    }
}
*tension_spring (from=[20,0,0],to=[50,30,50],wire_dia=1,od=2,coils=20);

module torsion_spring(deflection_angle=180,OD=1,wire_d=.1,leg_len=2,coils=5,LH=true,inverse=false) {
    // deflection_angle is not implimented
    
    //if (deflection_angle != 180) echo("ONLY 180 DEG TORSION SPRINGS IMPLEMENTED");
        
    turn_sign = LH ? 1 : -1 ;  // used for LH or RH springs
    sp_len = (coils+1)*wire_d;
    //echo(sp_len=sp_len);
    ID = OD-2*wire_d;
    difference () {
        cylinder(h=sp_len,d=OD);
        if (inverse == false) translate([0,0,-sp_len*0.05]) 
            cylinder(h=sp_len*1.1,d=ID);
    }
    
    // straight legs on each end
    x_offset = OD/2 - wire_d/2;
    WD = (inverse != false) ? wire_d*1.25 :  wire_d;
    LL = (inverse != false) ? leg_len*1.25 :  leg_len;
    
    leg_rot = 180-deflection_angle;
    rotate([0,0,leg_rot]) translate([x_offset,turn_sign*LL/2,0]) 
        rotate([90,0,0]) 
            hull() {
                if (inverse) translate([0,WD/2,0]) cylinder(h=LL,d=WD,center=true,$fn=16);
                cylinder(h=LL,d=WD,center=true,$fn=16);
            }
    translate([x_offset,-1*turn_sign*LL/2,sp_len]) 
        rotate([90,0,0]) 
            hull() {
                cylinder(h=LL,d=WD,center=true,$fn=16);
                if(inverse) translate([0,-WD/2,0]) cylinder(h=LL,d=WD,center=true,$fn=16);
            }
}
*torsion_spring (deflection_angle=9271K619_angle,OD=9271K619_OD,wire_d=9271K619_wd,leg_len=9271K619_len,coils=9271K619_coils,LH=9271K619_LH);
*translate([-30,0,0]) torsion_spring (deflection_angle=9271K619_angle,OD=9271K619_OD,wire_d=9271K619_wd,leg_len=9271K619_len,coils=9271K619_coils,LH=9271K619_LH, inverse=true);
*torsion_spring (deflection_angle=9271K589_angle,OD=9271K589_OD,wire_d=9271K589_wd,leg_len=9271K589_len,coils=9271K589_coils,LH=9271K589_LH,inverse=false);

module pt_pt_cylinder (from=[10,10,0],to=[-10,0,-10], d = 2){
    // Create a cylinder from point to point
    
    vec=from-to;
    length=norm(vec);
    dx = -vec[0];
    dy = -vec[1];
    dz = -vec[2];

    if (length>0.01) {  // check for non zero vector
        
        // "cylinder" is centered around z axis
        // These are the angles needed to rotate to correct direction
        ay = 90 - atan2(dz, sqrt(dx*dx + dy*dy));
        az = atan2(dy, dx);
        angles = [0, ay, az];
        
        translate (from) 
        rotate (angles) 
        cylinder(length,d = d,false);  
    }else {
        echo("MODULE PT_PT_CYLINDER; small length =",length);
    }
}

*pt_pt_cylinder(to=[100,0,100],from=[0,0,100],d=10);

module pt_pt_bar (from=[10,10,0],to=[-10,0,-10], d = 2){
    // Create a cylinder from point to point
    
    vec=from-to;
    length=norm(vec);
    dx = -vec[0];
    dy = -vec[1];
    dz = -vec[2];

    if (length>0.01) {  // check for non zero vector
        
        // "cylinder" is centered around z axis
        // These are the angles needed to rotate to correct direction
        ay = 90 - atan2(dz, sqrt(dx*dx + dy*dy));
        az = atan2(dy, dx);
        angles = [0, ay, az];
        
        translate (from) 
        rotate (angles) 
        linear_extrude(length, convexity=10) square(d,center=true);
    }else {
        echo("MODULE PT_PT_CYLINDER; small length =",length);
    }
}
*pt_pt_bar(to=[100,0,100],from=[0,50,100],d=2.54);

module pt_pt_belt (from=[10,10,10],to=[-10,0,10], d = 1,r_pulley=30,round=true){
    // Create belts from point to point
    
    // default is round belt
    // if round = false, then draw a GT2-6 belt
    gt2t=1; // thickness (1 mm)
    gt2w=6; // width (6 mm)
    
    vec= from - to;
    length=norm(vec);
    dx = -vec[0];
    dy = -vec[1];
    dz = -vec[2];
    from_up = [from[0]+(dy/length)*r_pulley,from[1]-(dx/length)*r_pulley,from[2]];
    from_down = [from[0]-(dy/length)*r_pulley,from[1]+(dx/length)*r_pulley,from[2]];

    if (length>0.01) {  // check for non zero vector
        echo("MODULE PT_PT_BELT; length =",length*2+2*r_pulley*PI);
        // "cylinder" is centered around z axis
        // Angles to rotate to correct direction
        ay = 90 - atan2(dz, sqrt(dx*dx + dy*dy));
        az = atan2(dy, dx);
        angles = [0, ay, az];
        
        translate (from_up) 
            rotate (angles) 
                if (round) 
                    cylinder(length,d = d,center=false);  
                else {
                    translate ([-gt2w/2,-gt2t/2,0])
                    cube([gt2w,gt2t,length],center=false);
                }
        translate (from_down) 
            rotate (angles) 
                if (round) 
                    cylinder(length,d = d,false);  
                else {
                    translate ([-gt2w/2,-gt2t/2,0])
                    cube([gt2w,gt2t,length],center=false);
                }
        translate(from)
            rotate([0,0,az+90])
                rotate_extrude(angle=180,convexity = 10)
                    translate([r_pulley, 0, 0])
                        if (round) circle(r = d/2);
                        else square([gt2t,gt2w],center=true);
        translate(to)
            rotate([0,0,az-90])
                rotate_extrude(angle=180,convexity = 10)
                    translate([r_pulley, 0, 0])
                        if (round) circle(r = d/2);
                        else square([gt2t,gt2w],center=true);
    }else {
        echo("MODULE PT_PT_BELT; small length =",length);
    }
}
*color ("black") pt_pt_belt (round=false);
*color ("grey") pt_pt_belt ([20,0,0],[-200,-100,0],round=true);

module cross_belt(a=[0,0,0],b=[5,0,0],r=1, d = 0.1,right=true){
    // Create a Cross Belt cylinder from pulley a to pulley b
    // of radius r and wire diameter d
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=0.1; // minimum size of fragment (default is 2)
    
    vec=b - a;
    length=norm(vec);
    if (length>2*r) {  // check for feasible
        phi=right ? acos(r/(length/2)) : -acos(r/(length/2));
        az=atan2(-vec[1],-vec[0]); // angle of ab vector on xy plane
        a_tangent = a + [r*cos(az-phi),r*sin(az-phi),0];
        b_tangent = b + [r*cos(az+(180-phi)),r*sin(az+(180-phi)),0];
        
        pt_pt_cylinder(a_tangent,b_tangent,d);
    }else {
        echo("MODULE CROSS_BELT; points too close = ",length);
    }
}
module balance_weight(l=3,r=1,t=.5,d_pin=0.25,d_grv=0.25){
    // Create balance_weight on xy plane at 0,0,0 of radius r
    // t is thickness (centered about z=0)
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=0.1; // minimum size of fragment (default is 2)
    ang=60;

    d1 = (l/2)/cos(ang/2);
    difference () {
        union () {
           translate ([0,0,t/2])
            pulley_gt2_2 ( teeth = 80 , pulley_t_ht = 7);
            cylinder(t,r=r,center=true);
        };
        // subtract bores
        cylinder(4*t,d=d_pin,center=true);
        translate ([l,0,0]) 
            cylinder(4*t,d=d_pin,center=true);
    }
}
module servo_horn (l=servo_horn_l, d1=servo_horn_d1, d2=servo_horn_d2, t=servo_horn_t,vis=true){
    // Create servo horn on xy plane, spline center at 0,0,0
    // horn length l pointing along x axis
    // spline end dia d1, other end d2, thickness t, from z=0 up
    // used for BOOLEAN SUBTRACTION set vis = false
    $fn=$preview ? 24 : 48; // minimum angle fragment
    difference () {
        union () {
            translate([0,0,t/2])
                cylinder(t,d=d1,center=true);
            translate([l,0,t/2])
                cylinder(t,d=d2,center=true);
            translate([0,-d2/2,0])
                cube([l,d2,t],center=false);
            rotate([0,0,-90])
                lug (r=d2/2,w=d1,h=l/2,t=t);
            if (!vis) {
                // SCREW HOLE FOR SECURING HORN
                translate([l*.85,0,t/3]) rotate([90,0,0]) cylinder(h=2*l,d=2.8,center=true);
            }
        }
        // subtract main axis cyl for visulization
        if (vis) cylinder (h=4*t,d=2,center=true);
    }
}
*servo_horn(vis=false);

module svoScrews() { // 2D pattern
    translate([-svo_shaft,0,0]) 
        rectPattern(svo_screw_l,svo_screw_w) 
            circle(d=3.5);  // min dia for 1/8" mill
}
module svo2D() { // for SVG, for X-carve
    svoScrews($fn=24);
    translate([-svo_shaft,0,0]) square([svo_l,svo_w], center=true);
}
*svo2D();  // 2D

module servo_body (vis=true){ // true = normal,  false = for subtraction
    // Create servo body on xy plane, spline shaft center at 0,0,0
    // long body direction along -x axis
    // body from z=0 down
    // used for BOOLEAN SUBTRACTION set vis = false
    $fn=$preview ? 24 : 48; // minimum angle fragment

    color("FireBrick") difference () {
        union () {
            translate([-svo_shaft,0,-svo_d/2]) // main body
                rounded_cube(size=[svo_l,svo_w,svo_d],r=.8,center=true,$fn=24); 
            
            translate([-svo_shaft,0,-svo_flange_d-svo_flange_t/2])  // flange
                rounded_cube(size=[svo_flange_l,svo_w,svo_flange_t],r=.8,center=true);
            
            translate([-svo_shaft,0,-8.9])
                cube(size=[svo_flange_l,2.54,4],center=true); // gussetts
            
            // cylinders for screw starts
            if (vis)  {
                cylinder (h=10,d=5,center=true);
            } else {
                translate([0,0,-40]) linear_extrude(60,convexity=10) svoScrews();
            }
        }
        // subtract main axis cyl for visulization
        if (vis) {
            cylinder (h=4*svo_d,d=4,center=true);
            translate([0,0,-20]) linear_extrude(20,convexity=10) svoScrews();
        }
    }
}
*servo_body(vis=true);

module servo_shim (l=61,w=25.4,t=3) {
    $fa=$preview ? 6 : 1; // minimum angle fragment
    flange_z = -9.65;
    difference () {
        translate([-svo_shaft,0,flange_z+t/2]) cube([l,w,t],center=true);
        servo_body (vis=false,$fn=16);
    }
}
*servo_shim();

module servo_shim_spacer(l=svo_flange_l,w=svo_w-1,t=1.5) {
    $fa=$preview ? 6 : 1; // minimum angle fragment
    flange_z = -9.65;
    difference () {
        translate([-svo_shaft,0,flange_z+4]) cube([l,w,t],center=true);
        servo_body (vis=false,$fn=16);
    }
}
*servo_shim_spacer();

module half_inch_hex_hub() { // modeled after ServoCity 0.500" Hex Clamping Hub SKU 545674 
    color("Silver")  difference() {
        translate([0,0,0.1]) washer(d=1/mm_inch, t=0.275/mm_inch,d_pin=0.3/mm_inch,center=false);
        rotate([0,0,45])Rotation_Pattern(number=4,radius=0.385/mm_inch,total_angle=360) 
            cylinder(h=50,d=0.125/mm_inch,center=false,$fn=12);
        hex (size=0.5/mm_inch,l=30);

    }
}
*half_inch_hex_hub();

module servo_hub() { // modeled after ServoCity servo hub SKU: 525123
    difference() {
        translate([0,0,0.799/mm_inch]) 
            washer(d=1/mm_inch, t=0.2/mm_inch,d_pin=0.3/mm_inch,center=false);
        Rotation_Pattern(number=8,radius=0.385/mm_inch,total_angle=360) 
            cylinder(h=50,d=0.135/mm_inch,center=false,$fn=12);
    }
    washer(d=0.5/mm_inch,t=0.8/mm_inch,d_pin=0.3/mm_inch,center=false);
}
*servo_hub();

module svo_block_ring (thk=0.2/mm_inch) { // represents side of servo block
    difference() {
        washer(d=1.05/mm_inch, t=thk,d_pin=0.3/mm_inch,center=false);
        Rotation_Pattern(number=8,radius=0.385/mm_inch,total_angle=360) 
            cylinder(h=thk*5,d=0.135/mm_inch,center=true,$fn=24);
    }
}
*svo_block_ring(thk=25,$fn=48);

module servo_block(angle=0) { // modeled after ServoCity Hub Shaft ServoBock SKU: 637112
    servo_body(vis=true);
    color("Silver") {
        servo_shim(l=2.41/mm_inch,w=1.31/mm_inch);
        translate([0,0,2]) rotate([0,0,angle]) servo_hub();
        translate([0,1.31/2/mm_inch,5.5]) rotate([90,0,0]) svo_block_ring();
        translate([0,-1.31/2/mm_inch,5.5]) rotate([90,0,180]) svo_block_ring();
    }
}
*servo_block(angle=10);

module GT2_2_idle_pulley () {
    // draw in inches (always scaled)
    color ("Silver") 
        translate ([0,0,GT2pulleyt/2])
        difference () {
            cylinder(h=GT2pulleyt,d=GT2pulleyd+6,center=true);
            cylinder(h=GT2pulleyt+1,d=hole_M5,center=true);
            difference () {
                cylinder(h=GT2pulleyt-2,d=GT2pulleyd+8,center=true);
                cylinder(h=GT2pulleyt,d=GT2pulleyd,center=true);
            }
    }
}
module Bearing (t=4,od=30,id=25) {
    $fn=64; 
    color ("Grey") 
    difference () {
        translate ([0,0,-t])
        // main body, slightly undersize for assembly visibility
        cylinder(h=t,d=od*.98,center=false); 
        cylinder(h=t*3,d=id,center=true); // center hole
    }
}
*Bearing();
module Bearing_Flanged (t=2,flange_t=1,od=3,id=1,flange_od=4) {
    $fn=64; 
    color ("SlateGrey") 
    difference () {
        union() {
            translate ([0,0,-t])
                // main body, slightly undersize for assembly visibility
                cylinder(h=t,d=od*.98,center=false); 
            
            // flange, slightly less thick for assembly visibility
            cylinder(h=flange_t*.98,d=flange_od,center=false);
        }
    cylinder(h=t*3,d=id,center=true); // center hole
    }
}
*Bearing_Flanged (); // default

*translate([15,0,0]) Bearing_Flanged (t=Qtr_bearing_t,flange_t=Qtr_bearing_flange_t,od=Qtr_bearing_od,id=Qtr_bearing_id,flange_od=Qtr_bearing_flange_od);

*translate([35,0,0]) Bearing_Flanged (t=Half_bearing_t, flange_t=Half_bearing_flange_t,od=Half_bearing_od,id=Half_bearing_id,flange_od=Half_bearing_flange_od);

*translate([-10,0,0]) Bearing_Flanged (t=M6_bearing_t,flange_t=M6_bearing_flange_t,od=M6_bearing_od,id=hole_M6,flange_od=M6_bearing_flange_od);

module Screw(length=10,dia=3) {
    // Draw Round Head Screw of length and diameter
    // Ratio of Head Diameter and Height determined by looking at Rounded Head Thread-Forming Screws for Plastic
    color ("DarkSlateGrey") 
    union () {
        cylinder(h=length,d=dia,center=false,$fn=16);
        rotate_extrude(convexity=10,$fn=16) 
            polygon( points=[[0,0],[dia*.95,0],[dia*.95,-dia*.5],[dia/1.5,-dia*.75],[0,-dia*.75],[0,0]] );
    }
}
*Screw();

module hex (size=20,l=10) {
    // Make a hex extrution with distance across flats = size
    // centered on xy=0 and up l from z=0
    // generate a list with the hex points
    hypotenuse = (size/2.0) / cos(30);
    hexP = [ for (i=[0:60:360]) [hypotenuse*cos(i),hypotenuse*sin(i)] ];
    //echo(hypotenuse=hypotenuse,hexP=hexP);
    linear_extrude(height=l,convexity=10) 
        polygon( points=hexP );
}
*hex();

lenPin=7; // P090 electrical pin length constant
L_pot_shaft = 13.1;  // P090 shaft length above the body

module P090S_pot (negative=false) {
    // units are in metric
    // The P090S (Style S) has the three pins off of the TOP
    // Solder the wires to the pins (need solid connection)
    // negative false = model a potentiometer for display
    // negative true = model to be used with a difference() in another model
    
    ss = negative ? 1.0: 0.97;  // if negative false then scale down
    // constants
    zbody = 5.1;
    zb = zbody+10;
    zpin = -4-lenPin;

    scale([ss,ss,ss]){ // scale down the model for display
        color("green") if (!negative) { // potentiometer for display
            translate([0,0,-zbody/2]) cube([10,12,zbody],center=true);
        } else {         // potentiometer for difference()
            translate([0,0,-zb/2]) cube([10,17,zb],center=true);
            // barb slots for wire connector
            translate([1.6,8.4,-zb]) cube([1.5,1,zb],center=false);
            translate([-1.22-1.9,8.4,-zb]) cube([1.5,1,zb],center=false);
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
                translate ([-5,-L_pot_shaft-1.45,5]) cube(L_pot_shaft,center=false); // key
        }
        // pins (3)
        translate([0,7,zpin]) elect_pin();
        translate([-2.5,7,zpin]) elect_pin();
        translate([2.5,7,zpin]) elect_pin();
        // clip
        clip();
        mirror([1,0,0]) clip();
        // wire connector
        //color("ivory") translate([0,6,-10]) cube([8,4,8],center=true);
    }
     
    module elect_pin() {
        // 1 mm diamater electric pin
        cylinder(h=lenPin,r=.5,$fn=8);
        translate([0,0,lenPin]) rotate([90,0,0]) cylinder(h=lenPin,r=.5,$fn=8);
    }
    module clip() {
        translate([4.9,0,0]) rotate([90,90,0])
        linear_extrude(3,center=true, convexity=10)
            polygon([[0,0],[8.5,0],[9.5,1],[10.5,0],[12,0],[12,-1],[0,-1],[0,0]]);
    }
}
*P090S_pot(negative=true);
*translate([20,0,0]) P090S_pot(negative=false);

module P090L_pot (negative=false) {
    // The P090L (Style L) has the three pins off of the side
    // Digi-key part no. P090S-04F20BR10K or P090S-14T20BR10K
    // https://www.digikey.com/en/products/detail/tt-electronics-bi/P090S-04F20BR10K/2408853 
    // https://www.mouser.com/ProductDetail/BI-Technologies-TT-Electronics/P090S-14T20BR10K
    // Solder the wires to the pins (need solid connection). Pins can be easily bent.
    // Cut off connectors to reduce installation volume with small diagonal cutters.
    // negative false = model a potentiometer for display
    // negative true = model to be used with a difference() in another model
    L_pot_shaft = 13.1;  // P090 shaft length above the body (mm)
    zbody = 5.5;  // all units are mm
    
    ss = negative ? 1.0: 0.97;  // if negative == false then scale down
    // constants
    zbDif = zbody+1;  // make body bigger for difference()

    scale([ss,ss,ss]){ // scale down the model for display
        color("green") 
        if (!negative) { // potentiometer for display
            translate([0,0,-zbody/2]) cube([10,12,zbody],center=true);
            // two cylinders on backside, drawn larger than real
            translate([0,-8.5/2,-zbody]) cylinder(h=4,d=3,center=true,$fn=FACETS);
            translate([0,8.5/2,-zbody]) cylinder(h=4,d=3,center=true,$fn=FACETS);

        } else {         // potentiometer for difference()
            translate([0,0,-zbDif/2]) cube([10,12.5,zbDif],center=true);
            translate([0,-12.5,-zbDif/2]) cube([10,30,zbDif],center=true);
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
P090L_pot(negative=true);
*translate([20,0,0]) P090L_pot(negative=false);

module RV112FF_pot (L=19,negative=false) {
    // units are in metric
    // negative false = model a potentiometer for display
    // negative true = model to be used with a difference() in another model
    // L = length of the shaft above the body
    
    ss = negative ? 1.0: 0.97;  // if negative is false then scale down
    // constants
    zbody = 5.1;
    zb = zbody+10;
    lenPin=7;
    zpin = -4-lenPin;

    scale([ss,ss,ss]){ // scale down the model for display
        color("green") if (!negative) { // potentiometer for display
            translate([0,0,-zbody/2]) cube([12,16,zbody],center=true);
        } else {         // potentiometer for difference()
            translate([0,0,-zb/2]) cube([12,22,zb],center=true);
            // barb slots for wire connector
            translate([3.5,11,-zb/2]) cube([2,2,zb],center=true);
            translate([-3.5,11,-zb/2]) cube([2,2,zb],center=true);
        }
        
        cylinder(h=10,d=9,center=true,$fn=48); // ring around the shaft
        
        // two bumps around the shaft
        translate([4,-5,0]) cylinder(h=2,d=2.5,center=true,$fn=24);
        translate([-4,5,0]) cylinder(h=2,d=2.5,center=true,$fn=24);
        
    
        // shaft F-Type
        color("darkslategrey") difference () {
            translate([0,0,L/2]) cylinder(h=L,d=6.2,center=true,$fn=48);
            translate ([-5,1.45,5]) cube(L,center=false); // key
        }
        // pins (4)
        translate([-3.75,10,zpin]) elect_pin();
        translate([-1.25,10,zpin]) elect_pin();
        translate([1.25,10,zpin]) elect_pin();
        translate([3.75,10,zpin]) elect_pin();
        // clip
        clip();
        mirror([1,0,0]) clip();
        // wire connector
        if (!negative) color("ivory") translate([0,10,-10]) cube([11,4,8],center=true);
    }
     
    module elect_pin() {
        // 1 mm diamater electric pin
        cylinder(h=lenPin,r=.5,$fn=8);
        translate([0,0,lenPin]) rotate([90,0,0]) cylinder(h=lenPin,r=.5,$fn=8);
    }
    module clip() {
        translate([6,0,0]) rotate([90,90,0])
        linear_extrude(3,center=true, convexity=10)
            polygon([[0,0],[8.5,0],[9.5,1],[10.5,0],[12,0],[12,-1],[0,-1],[0,0]]);
    }
}
*RV112FF_pot(negative=true);
*translate([20,0,0]) RV112FF_pot(negative=false);

module pot_joint(pot=true,lug_two = true,tlug = 8) {
    // If pot = true then model the side that holds the pot
    // Else model the lug that goes on the shaft
    dbody = 30;
    zbody = 16;
    dlug = 20;
    fascets = 120;
    difference () {
       // lug
        union() {
            if (pot) {
                translate([0,0,-zbody/2+1]) washer(d=dbody,t=zbody,d_pin=1,$fn=fascets);
                //translate([0,0,2.4]) washer(d=dbody-10,t=5,d_pin=1,$fn=fascets);
                translate([0,dbody/2-2,-zbody/2+1]) rotate([90,0,0]) cube([60,zbody,4],center=true);
                
                // lug opposite pot.  Large hole for access
                if (lug_two) translate([0,0,5+4+tlug]) washer(d=dbody,t=8,d_pin=7,$fn=fascets); 
            } else { // lug for shaft
                translate([0,0,5+3.8]) washer(d=dlug,t=tlug+0.4,d_pin=1,$fn=fascets);
                translate([0,0,16]) washer(d=9,t=20,d_pin=1,$fn=fascets);
            }
        }
        // remove potentiometer interfaces
        translate([0,0,-2]) rotate([0,0,-90]) RV112FF_pot(negative=true);

    }
}
*pot_joint(lug_two=false);
*rotate([0,0,-90]) {
    translate([0,0,5]) pot_joint(pot=false);
    *RV112FF_pot(negative=false);
}
module tube_barb (ID=4.763, OD=6.35) {
    // barb to connect two ends of tube into a loop
    // UNITS ARE METRIC
    $fn=48;
    barb ();
    mirror ([0,0,1]) barb(); 
    
    module barb () {
        rotate_extrude ()
            polygon([[0,0],[0,1.5*ID],[ID/2,1.5*ID],[OD/2,1.25*ID],[OD/2,ID],[ID/2,ID],[ID/2,.2*ID],[OD/2,.2*ID],[OD/2,0],[0,0]]);
    }
}
*tube_barb();

module above_plane(p1,p2,p3,s=100) {
        v1 = p2 - p1;
        v2 = p3 - p1;
        n = cross(v1,v2);
        n2 = n / norm(n) * sign(n.z);
        cp = (p1 + p2 + p3) / 3;
        axis = cross([0,0,1],n2);
        dot = [0,0,1] * n2;
        ang = acos(dot>1? 1 : dot<-1? -1 : dot); // Fixes FP rounding errors.
        difference() {
                children();
                translate(cp) rotate(a=ang,v=axis) translate([0,0,-2*s]) cube(4*s,center=true);
        }
}
// minimum rotation that brings direction di to direction do
module rotFromTo(di,do)
  if( norm(di-do)==0 || norm(di)==0 || norm(do)==0 )
    children();
  else
    mirror(do/norm(do)+di/norm(di)) mirror(di) children();

module cubeOnThreePoints(p) {
  norml = (cross(p[0]-p[1],p[0]-p[2]));
  normal = sign(norml.z)*norml;

  size = max(norm(p[0]-p[1]),norm(p[1]-p[2]),norm(p[0]-p[2]))*sqrt(2);
    echo (size=size);
  translate((p[0]+p[1]+p[2])/3 ) // center at the baricenter
    rotFromTo([0,0,1],normal)
      translate(-size*[1,1,0]/2)
        cube(size);
// just to illustration
  color("blue")
  for(pi=p) translate(pi) cube(2,center=true);

}
*cubeOnThreePoints([[0,0,0] , [10,0,-20], [-30,20,10] ]); 

module ruler_ticks(end){
    for(j=[1:end]) {
        color("DeepSkyBlue")translate([j,0,0,])cube([.1,3,.03]);
        color ("SpringGreen")translate([j-.5,0,0])cube([.1,2,.03]);
    }
    for(i=[0:10:end]){
        color("Black")translate([i,0,0])cube([.2,4,.04]);
        color("Black")linear_extrude(.02, convexity=10)translate([i,4,0])text(str(i),size
= 2);
    }
}
*ruler_ticks(100);

module ruler(end){
    color("DeepSkyBlue")
        linear_extrude(0.03, convexity=10)
            for(j=[1:end])
                translate([j-0.05,0,])square([.1,3]);

    color ("SpringGreen")
        linear_extrude(0.03, convexity=10)
            for(j=[1:end])
                translate([j-.55,0,0])square([.1,2]);

    color("Black") {
        linear_extrude(0.04, convexity=10)
            for(i=[0:10:end])
                translate([i - 0.1,0])square([.2,4]);

        linear_extrude(.02, convexity=10)
            for(i=[0:10:end])
                translate([i,4,0])text(str(i),size = 2);
    }
}
*translate ([50,0,50]) rotate([0,90,0]) ruler(100);

Vector=[for( i = [0:72*12.5]) [i*5,(cos(i*5)*31)+31+(20*100) ] ] ;  // your formula
Poly=[for(L=[[[0,200]], Vector, [[72*12.5*5,200]]], a=L) a];  // add the end points
*
*polygon(Poly);//echo(Poly) ; // verify the flat shape
*rotate_extrude() rotate(90) polygon(Poly) ; // and there it is ?

module Power_Energy_Meter() {
    // model of bayite DC 6.5-100V 0-100A LCD Digital Current Voltage Power Energy Meter
    color("DarkGray") {
        translate([0,0,-11.15]) cube([45,87,22.3],center=true);
        translate([0,0,1]) cube([50,91,2],center=true);
        translate([0,0,-7]) cube([45,89,10],center=true); // for removal to make lip
    }
}
*Power_Energy_Meter();

module Rocker_Switch () {
    color ("DarkRed") {
        translate([0,0,-10]) cube([10.5,29,20],center=true);
        translate([0,0,1]) cube([13.7,30.7,2],center=true);
    }
}
*translate([40,0,0]) Rocker_Switch();

module Current_Shunt () {
    bolt_center = 86.55;
    color ("DarkCyan") {
        difference() {
            cube([15,105,2],center=true);
            translate([0,bolt_center/2,0]) cylinder(h=20,d=5,center=true);
            translate([0,-bolt_center/2,0]) cylinder(h=20,d=5,center=true);
        }
    }
}
*translate([60,0,0]) Current_Shunt();

//This is used for rotational patterns. Child elements are rotated around zero
module Rotation_Pattern(number=3,radius=20,total_angle=360) {
  ang_inc = total_angle/number;
  //echo(ang_inc=ang_inc);
  if (number>1 && radius > 0) {
      for(i = [0 : number-1 ] ) {
        rotate([0,0,i*ang_inc]) translate([radius,0,0])
          children(0);
          }
    } else {
      echo("INVALID ARGUMENTS IN Rotation_Pattern module");
  }
}
*Rotation_Pattern(5,30) cylinder(h=10,d=3,center=true);

module rectPattern(x=10,y=20) { // four obects in a rectangular pattern
    translate([x/2,y/2,0]) children();
    translate([x/2,-y/2,0]) children();
    translate([-x/2,y/2,0]) children();
    translate([-x/2,-y/2,0]) children();
}
*rectPattern(30,50) circle(10); // 2D result

module 2d_test() {
    // RENDER F6 and export to .svg, then import to Easel
    // OpenSCAD exports in mm
    // Easel imports mm (use switch), then you can switch back to inch
    
    // Test pattern = 4 2 inch dia circles on a 4 inch diameter circle
    
    //hull()  // hull outlines the pattern (optional)
        Rotation_Pattern(number=4,radius=2/mm_inch,total_angle=360)
            circle(1/mm_inch,$fn=40);
}
*2d_test();

module U_section(Lbase=20,Lleg=15,Tbase=2,Tleg=1) {
    // Create a U section polygon (2D)
    // the origin in the lower left
    if(Lbase>0 && Lleg>0 && Tbase>0 && Tleg>0) {
        polygon([[0,0],[Lbase,0],[Lbase,Lleg],[Lbase-Tleg,Lleg],[Lbase-Tleg,Tbase],[Tleg,Tbase],[Tleg,Lleg],[0,Lleg],[0,0]]);
    }
}
*U_section();

module GoPro_model() { 
    color("grey") {
        rounded_cube([61,44,25],r=4,center=false,$fn=FACETS); // body
        translate([(61-32),(44-28),25]) rounded_cube([32,28,9],r=4,center=false,$fn=FACETS); // lense     
        translate([(61-16),(44-14),25]) cylinder(h=50,r=7,center=false,$fn=FACETS); // focal
        translate([15,-22,-20]) cube([30,22,45]); // base part representation
    }
}

module GoPro_Mount_model() {  // base to which GoPro mounts to
    color("Silver") {
        cube([35,45,3]);  // base
        wing();
        translate([35,0,0]) mirror([1,0,0]) wing();
        translate([16,5,0]) cube([2,32,5]);
    }
    module wing() {  // clips
        translate([0,11,0]) cube([3,23,10]);
        translate([0,12.5,8]) cube([5,20,2]);
    }
}
*translate([-12.5,25,26]) rotate([90,0,0]) GoPro_model();
*GoPro_Mount_model();

// Draw a spring cylinder from pt1-pt2 
// of spring constant K and free length freelen
// and color it based on the percent elongation
module draw_spring(pt1=[100,0,50],pt2=[100,100,50],freelen=10) {
    sprlen = norm(pt1-pt2); 
    pct_elong = (sprlen-freelen)/freelen-1; 
    sprd = norm(pt1-pt2)/15; // spring diameter for display only
    //echo(pct_elong=pct_elong*100,sprd=sprd);
    pt_pt_cylinder(from=pt1, to=pt2, d=sprd);
}
*draw_spring();

module compliant_claw2(len=160,width=120,t1=2,t2=38,r=18,pre_angle=15) {
    // U shaped claw with a pre angle
    //    t1 = general compliant thickness
    //    t2 = height of part
    // implement corner chamfers
    // Draws half and uses mirror
    $fa=$preview ? 6 : 1; // minimum angle fragment
    $fs=0.05; // minimum size of fragment (default is 2)
    
    poly_z = t2/2;
    module subtract_2 () { // triangle removal on end of claw
        linear_extrude(height = t2, convexity=10)
            polygon(points=[[-t2/3,0],[0,t2/3],[t2/3,0],[-t2/3,0]]);
    }
    
    module half_claw (link_adjust=0) {    
        // The Half Cylinder part of the claw
        rotate([0,0,-90])
            translate([-r-t1,width/2-r,0])
            rotate([0,0,-90]) 
            curved_beam(rot1=180+pre_angle,radOfCurve = r,t1=t1,t2=t2);
            *rotate_extrude(angle=180+pre_angle,convexity = 20)
                translate([r, 0, 0])
                    square([t1,t2],center=false); // on X,Z plane
        
        // Everything else
        // The long Finger and the link to the servo
        // Multiple transformations to the preload
        y_link = link_adjust+r;
        translate([width/2-r,r+t1,0])
        rotate([0,0,pre_angle]) 
        translate ([r,0,0]) { // x=r
            translate([0,link_adjust+r,0]) servo_connection(len=52,t1=t1,t2=t2);
            
            // Long finger thicker section
            cube([2*t1,len/1.5-r,t2],center=false);
            
            difference () {
                // Long finger full length
                cube([t1,len-r,t2],center=false);
                // subtract end chamfers
                translate ([-t2/10,len-r+t1,-t1]) rotate ([90,0,90]) subtract_2();
                translate ([t2/2,len-r+t1,t2+1]) rotate ([-90,0,90]) subtract_2();
            }
        }
    } // end module half_claw
    
    // back plate
    x9 = width-4*r;  // local x
    back_height = t2; // match claw interface
    translate([-x9/2,r-3*t1,0]) cube([x9,6*t1,back_height],center=false);
    
    End_w = 10; // End effector interface width, mm
    // Add a cube to connect the back plate
    translate([-End_w/2,-r,0]) cube([End_w,2*r,t2],center=false);
    
    // DRAW THE CLAW HALVES
    half_claw (link_adjust=24); // modify link location this side
    mirror([1,0,0]) half_claw (link_adjust=9); 
}
*compliant_claw2(len=150,width=120,t1=2,t2=25,r=18,pre_angle=15);
*translate ([0,0,40]) compliant_claw2 (len=claw_length,width=claw_width,t1=claw_t,t2=claw_height,r=claw_radius,pre_angle=15);
