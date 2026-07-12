// ============================================================================
// duck_sleeve_001 — "Face base" sleeve for the M4 Mac mini, with swappable
// snap-in mouths (lips / duck bill / buck teeth / tongue / mustache).
//
// Replica of the ribbed silicone face-base concept: the mini drops into a
// fluted tub; a soft mouth plugs into a countersunk slot on the front face.
//
// Device facts (verified, foundations doc 2026-07-11):
//   - chassis 127.1 x 127.1 x 49.7, corner radius ~22 (sources 22-23.5)
//   - airflow is BOTTOM-ONLY (intake front/central arcs of base ring,
//     exhaust rear arc) -> floor must be perforated + base must sit raised
//   - base foot ring outer d~110, contact disc d~100
//   - front port centerline 20.3 above desk, USB-C pill bottoms ~15.8
//     -> rim must stay below floor_top + 15.8 (we leave 1.8 margin)
//   - power button: bottom, left-rear corner viewed from front
//
// Printing:
//   - base: PLA/PETG, upright (as modeled), no supports (5mm bottom
//     roundover is the only overhang). Feet = 12.7mm adhesive bumpons in
//     the 0.8mm recesses, or print PART="feet" pucks in TPU and glue.
//   - mouths: TPU 95A recommended (squish-fit like the silicone original),
//     printed face-up as modeled — the 45 degree skirt makes them
//     support-free. mouth_fit=+0.1 is TPU interference; set to -0.1 for
//     rigid PLA mouths.
// ============================================================================
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
$fa = 1; $fs = 0.4;

// ---------------------------------------------------------------- mini fit
mini_w    = 127.1;
mini_rc   = 22;
fit       = 0.4;                    // per-side pocket clearance
pocket_w  = mini_w + 2*fit;         // 127.9
pocket_rc = mini_rc + fit;          // true outward offset of mini corner

// ---------------------------------------------------------------- body
wall      = 2.5;                    // wall at rib valleys
rib_depth = 0.6;
rib_pitch = 2.4;
outer_w   = pocket_w + 2*(wall + rib_depth);   // 134.1 (rib crest envelope)
outer_rc  = pocket_rc + wall + rib_depth;
rib_w     = outer_w - 2*rib_depth + 0.2;       // crests 0.1 proud of envelope
rib_rc    = outer_rc - rib_depth + 0.1;        // ...so intersection trims them

H         = 20;                     // rim height (mini ports clear by 1.8)
floor_t   = 6;                      // pocket floor top; pocket depth = 14
bot_r     = 5;                      // bottom roundover
top_r     = 1.0;                    // rim roundover

// ---------------------------------------------------------------- vent floor
vent_d     = 116;                   // triangle field spans past foot ring d110
vent_pitch = 5.8;
vent_web   = 1.6;
vent_round = 0.6;

// ---------------------------------------------------------------- misc floor
btn_pos     = [-42, 42];            // power button, left-rear (from front)
btn_d       = 20;
foot_pos    = 47;                   // bumpon recess centers (+-x, +-y)
foot_d      = 12.7;                 // 12.7mm hemisphere bumpon
foot_recess = 0.8;

// ------------------------------------------------------- mouth interface
// Contract: base cuts NOMINAL sizes; mouths add mouth_fit per side.
mouth_x     = -20;                  // left of center, like the original
mouth_z     = 14;                   // slot center height (top of slot z17)
slot_w      = 20;
slot_h      = 6;
slot_r      = 2.9;
skirt_flare = 1.4;                  // 45 deg self-supporting skirt
cs_clear    = 0.15;                 // countersink lateral clearance per side
cs_depth    = 1.5;                  // countersink depth (skirt is 1.4)
stem_l      = 2.9;                  // reaches 0.1 shy of pocket face
mouth_fit   = 0.1;                  // +TPU interference / -0.1 for rigid

// ============================================================== BASE ======
module vent_pattern2d() {
    difference() {
        circle(d=vent_d);
        for (a = [0, 60, 120]) rotate(a)
            ycopies(spacing=vent_pitch, n=ceil(vent_d/vent_pitch)+2)
                square([vent_d+8, vent_web], center=true);
    }
}

module mouth_slot_cut() {
    // straight slot through the wall
    translate([mouth_x, -outer_w/2+cs_depth+0.5, mouth_z]) rotate([90,0,0])
        linear_sweep(rect([slot_w, slot_h], rounding=slot_r), h=wall+rib_depth+2);
    // countersink for the 45deg skirt, opening at the outer face
    translate([mouth_x, -outer_w/2+cs_depth, mouth_z]) rotate([90,0,0])
        prismoid(size1=[slot_w+2*cs_clear, slot_h+2*cs_clear],
                 size2=[slot_w+2*(skirt_flare+cs_clear), slot_h+2*(skirt_flare+cs_clear)],
                 rounding1=slot_r+cs_clear, rounding2=slot_r+skirt_flare+cs_clear,
                 h=cs_depth+0.1);
}

module base() {
    difference() {
        // fluted tub: ribbed prism trimmed by the rounded envelope
        intersection() {
            linear_sweep(rect([rib_w, rib_w], rounding=rib_rc), h=H,
                         texture=texture("wave_ribs", n=12),
                         tex_size=[rib_pitch, H], tex_depth=rib_depth);
            offset_sweep(rect([outer_w, outer_w], rounding=outer_rc), height=H,
                         bottom=os_circle(r=bot_r), top=os_circle(r=top_r));
        }
        // pocket + insertion lead-in
        up(floor_t) linear_sweep(rect([pocket_w, pocket_w], rounding=pocket_rc), h=H);
        up(H-1.2)
            prismoid(size1=[pocket_w, pocket_w], size2=[pocket_w+2.4, pocket_w+2.4],
                     rounding1=pocket_rc, rounding2=pocket_rc+1.2, h=1.3);
        // triangle vent field through the floor (bottom-only airflow)
        translate([0,0,-1]) linear_extrude(floor_t+2)
            round2d(r=vent_round) vent_pattern2d();
        // power button access (bottom, left-rear)
        translate([btn_pos.x, btn_pos.y, -1]) cyl(d=btn_d, h=floor_t+2, anchor=BOTTOM);
        // bumpon recesses
        for (sx=[-1,1], sy=[-1,1])
            translate([sx*foot_pos, sy*foot_pos, -0.01])
                cyl(d=foot_d, h=foot_recess+0.01, anchor=BOTTOM);
        mouth_slot_cut();
    }
}

// ============================================================ MOUTHS ======
// Local frame: +z = out of the face, +y = up, back plate at z=0.
// Every mouth = mount (stem+skirt) + flange plate + sculpt, support-free.

module mouth_mount() {
    f = mouth_fit;
    translate([0,0,-stem_l])
        linear_sweep(rect([slot_w+2*f, slot_h+2*f], rounding=slot_r),
                     h=stem_l-skirt_flare+0.1);
    translate([0,0,-skirt_flare])
        prismoid(size1=[slot_w+2*f, slot_h+2*f],
                 size2=[slot_w+2*(skirt_flare+f), slot_h+2*(skirt_flare+f)],
                 rounding1=slot_r, rounding2=slot_r+skirt_flare,
                 h=skirt_flare+0.05);
}

module mouth_flange(d=[27,12], t=1.3) linear_sweep(ellipse(d=d), h=t);

// --- classic red lips -------------------------------------------------
module mouth_lips() {
    difference() {
        union() {
            mouth_mount();
            mouth_flange([27, 12.5]);
            translate([0,0,2.6]) scale([1.6, 0.78, 0.95]) torus(r_maj=6.8, r_min=3.3);
            translate([0,0,2.2]) scale([1.2, 0.45, 0.5]) sphere(r=6);  // fill donut hole
        }
        translate([0,0,5.6]) cuboid([40, 1.3, 2.8], rounding=0.6);      // mouth slit
    }
}

// --- duck bill ---------------------------------------------------------
module mouth_bill() {
    union() {
        mouth_mount();
        mouth_flange([27, 12.5]);
        intersection() {
            translate([0,0,0.8]) xrot(7) scale([1.45, 0.62, 0.72]) sphere(r=10.5);
            translate([0,0,25.2]) cube([60,60,50], center=true);   // keep z >= 0.2
            translate([0,44.4,0]) cube([100,100,100], center=true); // flat underside y>=-5.6
        }
    }
}

// --- buck teeth ---------------------------------------------------------
module mouth_teeth() {
    union() {
        mouth_mount();
        mouth_flange([26, 12]);
        hull() for (sx=[-1,1]) translate([sx*8, 3, 2.2]) sphere(r=2.9);  // upper lip roll
        for (sx=[-1,1])
            translate([sx*3.05, -1.6, 1.7]) cuboid([5.5, 7.5, 2.8], rounding=1.1);
    }
}

// --- tongue out ----------------------------------------------------------
module mouth_tongue() {
    difference() {
        union() {
            mouth_mount();
            mouth_flange([26, 15], 1.3);
            hull() for (sx=[-1,1]) translate([sx*7.5, 2.6, 2.2]) sphere(r=2.7); // lip roll
            hull() {
                translate([0, 1.0, 2.0]) scale([1, 0.8, 0.62]) sphere(r=5.6);
                translate([0, -3.5, 3.2]) scale([1, 0.7, 0.5]) sphere(r=5.2);
                translate([0, -7.0, 3.8]) scale([1, 0.6, 0.45]) sphere(r=4.2);
            }
        }
        translate([0, -5, 5.4]) xrot(-10) cuboid([1.2, 9, 2.6], rounding=0.5); // groove
    }
}

// --- mustache -------------------------------------------------------------
module mouth_stache() {
    sp = [ // [x, y, r] along one handlebar
        [0,    0.5, 3.4], [5.5,  1.8, 3.0], [10.5, 0.8, 2.5],
        [14,  -1.6, 2.0], [16.2, 1.0, 1.5]
    ];
    union() {
        mouth_mount();
        mouth_flange([33, 10]);
        for (m=[0,1]) mirror([m,0,0])
            for (i=[0:len(sp)-2]) hull() {
                translate([sp[i][0],   sp[i][1],   2.2]) scale([1,1,0.75]) sphere(r=sp[i][2]);
                translate([sp[i+1][0], sp[i+1][1], 2.2]) scale([1,1,0.75]) sphere(r=sp[i+1][2]);
            }
    }
}

// --- TPU foot pucks (optional; else use 12.7mm bumpons) -------------------
module feet_plate()
    grid_copies(spacing=20, n=[2,2])
        cyl(d=foot_d-0.25, h=foot_recess+3, rounding2=1, anchor=BOTTOM);

// =========================================================== ASSEMBLY =====
module mouth_of(kind) {
    if      (kind=="lips")   color("crimson")   mouth_lips();
    else if (kind=="bill")   color("orange")    mouth_bill();
    else if (kind=="teeth")  color("crimson")   mouth_teeth();
    else if (kind=="tongue") color("crimson")   mouth_tongue();
    else if (kind=="stache") color("saddlebrown") mouth_stache();
}

module assembly(kind="lips") {
    color("gainsboro") base();
    translate([mouth_x, -outer_w/2, mouth_z]) rotate([90,0,0]) mouth_of(kind);
}

// ================================================================ PART ====
PART = "assembly";

if      (PART == "assembly")        assembly("lips");
else if (PART == "assembly_bill")   assembly("bill");
else if (PART == "assembly_teeth")  assembly("teeth");
else if (PART == "assembly_tongue") assembly("tongue");
else if (PART == "assembly_stache") assembly("stache");
else if (PART == "base")            base();
else if (PART == "mouth_lips")      mouth_lips();
else if (PART == "mouth_bill")      mouth_bill();
else if (PART == "mouth_teeth")     mouth_teeth();
else if (PART == "mouth_tongue")    mouth_tongue();
else if (PART == "mouth_stache")    mouth_stache();
else if (PART == "feet")            feet_plate();
