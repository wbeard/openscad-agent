#!/bin/bash

# OpenSCAD to STL Exporter with Geometry Validation Gates
# Converts .scad files to .stl for 3D printing, then runs hard printability
# gates (trimesh + prusa-slicer --info): watertight, manifold, open edges,
# winding, bbox-vs-expected-size.
# Cross-platform: macOS, Linux, Windows (Git Bash/MSYS2)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
OUTPUT=""
FORMAT="binstl"  # Binary STL by default
VALIDATE=true
EXPECT_SIZE=""
TOLERANCE="0.5"
ALLOW_MULTI_PART=false

# ── Find OpenSCAD (cross-platform) ──────────────────────────
find_openscad() {
    if command -v openscad &> /dev/null; then
        echo "openscad"; return 0
    fi
    if [[ -x "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]]; then
        echo "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"; return 0
    fi
    for pf in "/c/Program Files/OpenSCAD" "/c/Program Files (x86)/OpenSCAD" \
              "$PROGRAMFILES/OpenSCAD" "${PROGRAMFILES:-}/OpenSCAD"; do
        if [[ -x "$pf/openscad.exe" ]]; then
            echo "$pf/openscad.exe"; return 0
        elif [[ -x "$pf/openscad.com" ]]; then
            echo "$pf/openscad.com"; return 0
        elif [[ -x "$pf/openscad" ]]; then
            echo "$pf/openscad"; return 0
        fi
    done
    for p in /usr/bin/openscad /usr/local/bin/openscad /snap/bin/openscad; do
        if [[ -x "$p" ]]; then echo "$p"; return 0; fi
    done
    return 1
}

OPENSCAD=$(find_openscad) || {
    echo "Error: OpenSCAD not found."
    echo "Install from https://openscad.org/ or via:"
    echo "  macOS:   brew install openscad"
    echo "  Linux:   sudo apt install openscad"
    echo "  Windows: winget install OpenSCAD.OpenSCAD"
    exit 1
}

# Manifold backend: fast, robust boolean engine — makes high \$fn and BOSL2
# practical. Only pass the flag if this build supports it.
BACKEND_ARGS=()
if "$OPENSCAD" --help 2>&1 | grep -q -- '--backend'; then
    BACKEND_ARGS=(--backend Manifold)
fi

# Parse arguments
INPUT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --binary)
            FORMAT="binstl"
            shift
            ;;
        --ascii)
            FORMAT="asciistl"
            shift
            ;;
        --expect-size)
            EXPECT_SIZE="$2"
            shift 2
            ;;
        --tolerance)
            TOLERANCE="$2"
            shift 2
            ;;
        --allow-multi-part)
            ALLOW_MULTI_PART=true
            shift
            ;;
        --no-validate)
            VALIDATE=false
            shift
            ;;
        --help|-h)
            echo "Usage: export-stl.sh <input.scad> [options]"
            echo ""
            echo "Options:"
            echo "  --output <path>       Output STL path (default: <input>.stl)"
            echo "  --binary              Binary STL format (default, smaller)"
            echo "  --ascii               ASCII STL format (human-readable)"
            echo "  --expect-size <X,Y,Z> Expected bbox in mm; export FAILS if off by more"
            echo "                        than the tolerance on any axis"
            echo "  --tolerance <mm>      Allowed bbox deviation per axis (default 0.5)"
            echo "  --allow-multi-part    Don't fail on disconnected parts"
            echo "  --no-validate         Skip the trimesh/prusa-slicer gates"
            echo ""
            echo "Exit codes: 0 = exported and gates passed, 1 = export failed,"
            echo "            2 = exported but validation gates FAILED"
            echo ""
            echo "Examples:"
            echo "  export-stl.sh model.scad"
            echo "  export-stl.sh model.scad --expect-size 30,20,16 --tolerance 0.3"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            else
                echo "Error: Multiple input files specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate input
if [[ -z "$INPUT" ]]; then
    echo "Error: No input file specified"
    echo "Usage: export-stl.sh <input.scad> [options]"
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

# Determine output path
if [[ -z "$OUTPUT" ]]; then
    BASENAME="${INPUT%.scad}"
    OUTPUT="${BASENAME}.stl"
fi

echo "========================================"
echo "Export STL: $(basename "$INPUT")"
echo "========================================"
echo ""

# Build OpenSCAD command
CMD=("$OPENSCAD" "${BACKEND_ARGS[@]}")
CMD+=("--export-format" "$FORMAT")
CMD+=("-o" "$OUTPUT")
CMD+=("$INPUT")

# Remove any stale STL so a failed export can't be mistaken for success
rm -f "$OUTPUT"

# Run OpenSCAD and capture all output (warnings go to stderr)
echo "Rendering and exporting (backend: ${BACKEND_ARGS[1]:-default})..."
RESULT=$("${CMD[@]}" 2>&1) || true

# Hard compile/geometry errors — feed the exact message back to the caller
if [[ ! -f "$OUTPUT" ]]; then
    echo ""
    echo "--- Export Failed ---"
    echo "OpenSCAD output:"
    echo "$RESULT" | grep -E "ERROR:|WARNING:|TRACE:" || echo "$RESULT"
    echo ""
    echo "RESULT: Export failed"
    exit 1
fi

if echo "$RESULT" | grep -q "ERROR:"; then
    echo ""
    echo "--- Export produced errors ---"
    echo "$RESULT" | grep -E "ERROR:|TRACE:" | head -20
    echo ""
    echo "RESULT: Export failed (errors during render)"
    exit 1
fi

SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')

# Get triangle count from binary STL
TRIANGLES=""
if [[ "$FORMAT" == "binstl" ]]; then
    TRIANGLES=$(od -An -tu4 -j80 -N4 "$OUTPUT" 2>/dev/null | tr -d ' ')
fi

echo ""
echo "--- Export Results ---"
echo "Output: $OUTPUT"
echo "Size: $SIZE"
if [[ -n "$TRIANGLES" ]]; then
    echo "Triangles: $TRIANGLES"
fi

# Pass OpenSCAD warnings through (often hint at the root cause of gate failures)
if echo "$RESULT" | grep -qi "WARNING"; then
    echo ""
    echo "OpenSCAD warnings:"
    echo "$RESULT" | grep -i "warning" | head -5
fi

# ── Validation gates (trimesh + prusa-slicer) ───────────────
if [[ "$VALIDATE" == true ]]; then
    echo ""
    echo "--- Geometry Validation Gates ---"
    VALIDATE_ARGS=("$OUTPUT" "--tolerance" "$TOLERANCE")
    if [[ -n "$EXPECT_SIZE" ]]; then
        VALIDATE_ARGS+=("--expect-size" "$EXPECT_SIZE")
    fi
    if [[ "$ALLOW_MULTI_PART" == true ]]; then
        VALIDATE_ARGS+=("--allow-multi-part")
    fi
    if python3 "$SCRIPT_DIR/validate-stl.py" "${VALIDATE_ARGS[@]}"; then
        echo ""
        echo "========================================"
        echo "RESULT: Export successful — all gates passed"
        echo "========================================"
    else
        echo ""
        echo "========================================"
        echo "RESULT: Export FAILED validation gates"
        echo "Fix the issues above in the .scad source and re-export."
        echo "========================================"
        exit 2
    fi
else
    echo ""
    echo "========================================"
    echo "RESULT: Exported (validation skipped)"
    echo "========================================"
fi
