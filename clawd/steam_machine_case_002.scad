// Steam Machine Protective Case ("OpenClaw" style) - v002
// Changes from v001: wider front opening (full faceplate/LED-bar width),
// ears slightly larger/lower so they sit fully on the flat side wall.
// One-piece rounded shell that slips over the Valve Steam Machine from above
// (device slides in from below through the open bottom).
//
// Real device dimensions (Valve Steam Machine, announced Nov 2025):
//   Width : 156.0 mm
//   Depth : 162.4 mm
//   Height: 152.0 mm (with feet; 148 mm without)
// Sources: Tom's Hardware review, thegamepost.com full specs.
//
// Front (low, near base): power button, 2x USB-A 3.2, microSD slot, LED light bar
// Rear: DisplayPort 1.4, HDMI 2.0, Ethernet, USB-C, 2x USB-A, AC power + fan exhaust grille

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
out_w = cav_w + 2*wall;
out_d = cav_d + 2*wall;
out_h = cav_h + wall;

r_out = 12;   // outer corner/top rounding radius
r_in  = 8;    // inner cavity corner radius

// Rear port/fan opening (rounded rect window)
rear_cut_w = 130;
rear_cut_z0 = 12;
rear_cut_z1 = 132;
rear_cut_r = 10;

// Front opening (power button + USB-A + microSD + LED bar, all near base)
front_cut_w = 132;
front_cut_z0 = 8;
front_cut_z1 = 50;
front_cut_r = 6;

// Side vent slats (vertical)
slat_n = 9;        // per side
slat_w = 5;        // slot width (along Y)
slat_pitch = 12;
slat_z0 = 30;
slat_z1 = 122;

// Top vent slats (run along Y)
top_slat_n = 9;
top_slat_w = 4;      // along X
top_slat_pitch = 12;
top_slat_len = 110;  // along Y

// Decorative round "ear" bumps on the sides
ear_r = 10;
ear_protrude = 6;
ear_z = 134;   // keep >= 2mm above slat tops (slat_z1) to avoid tangent geometry
ear_y_off = 35;   // +/- from center, two ears per side

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

/* ---------------- Main ---------------- */

module case_shell() {
    difference() {
        union() {
            rounded_shell_solid(out_w, out_d, out_h, r_out);

            // Ear bumps: two per side, protruding in X
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx*(out_w/2 - ear_r + ear_protrude),
                           sy*ear_y_off, ear_z])
                    sphere(r = ear_r);
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

        // Top vent slats
        for (i = [0 : top_slat_n - 1])
            translate([(i - (top_slat_n - 1)/2) * top_slat_pitch, 0, cav_h - 5])
                top_slat(top_slat_w, top_slat_len);
    }
}

case_shell();
