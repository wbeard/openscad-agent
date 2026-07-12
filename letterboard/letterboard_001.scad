// OpenClaw "letterboard" faceplate -- v001
// Sliding dovetail letter tiles on the magnetic faceplate interface of
// openclaw_case_005 (Mac mini M4 crab case).
//
// PART = "plate"    -> carrier plate with two dovetail rail strips (DEFAULT)
// PART = "tiles"    -> letter tile set for TILE_TEXT (prints face-down)
// PART = "end_caps" -> 2x press-in blank stops for the open rail ends
// PART = "preview"  -> plate + tiles seated in the grooves (visual check)
// PART = "xsection" -> debug: thin X-slice through a seated tile + groove
//
// COORDINATE SCHEME / PRINT ORIENTATION (read this first)
// Plate-local x/yl match the carrier interface (x -45..45, yl -18..18 up),
// but the whole plate is SHIFTED +z by rail_h = 2.8 so the part prints
// face-down with the raised rail strips on the bed:
//   z 0.0 .. 2.8   dovetail rail strips (proud of the cosmetic face)
//   z 2.8 .. 5.8   plate slab = plate_base() translated +2.8 (face at 2.8)
//   z 3.55.. 5.9   magnet pockets, open at the BACK (0.8 front skin intact)
// Pass-throughs are cut through everything (slab AND strips -- the USB pills
// (model +23.5/+39.2 after the interface x-mirror) nick the lower strip's top
// edge by 0.2 over a 2.3-wide lens at yl -8.7..-8.5; cosmetic only, the
// groove root stays 1.4 clear and the closed-end stop wall is untouched).
// Grooves are cut into the strips opening toward z=0 (the bed): opening 4.0
// at the strip outer surface (z=0), root 6.3 at depth 2.0. Printed face-down
// the groove walls lean ~30 deg from vertical and the root is a 6.3mm
// bridge -- support-free.
//
// MIRRORING (think of the finished plate): the cosmetic face you see when
// mounted is the BED side, viewed from -z. For that viewer, RIGHT = model -x
// and text must be mirrored in model space. Hence:
//   - groove OPEN end (loading, viewer's right) = model -x edge
//   - groove CLOSED end (stop wall, viewer's left) = model +x (x_closed)
//   - tile letters use mirror([1,0,0]) text(...)
//   - seated strings run from x_closed toward -x (viewer reads left-to-right)

PART = "plate";

TILE_TEXT = "OPENCLAW";   // tile set to generate (A-Z; spaces are skipped)

$fn = 64;

// ---- Faceplate interface v1 (carrier interface v1 -- matches openclaw_case_005.scad) ----
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
// plate-local pass-throughs (yl = case z - fp_cz): when mounted (face out,
// yl up) plate-local +x -> case -x, so pass-throughs are x-MIRRORED from the
// case cutouts:
//   USB pills 7x14 at (+39.2, -1.7) & (+23.5, -1.7)
//   LED d5 at (-25.4, -1.7); jack d10 at (-38.2, -1.7)
//   magnet pockets d6.15 x 2.25 from the BACK at (+-34, +-12.5), 0.8 front skin

// ---- Front port positions (from openclaw_case_005.scad; the interface
//      modules below reference these) ----
port_z     = 20.3;   // port centerline height (case z)
usbc_x     = [-39.2, -23.5];
led_x      = 25.4;
jack_x     = 38.2;

// ================= carrier interface v1 modules =================
// carrier interface v1 -- matches openclaw_case_005.scad (copied verbatim)

module rrect2(w, h, r) {
    offset(r = r) square([w - 2*r, h - 2*r], center = true);
}

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

// ================= letterboard parameters =================

// ---- Rail strips (proud of the face; z 0..rail_h in shifted coords) ----
rail_h     = 2.8;                    // strip protrusion above the face
rail_spans = [[7, 18], [-18, -8.5]]; // strip yl spans (lower stops at -8.5 to
                                     //   clear USB pill bottoms at -8.7 -> 9.5
                                     //   tall; upper is 11 tall)
grooves_yc = [12.5, -13.25];         // groove/strip centers (upper, lower)

// ---- Dovetail groove (cut into strips, opening toward the bed z=0) ----
groove_open = 4.0;   // opening width at the strip outer surface
groove_root = 6.3;   // root width at depth
groove_d    = 2.0;   // depth (60-deg flanks; walls lean ~30 deg face-down)
x_closed    = 41.5;  // closed-end stop wall (viewer's LEFT); ~3mm of strip
                     //   remains at mid-groove; thins to ~1mm at the very
                     //   corner where the groove root meets the plate corner
                     //   radius (backed by the slab -- acceptable for a stop)

// ---- Letter tiles ----
tile_w      = 9;
tile_h      = 9.0;   // = lower strip 9.5 - 0.5; ONE height for both rows so
                     //   tiles are interchangeable (on the 11-tall upper
                     //   strip ~1mm of strip shows above/below each tile)
tile_face_t = 1.2;   // face slab thickness
rib_neck    = 3.6;   // dovetail rib: neck width at the tile back
rib_crest   = 5.9;   // crest width at the rib top
rib_h       = 1.8;   // rib height (0.2 float off the groove root)
rib_relief  = 0.3;   // chamfer (relief) at the rib root
rib_bump    = 0.25;  // crush bump proud of one flank (takes up the slop)
eng_d       = 0.6;   // letter engraving depth (paint-pen fill)
tile_font   = "Liberation Sans:style=Bold";
tile_txt    = 6.5;   // text size
txt_drop    = 0.36*tile_txt; // baseline drop to center cap-height glyphs

cap_extra   = 0.15;  // end_cap rib oversize per side -> press-in interference

// ================= letterboard modules =================

// Groove cutter: trapezoid cross-section extruded along +x from the open
// (-x) edge to the closed-end wall at x_closed. 2D coords: x=yl, y=z.
module groove_cut(yc) {
    ho = groove_open/2;
    hr = groove_root/2;
    translate([-48, yc, 0])
        rotate([90, 0, 90])   // 2D x -> Y, 2D y -> Z, extrude -> +X
            linear_extrude(x_closed + 48)
                polygon([[-ho, -0.5], [ho, -0.5], [ho, 0],
                         [hr, groove_d], [-hr, groove_d], [-ho, 0]]);
}

// Two rail strips, clipped to the plate outline (full width)
module rail_strips() {
    for (s = rail_spans)
        linear_extrude(rail_h)
            intersection() {
                rrect2(fp_w, fp_h, fp_r);
                translate([0, (s[0] + s[1])/2])
                    square([fp_w + 4, s[1] - s[0]], center = true);
            }
}

// Debossed claw glyph (two overlapping circles) in the face's lower-right
// quadrant as mounted (= model -x, lower yl; the corner itself is occupied
// by the jack/LED pass-throughs and the lower rail). Cut 0.6 into the face.
module claw_glyph() {
    translate([0, 0, rail_h - 0.05])
        linear_extrude(eng_d + 0.05) {
            translate([-18,   -4.5]) circle(d = 4);
            translate([-16.4, -2.1]) circle(d = 3);
        }
}

// The carrier plate with rails + grooves
module letter_plate() {
    difference() {
        union() {
            rail_strips();                          // z 0..2.8
            translate([0, 0, rail_h]) plate_base(); // face z=2.8, back z=5.8
        }
        for (yc = grooves_yc) groove_cut(yc);
        // second pass-through subtraction, un-shifted (spans z -1..4):
        // carries the port cutouts through the strips too
        plate_passthroughs();
        claw_glyph();
    }
}

// Dovetail rib cross-section (2D: x=yl offset from rib center, y=height off
// the tile back). Root relief chamfer, straight flanks, flat crest.
// bumped=true inserts the crush-bump apex on the +yl flank.
module rib_xsec(extra = 0, bumped = false) {
    hn = rib_neck/2  + extra;
    hc = rib_crest/2 + extra;
    fx = hc - hn;  fz = rib_h - rib_relief;   // flank vector
    fl = sqrt(fx*fx + fz*fz);
    bxp = (hn + hc)/2        + rib_bump*( fz/fl);  // bump apex (flank midpoint
    bzp = (rib_relief + rib_h)/2 + rib_bump*(-fx/fl); //  + normal*bump)
    pts = bumped
        ? [[-(hn - rib_relief), 0], [hn - rib_relief, 0], [hn, rib_relief],
           [bxp, bzp], [hc, rib_h], [-hc, rib_h], [-hn, rib_relief]]
        : [[-(hn - rib_relief), 0], [hn - rib_relief, 0], [hn, rib_relief],
           [hc, rib_h], [-hc, rib_h], [-hn, rib_relief]];
    polygon(pts);
}

// Rib running along +x from x=0, length len, with two 2mm crush-bump
// segments at 1/4 and 3/4 of the length
module rib(len, extra = 0) {
    rotate([90, 0, 90]) linear_extrude(len) rib_xsec(extra);
    for (bx = [0.25*len, 0.75*len])
        translate([bx - 1, 0, 0])
            rotate([90, 0, 90]) linear_extrude(2) rib_xsec(extra, bumped = true);
}

// One letter tile: face slab (face on the bed at z=0, 0.3 edge chamfer),
// dovetail rib on the back, letter MIRRORED and engraved 0.6 into the face
// so it reads correctly on the finished (bed-side) surface.
module tile(ch = "", extra = 0) {
    difference() {
        union() {
            hull() {
                linear_extrude(0.05)
                    offset(r = -0.3) square([tile_w, tile_h], center = true);
                translate([0, 0, 0.3])
                    linear_extrude(0.05) square([tile_w, tile_h], center = true);
            }
            translate([0, 0, 0.3])
                linear_extrude(tile_face_t - 0.3)
                    square([tile_w, tile_h], center = true);
            translate([-tile_w/2, 0, tile_face_t]) rib(tile_w, extra);
        }
        if (ch != "")
            translate([0, -txt_drop, -0.1])
                linear_extrude(eng_d + 0.1)
                    mirror([1, 0, 0])
                        text(ch, size = tile_txt, font = tile_font,
                             halign = "center", valign = "baseline");
    }
}

// Blank press-in stop for the open rail end (+0.15/side rib interference)
module end_cap() {
    tile("", cap_extra);
}

// Print-layout grid for a string: 12mm pitch, 8 per row, spaces skipped
module tile_set(s) {
    for (i = [0 : len(s) - 1])
        if (s[i] != " ")
            translate([(i % 8)*12, -floor(i/8)*13, 0])
                tile(s[i]);
}

// Seat a tile in groove row (0=upper, 1=lower), slot i counted from the
// closed end. Tile back lands on the strip surface (z=0), rib in the groove.
module seated_tile(row, i) {
    translate([x_closed - tile_w*(i + 0.5), grooves_yc[row], -tile_face_t])
        children();
}

// ================= output =================

if (PART == "plate") {
    letter_plate();
} else if (PART == "tiles") {
    tile_set(TILE_TEXT);
} else if (PART == "end_caps") {
    for (y = [-1, 1])
        translate([0, y*7, 0])
            end_cap();
} else if (PART == "preview") {
    letter_plate();
    up = "OPENCLAW";                       // reads left-to-right when mounted
    for (i = [0 : len(up) - 1])
        color(i % 2 == 0 ? "gold" : "orange")
            seated_tile(0, i) tile(up[i]);
    lo = "M4";
    for (i = [0 : len(lo) - 1])
        color("tomato")
            seated_tile(1, i) tile(lo[i]);
    color("yellowgreen")
        seated_tile(1, len(lo)) end_cap();
} else if (PART == "xsection") {
    intersection() {
        union() {
            letter_plate();
            seated_tile(0, 3) tile("A");   // tile centered near x=10
        }
        translate([9.5, -25, -5]) cube([1, 50, 12]);
    }
}
