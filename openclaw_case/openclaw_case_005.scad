// OpenClaw Mac Mini case (crab shell) - v005: magnetic faceplate interface
// Fits Apple Mac mini M4 (2024): 127.1 x 127.1 x 49.7 mm
// Open bottom: the mini slides in from below, case rests over it.
// Print orientation: top face down on the bed (flip 180 in slicer).
//
// v005 changes vs v004:
//   - FIXED front cutouts to the real M4 layout (photogrammetry vs Chargerlab
//     teardown, +-0.7mm -- caliper-verify): vertical USB-C pills at x=-39.2/-23.5,
//     LED d5 at +25.4, headphone jack d9 at +38.2, all centered z=20.3.
//     (v004's horizontal 15x8 slots at +-10 / jack +32 / LED -32 were wrong.)
//   - FIXED cavity corner radius 26 -> 23 (mini corner ~22mm; v004 bound ~0.5mm
//     on the corner diagonals).
//   - NEW raised bezel frame ("crab apron") on the front face with a recessed
//     magnetic faceplate pocket: interchangeable 90x36 plates, 4x 6x2 N35 discs.
//     Magnet pockets are CLEARANCE fit (+0.15) -- FDM holes print undersize;
//     glue (CA dab) is the primary retention. Case magnets N-out, plate S-out.
//   - NEW vent grid through the pocket floor (upper band): the louver faceplate
//     meters it; all other plates seal it.
//
// PART = "shell"       -> the case itself
// PART = "accessories" -> 2 antennae + 2 eye discs (print in white/black)
// PART = "plate_blank" -> reference blank faceplate (prints face-down)
// PART = "fit_coupon"  -> pocket-corner + magnet-fit test coupon (PRINT FIRST)
// PART = "assembly"    -> preview: shell with a blank plate seated

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
rc_in  = 23;                      // cavity corner radius (mini ~22, VERIFY)
rc     = rc_in + wall;            // outer vertical corner radius
rt     = 12;                      // top edge roundover
corner = out_w/2 - rc;            // corner circle center offset (41.25)
front_y = -out_w/2;               // front face plane (-68.25)

// ---- Rear port opening ----
rear_w = 94;   // narrow enough to clear the rear claws
rear_h = 26;
rear_z = 12;
rear_r = 8;

// ---- Front ports (REAL M4 layout; viewer's left = -x, facing the front) ----
// Device: USB-C vertical pills 2.7x9 at -39.2/-23.5, LED at +25.4,
// jack ~4.2 aperture at +38.2, centerline 20.3 above desk. Cutouts carry
// >=1.5mm slop for the photogrammetry tolerance.
port_z     = 20.3;   // port centerline height
usbc_x     = [-39.2, -23.5];
usbc_w     = 6;      // cutout width  (device pill 2.7)
usbc_h     = 13;     // cutout height (device pill 9.0)
led_x      = 25.4;
led_d      = 5;
jack_x     = 38.2;
jack_d     = 9;

// ---- Faceplate interface v1 (contract -- faceplate files copy this block) ----
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
// MOUNTING CHIRALITY: plates are modeled with the cosmetic FACE at z=0
// (face-down print). Seating the plate (face outward, yl up) maps
// plate-local +x -> case -x. Therefore plate-local pass-through x-coords
// are the NEGATION of the case-coordinate port positions:
//   USB pills 7x14 at (+39.2, -1.7) & (+23.5, -1.7)   [case x -39.2/-23.5]
//   LED d5 at (-25.4, -1.7); jack d10 at (-38.2, -1.7) [case x +25.4/+38.2]
//   magnet pockets d6.15 x 2.25 from the BACK at (+-34, +-12.5), 0.8 front skin
// Face text/asymmetric art must be MIRRORED in model space to read correctly
// when mounted (verify via a face-side render).

// ---- Vent grid through pocket floor (upper band; louver plate meters it) ----
vgrid_x   = [-21, -7, 7, 21];   // slot centers
vgrid_z   = [29.5, 35.5];       // two rows
vgrid_w   = 10;   vgrid_h = 3;  // slot size (rounded r1.5)

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

// ================= 2D helpers =================

module rrect2(w, h, r) {
    offset(r = r) square([w - 2*r, h - 2*r], center = true);
}

// ================= shell modules =================

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
                    cylinder(r = r, h = 46, center = true);
}

// Two-lobe pincer claw, built pointing along +X
module claw() {
    union() {
        sphere(claw_r1);
        translate([5, 0, claw_r1 - 4]) sphere(claw_r2);
    }
}

// Extrude a 2D XZ-plane profile along -Y, from y0 toward the front, depth d
module xz_slab(y0, d) {
    translate([0, y0, 0])
        rotate([90, 0, 0])
            linear_extrude(d)
                children();
}

// ---- Faceplate frame + pocket ----

// Raised bezel frame ("crab apron"): slab embedded frame_e into the wall,
// protruding frame_p from the face. Frame sits on the bed span z 0..frame_h.
module faceplate_frame() {
    xz_slab(front_y + frame_e, frame_e + frame_p)
        translate([0, frame_h/2])
            rrect2(frame_w, frame_h, frame_r);
}

// Cutters for the pocket: recess + rim chamfer + finger notch + floor divot
module faceplate_pocket() {
    pw = fp_w + 2*fp_clr;   // 90.8
    ph = fp_h + 2*fp_clr;   // 36.8
    pr = fp_r + fp_clr;
    ff = front_y - frame_p; // frame front plane (-71.25)

    // straight pocket: frame front -> original face plane
    xz_slab(front_y, frame_p + 0.1)
        translate([0, fp_cz]) rrect2(pw, ph, pr);
    // 45-deg chamfer lead-in at the rim
    hull() {
        xz_slab(ff - 0.05, 0.1)
            translate([0, fp_cz]) offset(r = cham) rrect2(pw, ph, pr);
        xz_slab(ff + cham, 0.1)
            translate([0, fp_cz]) rrect2(pw, ph, pr);
    }
    // finger notch through the frame's bottom rim
    hull()
        for (x = [-1, 1])
            translate([x*(notch_w/2 - 3), ff - 1, 0])
                rotate([-90, 0, 0])
                    cylinder(r = 3, h = 3);
    translate([-notch_w/2, ff - 1, -1])
        cube([notch_w, 3, 10]);
    // thumbnail divot into the pocket floor behind the plate's bottom edge
    translate([-notch_w/2, front_y, 3])
        cube([notch_w, 1.5, 7]);
}

// Magnet pockets drilled into the pocket floor (leaves 1.75mm to cavity)
module magnet_pockets_case() {
    for (x = [-1, 1], dz = [-1, 1])
        translate([x*mag_x, front_y + mag_pock_t, fp_cz + dz*mag_dz])
            rotate([90, 0, 0])
                cylinder(d = mag_pock_d, h = mag_pock_t + 0.1);
}

// Front port cutters (shared by shell and seated plate; punch through all)
module front_cutters() {
    for (x = usbc_x)
        translate([x, front_y + wall/2, port_z])
            y_slot(usbc_w, usbc_h, usbc_w/2 - 0.01);
    translate([led_x, front_y + wall/2, port_z])
        rotate([90, 0, 0]) cylinder(d = led_d, h = 46, center = true);
    translate([jack_x, front_y + wall/2, port_z])
        rotate([90, 0, 0]) cylinder(d = jack_d, h = 46, center = true);
}

// Vent grid through the pocket floor, upper band (|x|<=26, clear of magnets)
module vent_grid() {
    for (x = vgrid_x, z = vgrid_z)
        translate([x, front_y + wall/2, z])
            y_slot(vgrid_w, vgrid_h, 1.45);
}

// ================= shell =================

module shell() {
    difference() {
        union() {
            rounded_shell(out_w, out_h, rc, rt);
            faceplate_frame();
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

        // front ports + faceplate interface (-y wall)
        front_cutters();
        faceplate_pocket();
        magnet_pockets_case();
        vent_grid();

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

// ================= faceplate blank (reference carrier) =================
// Plate-local coords: x across (matches case x), yl up (case z - fp_cz),
// z = thickness with the cosmetic FACE at z=0. Prints face-down as modeled
// (face on the bed). Faceplate designs copy this module + the param block.

module plate_passthroughs() {
    // mirrored in x: plate-local +x -> case -x when mounted (see contract)
    mirror([1, 0, 0]) {
        for (x = usbc_x)
            hull()
                for (s = [-1, 1])
                    translate([x, (port_z - fp_cz) + s*(14/2 - 7/2), -1])
                        cylinder(d = 7, h = fp_t + 2);
        translate([led_x, port_z - fp_cz, -1])  cylinder(d = 5,  h = fp_t + 2);
        translate([jack_x, port_z - fp_cz, -1]) cylinder(d = 10, h = fp_t + 2);
    }
}

module plate_magnet_pockets() {
    // from the back, leaving a 0.8 cosmetic front skin
    for (x = [-1, 1], y = [-1, 1])
        translate([x*mag_x, y*mag_dz, fp_t - mag_pock_t])
            cylinder(d = mag_pock_d, h = mag_pock_t + 0.1);
}

module plate_base() {
    difference() {
        union() {
            // 0.8 chamfered face edge
            hull() {
                linear_extrude(0.05)
                    offset(r = -0.8) rrect2(fp_w, fp_h, fp_r);
                translate([0, 0, 0.8])
                    linear_extrude(0.05) rrect2(fp_w, fp_h, fp_r);
            }
            translate([0, 0, 0.8])
                linear_extrude(fp_t - 0.8) rrect2(fp_w, fp_h, fp_r);
        }
        plate_passthroughs();
        plate_magnet_pockets();
    }
}

// Seated plate for the assembly preview, built directly in case coords
// (back against the pocket floor, face flush with the frame front)
module plate_seated() {
    difference() {
        xz_slab(front_y, fp_t)
            translate([0, fp_cz]) rrect2(fp_w, fp_h, fp_r);
        front_cutters();
        // magnet pockets from the back face
        for (x = [-1, 1], dz = [-1, 1])
            translate([x*mag_x, front_y - fp_t + mag_pock_t, fp_cz + dz*mag_dz])
                rotate([90, 0, 0])
                    cylinder(d = mag_pock_d, h = mag_pock_t + 0.1);
    }
}

// ================= fit coupon =================
// PRINT THIS FIRST. Left: pocket-corner recess (checks plate drop-in fit).
// Right: three magnet pockets at d6.05 / 6.15 / 6.25 (1/2/3 dots) -- pick
// the one that grips a 6x2 disc snugly and set mag_pock_d accordingly.

module fit_coupon() {
    pw = fp_w + 2*fp_clr;
    ph = fp_h + 2*fp_clr;
    pr = fp_r + fp_clr;
    difference() {
        linear_extrude(5) rrect2(70, 28, 3);
        // pocket-corner recess: one rounded corner of the real pocket outline
        // lands at (-26, 0); drop the plate's matching corner in to test fit
        translate([-26 + pw/2, ph/2, 5 - fp_t])
            linear_extrude(fp_t + 1) rrect2(pw, ph, pr);
        // three magnet pockets: d6.05 / 6.15 / 6.25, marked by 1/2/3 dots
        for (i = [0 : 2]) {
            px = -20 + i*16;
            translate([px, -8, 5 - mag_pock_t])
                cylinder(d = 6.05 + i*0.10, h = mag_pock_t + 1);
            for (dot = [0 : i])
                translate([px + 6, -11.5 + dot*2.5, 4.4])
                    cylinder(d = 1.6, h = 1);
        }
    }
}

// ================= accessories =================

// Curved antenna: plug fits the 7mm hole, horn curves like an eyestalk.
// Printed standing: plug on the bed, horn bends 70 degrees (support-free).
module antenna() {
    pts = [for (a = [0 : 10 : 70]) [18*(1 - cos(a)), 0, 18*sin(a)]];
    union() {
        cylinder(d = ant_hole_d - 0.4, h = 10);
        translate([0, 0, 10])
            cylinder(d = ant_cbore_d - 0.5, h = 1.4);
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
    for (y = [-1, 1])
        translate([0, y*15, 0])
            antenna();
    for (y = [-1, 1])
        translate([40, y*20, 0])
            eye_disc();
} else if (PART == "plate_blank") {
    plate_base();
} else if (PART == "fit_coupon") {
    fit_coupon();
} else if (PART == "assembly") {
    shell();
    color("coral") plate_seated();
}
