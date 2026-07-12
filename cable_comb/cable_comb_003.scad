// Print-in-place desk cable comb - v003
// v002: catch posts/hinge fillets added after tower cuts (recess/notch were
//       deleting the snap bump and root fillets in v001); catch post lowered
//       to 1.2 mm + 45 deg top chamfer so it clears the neighboring open gate.
// v003: hinge relief slot now cut through the tower top (v002 left a solid
//       0.45 mm slab exactly where the closed web must lie, so gates could
//       never physically close); also removes the degenerate STL faces that
//       tangency caused.
// 5 cable channels (IDs 5/5/6/8/8 mm) with individual living-hinge snap gates.
// Prints flat, no supports: gates print OPEN at 120 deg from closed
// (30 deg past vertical -> max 30 deg overhang).
//
// Material: PETG strongly recommended for the living hinges.
//           PLA hinges survive only ~20-50 open/close cycles.
// Underside: 60x12x0.8 recess for adhesive strip; 2x 5x2.5 zip-tie
//            slots through the base outboard of the end channels.
//
// PART = "print"          -> printable state, gates open 120 deg (DEFAULT)
// PART = "preview_closed" -> gates closed, to verify catch lap + cable clearance

PART = "print";

$fn = 64;

// ---- Channels ----
ch_d   = [5, 5, 6, 8, 8];   // per-channel inner diameters
n_ch   = 5;
pitch  = 14;                 // channel spacing
ch_x0  = -pitch*(n_ch-1)/2;  // first channel center x (-28)

// ---- Base / towers ----
base_l  = 80;    // base length  (x)  (~78 spec, +2 for zip-slot webs)
base_w  = 16;    // base depth   (y)
base_t  = 3;     // base thickness
base_r  = 3;     // base corner radius
tower_h = 12;    // tower height above base
top_z   = base_t + tower_h;          // 15, tower top
bore_z  = base_t + max(ch_d)/2;      // 7, bore center height
tower_l = 72.4;  // tower block length (x), r2 corners

// ---- Gates / living hinges ----
gate_t   = 1.6;   // gate plate thickness
gate_w   = 8;     // gate width along y (cable axis)
hinge_t  = 0.45;  // living-hinge web thickness
hinge_l  = 1.8;   // hinge web free length
open_ang = 120;   // printed opening angle from closed
dome_h   = 1.3;   // cable-press dome protrusion on gate inner face
hinge_zc = top_z - hinge_t/2;   // hinge pivot height (web mid-plane, 14.775)

// ---- Snap catch (far tower) ----
catch_gap    = 0.5;   // gate tip to catch-post face
catch_proud  = 0.8;   // bump protrusion from post face
catch_eng    = 0.3;   // horizontal lap of bump over gate tip
recess_d     = 1.8;   // tip landing recess depth in far tower top
post_w       = 1.2;   // catch post width (x)
post_h       = 1.2;   // catch post height above tower top
nail_l       = 4;     // fingernail slot length (y)
nail_w       = 1.5;   // fingernail slot width (x)

// ---- Underside ----
pad_l = 60;  pad_w = 12;  pad_t = 0.8;   // adhesive recess
zip_w = 2.5; zip_l = 5;                  // zip-tie slot (x by y)
zip_x = 37.7;                            // slot center from middle

function cx(i) = ch_x0 + i*pitch;        // channel center x

// ================= helpers =================

module rounded_plate(l, w, h, r)
    linear_extrude(h)
        offset(r = r)
            square([l - 2*r, w - 2*r], center = true);

// extrude an XZ-plane 2D profile along y, centered
module extrude_y(w)
    rotate([90, 0, 0])
        linear_extrude(w, center = true)
            children();

// concave quarter-fillet bar along y (fills corner toward +x, -z)
module root_fillet(r, w)
    extrude_y(w)
        difference() {
            square([r, r]);
            translate([r, 0]) circle(r);
        }

// ================= body =================

module body() {
    // NOTE: posts + fillets are unioned AFTER the cuts, otherwise the
    // recess / hinge-notch cuts would delete the snap bumps and fillets.
    difference() {
        union() {
            rounded_plate(base_l, base_w, base_t, base_r);
            translate([0, 0, base_t])
                rounded_plate(tower_l, base_w, tower_h, 2);
        }

        for (i = [0 : n_ch-1]) {
            tw = ch_d[i];
            // channel bore + open throat upward
            translate([cx(i), 0, bore_z]) {
                rotate([90, 0, 0]) cylinder(d = tw, h = base_w + 2, center = true);
                translate([-tw/2, -(base_w+2)/2, 0])
                    cube([tw, base_w + 2, tower_h + 2]);
            }
            // hinge relief slot (left tower, open through the top so the
            // web has free space both when printed open and folded closed)
            translate([cx(i) - tw/2 - hinge_l, -4.3, base_t + 10])
                cube([hinge_l + 0.01, 8.6, tower_h - 10 + 1]);
            // gate-tip landing recess (far tower top)
            translate([cx(i) + tw/2 - 0.2, -4.3, top_z - recess_d + 0.1])
                cube([2.2 + catch_gap, 8.6, recess_d + 2]);
            // fingernail slot beside the catch
            translate([cx(i) + tw/2 + 1.0, 2.3, top_z - 2.4])
                cube([nail_w, nail_l, 5]);
        }

        // adhesive recess (underside)
        translate([-pad_l/2, -pad_w/2, -0.1]) cube([pad_l, pad_w, pad_t + 0.1]);
        // zip-tie slots through the base, outboard of the end channels
        for (s = [-1, 1])
            translate([s*zip_x - zip_w/2, -zip_l/2, -1])
                cube([zip_w, zip_l, base_t + 2]);
    }

    // catch posts with snap bumps (far/right tower of each channel)
    for (i = [0 : n_ch-1]) catch_post(i);
    // hinge-root fillets on tower face (r0.3, stays with body)
    for (i = [0 : n_ch-1])
        translate([cx(i) - ch_d[i]/2 - hinge_l, 0, top_z - hinge_t - 0.3])
            root_fillet(0.3, gate_w);
}

// catch post + bump, far tower of channel i.
// +x top corner is chamfered 45 deg so the NEXT channel's open gate web
// (which roots only 0.5 mm away on the tightest tower) clears it.
module catch_post(i) {
    xf = cx(i) + ch_d[i]/2 + 2 + catch_gap;   // post face x
    translate([xf, 0, 0]) {
        extrude_y(4)
            polygon([[0, top_z],
                     [post_w, top_z],
                     [post_w, top_z + post_h - 0.6],
                     [post_w - 0.6, top_z + post_h],
                     [0, top_z + post_h]]);
        // bump: 45 deg lead-in on top, ~80 deg retention face below
        extrude_y(4)
            polygon([[0, top_z + 0.16],
                     [-catch_proud, top_z + 0.05],
                     [-catch_proud, top_z + 0.35],
                     [0, top_z + 1.15]]);
    }
}

// ================= gate =================

// gate in hinge-local coords: origin at hinge pivot (root, web mid-plane),
// closed pose, plate extending +x. tw = throat width.
module gate(tw) {
    L = tw + 2;                 // plate spans throat + 2 mm lap
    zt =  hinge_t/2;            // web/plate top
    zb = -hinge_t/2;            // web bottom
    pb = zt - gate_t;           // plate bottom (-1.375)
    union() {
        extrude_y(gate_w)
            polygon([
                [0, zt],
                [hinge_l + L, zt],
                [hinge_l + L, pb + 0.4],            // tip lead-in chamfer
                [hinge_l + L - 0.4, pb],
                [hinge_l + 1.15, pb],               // 45 deg root chamfer bottom
                // chamfer up to r0.3 fillet arc at web/plate junction
                [hinge_l + 0.088, zb - 0.088],
                [hinge_l - 0.009, zb - 0.023],
                [hinge_l - 0.124, zb],
                [0, zb]
            ]);
        // cable-press dome on the inner (closed-facing-down) face
        translate([hinge_l + tw/2, 0, pb])
            scale([tw*0.45, 3.2, dome_h]) sphere(r = 1);
    }
}

// place gate of channel i at opening angle ang (0 = closed)
module gate_at(i, ang)
    translate([cx(i) - ch_d[i]/2 - hinge_l, 0, hinge_zc])
        rotate([0, -ang, 0])
            gate(ch_d[i]);

// ================= assembly =================

module comb(ang) {
    body();
    for (i = [0 : n_ch-1]) gate_at(i, ang);
}

// ================= output =================

if (PART == "print")               comb(open_ang);
else if (PART == "preview_closed") comb(0);
