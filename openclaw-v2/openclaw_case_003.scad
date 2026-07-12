// OpenClaw v2 — Mac mini crab case, from scratch
// =================================================
// Device: Apple M4 Mac mini (2024), verified dims:
//   chassis 127.1 x 127.1 x 49.7 mm, corner radius ~22 (tunable)
//   front ports (facing front, x from centerline, z above desk):
//     USB-C vertical pills 2.7x9.0 at x = -39.2, -23.5; LED at +25.4;
//     headphone jack (~4.2 aperture) at +38.2; port centerline z = 20.3
//   airflow bottom-only (base ring), power button bottom left-rear
// Case: one-piece slip-over shell, open bottom. Print flipped (top on bed).
//
// PART = "shell"       -> the case
// PART = "accessories" -> 2 antennae (white) + 2 eye discs (black)

PART = "shell";

$fn = 64;

// ---------------- device + fit ----------------
mini_w  = 127.1;
mini_h  = 49.7;
mini_rc = 22;      // device corner radius (caliper-verify; sources say 22-23.5)
clear   = 0.75;    // fit clearance per side
wall    = 4;

// ---------------- derived shell ----------------
cav_w  = mini_w + 2*clear;      // 128.6
cav_h  = mini_h + 1.3;          // 51.0 (tight headroom; antenna plugs are short)
out_w  = cav_w + 2*wall;        // 136.6
out_h  = cav_h + wall;          // 55.0
rc_in  = mini_rc + clear;       // 22.75 cavity corner radius
rc     = rc_in + wall;          // 26.75 outer corner radius
rt     = 12;                    // top edge roundover
corner = out_w/2 - rc;          // 41.55 corner circle center offset

// ---------------- rear port window ----------------
rear_w = 94;                    // clears the rear claws (>=2mm margin)
rear_h = 28;
rear_z = 10;
rear_r = 10;

// ---------------- front cutouts (from photogrammetry) ----------------
port_z    = 20.3;               // port centerline above desk
usbc_x    = [-39.2, -23.5];     // vertical pills
usbc_cut_w = 9;                 // cutout width  (port is 2.7 wide + plug body)
usbc_cut_h = 15;                // cutout height (port is 9.0 tall)
led_x     = 25.4;  led_d  = 4;
jack_x    = 38.2;  jack_d = 10;

// ---------------- side vents (decorative; device breathes via bottom) ----------------
vent_n   = 6;
vent_w   = 4;
vent_gap = 9;
vent_h   = 28;
vent_z   = 12;
vent_yc  = 20;                  // band center, rear-biased

// ---------------- claws (pincer per corner) ----------------
claw_z = 16;                    // palm center height

// ---------------- face: eyes + antennae ----------------
eye_d     = 30;   eye_depth = 2;
eye_x     = 29;   eye_y     = 0;
ant_hole_d  = 7;  ant_cbore_d = 13;
ant_x     = 31;   ant_y     = 40;   // toward the rear edge, like the photos

// ---------------- power button access ----------------
// button is on the mini's bottom, left-rear corner -> finger notch in the
// left wall's bottom rim
notch_r = 8;
notch_y = 32;

// ================= primitives =================

// Rounded box: vertical corner radius rcv, top edge roundover rtv, flat bottom
module rounded_shell(w, h, rcv, rtv) {
    hull()
        for (x = [-1, 1], y = [-1, 1])
            translate([x*(w/2 - rcv), y*(w/2 - rcv), 0]) {
                cylinder(r = rcv, h = 1);
                translate([0, 0, h - rtv])
                    rotate_extrude()
                        translate([rcv - rtv, 0])
                            circle(rtv);
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

// Crab pincer, built pointing along +X: one bulbous rounded mass with a
// V-wedge notch cut into the tip -> two rounded fingers, pointy but soft
module claw() {
    difference() {
        hull() { sphere(10); translate([12, 0, 1]) sphere(7.5); }
        // pincer notch: narrow wedge, apex inside the tip, opening outward
        translate([11, 0, 1])
            rotate([90, 0, 0])
                linear_extrude(30, center = true)
                    polygon([[0, 0], [16, 4], [16, -4]]);
    }
}

// ================= shell =================

module shell() {
    difference() {
        union() {
            rounded_shell(out_w, out_h, rc, rt);
            // pincer claws, one per corner, palm embedded 2mm into the wall
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx*(corner + (rc - 2)*0.707),
                           sy*(corner + (rc - 2)*0.707),
                           claw_z])
                    rotate([0, 0, atan2(sy, sx)])
                        claw();
        }

        cavity();

        // rear port window (+y)
        translate([0, out_w/2 - wall/2, rear_z + rear_h/2])
            y_slot(rear_w, rear_h, rear_r);

        // front cutouts (-y): 2 vertical USB-C pills, LED, headphone jack
        for (x = usbc_x)
            translate([x, -(out_w/2 - wall/2), port_z])
                y_slot(usbc_cut_w, usbc_cut_h, usbc_cut_w/2 - 0.01);
        translate([led_x, -(out_w/2 - wall/2), port_z])
            rotate([90, 0, 0]) cylinder(d = led_d, h = 40, center = true);
        translate([jack_x, -(out_w/2 - wall/2), port_z])
            rotate([90, 0, 0]) cylinder(d = jack_d, h = 40, center = true);

        // decorative side vents, both sides
        for (x = [-1, 1], i = [0 : vent_n - 1])
            translate([x*(out_w/2 - wall/2),
                       vent_yc + (i - (vent_n-1)/2)*vent_gap,
                       vent_z + vent_h/2])
                cube([wall + 16, vent_w, vent_h], center = true);

        // power-button finger notch, left wall bottom rim near the rear
        translate([-(out_w/2 - wall/2), notch_y, 0])
            rotate([0, 90, 0])
                cylinder(r = notch_r, h = wall + 16, center = true);

        // eye recesses
        for (x = [-1, 1])
            translate([x*eye_x, eye_y, out_h - eye_depth])
                cylinder(d = eye_d, h = eye_depth + 1);

        // antenna holes with grommet counterbore
        for (x = [-1, 1])
            translate([x*ant_x, ant_y, 0]) {
                translate([0, 0, out_h - wall - 2])
                    cylinder(d = ant_hole_d, h = wall + 4);
                translate([0, 0, out_h - 1.6])
                    cylinder(d = ant_cbore_d, h = 3);
            }
    }
}

// ================= accessories =================

// Antenna: short plug (only ~1.3mm headroom above the device inside!),
// grommet flange, tapered horn with a 70-degree bend. Prints standing.
module antenna() {
    pts = [for (a = [0 : 10 : 70]) [16*(1 - cos(a)), 0, 16*sin(a)]];
    union() {
        cylinder(d = ant_hole_d - 0.4, h = 4.5);          // plug (short!)
        translate([0, 0, 4.5])
            cylinder(d = ant_cbore_d - 0.5, h = 1.4);      // flange / grommet
        translate([0, 0, 5.9])
            for (i = [0 : len(pts) - 2])
                hull() {
                    translate(pts[i])   sphere(2.8 - 1.3*i/(len(pts)-1));
                    translate(pts[i+1]) sphere(2.8 - 1.3*(i+1)/(len(pts)-1));
                }
    }
}

// Eye disc: drops into the recess; pupil dome offset like the photos
module eye_disc() {
    cylinder(d = eye_d - 0.6, h = eye_depth + 0.6);
    translate([-6, 0, eye_depth + 0.5])
        scale([1, 1, 0.5]) sphere(d = 7);
}

// ================= output =================

if (PART == "shell") {
    shell();
} else if (PART == "accessories") {
    for (y = [-1, 1]) translate([0, y*15, 0])  antenna();
    for (y = [-1, 1]) translate([35, y*20, 0]) eye_disc();
}
