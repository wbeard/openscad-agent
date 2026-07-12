// OpenClaw v2 — Mac mini crab case (BOSL2 rebuild, v005)
// ========================================================
// Device dims (user-verified, photogrammetry ±0.7 mm):
//   chassis 127.1 x 127.1 x 49.7 mm, corner radius ~22 (tunable; sources 22-23.5)
//   front, facing it (x from centerline, z above desk):
//     USB-C vertical pills 2.7 x 9.0 at x = -39.2, -23.5
//     LED at +25.4; headphone jack (~4.2 aperture) at +38.2
//     port centerline z = 20.3
//   airflow bottom-only (base ring); power button bottom left-rear
// Case: one-piece slip-over shell, open bottom. Print flipped (top on bed).
//
// PART = "shell"       -> the case
// PART = "accessories" -> 2 antennae (white) + 2 eye discs (black)

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
$fa = 1; $fs = 0.4;

PART = "shell";

// ---------------- device + fit ----------------
mini_w  = 127.1;   // Apple: 12.7 cm square
mini_h  = 49.7;
mini_rc = 22;      // caliper-verify; design tunable
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

// ---------------- front cutouts (photogrammetry) ----------------
port_z     = 20.3;
usbc_x     = [-39.2, -23.5];    // vertical pills
usbc_cut_w = 9;                 // cutout admits the cable plug body
usbc_cut_h = 15;
led_x  = 25.4;  led_d  = 4;
jack_x = 38.2;  jack_d = 10;

// ---------------- side vents (decorative; device breathes via bottom) ----------------
vent_n   = 6;
vent_w   = 4;
vent_gap = 9;
vent_h   = 28;
vent_z   = 12;
vent_yc  = 20;

// ---------------- claws ----------------
claw_z     = 16;                // palm center height
claw_embed = 2;                 // palm sunk into the wall

// ---------------- face ----------------
eye_d = 30;  eye_depth = 2;
eye_x = 29;  eye_y = 0;
ant_hole_d = 7;  ant_cbore_d = 13;
ant_x = 31;  ant_y = 40;        // rear edge of the top, like the photos

// ---------------- power button access ----------------
notch_r = 8;
notch_y = 32;                   // left wall, near the rear

// ================= claw =================
// Crab pincer along +X: bulbous palm, fat rounded upper finger and shorter
// lower thumb with a V gap between the rounded tips
module claw() {
    hull() { sphere(10); translate([7, 0, 0]) sphere(8.5); }
    hull() { translate([7, 0, 4]) sphere(7); translate([15, 0, 6]) sphere(4.5); }
    hull() { translate([7, 0, -4]) sphere(6); translate([13, 0, -6.5]) sphere(3.5); }
}

// ================= shell =================

module shell() {
    diff()
    union() {
        // body: rounded-square sweep, torus-rounded top edge
        offset_sweep(rect([out_w, out_w], rounding=rc),
                     height=out_h, top=os_circle(r=rt));

        // pincer claws, one per corner, pointing out along the diagonals
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*(corner + (rc - claw_embed)*0.707),
                       sy*(corner + (rc - claw_embed)*0.707),
                       claw_z])
                zrot(atan2(sy, sx))
                    claw();

        // ---- removals ----
        // interior cavity
        tag("remove") up(-0.01)
            linear_sweep(rect([cav_w, cav_w], rounding=rc_in),
                         h=cav_h + 0.01, anchor=BOT);

        // rear port window (+y wall)
        tag("remove")
            translate([0, out_w/2 - wall/2, rear_z + rear_h/2])
                cuboid([rear_w, wall + 16, rear_h], rounding=rear_r, edges="Y");

        // front (-y wall): 2 vertical USB-C pills, LED, headphone jack
        tag("remove")
            for (x = usbc_x)
                translate([x, -(out_w/2 - wall/2), port_z])
                    cuboid([usbc_cut_w, wall + 16, usbc_cut_h],
                           rounding=usbc_cut_w/2 - 0.01, edges="Y");
        tag("remove") translate([led_x, -(out_w/2 - wall/2), port_z])
            ycyl(d=led_d, l=wall + 16, $fn=32);
        tag("remove") translate([jack_x, -(out_w/2 - wall/2), port_z])
            ycyl(d=jack_d, l=wall + 16, $fn=48);

        // decorative side vents, both sides
        tag("remove")
            for (x = [-1, 1], i = [0 : vent_n - 1])
                translate([x*(out_w/2 - wall/2),
                           vent_yc + (i - (vent_n - 1)/2)*vent_gap,
                           vent_z + vent_h/2])
                    cuboid([wall + 16, vent_w, vent_h]);

        // power-button finger notch, left wall bottom rim near the rear
        tag("remove") translate([-(out_w/2 - wall/2), notch_y, 0])
            xcyl(r=notch_r, l=wall + 16);

        // eye disc recesses on top
        tag("remove")
            for (x = [-1, 1])
                translate([x*eye_x, eye_y, out_h - eye_depth])
                    cyl(d=eye_d, h=eye_depth + 1, anchor=BOT);

        // antenna holes with grommet counterbore
        tag("remove")
            for (x = [-1, 1])
                translate([x*ant_x, ant_y, 0]) {
                    up(out_h - wall - 2) cyl(d=ant_hole_d, h=wall + 4, anchor=BOT, $fn=48);
                    up(out_h - 1.6)      cyl(d=ant_cbore_d, h=3, anchor=BOT, $fn=64);
                }
    }
}

// ================= accessories =================

// Antenna: short plug (only ~1.3mm headroom above the device inside!),
// grommet flange, tapered horn with a 70-degree bend. Prints standing.
module antenna() {
    pts = [for (a = [0 : 10 : 70]) [16*(1 - cos(a)), 0, 16*sin(a)]];
    union() {
        cylinder(d = ant_hole_d - 0.4, h = 4.5, $fn=48);
        translate([0, 0, 4.5])
            cylinder(d = ant_cbore_d - 0.5, h = 1.4, $fn=64);
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
    // preview layout only — export single parts (STL gate rejects disjoint parts)
    for (y = [-1, 1]) translate([0, y*15, 0])  antenna();
    for (y = [-1, 1]) translate([35, y*20, 0]) eye_disc();
} else if (PART == "antenna") {
    antenna();      // print 2, in white
} else if (PART == "eye_disc") {
    eye_disc();     // print 2, in black
}
