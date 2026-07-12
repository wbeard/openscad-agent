// Monolith Sleeve - friction-fit architectural shell for the M4 Mac mini - v003
// One crisp rectangular block: blank front and sides, every service feature on
// the rear wall (grommet + low exhaust louvers) or hidden under the skirt.
//
// v003 fixes over v002 (both STL validation failures):
// - tray press-fit tabs moved off the front corner arcs (y -55 -> -38); the
//   old ones floated 4.7mm away from the curved plate edge
// - chassis: spars drawn 0.4 oversize so the footprint intersection cuts them
//   (raw spar faces exactly coplanar with the footprint boundary at x=+/-63.85
//   were the actual source of the 40+ non-manifold edges); piers widened to
//   9x9 and the cove relief cut pulled back to y39.5 to kill the remaining
//   exactly-coplanar face pairs
//
// v002 fixes over v001:
// - deck ledge no longer collides with the mini (deck_gap 2->6, loft_h 10->6;
//   ledge underside tip now lands exactly at the mini top plane, out_z still 100)
// - chassis rebuilt: low stringer grid (h2.5, air flows OVER it) + 6 support
//   piers placed inside the contact disc (r<49), so the base-ring keep-clear
//   annulus no longer severs the rails into floating islands
// - sleeve-wall key blocks deleted (they blocked the mini's bottom insertion
//   path); the chassis now keys with prongs that enter the side skirt-scallop
//   pockets from below instead
//
// M4 Mac mini: 127.1 x 127.1 x 49.7, corner r~22, 670g. ALL airflow is through
// the bottom base ring (intake front/central arcs, exhaust rear arc; ring outer
// d~110, contact disc d~100, shell edge 3.4mm above desk). The mini rides 10mm
// up on a drop-in chassis; a transverse baffle at ~60% of its depth splits the
// plinth plenum into a front intake zone (fed by skirt shadow-gap scallops) and
// a rear exhaust zone that opens into the full-height cable chase and vents out
// low rear louvers. Neither rails nor baffle cover the base ring itself (an
// annular keep-clear r49-61 is relieved from all chassis tops).
//
// NOTE: chase_d=40 is generous. A right-angle C7 cord allows chase_d=24 -
// MEASURE the Apple cord (923-11979) before printing and shrink if it clears.
//
// PART = "sleeve"     -> outer tube, open top+bottom (DEFAULT; prints upright,
//                        support-free: ledges are 45-underchamfered)
// PART = "chassis"    -> standoff rails + baffle grid (prints flat as-is)
// PART = "tray"       -> gear deck with hub/SSD bays (prints flat, no bridging)
// PART = "cap"        -> flush top plug (output face-down, print-ready)
// PART = "assembly"   -> everything in place (+ ghost mini)
// PART = "rib_coupon" -> 30mm tube slice (z24-54 band) for a crush-rib fit test
// SHOW_SECTION = true -> cut the assembly at x=0 to prove the air path

PART = "sleeve";
SHOW_SECTION = false;

$fn = 64;

// ---- Device + fit ----
mini_w   = 127;     // mac mini footprint (actual 127.1)
mini_h   = 50;      // mac mini height (actual 49.7)
clear    = 0.75;    // cavity clearance per side
wall     = 4;       // shell wall thickness

// ---- Plan (XY) ----
cav_w    = mini_w + 2*clear;         // 128.5 cavity width (X) and mini-zone depth
cav_r    = 23;                       // cavity corner radius (mini corner ~22)
chase_d  = 40;                       // rear cable chase depth (see header note)
chase_r  = 8;                        // chase rear corner radius
out_x    = cav_w + 2*wall;           // 136.5
out_y    = cav_w + chase_d + 2*wall; // 176.5
y_front  = -cav_w/2;                 // -64.25 cavity front face
y_chase  =  cav_w/2;                 //  64.25 chase begins (mini rear)
y_rear   =  cav_w/2 + chase_d;       // 104.25 interior rear face

// ---- Stack (Z) ----
plinth_gap = 10;    // mini standoff height = plenum height
deck_gap   = 6;     // mini top -> tray bottom (deck ledge underchamfer lives here)
deck_t     = 4;     // tray plate thickness
bay_h      = 20;    // gear bay zone height
loft_h     = 6;     // dead air above the bays, under the cap
cap_h      = 4;     // cap face thickness
cap_lip    = 6;     // cap lip depth
out_z      = plinth_gap + mini_h + deck_gap + deck_t + bay_h + loft_h + cap_h; // 100
z_deck     = plinth_gap + mini_h + deck_gap;  // 62 deck ledge top / tray bottom
z_cap      = out_z - cap_h;                   // 96 cap ledge top

chamfer     = 1.0;  // 45-deg chamfer on ALL outer block edges
ledge_proud = 3;    // internal ledges protrude this far from the cavity wall
ledge_land  = 3;    // flat land above the 45-deg underchamfer

// ---- Crush ribs (cavity friction fit) ----
rib_faces = 127.15;                  // rib-face-to-rib-face across the cavity
rib_bite  = (mini_w + 0.1) - rib_faces; // engagement on the real 127.1 mini
rib_prot  = (cav_w - rib_faces)/2;   // 0.675 proud of the wall
rib_r     = 0.8;
rib_z0    = 22;                      // start above the base intake ring
rib_z1    = plinth_gap + mini_h - 5; // 55, stop 5 below the mini top

// ---- Skirt intake scallops (read as a shadow gap at desk level) ----
scal_w = 40;  scal_h = 6;
scal_front_x = [-46, 0, 46];
scal_side_y  = [-40, 8, 56];

// ---- Rear exhaust louvers (z 4-22 band; 3x 90x5, 1.5 webs) ----
louv_w = 90;  louv_h = 5;
louv_z = [4, 10.5, 17];

// ---- Rear cable grommet ----
grom_w = 40;  grom_h = 18;  grom_r = 6;  grom_z0 = 60;   // z 60-78

// ---- Power-button finger cove (LEFT-REAR; button is on the mini underside) ----
cove_y0 = 36;  cove_y1 = 66;
cove_h_out = 12;   // opening height at the outer face
cove_h_in  = 18;   // roof scoops up at 45 deg going inward, under the mini

// ---- Chassis (standoff grid + baffle) ----
// Low stringers let plenum air flow straight over them; short piers rise to
// plinth_gap only inside the mini's contact disc (r<49), so nothing touches
// or shadows the base ring annulus (r49-61). The baffle alone runs full
// height (it must seal), notched where it crosses the ring band.
ring_lo   = 49;  ring_hi = 61;       // keep-clear annulus over the base ring
rail_y    = [-44, -20, 20, 44];      // 4 stringer rails running X
rail_w    = 8;
string_h  = 2.5;                     // stringer height (air passes over)
pier_xy   = [[0,-44], [-40,-20], [40,-20], [-40,20], [40,20], [0,44]];
pier_w    = 9;                       // pier plan size (overlaps the 8-wide stringers); tops at plinth_gap
spar_x    = cav_w/2 - 0.4 - rail_w/2; // 59.85 side spar centerline
baffle_y  = -mini_w/2 + 0.6*mini_w;  // 12.7 transverse baffle (60% of depth)
baffle_t  = 4;
chassis_clr = 0.4;                   // chassis outline clearance per side

// ---- Chassis keying: prongs into the side skirt-scallop pockets ----
// The chassis inserts from below (with the mini already resting in the tube),
// so keying must live below z6 where nothing crosses the mini's path. Four
// prong pairs drop into the two front side scallops; the asymmetric scallop
// spacing makes the fit one-way.
prong_w   = 8;                       // prong width along Y
prong_h   = 5;                       // scallop is 6 tall; 1mm air above
key_scal_y = [-40, 8];               // which side scallops are engaged

// ---- Tray (gear deck) ----
tray_clr = 0.4;
tab_w    = 8;   tab_p = 0.4;         // press-fit tabs, proud of the outline
tab_y    = [-38, 50];
bay_wall = 2.4;
hub_w = 58;  hub_l = 135;  hub_wh = 16;  // hub bay (Satechi 132x32.5, Anker 117x55)
ssd_w = 36;  ssd_l = 112;  ssd_wh = 15;  // SSD bay (ORICO ~108x29.5x13.5)
gap_bays = 10;                        // cable slot between the bays
nub_p = 0.5;  nub_r = 0.8;            // crush nubs on the bay walls
nub_y = [-40, -5, 30];

// bay X layout (front-to-back along Y, rears open into the chase)
bays_span = (hub_w + 2*bay_wall) + gap_bays + (ssd_w + 2*bay_wall); // 113.6
hub_xi0 = -bays_span/2 + bay_wall;    // -54.4 hub interior left
hub_xi1 = hub_xi0 + hub_w;            //   3.6
ssd_xi0 = hub_xi1 + bay_wall + gap_bays + bay_wall; //  18.4
ssd_xi1 = ssd_xi0 + ssd_w;            //  54.4
slot_x  = hub_xi1 + bay_wall + gap_bays/2;          //  11 cable slot centerline

// ---- Cap ----
cap_clr = 0.4;

// ---- Cap ledge tabs (tray must drop PAST cap height, so the cap ledge is
//      segmented in the mini zone; continuous only around the chase) ----
captab_side_y  = [-15, 15];   // one 30-long tab per side wall
captab_front_x = [[15, 40], [-40, -15]];  // two 25-long tabs on the front wall

// ================= 2D profiles =================

// full interior plan: mini zone (r23 front corners) + chase (r8 rear corners)
module cavity_2d() {
    hull()
        for (sx = [-1, 1]) {
            translate([sx*(cav_w/2 - cav_r), y_front + cav_r]) circle(cav_r);
            translate([sx*(cav_w/2 - chase_r), y_rear - chase_r]) circle(chase_r);
        }
}

// chamfered rectangle (45-deg corner chamfers, final size a x b)
module cham_rect(a, b, c) {
    offset(delta = c, chamfer = true) square([a - 2*c, b - 2*c], center = true);
}

// two-lobe pincer outline (openclaw claw() motif, flattened)
module claw_glyph_2d() {
    difference() {
        offset(r = 2) { circle(14); translate([12, 9]) circle(9); }
        circle(14);
        translate([12, 9]) circle(9);
    }
}

// ================= sleeve =================

// outer block with 1mm 45-deg chamfers on ALL edges
module monolith_block() {
    translate([0, chase_d/2, 0])   // block center sits chase_d/2 behind mini center
        intersection() {
            linear_extrude(out_z) cham_rect(out_x, out_y, chamfer);
            translate([0, 0, out_z/2]) rotate([90, 0, 0])
                linear_extrude(out_y + 2, center = true) cham_rect(out_x, out_z, chamfer);
            translate([0, 0, out_z/2]) rotate([0, 90, 0])
                linear_extrude(out_x + 2, center = true) cham_rect(out_z, out_y, chamfer);
        }
}

// internal ledge ring, 45-deg underchamfered (support-free printed upright)
module ledge_ring(z_top) {
    z0 = z_top - ledge_land - ledge_proud;
    difference() {
        translate([0, 0, z0]) linear_extrude(ledge_land + ledge_proud) cavity_2d();
        translate([0, 0, z0 - 0.5])
            linear_extrude(ledge_land + ledge_proud + 1)
                offset(r = -ledge_proud) cavity_2d();
        hull() {   // 45-deg flare eats the ledge underside
            translate([0, 0, z0 - 0.01]) linear_extrude(0.01) cavity_2d();
            translate([0, 0, z0 + ledge_proud]) linear_extrude(0.01)
                offset(r = -ledge_proud) cavity_2d();
        }
    }
}

// one vertical half-round crush rib with a coned lead-in at the bottom
module rib_at(px, py) {
    translate([px, py, rib_z0]) {
        cylinder(r1 = 0.1, r2 = rib_r, h = 2*rib_r);
        translate([0, 0, 2*rib_r - 0.01])
            cylinder(r = rib_r, h = rib_z1 - rib_z0 - 2*rib_r);
    }
}

module crush_ribs() {
    emb = rib_r - rib_prot;   // rib center sits this far inside the wall face
    for (s = [-1, 1], yy = [-40, 0, 40]) rib_at(s*(cav_w/2 + emb), yy); // sides
    for (xx = [-35, 0, 35]) rib_at(xx, y_front - emb);                  // front
}

// ---- cutouts ----

module skirt_scallops() {
    for (xc = scal_front_x)   // front wall
        translate([xc - scal_w/2, y_front - wall - 1.5, -0.5])
            cube([scal_w, wall + 15, scal_h + 0.5]);
    for (s = [-1, 1], yc = scal_side_y)   // side walls
        translate([s > 0 ? cav_w/2 - 14 : -cav_w/2 - wall - 1.5, yc - scal_w/2, -0.5])
            cube([wall + 15.5, scal_w, scal_h + 0.5]);
}

module rear_louvers() {
    for (zb = louv_z)
        translate([-louv_w/2, y_rear - 1, zb])
            cube([louv_w, wall + 3, louv_h]);
}

module grommet_slot() {
    translate([0, y_rear + wall/2, grom_z0 + grom_h/2])
        hull()
            for (sx = [-1, 1], sz = [-1, 1])
                translate([sx*(grom_w/2 - grom_r), 0, sz*(grom_h/2 - grom_r)])
                    rotate([-90, 0, 0])
                        cylinder(r = grom_r, h = wall + 4, center = true);
}

// 30-wide skirt scallop, roof scooped up at 45 deg toward the mini underside
module finger_cove() {
    hull() {
        translate([-out_x/2 - 1, cove_y0, -0.5])
            cube([0.01, cove_y1 - cove_y0, cove_h_out + 0.5]);
        translate([y_front + 1, cove_y0, -0.5])
            cube([0.01, cove_y1 - cove_y0, cove_h_in + 0.5]);
    }
}

// cap ledge only where the tray never passes: tabs + continuous chase ring
module cap_ledge_zones() {
    translate([-out_x/2, 66, 0]) cube([out_x, out_y, out_z]);          // chase ring
    for (s = [-1, 1], yc = captab_side_y)                              // side tabs
        translate([s > 0 ? 55 : -70, yc - 15, 0]) cube([15, 30, out_z]);
    for (xr = captab_front_x)                                          // front tabs
        translate([xr[0], y_front - wall, 0]) cube([xr[1] - xr[0], 10, out_z]);
}

module sleeve() {
    difference() {
        union() {
            difference() {
                monolith_block();
                translate([0, 0, -1]) linear_extrude(out_z + 2) cavity_2d();
            }
            // deck ledge: mini zone only (chase stays clear full height)
            intersection() {
                ledge_ring(z_deck);
                translate([-out_x/2, -out_y, 0]) cube([out_x, out_y + y_chase, out_z]);
            }
            // cap ledge: segmented tabs + continuous chase ring
            intersection() { ledge_ring(z_cap); cap_ledge_zones(); }
            crush_ribs();
        }
        skirt_scallops();
        rear_louvers();
        grommet_slot();
        finger_cove();
    }
}

// ================= chassis =================

module chassis_footprint() {
    translate([0, 0, -1])
        linear_extrude(plinth_gap + 2)
            intersection() {
                offset(r = -chassis_clr) cavity_2d();
                translate([-100, -100]) square([200, 100 + y_chase - chassis_clr]);
            }
}

module chassis() {
    difference() {
        union() {
            intersection() {
                union() {
                    for (yc = rail_y)                   // 4 low stringers along X
                        translate([-out_x/2, yc - rail_w/2, 0])
                            cube([out_x, rail_w, string_h]);
                    // 2 low spars along Y, drawn 0.4 oversize outward so the
                    // footprint intersection cuts them (a raw face exactly
                    // coplanar with the footprint boundary makes non-manifold
                    // edges in the mesh)
                    for (s = [-1, 1])
                        translate([s*spar_x - rail_w/2 - (s < 0 ? 0.4 : 0), -cav_w/2, 0])
                            cube([rail_w + 0.4, cav_w, string_h]);
                    translate([-out_x/2, baffle_y - baffle_t/2, 0])  // full-height baffle
                        cube([out_x, baffle_t, plinth_gap]);
                    for (p = pier_xy)                   // support piers (disc zone)
                        translate([p[0] - pier_w/2, p[1] - pier_w/2, 0])
                            cube([pier_w, pier_w, plinth_gap]);
                }
                chassis_footprint();
            }
            // keying prongs: pairs that drop into the side scallop pockets
            // from below (outer edges land 0.4 shy of the pocket ends)
            for (s = [-1, 1], yc = key_scal_y, e = [-1, 1])
                translate([s > 0 ? 60 : -67.25,
                           yc + e*(scal_w/2 - 0.4) - (e > 0 ? prong_w : 0), 0])
                    cube([7.25, prong_w, prong_h]);
        }
        // keep the base ring unobstructed: notch the baffle over the annulus
        translate([0, 0, string_h + 3.5])
            linear_extrude(plinth_gap)
                difference() { circle(ring_hi); circle(ring_lo); }
        // finger relief for the power button (matches the sleeve cove)
        translate([-out_x/2 - 1, 39.5, -0.5])
            cube([out_x/2 - 38 + 1, 25, plinth_gap + 1]);
    }
}

// ================= tray =================

module tray_2d() {
    difference() {
        intersection() {
            offset(r = -tray_clr) cavity_2d();
            translate([-100, -100]) square([200, 100 + y_chase - tray_clr]);
        }
        // notches that drop past the cap-ledge tabs
        for (s = [-1, 1])
            translate([s > 0 ? 60.85 : -66, -15.5]) square([5.15, 31]);
        for (xr = captab_front_x)
            translate([xr[0] - 0.5, -66]) square([xr[1] - xr[0] + 1, 66 - 60.85]);
    }
}

module bay_walls(xi0, xi1, yfi, h) {
    translate([xi0 - bay_wall, yfi - bay_wall, deck_t]) {
        cube([bay_wall, 130, h]);                        // left wall
        cube([xi1 - xi0 + 2*bay_wall, bay_wall, h]);     // front stop
    }
    translate([xi1, yfi - bay_wall, deck_t]) cube([bay_wall, 130, h]);  // right wall
}

module bay_nubs(xi0, xi1, h) {
    for (yy = nub_y) {
        translate([xi0 - nub_r + nub_p, yy, deck_t]) cylinder(r = nub_r, h = h - 4);
        translate([xi1 + nub_r - nub_p, yy, deck_t]) cylinder(r = nub_r, h = h - 4);
    }
}

module tray() {
    union() {
        difference() {
            linear_extrude(deck_t) tray_2d();
            translate([0, 0, -0.5]) linear_extrude(deck_t + 1)   // cable slot
                hull() {
                    translate([slot_x, -45]) circle(4);
                    translate([slot_x,  50]) circle(4);
                }
        }
        // press-fit tabs (0.4 proud -> land on the cavity walls)
        for (s = [-1, 1], yc = tab_y)
            translate([s*(cav_w/2 - tray_clr - 0.225), yc, deck_t/2])
                cube([0.85 + tab_p, tab_w, deck_t], center = true);
        // bays, clipped to the plate outline
        intersection() {
            union() {
                bay_walls(hub_xi0, hub_xi1, -56, hub_wh);
                bay_walls(ssd_xi0, ssd_xi1, -54, ssd_wh);
                bay_nubs(hub_xi0, hub_xi1, hub_wh);
                bay_nubs(ssd_xi0, ssd_xi1, ssd_wh);
            }
            linear_extrude(deck_t + bay_h) tray_2d();
        }
    }
}

// ================= cap =================

module cap() {   // modeled in installed coordinates (z_cap..out_z)
    difference() {
        union() {
            // face with a 1mm chamfered top edge (shadow line)
            translate([0, 0, z_cap]) linear_extrude(cap_h - chamfer)
                offset(r = -cap_clr) cavity_2d();
            hull() {
                translate([0, 0, z_cap + cap_h - chamfer]) linear_extrude(0.01)
                    offset(r = -cap_clr) cavity_2d();
                translate([0, 0, out_z - 0.01]) linear_extrude(0.01)
                    offset(r = -cap_clr - chamfer) cavity_2d();
            }
            // registration lip, rides inside the ledge ring
            translate([0, 0, z_cap - cap_lip]) linear_extrude(cap_lip + 0.5)
                difference() {
                    offset(r = -(ledge_proud + cap_clr)) cavity_2d();
                    offset(r = -(ledge_proud + cap_clr + 3)) cavity_2d();
                }
        }
        // debossed claw glyph on the UNDERSIDE
        translate([0, 20, z_cap - 0.01]) linear_extrude(0.41)
            scale(1.4) claw_glyph_2d();
    }
}

// ================= assembly =================

module mini_ghost() {
    translate([0, 0, plinth_gap]) linear_extrude(mini_h)
        offset(r = 22) square([mini_w - 44, mini_w - 44], center = true);
}

module assembly(ghost = true) {
    color("gainsboro") sleeve();
    color("dimgray")   chassis();
    color("burlywood") translate([0, 0, z_deck]) tray();
    color("slategray") cap();
    if (ghost) %mini_ghost();
}

// ================= output =================

if (PART == "sleeve") {
    sleeve();
} else if (PART == "chassis") {
    chassis();
} else if (PART == "tray") {
    tray();
} else if (PART == "cap") {
    // flip face-down for printing (face on the bed, lip up, deboss up)
    translate([0, 0, out_z]) rotate([180, 0, 0]) cap();
} else if (PART == "assembly") {
    if (SHOW_SECTION)
        difference() {
            assembly(ghost = false);
            translate([-300, -200, -10]) cube([300, 500, 220]);
        }
    else
        assembly();
} else if (PART == "rib_coupon") {
    translate([0, 0, -24])
        intersection() {
            sleeve();
            translate([-100, -100, 24]) cube([200, 300, 30]);
        }
}
