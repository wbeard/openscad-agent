// MacBook Lid Prop v002 — clips onto the base front edge, three-finger hook
// holds the lid open ~40mm for airflow.
// Designed to scale for MacBook Pro 14"/16".
// v002 changes:
//   - Bottom lip thinned 4 -> 2.5mm (fits under base with ~2.5mm foot height)
//   - Top lip thickened to 5mm for strength
//   - 45-degree chamfer lead-in at slot mouth for easy clip-on
//   - Snugger slot fit (0.4mm clearance)
//   - Wider stem base, rounder block corners
// Print suggestion: TPU or PETG, lying on its back with supports under fingers.

$fn = 64;

// ---------- Laptop dimensions (MacBook Pro 14/16) ----------
lid_t      = 4.7;    // lid thickness
base_t     = 11.0;   // base body thickness at front edge
clear      = 0.4;    // fit clearance

// ---------- Clamp block (grips laptop base edge) ----------
block_w    = 26;     // width along laptop edge (X)
block_d    = 20;     // depth (Y), laptop enters from +Y
block_r    = 4;      // corner rounding
lip_bot    = 2.5;    // thin lip slips under the base (feet lift it ~2.5mm)
lip_top    = 5;      // thicker lip rides on the palm-rest deck edge
slot_d     = 12;     // how far the base edge slides in
slot_h     = base_t + clear;             // 11.4
block_h    = slot_h + lip_bot + lip_top; // 18.9

// ---------- Fingers / hook ----------
finger_d   = 7;                      // finger tube diameter
n_fingers  = 3;
finger_gap = 4.5;                    // spacing between fingers
palm_w     = n_fingers * finger_d + (n_fingers - 1) * finger_gap; // 30
hook_gap   = lid_t + clear;          // 5.1 — lid slides in here
hook_R     = (hook_gap + finger_d) / 2;  // curl centerline radius

// ---------- Heights / positions ----------
lid_rest_z = 55;                     // where the lid bottom edge rests
curl_z     = lid_rest_z + hook_R - finger_d / 2;  // curl center height
palm_y     = -15;                    // stem/palm depth position
leg_len    = 8;                      // lower leg the lid rests on
tip_len    = 7;                      // upper fingertip over the lid

// ============================================================

// capsule along X: rounded bar
module xbar(half_w, d) {
    hull() {
        translate([-half_w, 0, 0]) sphere(d = d);
        translate([ half_w, 0, 0]) sphere(d = d);
    }
}

// rounded clamp block, slot opening toward +Y (laptop side)
module clamp_block() {
    difference() {
        // rounded box: x centered, y in [-block_d, 0], z in [0, block_h]
        hull()
            for (x = [-block_w/2 + block_r, block_w/2 - block_r],
                 y = [-block_d + block_r, -block_r],
                 z = [block_r, block_h - block_r])
                translate([x, y, z]) sphere(r = block_r);
        // slot for the laptop base edge
        translate([-block_w/2 - 1, -slot_d, lip_bot])
            cube([block_w + 2, slot_d + 1, slot_h]);
        // chamfered lead-in at the slot mouth (top and bottom lip)
        translate([0, 0.5, lip_bot])
            rotate([45, 0, 0]) cube([block_w + 2, 3, 3], center = true);
        translate([0, 0.5, lip_bot + slot_h])
            rotate([45, 0, 0]) cube([block_w + 2, 3, 3], center = true);
    }
}

// one finger: C-curl in the Y-Z plane opening toward +Y,
// with a lower leg (lid rests on it) and an upper tip (hooks over lid)
module finger() {
    // curl: half-torus, ends at z = ±hook_R, bulging toward -Y
    rotate([0, 0, 180]) rotate([0, 90, 0])
        rotate_extrude(angle = 180)
            translate([hook_R, 0]) circle(d = finger_d);
    // lower leg toward laptop
    translate([0, 0, -hook_R]) {
        rotate([-90, 0, 0]) cylinder(h = leg_len, d = finger_d);
        translate([0, leg_len, 0]) sphere(d = finger_d);
    }
    // upper fingertip over the lid
    translate([0, 0, hook_R]) {
        rotate([-90, 0, 0]) cylinder(h = tip_len, d = finger_d);
        translate([0, tip_len, 0]) sphere(d = finger_d);
    }
}

module lid_prop() {
    clamp_block();

    // stem: flares from block top up into the palm
    hull() {
        translate([0, palm_y, block_h + 1]) xbar(7, 13);
        translate([0, palm_y, 36])          xbar(4.5, 10);
    }
    hull() {
        translate([0, palm_y, 36])                   xbar(4.5, 10);
        translate([0, palm_y, curl_z - hook_R])      xbar(palm_w/2 - finger_d/2, finger_d);
    }

    // palm bar + three fingers
    translate([0, palm_y, curl_z - hook_R])
        xbar(palm_w/2 - finger_d/2, finger_d);
    for (i = [-1, 0, 1])
        translate([i * (finger_d + finger_gap), palm_y, curl_z])
            finger();
}

color("darkorange") lid_prop();
