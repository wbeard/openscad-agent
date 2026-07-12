// labyrinth_001.scad -- "Labyrinth" captive-ball fidget faceplate for the
// OpenClaw Mac mini case (mounts on the carrier of openclaw_case_005.scad).
//
// ============================================================================
// *** SLICER PAUSE AT Z=7.8 -- DROP 1 BB IN, RESUME ***
// ============================================================================
//
// Ball: 6mm airsoft BB (actual 5.95 +-0.03; design gated for 5.90..6.00).
// Print: FACE DOWN as modeled (cosmetic face at z=0 on the bed), 0.2mm layers.
//   - The z=7.8 channel ceiling bridges 7.2mm over the channels: fine for any
//     tuned printer; it is hidden inside the part anyway.
//   - Elephant foot narrows the 4.8 sight slot on layer 1: enable slicer
//     elephant-foot compensation (~0.2mm) or lightly deburr the slot edges.
//     The ball rides the shelf at z=1.2, not layer 1, so function is safe.
//   - Pause at Z=7.8 (layer 39 at 0.2mm), drop one BB anywhere into the open
//     channel network, resume. The ceiling bridges shut above it.
//
// Geometry stack (z = thickness, face at z=0):
//   z 0..8    maze block, outline 96x40 r9 (overlays the case bezel frame)
//   z 8..11   carrier base, plate outline 90x36 r7 (seats in the case pocket)
//   z 8.75..11  magnet pockets d6.15x2.25 open at the back
//   z 0..11   four port pass-throughs (widened +1/side through the block,
//             1x45deg chamfered mouths at the face)
//
// Channel spec:
//   channel 7.2 wide, void z 1.2..7.8 (ceiling = bridge layer at z 7.8)
//   sight slot 4.8 wide through the 1.2 face lip (z 0..1.2)
//   45deg flare 4.8 -> 7.2 between z 1.2 and 2.4 (ball shelf)
//   Ball d5.95 seat: center z = 1.2 + sqrt(2.975^2 - 2.4^2) = 2.958,
//   ball top z = 5.93 -> 1.87 headroom under the 7.8 ceiling (>= 1.5 OK).
//   Worst ball d6.00: center z 3.00, top 6.00 -> headroom 1.80 (OK).
//   Slot 4.8 < min ball 5.90 -> ball cannot fall out the face.
//
// PART = "plate" (default, bed-ready) | "plug" (loading plug) | "preview"
// DEBUG_XSEC = true -> thin slab through both straights (channel profile)
// LOADING_HOLE = true -> d7 back hole over the trap stub + use PART="plug"

PART         = "plate";   // "plate" | "plug" | "preview"
DEBUG_XSEC   = false;     // cross-section slab through the straights
LOADING_HOLE = false;     // fallback if you don't want a slicer pause

$fa = 3; $fs = 0.4;

// ---- Faceplate interface v1 (contract -- faceplate files copy this block) --
// carrier interface v1 -- matches openclaw_case_005.scad
fp_w      = 90;    fp_h = 36;    fp_r = 7;  // plate outline, rounded rect
fp_cz     = 22;                             // plate center height (case z)
fp_t      = 3.0;                            // plate thickness = pocket depth
fp_clr    = 0.4;                            // pocket clearance per side
frame_w   = 100;   frame_h = 44;  frame_r = 11;  // bezel frame outline (z 0..44)
frame_p   = 3.0;                            // frame protrusion from face
frame_e   = 3.0;                            // frame embed into wall
mag_d     = 6;     mag_t = 2;               // N35 disc 6x2 (+-0.1 mfg tol)
mag_pock_d = 6.15; mag_pock_t = 2.25;       // clearance fit + glue
mag_x     = 34;    mag_dz = 12.5;           // magnets at (+-34, fp_cz +- 12.5)
notch_w   = 20;                             // finger notch, bottom center
cham      = 1.2;                            // 45-deg pocket rim lead-in
// plate-local pass-throughs (yl = case z - fp_cz):
//   USB pills 7x14 at (-39.2, -1.7) & (-23.5, -1.7)
//   LED d5 at (+25.4, -1.7); jack d10 at (+38.2, -1.7)
//   magnet pockets d6.15 x 2.25 from the BACK at (+-34, +-12.5), 0.8 front skin

// port coordinates -- copied from openclaw_case_005.scad (used by the
// interface modules below)
port_z     = 20.3;   // port centerline height
usbc_x     = [-39.2, -23.5];
led_x      = 25.4;
jack_x     = 38.2;

// carrier interface v1 -- matches openclaw_case_005.scad
module rrect2(w, h, r) {
    offset(r = r) square([w - 2*r, h - 2*r], center = true);
}

// carrier interface v1 -- matches openclaw_case_005.scad
module plate_passthroughs() {
    for (x = usbc_x)
        hull()
            for (s = [-1, 1])
                translate([x, (port_z - fp_cz) + s*(14/2 - 7/2), -1])
                    cylinder(d = 7, h = fp_t + 2);
    translate([led_x, port_z - fp_cz, -1])  cylinder(d = 5,  h = fp_t + 2);
    translate([jack_x, port_z - fp_cz, -1]) cylinder(d = 10, h = fp_t + 2);
}

// carrier interface v1 -- matches openclaw_case_005.scad
module plate_magnet_pockets() {
    // from the back, leaving a 0.8 cosmetic front skin
    for (x = [-1, 1], y = [-1, 1])
        translate([x*mag_x, y*mag_dz, fp_t - mag_pock_t])
            cylinder(d = mag_pock_d, h = mag_pock_t + 0.1);
}

// ================= labyrinth parameters =================

blk_w  = 96;  blk_h = 40;  blk_r = 9;   // maze block outline
blk_t  = 8;                             // block thickness (z 0..8)
tot_t  = 11;                            // total thickness (block + carrier)

lip_t   = 1.2;    // sight lip (face skin) thickness
slot_w  = 4.8;    // sight slot width (through the lip)
flare_z = 2.4;    // 45deg flare done by here (4.8 -> 7.2 over z 1.2..2.4)
ch_w    = 7.2;    // channel width
ceil_z  = 7.8;    // channel ceiling (bridge layer) -> channel height 6.6
gate_w  = 6.4;    // pinch-gate opening
widen   = 1.0;    // port tunnel widening per side through the block
yl_port = port_z - fp_cz;   // -1.7, port centerline in plate-local yl

ball_lo = 5.90;  ball_hi = 6.00;  ball_nom = 5.95;

// ---- ball-gate sanity (evaluated every compile) ----
seat_z_nom = lip_t + sqrt(pow(ball_nom/2,2) - pow(slot_w/2,2)); // 2.958
seat_z_hi  = lip_t + sqrt(pow(ball_hi/2,2)  - pow(slot_w/2,2)); // 3.000
assert(slot_w <= ball_lo - 1.0, "slot too wide: ball could escape the face");
assert(ch_w   >= ball_hi + 1.0, "channel too tight for the biggest ball");
assert(gate_w >= ball_hi + 0.35, "pinch gate would jam the biggest ball");
assert(ceil_z - (seat_z_hi + ball_hi/2) >= 1.5, "not enough headroom");
echo("*** SLICER PAUSE AT Z=7.8 -- DROP 1 BB IN, RESUME ***");
echo(str("ball d", ball_nom, " seat center z=", seat_z_nom,
         "  top z=", seat_z_nom + ball_nom/2,
         "  headroom=", ceil_z - (seat_z_nom + ball_nom/2)));

// ================= maze layout (hand-tuned polylines, plate-local mm) ======
//
// Widened port tunnel envelopes (block portion, +1/side):
//   USB pills d9:  USB1 x -43.7..-34.7, USB2 x -28.0..-19.0, yl -9.7..+6.3
//   LED d7:  x 21.9..28.9, yl -5.2..+1.8
//   jack d12: x 32.2..44.2, yl -7.7..+4.3
// Channel void half-width 3.6; keep >=1.5 to tunnels & magnet pockets,
// >=1.4 to everything else. Magnet pocket voids: r3.075 at (+-34, +-12.5).
//
// Clearance arithmetic (all gaps are void-edge to void-edge):
//  * straights end at x +-25.5, NOT the spec sketch's +-27 or +-38:
//      lateral gap to magnet pocket = (34 - 25.5) - 3.6 - 3.075 = 1.825 >= 1.5
//      (at +-27 the gap is only 0.325 -- violates; 45deg corner elbows were
//       checked and rejected: an elbow from (25.5,12.5) toward the corner
//       passes ~5.66 from the magnet center < 3.6+3.075+1.5 = 8.175)
//  * top straight yl +12.5: void bottom 8.9 vs USB tops 6.3 -> gap 2.6
//  * bottom straight yl -13.5 CANNOT pass under USB2: void top -9.9 vs pill
//      bottom -9.7 -> 0.2 gap; and no lower lane exists (band between pill
//      bottom -9.7-1.5 and base-coverage edge -18 is 6.8 < 7.2 channel).
//      So the bottom straight runs x -13.5..+25.5 (its left end = connector 1)
//  * bottom straight right end (25.5,-13.5) to magnet (34,-12.5):
//      sqrt(8.5^2+1^2) - 3.6 - 3.075 = 1.88 >= 1.5
//  * connector C1 at x -13.5 (spec sketch -15 gives 0.4 -- violates):
//      void left edge -17.1 vs USB2 right edge -19.0 -> gap 1.9
//  * connector C2 at x +3: >= 15.3 to everything
//  * connector C3 at x +16.5 (spec sketch +18 gives 0.3 -- violates):
//      void right edge 20.1 vs LED left edge 21.9 -> gap 1.8
//  * trap stub (3,0)->(7.5,-4.5): right edge 11.1 vs C3 void 12.9 -> 1.8;
//      bottom edge -8.1 vs bottom-straight void top -9.9 -> 1.8
//  * base (90x36) ceiling coverage: deepest void edge yl -17.25 (divot),
//      widest yl +16.1 -- all inside +-18, so every channel has the full
//      z 7.8..11 lid (0.2 block + 3.0 base) above it
//  * divot (6.25,-13.5) r3.75, z 0.6..1.3: block edge yl -20 -> wall 2.75

pt_TL = [-25.5,  12.5];  pt_TR = [ 25.5,  12.5];   // top straight
pt_BL = [-13.5, -13.5];  pt_BR = [ 25.5, -13.5];   // bottom straight
x_c1  = -13.5;  x_c2 = 3;  x_c3 = 16.5;            // connectors

maze_paths = [
    [pt_TL, pt_TR],                                // top straight
    [[x_c1, 12.5], [x_c1, -13.5]],                 // connector 1
    [[x_c2, 12.5], [x_c2, -13.5]],                 // connector 2
    [[x_c3, 12.5], [x_c3, -13.5]],                 // connector 3
    [pt_BL, pt_BR],                                // bottom straight
    [[x_c2, 0], [7.5, -4.5]],                      // dead-end trap stub (45deg)
];

trap_end  = [7.5, -4.5];          // loading hole goes here
divot_pos = [6.25, -13.5];        // start divot: center of bottom straight
gate_T_x  = -20;                  // pinch gate on the top straight
gate_B_x  =  22;                  // pinch gate on the bottom straight

// ================= channel network modules =================

// hull-chain of consecutive cylinders -> capsule runs, corners rounded r>=3.6
module chain(path, d, z0, z1) {
    for (i = [0 : len(path) - 2])
        hull() for (p = [path[i], path[i+1]])
            translate([p[0], p[1], z0]) cylinder(d = d, h = z1 - z0);
}

// 45deg flare 4.8 -> 7.2 between z 1.2 and 2.4 (hull of cone pairs)
module flare(path) {
    for (i = [0 : len(path) - 2])
        hull() for (p = [path[i], path[i+1]])
            translate([p[0], p[1], lip_t])
                cylinder(d1 = slot_w, d2 = ch_w, h = flare_z - lip_t);
}

module sight_slot(path) { chain(path, slot_w, -0.1, lip_t + 0.05); }
module channel(path)    { chain(path, ch_w, flare_z - 0.05, ceil_z); }

module maze_voids() {
    for (p = maze_paths) {
        sight_slot(p);
        flare(p);
        channel(p);
    }
    // start divot: d7.5 x 0.6 deep in the channel floor (shelf) -- ball drops
    // 0.6 into it and needs a flick to leave the start position
    translate([divot_pos[0], divot_pos[1], lip_t - 0.6])
        cylinder(d = 7.5, h = 0.7);
    if (LOADING_HOLE)   // fallback: d7 hole through the back over the trap
        translate([trap_end[0], trap_end[1], ceil_z - 0.1])
            cylinder(d = 7, h = tot_t - ceil_z + 0.2);
}

// pinch gate: opposing wall bumps narrowing the channel to 6.4 at ball height
module gate_bumps(x, yc) {
    for (s = [-1, 1])
        translate([x, yc + s*(ch_w/2 + 1.5 - (ch_w - gate_w)/2), 1.8])
            cylinder(r = 1.5, h = ceil_z - 1.8);   // protrudes 0.4 into channel
}

// widened port tunnels through the block (z 0..8) + 1x45 chamfered mouths
module block_tunnels() {
    for (x = usbc_x) {
        hull() for (s = [-1, 1])
            translate([x, yl_port + s*3.5, -0.1]) cylinder(d = 9, h = blk_t + 0.11);
        hull() for (s = [-1, 1])
            translate([x, yl_port + s*3.5, -0.02]) cylinder(d1 = 11, d2 = 9, h = 1);
    }
    translate([led_x, yl_port, -0.1])   cylinder(d = 7,  h = blk_t + 0.11);
    translate([led_x, yl_port, -0.02])  cylinder(d1 = 9,  d2 = 7,  h = 1);
    translate([jack_x, yl_port, -0.1])  cylinder(d = 12, h = blk_t + 0.11);
    translate([jack_x, yl_port, -0.02]) cylinder(d1 = 14, d2 = 12, h = 1);
}

// ================= the plate =================

module plate() {
    union() {
        difference() {
            union() {
                // maze block z 0..8, 0.6x45 face-edge chamfer (elephant foot)
                hull() {
                    linear_extrude(0.05) offset(r = -0.6) rrect2(blk_w, blk_h, blk_r);
                    translate([0, 0, 0.6]) linear_extrude(0.05) rrect2(blk_w, blk_h, blk_r);
                }
                translate([0, 0, 0.6]) linear_extrude(blk_t - 0.6) rrect2(blk_w, blk_h, blk_r);
                // carrier base z 8..11
                translate([0, 0, blk_t]) linear_extrude(tot_t - blk_t) rrect2(fp_w, fp_h, fp_r);
            }
            maze_voids();
            block_tunnels();
            // contract cutouts through the carrier portion (z 7..11.1 covered)
            translate([0, 0, blk_t]) {
                plate_passthroughs();
                plate_magnet_pockets();
            }
        }
        // pinch gates (added back inside the channel, fused to walls+ceiling)
        gate_bumps(gate_T_x,  12.5);
        gate_bumps(gate_B_x, -13.5);
    }
}

// loading plug: press-fit, prints head-down
module plug() {
    cylinder(d = 7.4, h = 1.2);                       // head (jams in d7 mouth)
    translate([0, 0, 1.2]) cylinder(d = 6.85, h = 3.2); // stem (fills to ceiling)
}

// ================= part selection =================

module plate_shown() {
    if (DEBUG_XSEC)
        // slab x 10.5..12.5 -- clear of divot (ends x 10.0) and C3 (starts
        // 12.9); shows both straights' profiles: slot, flare, seat, ceiling.
        rotate([0, -90, 0])
            intersection() {
                plate();
                translate([10.5, -25, -1]) cube([2, 50, tot_t + 2]);
            }
    else
        plate();
}

if (PART == "plate") {
    plate_shown();
} else if (PART == "plug") {
    plug();
} else if (PART == "preview") {
    // face-up display: flip so the sight slots face the camera; dummy ball
    // sitting in the start divot (seat center z = 0.6 + 1.758 = 2.358)
    translate([0, 0, tot_t]) rotate([180, 0, 0]) color("LightSteelBlue") plate();
    color("Red")
        translate([divot_pos[0], -divot_pos[1], tot_t - (0.6 + sqrt(pow(ball_nom/2,2) - pow(slot_w/2,2)))])
            sphere(d = ball_nom);
}
