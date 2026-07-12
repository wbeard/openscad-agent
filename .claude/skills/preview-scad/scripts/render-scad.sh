#!/bin/bash

# OpenSCAD Preview Renderer
# Renders .scad files to PNG images for visual verification
# Supports multi-view rendering (iso/front/right/top) for structured critique
# Cross-platform: macOS, Linux, Windows (Git Bash/MSYS2)

set -e

# Default values
SIZE="800x600"
COLORSCHEME="Cornfield"
RENDER_MODE="preview"
EXPLICIT_MODE=""
OUTPUT=""
CAMERA=""
VIEWS=""

# ── Find OpenSCAD (cross-platform) ──────────────────────────
find_openscad() {
    # 1. Check PATH first
    if command -v openscad &> /dev/null; then
        echo "openscad"
        return 0
    fi

    # 2. macOS default
    if [[ -x "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]]; then
        echo "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
        return 0
    fi

    # 3. Windows Program Files
    for pf in "/c/Program Files/OpenSCAD" "/c/Program Files (x86)/OpenSCAD" \
              "$PROGRAMFILES/OpenSCAD" "${PROGRAMFILES:-}/OpenSCAD"; do
        if [[ -x "$pf/openscad.exe" ]] || [[ -x "$pf/openscad" ]]; then
            echo "$pf/openscad"
            return 0
        fi
        # Also check if just the dir exists (exe may not have .exe in git bash)
        if [[ -d "$pf" ]]; then
            export PATH="$PATH:$pf"
            if command -v openscad &> /dev/null; then
                echo "openscad"
                return 0
            fi
        fi
    done

    # 4. Linux common paths
    for p in /usr/bin/openscad /usr/local/bin/openscad /snap/bin/openscad; do
        if [[ -x "$p" ]]; then
            echo "$p"
            return 0
        fi
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

echo "Using OpenSCAD: $OPENSCAD"

# Manifold backend: much faster full renders, handles high \$fn and BOSL2.
# Only pass the flag if this OpenSCAD build supports it (2023+ snapshots).
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
        --size)
            SIZE="$2"
            shift 2
            ;;
        --camera)
            CAMERA="$2"
            shift 2
            ;;
        --colorscheme)
            COLORSCHEME="$2"
            shift 2
            ;;
        --views)
            VIEWS="$2"
            shift 2
            ;;
        --render)
            RENDER_MODE="render"
            EXPLICIT_MODE="render"
            shift
            ;;
        --preview)
            RENDER_MODE="preview"
            EXPLICIT_MODE="preview"
            shift
            ;;
        --help|-h)
            echo "Usage: render-scad.sh <input.scad|input.stl> [options]"
            echo ""
            echo "STL inputs are wrapped in an auto-generated <stem>_view.scad importer."
            echo ""
            echo "Options:"
            echo "  --output <path>       Output PNG path (default: <input>.png)"
            echo "  --size <WxH>          Image size (default: 800x600)"
            echo "  --camera <params>     Camera position: x,y,z,rotx,roty,rotz,dist"
            echo "  --colorscheme <name>  Color scheme (default: Cornfield)"
            echo "  --views <list>        Multi-view render: comma list of iso,front,right,top,back,left,bottom"
            echo "                        or 'std' for iso,front,right,top."
            echo "                        Outputs <base>_<view>.png per view. Implies --render."
            echo "  --render              Full render mode (slower, accurate)"
            echo "  --preview             Preview mode (faster, default for single view)"
            echo ""
            echo "Examples:"
            echo "  render-scad.sh model.scad --views std"
            echo "  render-scad.sh model.scad --size 1024x768 --camera 30,20,25,11,3.5,20,80"
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
    echo "Usage: render-scad.sh <input.scad> [options]"
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

# Accept STL input directly: wrap it in a one-line OpenSCAD import file
# (same <stem>_view.scad convention run-cad-py.sh uses)
if [[ "$INPUT" == *.stl ]]; then
    STL_STEM="${INPUT%.stl}"
    WRAPPER="${STL_STEM}_view.scad"
    echo "import(\"$(basename "$INPUT")\");" > "$WRAPPER"
    if [[ -z "$OUTPUT" ]]; then
        OUTPUT="${STL_STEM}.png"
    fi
    INPUT="$WRAPPER"
fi

# Determine output path
if [[ -z "$OUTPUT" ]]; then
    BASENAME="${INPUT%.scad}"
    OUTPUT="${BASENAME}.png"
fi

# Multi-view implies full render unless --preview was explicitly requested
if [[ -n "$VIEWS" && "$EXPLICIT_MODE" != "preview" ]]; then
    RENDER_MODE="render"
fi

# Map a view name to gimbal camera rotations (translation/distance are
# recomputed by --viewall --autocenter)
view_camera() {
    case $1 in
        iso)    echo "0,0,0,55,0,25,500" ;;
        front)  echo "0,0,0,90,0,0,500" ;;
        back)   echo "0,0,0,90,0,180,500" ;;
        right)  echo "0,0,0,90,0,90,500" ;;
        left)   echo "0,0,0,90,0,270,500" ;;
        top)    echo "0,0,0,0,0,0,500" ;;
        bottom) echo "0,0,0,180,0,0,500" ;;
        *)      return 1 ;;
    esac
}

# Render one image; args: <output.png> [camera]
render_one() {
    local out="$1"
    local cam="$2"

    local CMD=("$OPENSCAD" "${BACKEND_ARGS[@]}")
    CMD+=("--viewall" "--autocenter")
    CMD+=("--imgsize" "${SIZE/x/,}")
    CMD+=("--colorscheme" "$COLORSCHEME")

    if [[ -n "$cam" ]]; then
        CMD+=("--camera" "$cam")
    fi

    if [[ "$RENDER_MODE" == "preview" ]]; then
        CMD+=("--preview")
    else
        CMD+=("--render")
    fi

    CMD+=("-o" "$out")
    CMD+=("$INPUT")

    # Remove any stale image so a failed render can't be mistaken for success
    rm -f "$out"

    local RENDER_OUTPUT
    RENDER_OUTPUT=$("${CMD[@]}" 2>&1) || true

    # Surface compile/geometry errors even if OpenSCAD still wrote a PNG
    # (preview mode can emit an empty image on error) so the caller can
    # feed the exact error back into the next iteration.
    if echo "$RENDER_OUTPUT" | grep -q "ERROR:"; then
        echo "COMPILE/GEOMETRY ERROR in $INPUT:"
        echo "$RENDER_OUTPUT" | grep -E "ERROR:|WARNING:|TRACE:" | head -20
        return 1
    fi

    if [[ ! -f "$out" ]]; then
        echo "Render failed. OpenSCAD output:"
        echo "$RENDER_OUTPUT"
        return 1
    fi

    # Pass warnings through — often the clue for geometry problems
    if echo "$RENDER_OUTPUT" | grep -q "WARNING:"; then
        echo "$RENDER_OUTPUT" | grep "WARNING:" | head -10
    fi

    local FILE_SIZE
    FILE_SIZE=$(ls -lh "$out" 2>/dev/null | awk '{print $5}')
    echo "Success: $out ($FILE_SIZE)"
}

echo "Rendering: $INPUT (mode: $RENDER_MODE, size: $SIZE)"

if [[ -n "$VIEWS" ]]; then
    [[ "$VIEWS" == "std" ]] && VIEWS="iso,front,right,top"
    BASE="${OUTPUT%.png}"
    FAILED=0
    IFS=',' read -ra VIEW_LIST <<< "$VIEWS"
    for v in "${VIEW_LIST[@]}"; do
        CAM=$(view_camera "$v") || { echo "Unknown view: $v (use iso,front,right,top,back,left,bottom)"; exit 1; }
        render_one "${BASE}_${v}.png" "$CAM" || FAILED=1
    done
    if [[ "$FAILED" == 1 ]]; then
        exit 1
    fi
    echo ""
    echo "Multi-view render complete. Read ALL images and critique against the rubric:"
    for v in "${VIEW_LIST[@]}"; do
        echo "  ${BASE}_${v}.png"
    done
else
    render_one "$OUTPUT" "$CAMERA" || exit 1
fi
