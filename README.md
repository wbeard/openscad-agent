# OpenSCAD Agent

A Claude Code-powered 3D modeling agent environment for creating 3D printable designs with multiple CAD backends: OpenSCAD + BOSL2, build123d (B-rep), and signed distance fields (fogleman/sdf).

## Overview

This project provides an AI-assisted workflow for designing 3D models through natural language. Describe what you want to create, and the agent will iteratively generate CAD code, render multi-view previews, critique them against a rubric, and refine the design — then export STL through hard printability gates.

## Features

- **Natural language 3D modeling** with the right backend per shape class:
  - **build123d** — mechanical/functional parts (real fillets, chamfers, shells, counterbores, toleranced STL)
  - **OpenSCAD + BOSL2** — quick parametric parts, .scad deliverables
  - **sdf** — smooth organic-but-parametric forms (vases, grips, blended sculpts)
- **Iterative refinement**: versioned files (`model_001`, `model_002`, …) with multi-view renders (iso/front/right/top) and a structured critique rubric
- **Hard validation gates**: trimesh + PrusaSlicer checks — watertight, manifold, open edges, winding, bounding-box-vs-spec — failures block export and feed specifics back to the agent
- **Local doc search (RAG)**: BM25 index over BOSL2/build123d/sdf documentation so the agent grounds API usage in real docs

## Dependencies

### Required

| Dependency | What for | Install (macOS) |
|------------|----------|-----------------|
| [Claude Code](https://claude.ai/claude-code) | The agent CLI | see site |
| [OpenSCAD](https://openscad.org/) **2023+ snapshot** | Rendering/preview for all backends; .scad compilation. Snapshot needed for the fast Manifold backend (scripts auto-detect and degrade to stable) | `brew install --cask openscad@snapshot` |
| [BOSL2](https://github.com/BelfrySCAD/BOSL2) | OpenSCAD library for mechanical parts | `git clone --depth 1 https://github.com/BelfrySCAD/BOSL2.git ~/Documents/OpenSCAD/libraries/BOSL2` |
| Python 3 + [trimesh](https://trimesh.org/) | STL validation gates | `pip3 install --user trimesh numpy` |
| [PrusaSlicer](https://www.prusa3d.com/prusaslicer/) | Slicer cross-check in validation gates | `brew install --cask prusaslicer` |
| [uv](https://docs.astral.sh/uv/) + CAD venv | Runs build123d / sdf / doc search (needs Python ≥3.10) | see below |

### CAD Python venv (build123d, sdf, doc search)

```bash
brew install uv
uv venv --python 3.12 ~/.venv-cad3d
uv pip install --python ~/.venv-cad3d/bin/python \
    build123d trimesh numpy rank-bm25 'git+https://github.com/fogleman/sdf.git'
```

### Documentation corpus (for /cad-docs search)

```bash
mkdir -p ~/.cad-docs && cd ~/.cad-docs
git clone --depth 1 https://github.com/BelfrySCAD/BOSL2.wiki.git bosl2-wiki
git clone --depth 1 --filter=blob:none --sparse https://github.com/gumyr/build123d.git build123d-repo
git -C build123d-repo sparse-checkout set docs
curl -sL https://raw.githubusercontent.com/fogleman/sdf/main/README.md -o sdf-README.md
```

### mesh3d (generative 3D) — additional dependencies

| Dependency | What for | Install (macOS) |
|------------|----------|-----------------|
| [Blender](https://www.blender.org/) ≥ 4.1 | Mandatory voxel-remesh print prep (subprocess; never `pip install bpy`) | `brew install --cask blender` |
| mesh3d venv | Light client venv: trimesh, requests, pillow, numpy — nothing heavier | `uv venv --python 3.12 ~/.venv-mesh3d && uv pip install --python ~/.venv-mesh3d/bin/python trimesh requests pillow numpy` |
| Shape + image server | External GPU service implementing the contracts in `.claude/skills/mesh3d/scripts/gen_shape.py` / `gen_image.py` docstrings. **Separate deliverable — not in this repo.** | set `MESH3D_SHAPE_ENDPOINT`, `MESH3D_IMAGE_ENDPOINT` (keys via `MESH3D_*_KEY`, never argv) |

## Usage

Start Claude Code in this directory and describe what you want:

```
/openscad make a phone stand          # OpenSCAD/BOSL2 backend
/build123d enclosure for a 50x30 PCB  # mechanical B-rep backend
/sdf-shapes ergonomic bicycle grip    # organic SDF backend
```

## Skills

| Skill | Description |
|-------|-------------|
| `/openscad` | Versioned OpenSCAD/BOSL2 modeling with rendering and iteration |
| `/build123d` | Mechanical parts in build123d Python (fillets/shells/tolerances) |
| `/sdf-shapes` | Smooth organic forms via signed distance fields |
| `/mesh3d` | Text/image → generative 3D → print-ready STL (figurines, sculpture) |
| `/preview-scad` | Multi-view PNG rendering (accepts .scad and .stl) |
| `/export-stl` | STL export + hard geometry gates (trimesh + PrusaSlicer) |
| `/cad-docs` | BM25 search over local BOSL2/build123d/sdf docs |

### Workflow

```
model source (.scad or .py) → multi-view render → rubric critique
        ↑                                              |
        └── iterate (errors fed back, max 3/issue) ←──┘
                          ↓ (rubric passes)
              STL export → validation gates (watertight, manifold, bbox-vs-spec)
                          ↓ (exit 2 = fix & retry)
                     Ready for slicer
```

## File Structure

```
.
├── .claude/
│   ├── settings.local.json      # Claude Code permissions
│   └── skills/
│       ├── openscad/            # OpenSCAD/BOSL2 skill (+ BOSL2 cheat-sheet)
│       ├── build123d/           # Mechanical B-rep skill (+ cheat-sheet)
│       ├── sdf-shapes/          # Organic SDF skill (+ cheat-sheet)
│       ├── preview-scad/        # Multi-view PNG rendering
│       ├── export-stl/          # STL export + validation gates
│       └── cad-docs/            # Local documentation search
├── AGENTS.md                    # Agent instructions
└── <project dirs>               # Generated models, previews, and exports
```

## License

MIT
