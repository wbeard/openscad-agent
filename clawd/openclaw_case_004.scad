// OpenClaw-style Mac Mini case (crab shell) - v003: full crab character
// Fits Apple Mac mini (M2/M4): 127 x 127 x 50 mm
// Open bottom: the mini slides in from below, case rests over it.
// Print orientation: top face down on the bed (flip 180 in slicer).
//
// PART = "shell"       -> the case itself
// PART = "accessories" -> 2 antennae + 2 eye discs (print in white/black)

PART = "shell";

$fn = 64;

// ---- Device + fit ----
mini_w   = 127;    // mac mini footprint (square)
mini_h   = 50;     // mac mini height
clear    = 0.75;   // clearance per side
wall     = 4;      // shell wall thickness

// ---- Derived shell dims ----
cav_w  = mini_w + 2*clear;        // 128.5 cavity footprint
cav_h  = mini_h + 1.5;            // cavity height (headroom)
out_w  = cav_w + 2*wall;          // 136.5 outer footprint
out_h  = cav_h + wall;            // 55.5 outer height
rc_in  = 26;                      // cavity corner radius (mini ~25)
rc     = rc_in + wall;            // outer vertical corner radius
rt     = 12;                      // top edge roundover
corner = out_w/2 - rc;            // corner circle center offset (38.25)

// ---- Rear port opening ----
rear_w = 94;   // narrow enough to clear the rear claws
rear_h = 26;
rear_z = 12;
rear_r = 8;

// ---- Front ports (2x USB-C + headphone jack + LED) ----
front_z = 21;
usbc_w  = 15;
usbc_h  = 8;
jack_d  = 10;

// ---- Side vents ----
vent_n   = 6;
vent_w   = 4;
vent_gap = 9;
vent_h   = 28;
vent_z   = 10;
vent_y0  = 10;

// ---- Crab claws (one per corner, two-lobe pincer) ----
claw_r1   = 12;    // big lobe
claw_r2   = 9;     // small lobe (creates the pincer crease)
claw_z    = 16;    // big lobe center height
claw_off  = 30;    // distance from corner circle center, along the diagonal

// ---- Face: eyes + antennae on top ----
eye_d       = 30;   // eye disc recess diameter
eye_depth   = 2;
eye_x       = 28;
eye_y       = 2;
ant_hole_d  = 7;    // antenna through-hole
ant_cbore_d = 13;   // grommet-look counterbore
ant_x       = 30;
ant_y       = -38;  // toward the front

// ================= modules =================

// Rounded box: vertical corner radius rcv, top edge roundover rtv, flat bottom
module rounded_shell(w, h, rcv, rtv) {
    hull() {
        for (x = [-1, 1], y = [-1, 1]) {
            translate([x*(w/2 - rcv), y*(w/2 - rcv), 0]) {
                cylinder(r = rcv, h = 1);
                translate([0, 0, h - rtv])
                    rotate_extrude()
                        translate([rcv - rtv, 0])
                            circle(rtv);
            }
        }
    }
}

module cavity() {
    translate([0, 0, -1])
        linear_extrude(cav_h + 1)
            offset(r = rc_in)
                square([cav_w - 2*rc_in, cav_w - 2*rc_in], center = true);
}

// Rounded-rect hole punched along Y (through front/back walls)
module y_slot(wid, hgt, r) {
    hull()
        for (x = [-1, 1], z = [-1, 1])
            translate([x*(wid/2 - r), 0, z*(hgt/2 - r)])
                rotate([90, 0, 0])
                    cylinder(r = r, h = 40, center = true);
}

// Two-lobe pincer claw, built pointing along +X
module claw() {
    union() {
        sphere(claw_r1);
        translate([5, 0, claw_r1 - 4]) sphere(claw_r2);
    }
}

// ================= shell =================

module shell() {
    difference() {
        union() {
            rounded_shell(out_w, out_h, rc, rt);
            // four corner claws, pointing out along each diagonal
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx*(corner + claw_off*0.707),
                           sy*(corner + claw_off*0.707),
                           claw_z])
                    rotate([0, 0, atan2(sy, sx)])
                        claw();
        }

        // interior
        cavity();

        // rear port opening (+y wall)
        translate([0, out_w/2 - wall/2, rear_z + rear_h/2])
            y_slot(rear_w, rear_h, rear_r);

        // front: two USB-C slots + headphone jack + status LED (-y wall)
        for (x = [-10, 10])
            translate([x, -(out_w/2 - wall/2), front_z])
                y_slot(usbc_w, usbc_h, usbc_h/2 - 0.01);
        translate([32, -(out_w/2 - wall/2), front_z])
            rotate([90, 0, 0])
                cylinder(d = jack_d, h = 40, center = true);
        translate([-32, -(out_w/2 - wall/2), front_z])
            rotate([90, 0, 0])
                cylinder(d = 3.5, h = 40, center = true);

        // side vents (both sides, rear half)
        for (x = [-1, 1], i = [0 : vent_n - 1])
            translate([x*(out_w/2 - wall/2),
                       vent_y0 + i*vent_gap - (vent_n-1)*vent_gap/2 + 12,
                       vent_z + vent_h/2])
                cube([wall + 16, vent_w, vent_h], center = true);

        // eye disc recesses on top
        for (x = [-1, 1])
            translate([x*eye_x, eye_y, out_h - eye_depth])
                cylinder(d = eye_d, h = eye_depth + 1);

        // antenna through-holes with grommet counterbore
        for (x = [-1, 1])
            translate([x*ant_x, ant_y, 0]) {
                translate([0, 0, out_h - wall - 6])
                    cylinder(d = ant_hole_d, h = wall + 8);
                translate([0, 0, out_h - 1.5])
                    cylinder(d = ant_cbore_d, h = 3);
            }
    }
}

// ================= accessories =================

// Curved antenna: plug fits the 7mm hole, horn curves like an eyestalk.
// Printed standing: plug on the bed, horn bends 70 degrees (support-free).
module antenna() {
    pts = [for (a = [0 : 10 : 70]) [18*(1 - cos(a)), 0, 18*sin(a)]];
    union() {
        // plug (goes into the hole)
        cylinder(d = ant_hole_d - 0.4, h = 10);
        // flange (sits in the counterbore, reads as the white grommet ring)
        translate([0, 0, 10])
            cylinder(d = ant_cbore_d - 0.5, h = 1.4);
        // curved horn rising from the flange (arc in XZ, starts pointing +Z)
        translate([0, 0, 11.4])
            for (i = [0 : len(pts) - 2])
                hull() {
                    translate(pts[i])   sphere(3 - 1.4*i/(len(pts)-1));
                    translate(pts[i+1]) sphere(3 - 1.4*(i+1)/(len(pts)-1));
                }
    }
}

// Eye disc: drops into the top recess, pupil dome in the middle
module eye_disc() {
    cylinder(d = eye_d - 0.5, h = eye_depth + 0.5);
    translate([0, 0, eye_depth + 0.4])
        scale([1, 1, 0.5]) sphere(d = 8);
}

// ================= output =================

if (PART == "shell") {
    shell();
} else if (PART == "accessories") {
    // antennae stand plug-down on the bed
    for (y = [-1, 1])
        translate([0, y*15, 0])
            antenna();
    for (y = [-1, 1])
        translate([40, y*20, 0])
            eye_disc();
}
