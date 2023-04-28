// PART CONSTANT Configuration File
//  last modified October 5 2021 by SrAmo

// conversions
mm_inch = 1/25.4;

// 1/4 ID bearing OD if using a bearing (PART FR4-ZZ C3)
Qtr_bearing_id = 0.25/mm_inch;
Qtr_bearing_od=0.628/mm_inch; // 0.628 inch = 15.9512 mm
Qtr_bearing_flange_od=0.71/mm_inch; // .71 inch = 18.034 mm
Qtr_bearing_flange_t=0.05/mm_inch; // 0.05 inch = 1.27 mm
Qtr_bearing_t=0.155/mm_inch; // 0.155 inch = 3.937 mm

// 1/2 ID flanged bearing 
Half_bearing_id=0.50/mm_inch;
Half_bearing_od=1.125/mm_inch;
Half_bearing_flange_od=1.23/mm_inch; 
Half_bearing_flange_t=0.06/mm_inch; 
Half_bearing_t=0.31/mm_inch; 

M6_bearing_od=12; 
M6_bearing_flange_od=13.6;
M6_bearing_flange_t=0.8;
M6_bearing_t=3.15;

// round belt diameter throughout, if used
//belt_d=4.826;   // 0.19 in = 4.826 mm

hole_qtr_inch=6.48;   // hole for 0.25 inch joint/bolt 0.255 inch = 6.477 mm
hole_no6_screw = 2.5; // hole start diameter for number 6 screw 0.095 inch = 2.413
hole_M3=3.1; // hole for M3 (3 mm) joint/bolt
//hole_M5=5.1;  
hole_M6=6.1;
hole_servo_bushing=3.81; // hole for servo bushing 0.15 inch = 3.81 mm

// STANDARD 40MM X 20MM X 40MM SERVO DIMENSIONS
svo_l = 40.66; // Servo Length for openings in parts
svo_w = 20.3; // Servo Width for openings in parts
svo_d = 42; // Servo Depth from Horn interface to bottom of part
svo_shaft = 10.6; // Servo dist from shaft to edge of body in length direction, was 10.2
svo_screw_l = 49.5; // Servo screw hole length between
svo_screw_w = 10; // Servo screw hole width between
svo_flange_l = 57; // Servo flange length, was 55
svo_flange_t = 3; // Servo flange thickness
svo_flange_d = 10; // Servo depth from Horn interface to top of flange
servo_horn_l=25;
servo_horn_d1=15.25;
servo_horn_d2=7.5;
servo_horn_t=7.4;

// Springs
//  McMaster Carr 9271K619, torsion spring, used in MAKE 2
9271K619_angle = 180; // free leg angle
9271K619_OD = 19.35; // mm
9271K619_wd = 1.9;  // wire diameter mm
9271K619_len = 51;  // arm length mm
9271K619_coils = 7;  // number of coils
9271K619_LH = true;  // LH or RH (false)
9271K619_t = (9271K619_coils+1)*9271K619_wd; // thickness of the spring
9271K619_ID = 9271K619_OD-2*9271K619_wd;  // ID of the coil

//  McMaster Carr 9271K589, torsion spring, used in MAKE 3
9271K589_angle = 90; // free leg angle
9271K589_OD = 21.54; // mm
9271K589_wd = 2.667;  // wire diameter mm
9271K589_len = 88.9;  // arm length mm
9271K589_coils = 5.25;  // number of coils
9271K589_LH = true;  // LH or RH (false)
9271K589_t = (9271K589_coils+1)*9271K589_wd; // thickness of the spring
9271K589_ID = 9271K589_OD-2*9271K589_wd;  // ID of the coil
//9271K589_Dshaft = 12.7; // The largest shaft that can go through spring

pot_shaft_dia = 6.2; // mm, potentiometer shaft dia
pot_lug_t = 8; // thickness of the lug over potentiometer shaft
