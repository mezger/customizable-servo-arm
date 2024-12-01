/**
 *  Customizable servo arm generator for OpenSCAD by Matthias Mezger
 *
 *  Based on "Parametric Servo Arms 3F 2F 1F" by Paul Barrett (https://www.thingiverse.com/thing:630862)
 *  and "Parametric servo arms" by Charles Rincheval (https://www.thingiverse.com/thing:28566)
 *
 *  Info:
 *  https://www.hepf.at/servo-spline-information/
 *  https://community.robotshop.com/blog/show/modelling-a-servo-spline
 *  http://projectsbyjb.blogspot.com/2014/11/servo-spline-adapters.html
 *
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


// Distance between center of servo head and center of outer bore hole (in mm).
arm_length = 25;
arm_thickness = 1.5;
arm_count = 1;
arm_hole_diameter = 1.2;
arm_hole_distance = 4;

// Gap between arm and servo head. This value depends on your printer and the material you use. With PLA material, use clear : 0.3, for ABS, use 0.2
SERVO_HEAD_CLEAR = 0.1;

//labeled combo box for string
servo_preset="3F"; // [3F:FUTABA 3F Standard Spline (25T), 2F:FUTABA 2F Spline (21T), 1F:FUTABA 1F Spline (15T), A1:HITEC A1 Sub-micro Spline (15T), SG90:SG90 (21T)]


/* [Hidden] */

$fn = 100;

/**
 *  Head / Tooth parameters
 *
 *  First array (head related) :
 *  0. Head external diameter
 *  1. Head heigth
 *  2. Head thickness (thickness of wall)
 *  3. Head screw diameter (diameter of hole)
 *
 *  Second array (tooth related) :
 *  0. Tooth count
 *  1. Tooth height
 *  2. Tooth length
 *  3. Tooth width
 */
// FUTABA 3F Standard Spline (25 teeth)
FUTABA_3F_SPLINE = [
    [5.92, 4, 1.1, 2.5],
    [25, 0.3, 0.7, 0.1]
];
// FUTABA 2F Spline (21 teeth) ??
FUTABA_2F_SPLINE = [
    [4.5, 4, 1.1, 2.5],
    [22, 0.25, 0.6, 0.09]
];
// FUTABA 1F Spline (15 teeth)
FUTABA_1F_SPLINE = [
    [4.0, 3.75, 1.1, 2.4],
    [15, 0.25, 0.6, 0.09]
];
// HITEC A1 Sub-micro Spline (15 teeth)
// A15T = A1 3.9mm
A15T_A1_SPLINE = [
    [3.9, 3.2, 1.1, 2.4],
    [15, 0.375, 0.66, 0.13]
];
// HITEC B1 Mini Spline (25 Zähne)
// HITEC C1 Standard Spline (24 Zähne)
// HITEC H25T Hitec Standard Spline (25 Zähne) -> identisch mit FUTABA 3F
// HITEC D1 Heavy Duty Spline (15 Zähne)
// JR Graupner 23T (23 Zähne)
// Robbe: 25T ???
// Towerpro Micro 20T ???
// Traxxas: 25T ???
// SG90 21T (Näherung, da im Original rundes Profil der Zähne, siehe https://community.robotshop.com/blog/show/modelling-a-servo-spline)
SG90_SPLINE = [
    [4.9, 3.2, 1.5, 2.5],
    [21, 0.25, 0.65, 0.25]
];


/**
 *  servo head tooth
 *
 *    |<-w->|
 *    |_____|___
 *    /     \  ^h
 *  _/       \_v
 *   |<--l-->|
 *
 *  - tooth length (l)
 *  - tooth width (w)
 *  - tooth height (h)
 *  - height
 *
 */
module servo_head_tooth(length, width, height, head_height) {
    linear_extrude(height = head_height) {
        polygon([[-length / 2, 0], [-width / 2, height], [width / 2, height], [length / 2,0]]);
    }
}


/**
 *  Servo head (a model of the part where our servo arm will fit on) 
 *  This will later be subtracted from our arm.
 */
module servo_head(params, clear = SERVO_HEAD_CLEAR) {

    head = params[0];
    tooth = params[1];

    head_diameter = head[0];
    head_heigth = head[1];

    tooth_count = tooth[0];
    tooth_height = tooth[1];
    tooth_length = tooth[2];
    tooth_width = tooth[3];

    //% cylinder(r = head_diameter / 2, h = head_heigth + 1);

    //the core of the head
    cylinder(r = head_diameter/2 - tooth_height + 0.03 + clear, h = head_heigth);

    //the teeth
    for (i = [0 : tooth_count]) {
        rotate([0, 0, i * (360 / tooth_count)]) {
            translate([0, head_diameter/2 - tooth_height + clear, 0]) {
                servo_head_tooth(tooth_length, tooth_width, tooth_height, head_heigth);
            }
        }
    }
}


/**
 *  Servo adapter (the part that fits on the servo head). This is the Base for our servo arm,
 *  and it can be the base for other parts that are directly mounted on an servo.
 */
module servo_adapter(params, clear = SERVO_HEAD_CLEAR) {
    head = params[0];
    tooth = params[1];

    head_diameter = head[0];
    head_heigth = head[1];
    head_thickness = head[2];
    head_screw_diameter = head[3];

    tooth_length = tooth[2];
    tooth_width = tooth[3];

    difference() {
        cylinder(r = head_diameter/2 + head_thickness, h = head_heigth + 1);
        cylinder(r = head_screw_diameter/2, h = head_heigth + 1);
        translate([0,0,1]) servo_head(params, clear);
    }
}


/**
 *  Servo arm
 */
module servo_arm(params, clear = SERVO_HEAD_CLEAR) {
    head = params[0];
    tooth = params[1];

    head_diameter = head[0];
    head_heigth = head[1];
    head_thickness = head[2];
    head_screw_diameter = head[3];

    for(i=[0:360/arm_count:360]) {
        rotate([0,0,i]) {
            difference() {
                hull() {
                    cylinder(r = head_diameter/2 + head_thickness + 0.5, h = arm_thickness);
                    translate([arm_length,0,0]) cylinder(d=3*arm_hole_diameter, h=arm_thickness);
                }
                //cut for servo_adapter
                cylinder(r = head_diameter/2 + head_thickness - 0.1, h = arm_thickness);
                //holes
                hole_count = (arm_length-(head_diameter/2+head_thickness+head_heigth))/arm_hole_distance;
                for(j=[0:hole_count]) {
                    translate([arm_length-j*arm_hole_distance,0,0]) 
                        cylinder(d=arm_hole_diameter, h=arm_thickness);
                }
            }
            //support
            translate([head_diameter/2+head_thickness-0.7,-0.75,arm_thickness]) hull() {
                cube([head_diameter/2 + head_thickness, 1.5, 0.1]); 
                cube([0.1, 1.5, head_heigth+1-arm_thickness]); 
            }
        }
    }
    //servo adapter in the middle
    servo_adapter(params, clear);
}


if(servo_preset=="3F") servo_arm(FUTABA_3F_SPLINE, SERVO_HEAD_CLEAR);
if(servo_preset=="2F") servo_arm(FUTABA_2F_SPLINE, SERVO_HEAD_CLEAR);
if(servo_preset=="1F") servo_arm(FUTABA_1F_SPLINE, SERVO_HEAD_CLEAR);
if(servo_preset=="A1") servo_arm(A15T_A1_SPLINE, SERVO_HEAD_CLEAR);
if(servo_preset=="SG90") servo_arm(SG90_SPLINE, SERVO_HEAD_CLEAR);



//servo_head(SG90_SPLINE, 0);
//servo_adapter(SG90_SPLINE);
//servo_arm(SG90_SPLINE, SERVO_HEAD_CLEAR);