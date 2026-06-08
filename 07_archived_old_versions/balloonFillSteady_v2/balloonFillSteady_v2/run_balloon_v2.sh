#!/usr/bin/env bash
set -e
blockMesh
checkMesh
foamRun -solver incompressibleFluid | tee log.foamRun
python3 post_process_balloon_stress.py
paraFoam
