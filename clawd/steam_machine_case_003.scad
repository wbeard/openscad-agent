// Steam Machine Protective Case ("OpenClaw" crab style) - v003
// Changes from v002: full crab character, matching openclaw_case_004.scad:
//   - four corner two-lobe pincer claws near the bottom rim
//   - face on top: two eye disc recesses + two antenna grommet holes
//   - PART selector: "shell" or "accessories" (2 antennae + 2 eye discs)
//   - rear and front windows narrowed 130/132 -> 120 to clear the claws
//   - top vent band shifted to the rear half of the top to make room for the face
//   - antenna plug shortened to 3.5mm (wall is 4mm; only 0.75mm headroom
//     above the device, so the mini's 10mm plug would hit the device top)
//
// Real device dimensions (Valve Steam Machine, announced Nov 2025):
//   Width : 156.0 mm
//   Depth : 162.4 mm
//   Height: 152.0 mm (with feet; 148 mm without)
// Sources: Tom's Hardware review, thegamepost.com full specs.
//
// Front (low, near base): power button, 2x USB-A 3.2, microSD slot, LED light bar
// Rear: DisplayPort 1.4, HDMI 2.0, Ethernet, USB-C, 2x USB-A, AC power + fan grille
//
// Print orientation: shell open-bottom down on the bed; accessories as laid out.

PART = "shell";

$fn = 64;

/* ---------------- Parameters ---------------- */
// Device
dev_w = 156.0;   // X - width
dev_d = 162.4;   // Y - depth
dev_h = 152.0;   // Z - height (with feet)

// Fit
clearance = 0.75;   // per side
wall      = 4.0;    // wall thickness

// Derived cavity (inner) dimensions
cav_w = dev_w + 2*clearance;
cav_d = dev_d + 2*clearance;
cav_h = dev_h + clearance;      // clearance on top only (bottom is open)

// Outer shell
out_w = cav_w + 2*wall;         // 165.5
out_d = cav_d + 2*wall;         // 171.9
out_h = cav_h + wall;           // 156.75

r_out = 12;   // outer corner/top rounding radius
r_in  = 8;    // inner cavity corner radius

// Corner circle centers (vertical edges)
corner_x = out_w/2 - r_out;     // 70.75
corner_y = out_d/2 - r_out;     // 73.95

// Rear port/fan opening (rounded rect window). Narrowed to clear the claws:
// claw big lobe reaches |x| = 65.2, window edge at 60 -> 5.2mm margin.
rear_cut_w = 120;
rear_cut_z0 = 12;
rear_cut_z1 = 132;
rear_cut_r = 10;

// Front opening (power button + USB-A + microSD + LED bar, all near base)
front_cut_w = 120;   // narrowed from 132 to clear the front claws
front_cut_z0 = 8;
front_cut_z1 = 50;
front_cut_r = 6;

// Side vent slats (vertical)
slat_n = 9;        // per side
slat_w = 5;        // slot width (along Y)
slat_pitch = 12;
slat_z0 = 30;
slat_z1 = 122;

// Top vent slats (run along Y, rear half of the top - face goes in front)
top_slat_n = 9;
top_slat_w = 4;       // along X
top_slat_pitch = 12;
top_slat_len = 55;    // along Y
top_slat_y = 38;      // band center (rear half); spans y = 10.5 .. 65.5

// Decorative round "ear" bumps on the sides
ear_r = 10;
ear_protrude = 6;
ear_z = 134;   // keep >= 2mm above slat tops (slat_z1) to avoid tangent geometry
ear_y_off = 35;   // +/- from center, two ears per side

// Crab claws (one per corner, two-lobe pincer; ~20% up from the mini case)
claw_r1  = 14;    // big lobe
claw_r2  = 11;    // small lobe (creates the pincer crease)
claw_z   = 18;    // big lobe center height (sphere bottom at z=4, clear of bed)

// Face: eyes + antennae on the top surface (front half)
eye_d       = 30;    // eye disc recess diameter
eye_depth   = 2;
eye_x       = 26;
eye_y       = -32;   // forward of center (front = -Y)
ant_hole_d  = 7;     // antenna through-hole
ant_cbore_d = 13;    // grommet-look counterbore
ant_x       = 40;
ant_y       = -58;   // toward the front corners (flat region ends at |y|=73.95)

/* ---------------- Helpers ---------------- */

// Rounded box: flat bottom at z=0, rounded vertical edges and rounded top
module rounded_shell_solid(w, d, h, r) {
    hull() {
        for (sx = [-1, 1], sy = [-1, 1]) {
            translate([sx*(w/2 - r), sy*(d/2 - r), 0]) {
                cylinder(r = r, h = h - r);
                translate([0, 0, h - r]) sphere(r = r);
            }
        }
    }
}

// Rounded-rect prism along Y (for rear/front window cutouts)
module rounded_rect_y(w, h, len, r) {
    hull()
        for (sx = [-1, 1], sz = [-1, 1])
            translate([sx*(w/2 - r), 0, sz*(h/2 - r)])
                rotate([90, 0, 0])
                    cylinder(r = r, h = len, center = true);
}

// Vertical slot penetrating in X (capsule cross-section in Y-Z)
module side_slat(width, z0, z1) {
    hull() {
        translate([0, 0, z0 + width/2])
            rotate([0, 90, 0]) cylinder(r = width/2, h = out_w + 20, center = true);
        translate([0, 0, z1 - width/2])
            rotate([0, 90, 0]) cylinder(r = width/2, h = out_w + 20, center = true);
    }
}

// Top slot penetrating in Z (capsule footprint in X-Y)
module top_slat(width, len) {
    hull() {
        translate([0,  (len/2 - width/2), 0]) cylinder(r = width/2, h = wall + r_out + 20);
        translate([0, -(len/2 - width/2), 0]) cylinder(r = width/2, h = wall + r_out + 20);
    }
}

// Two-lobe pincer claw, built pointing along +X (from openclaw_case_004)
module claw() {
    union() {
        sphere(claw_r1);
        translate([6, 0, claw_r1 - 5]) sphere(claw_r2);
    }
}

/* ---------------- Shell ---------------- */

module case_shell() {
    difference() {
        union() {
            rounded_shell_solid(out_w, out_d, out_h, r_out);

            // Ear bumps: two per side, protruding in X
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx*(out_w/2 - ear_r + ear_protrude),
                           sy*ear_y_off, ear_z])
                    sphere(r = ear_r);

            // Four corner pincer claws, pointing out along each diagonal.
            // Big lobe center sits on the outer wall surface (corner circle
            // center + r_out along the diagonal) so it protrudes ~one radius.
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx*(corner_x + r_out*0.707),
                           sy*(corner_y + r_out*0.707),
                           claw_z])
                    rotate([0, 0, atan2(sy, sx)])
                        claw();
        }

        // Inner cavity (open bottom: extends below z=0)
        translate([0, 0, -1])
            rounded_shell_solid(cav_w, cav_d, cav_h + 1, r_in);

        // Rear opening (ports + fan exhaust). Rear = +Y
        translate([0, out_d/2 - wall/2, (rear_cut_z0 + rear_cut_z1)/2])
            rounded_rect_y(rear_cut_w, rear_cut_z1 - rear_cut_z0, wall + 30, rear_cut_r);

        // Front opening (power button, USB-A, microSD, LED bar). Front = -Y
        translate([0, -(out_d/2 - wall/2), (front_cut_z0 + front_cut_z1)/2])
            rounded_rect_y(front_cut_w, front_cut_z1 - front_cut_z0, wall + 30, front_cut_r);

        // Side vent slats (both sides cut in one pass, slots run through X)
        for (i = [0 : slat_n - 1])
            translate([0, (i - (slat_n - 1)/2) * slat_pitch, 0])
                side_slat(slat_w, slat_z0, slat_z1);

        // Top vent slats (rear half of the top)
        for (i = [0 : top_slat_n - 1])
            translate([(i - (top_slat_n - 1)/2) * top_slat_pitch, top_slat_y,
                       cav_h - 5])
                top_slat(top_slat_w, top_slat_len);

        // Eye disc recesses on top (front half)
        for (sx = [-1, 1])
            translate([sx*eye_x, eye_y, out_h - eye_depth])
                cylinder(d = eye_d, h = eye_depth + 1);

        // Antenna through-holes with grommet counterbore
        for (sx = [-1, 1])
            translate([sx*ant_x, ant_y, 0]) {
                translate([0, 0, cav_h - 1])
                    cylinder(d = ant_hole_d, h = wall + r_out + 5);
                translate([0, 0, out_h - 1.5])
                    cylinder(d = ant_cbore_d, h = 3);
            }
    }
}

/* ---------------- Accessories ---------------- */

// Curved antenna: plug fits the 7mm hole, horn curves like an eyestalk.
// Printed standing: plug on the bed, horn bends 70 degrees (support-free).
// Plug shortened to 3.5mm (4mm wall; only 0.75mm headroom above the device).
ant_plug_h = wall - 0.5;

module antenna() {
    pts = [for (a = [0 : 10 : 70]) [18*(1 - cos(a)), 0, 18*sin(a)]];
    union() {
        // plug (goes into the hole)
        cylinder(d = ant_hole_d - 0.4, h = ant_plug_h);
        // flange (sits in the counterbore, reads as the grommet ring)
        translate([0, 0, ant_plug_h])
            cylinder(d = ant_cbore_d - 0.5, h = 1.4);
        // curved horn rising from the flange (arc in XZ, starts pointing +Z)
        translate([0, 0, ant_plug_h + 1.4])
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

/* ---------------- Output ---------------- */

if (PART == "shell") {
    case_shell();
} else if (PART == "accessories") {
    // antennae stand plug-down on the bed
    for (y = [-1, 1])
        translate([0, y*15, 0])
            antenna();
    for (y = [-1, 1])
        translate([40, y*20, 0])
            eye_disc();
}
