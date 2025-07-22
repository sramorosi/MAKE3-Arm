// Mechanical Engineering Module and Function Library
//  Started on 4/6/2020 by SrAmo
//  last modified May 2023 by SrAmo

// Force or Torque magnitude for testing modules
mag = 1; // [-40:0.2:40]
// Display force arrows
display_force = false; 
// Display torque arrow
display_torque = false;

if (display_force) force_arrow([0,0,0],[1,0,0],mag=mag);
if (display_force) force_arrow([0,0,0],[0,-1,0],mag=mag);
if (display_force) force_arrow([0,0,0],[0,0,1],mag=-mag); // note neg mag

if (display_force) color ("blue") force_arrow([2,2,2],[1,1,0],mag=mag);
if (display_force) color ("green") force_arrow([2,2,2],[0,1,1],mag=mag);
if (display_force) force_arrow([2,2,2],[1,0,1],mag=mag);

if (display_torque) torque_arrow([0,0,0],mag=mag);
if (display_torque) torque_arrow([0,0,5],mag=-mag);

// convert number into a red to green value,  for displaying color ramp
function val_red(i) = i < 3 ? 0 : i < 4 ? 0.25 : i < 5 ? 0.5 : 1 ;
function val_green(i) = i < 3 ? 1 : i < 4 ? 0.75 : i < 5 ? 0.5 : 0;

// a simple recursive function that adds the values of a list of floats;
// uses tail recursion
function add(v, i = 0, r = 0) = i < len(v) ? add(v, i + 1, r + v[i]) : r;
//ar1 = [1,1,1,1.2,1];
//sum1 = add(ar1);
//echo(sum1=sum1);

function law_sines_angle (C=30,a=10,c_ang=120) = 
// law of sines, given length C, a, and C Angle, return A angle
asin((a/C)*sin(c_ang));

function law_sines_length (C=30,c_ang=120,b_ang=30) =
// law of sines, given length C, c angle and b angle, return B length
C * (sin(b_ang)/sin(c_ang));

function law_cosines (a=10,b=10,c=10) = 
// law of cosines, find angle between sides a and b given three side lengths
acos((a*a+b*b-c*c)/(2*a*b));

// Law of Cosine to find the angle opposite C, given sides A B C
function LawOfCosinesAngle(A=20,B=20,C=10) =
    acos(((A*A)+(B*B)-(C*C))/(2*A*B));
//test = LawOfCosinesAngle();
//echo(test=test);

// Law of Cosine to find the length C, given sides A B and angle between A and B
function LawOfCosinesC(A=20,B=20,GAMMA=40) =
    sqrt((A*A)+(B*B)-2*A*B*cos(GAMMA));

function rot_x (x,y,a) = x*cos(a)-y*sin(a);

function rot_y (x,y,a) = x*sin(a)+y*cos(a);

function rot_pt_x (pt=[10,10,10],xang=45) =
// Rotate pt about the X-axis by xang
[pt[0],rot_x(pt[1],pt[2],xang),rot_y(pt[1],pt[2],xang)];

function rot_pt_y (pt=[10,10,10],yang=45) =
// Rotate pt about the Y-axis by yang
[rot_x(pt[0],pt[2],yang),pt[1],rot_y(pt[0],pt[2],yang)];

//ypoint = rot_pt_y();
//echo(ypoint=ypoint);

function rot_pt_z (pt=[10,10,10],zang=45) =
// Rotate pt about the Z-axis by zang
[rot_x(pt[0],pt[1],zang),rot_y(pt[0],pt[1],zang),pt[2]];

function anglesToC(alphaA=90,alphaB=0,alphaT=0,lAB=1,lBC=1) =
// Forward Kinematics
// alpha = global angles,  theta = local angles
// returns points C
let (pC1=[lBC,0,0])
let (pB1=[lAB,0,0])
let (pC2=rot_pt_y(pC1,alphaB))
let (pC3=pC2+pB1)
let (pC4=rot_pt_y(pC3,alphaA))
rot_pt_z(pC4,alphaT);

//ptsCD=anglesToC(90,-90,45,195,240);
//echo(ptsCD=ptsCD);

function ik_xy (c=[0,10,0],lenAB=100,lenBC=120,AY=0) = 
// Simple Inverse Kinematics on the xy plane
// Given a three body system Ground-AB-BC, where A is [0,AY,0]
// Lengths LenAB and LenBC are specified
// The location of c is specified. The z component is ignored
// The joints A,B are on the xy plane
// calculate the angles given pt C ***Inverse Kinematics***
// returns an array with [alphaA,alphaB] 
//    where alphaB is ABC (i.e. local, not BC global to horizontal)
let (vxy = norm([c[0],c[1]-AY,0]))  // vector length on the xy plane
let (vt_long = (vxy > (lenAB+lenBC) ? true : false) )
let (sub_angle1 = atan2(c[1]-AY,c[0]))  // atan2 (Y,X)!
let (sub_angle2 = vt_long ? 0.01 : law_cosines(vxy,lenAB,lenBC) )
let (a_ang = sub_angle1 + sub_angle2)
let (b_ang = vt_long ? 0.01 : law_cosines(lenBC,lenAB,vxy)-180 )
[a_ang,b_ang] ;

function inverse_arm_kinematics (c=[0,10,0],lenAB=100,lenBC=120,aOffset=0) = 
// Inverse Kinematics on the xz plane
// Given a three body system Ground-AB-BC, where A is [0,0,0]
// Lengths LenAB and LenBC are specified
//  aOffset is the X offset from the Turntable axis
// The location of c is specified
// The joints A,B are on a plane with rotation alphaT parallel to Z through A
// With alphaT = 0, then joints A & B are parallel to the Y axis
// calculate the angles given pt C ***Inverse Kinematics***
// returns an array with [alphaA,alphaB,alphaT] 
//    where alphaB is ABC (not BC to horizontal)
let (vxy = norm([c[0],c[1],0]))  // vector length on the xy plane
let (alphaT = vxy > 0 ? atan2(c[1],c[0]) : 0) // T angle (check for zero)
let (crot = rot_pt_z(c,-alphaT)) // rotate to the XZ plane
let (newA = [crot[0]-aOffset,crot[1],crot[2]])  // subtract the offset
let (vt = norm(newA))  // vector length from A to C
let (vt_long = (vt > (lenAB+lenBC) ? true : false) )
let (sub_angle1 = atan2(newA[2],newA[0]))  // atan2 (Y,X)!
let (sub_angle2 = vt_long ? 0.1 : law_cosines(vt,lenAB,lenBC) )
let (a_ang = sub_angle1 + sub_angle2)
let (b_ang = vt_long ? 0.1 : law_cosines(lenBC,lenAB,vt)-180 )
//echo(vt=vt,sub_angle1=sub_angle1,sub_angle2=sub_angle2,vt_long=vt_long)
[a_ang,b_ang,alphaT] ;
    
//invAngles = inverse_arm_kinematics([7.071,7.071,10],10,10);
//invAngles = inverse_arm_kinematics([346.41, 200, 200],200,400,100); // 346 = 400*cos(30)
//echo(invAngles=invAngles);

// linear interpolation function
// Returns the value between A and B given t between t_l and t_h
function linear_interp (A,B,t,t_l,t_h) = (A+((t-t_l)/(t_h-t_l))*(B-A));

// distance from 0,0 to line function
//  reference Wikipedia "distance from a point to a line"
//  see formula for line defined by two points
//  when the point is 0,0 the formula is simple
// line is defined by two points p1 and p2
function dist_line_origin (p1=[1,1],p2=[0,2])=
(p2[0]*p1[1]-p2[1]*p1[0])/norm([(p1[0]-p2[0]),(p1[1]-p2[1]),0]);

function dist_line_pt (p1=[-5,5,0],p2=[0,5,0],pt=[10,0,0])=
((p2[1]-p1[1])*pt[0]-(p2[0]-p1[0])*pt[1]+p2[0]*p1[1]-p2[1]*p1[0])/norm([(p1[0]-p2[0]),(p1[1]-p2[1]),0]);

function ptpt_dist(p1=[-5,5,0],p2=[0,0,0])=
let (p3 = p1 - p2)
norm(p3);
//sqrt((p1[0]-p2[0])*(p1[0]-p2[0]) + (p1[1]-p2[1])*(p1[1]-p2[1])+(p1[2]-p2[2])*(p1[2]-p2[2]));

p1=[1,1,0];
p2=[-1,-1,0];
ANS = ptpt_dist(p1,p2);
echo(ANS=ANS);
p3 = p1-p2;
ANS2 = norm(p3);
echo(ANS2=ANS2);

function rotZ_pt (a=10,p=[1,1,0]) = ([(p[0]*cos(a)+p[1]*sin(a)),(p[1]*cos(a)+p[0]*sin(a)),p[2]]);

// recursive module that draws a 3D point list
//   An optional value list can be provided and the height of the
//   cylinders will be set to the corresponding value in the list.
module draw_3d_list(the3dlist=[],size=10,dot_color="blue",value=[],idx=0) {
    point=the3dlist[idx];
    height=value[idx];
    //echo(point=point);
    if (point != undef) { // not undefined means there is a point
        if (height != undef) {
           color(dot_color) translate(point) translate([0,0,height/2]) sphere(r=size);   
        } else {
            color(dot_color) translate(point) sphere(r=size);  
        }
       idx=idx+1;
       draw_3d_list(the3dlist,size,dot_color,value,idx);
    }  
    // Note: that an undefined causes the recursion to stop
}

function larger(a=0,b=-1) =  abs(a) > abs(b) ? a : b ; // Simple function to return the value farthest from zero

function largeInVector(vector,i=0) = 
// Recursive function to return the value farthest from zero in a vector
    (i < len(vector)-1) ? 
    larger((vector[i]),(largeInVector(vector,i+1))) :  
         vector[i] ;

function WhereInVector(vector,value,i=0) = 
// Recursive function to return the fist location of a value in a vector
    (i < len(vector)-1) ? 
    (vector[i]==value ? i : WhereInVector(vector,value,i+1)) :  
        (vector[i]==value ?  i : -9999) ;

//aaa = [-20,2,-1000,2,10,500];
//test = largeInVector(aaa);
//position = WhereInVector(aaa,test);
//echo(test=test,position=position);

module Margin_Safety(min,max,allowable,name="THING NAME") {
    // calculate Engineering Margin of Safety for "thing"
    // Two actual values can be provided, representing most negative and most pos
    // allowable = the allowable value
    MAX = max(abs(max),abs(min));
    MS = (allowable/MAX)-1;
    echo(name," MARGIN OF SAFETY ",MS=MS,MAX=MAX);
}
module Margin_Safety2(loads=[],allowable,name="THING NAME") {
    // calculate Engineering Margin of Safety for "thing"
    // Two actual values can be provided, representing most negative and most pos
    // allowable = the allowable value
    loadslen=len(loads);
    if (loadslen > 0) {
        //min_load=min(loads);
        max_load=largeInVector(loads);
        pos = WhereInVector(loads,max_load);
        MAX = abs(max_load);
        MS = (allowable/MAX)-1;
        echo(name," MARGIN OF SAFETY ",MS=MS,max_load=max_load,pos=pos);
    } else {
        echo(" NO LOADS PASSED TO MS MODULE ");
    }
}

module force_arrow(from=[1,1,0],vec=[1,0,0],mag=10) {
    // draw a 3D force of length (mag), at (from), direction (vec)
    $fn = $preview ? 10 : 20;     // number of fragments
    if (norm(vec)>0.001) {  // check for non zero vector
        
        dx = -vec[0];
        dy = -vec[1];
        dz = -vec[2];
        
        // "cylinder" is centered around z axis
        // These are angles needed to rotate to correct direction
        ay = 90 - atan2(dz, sqrt(dx*dx + dy*dy));
        az = atan2(dy, dx);
        angles = [0, ay, az];
        
        d = abs(mag); // used to scale arrow
        sclr=d*.05; // scaler for arrow shaft
        
        if (abs(mag)>0.1) { // don't draw if small
            color("red") 
            translate (from) 
            rotate (angles) 
            translate([0,0,-d])
            union () {
                translate([0,0,d*.1])
                    cylinder(d*.9,d1=sclr,d2=sclr,false);
                cylinder(d*.2,0,d*.1,false);
            }
        } else {
            //echo("MODULE FORCE_ARROW; small mag = ",mag);
    }
    } else {
        //echo("MODULE FORCE_ARROW; vec too small = ",vec);
    }
}
module torque_arrow(to=[10,4,0],mag=10) {
    // draw a torque of diameter abs(mag), at to point
    // assumes torque is on x,y plane (for now)
    // arrowhead changes direction with sign of mag
    $fn = $preview ? 40 : 72;     // number of fragments
    d = abs(mag); // used to scale arrow
    sclr=d*.025; // scaler for arrow shaft
    if (abs(mag)>0.1) {
        // "cylinder" is centered around z axis
        // first rotate so that it is around x axis
        // then rotate about z to point in vector location
        color("blue") 
        translate (to) 
        rotate_extrude(angle=270,convexity = 10) 
        translate([abs(mag/2), 0, 0]) 
        circle(r = sclr);
        if (mag>0) { // positive arrowhead
            color("blue") 
            translate ([to[0]+d*.2,to[1]-mag/2,to[2]]) 
            rotate([0,-90,0]) 
            cylinder(d*.2,0,d*.1,false);
        } else { // negative arrowhead
            color("blue") 
            translate ([to[0]-mag/2,to[1]-d*.2,to[2]]) 
            rotate([-90,0,0]) 
            cylinder(d*.2,0,d*.1,false);
        }
    } else {
        //echo("MODULE TORQUE_ARROW; small mag = ",mag);
    }
}

// return the torque given a rotation theta of a torsion spring of strength K
function torsion_spr_torque(K,theta,theta_zero) =
    K*(theta-theta_zero);

// Calculate the torque about a joint pt caused by a pt1-pt2 spring
// of spring constant K and free length freelen
function spring_torque(pt1=[10,0,0],pt2=[10,10,0],ptj=[-10,0,0],K=1,freelen=1) = 
    let (arm = dist_line_pt(pt1,pt2,ptj)) // dist_line_pt in force_lib
    let (sprlen = norm(pt1-pt2)) 
    K * (sprlen-freelen) * arm;  // the torque calculation

//sprtest = spring_torque();  // test
//echo(sprtest=sprtest);

//This is used for rotational patterns. Child elements are rotated around zero
module Rotation_Pattern(number=3,radius=20,total_angle=360) {
  ang_inc = total_angle/(number-1);
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
Rotation_Pattern(number=5,radius=30,total_angle=180) cylinder(h=10,d=3,center=true);
