// OpenClaw-style Mac Mini case (crab shell)
// Fits Apple Mac mini (M2/M4): 127 x 127 x 50 mm
// Open bottom: the mini slides in from below, case rests over it.
// Print orientation: top face down on the bed (flip 180 in slicer).

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

// ---- Rear port opening ----
rear_w = 104;
rear_h = 26;
rear_z = 12;      // bottom of opening above bed
rear_r = 8;

// ---- Front ports (2x USB-C + headphone jack) ----
front_z    = 20;   // center height
usbc_w     = 14;   // generous slot width
usbc_h     = 7;
jack_d     = 9;

// ---- Side vents ----
vent_n   = 6;
vent_w   = 4;      // slot width (along y)
vent_gap = 9;      // pitch
vent_h   = 28;
vent_z   = 10;
vent_y0  = 10;     // start offset toward rear (+y)

// ---- Ears ----
ear_r = 10;
ear_z = 16;
ear_y = -34;       // toward the front

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

// Interior cavity: rounded square column, flat top
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

// ================= assembly =================

difference() {
    union() {
        rounded_shell(out_w, out_h, rc, rt);
        // side ears (little crab bumps)
        for (x = [-1, 1])
            translate([x*(out_w/2 - 1), ear_y, ear_z])
                sphere(ear_r);
    }

    // interior
    cavity();

    // rear port opening (+y wall)
    translate([0, out_w/2 - wall/2, rear_z + rear_h/2])
        y_slot(rear_w, rear_h, rear_r);

    // front: two USB-C slots + headphone jack (-y wall)
    for (x = [-10, 10])
        translate([x, -(out_w/2 - wall/2), front_z])
            y_slot(usbc_w, usbc_h, usbc_h/2 - 0.01);
    translate([32, -(out_w/2 - wall/2), front_z])
        rotate([90, 0, 0])
            cylinder(d = jack_d, h = 40, center = true);

    // side vents (both sides, rear half)
    for (x = [-1, 1], i = [0 : vent_n - 1])
        translate([x*(out_w/2 - wall/2),
                   vent_y0 + i*vent_gap - (vent_n-1)*vent_gap/2 + 20,
                   vent_z + vent_h/2])
            cube([wall + 8, vent_w, vent_h], center = true);
}
