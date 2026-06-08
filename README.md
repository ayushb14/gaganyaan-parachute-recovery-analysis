# Gaganyaan Parachute Recovery Analysis

## Project Title
A Coupled MATLAB–OpenFOAM Framework for Trajectory Prediction, Uncertainty Quantification, and Stage-Wise Aerodynamic Analysis of a Gaganyaan-Type Crew Module Parachute Recovery System

## Overview
This project presents a coupled MATLAB–OpenFOAM simulation framework for analysing the staged parachute deployment sequence of a Gaganyaan-type crew module descent system.

The framework combines:
- MATLAB-based descent modelling
- Monte Carlo uncertainty analysis
- OpenFOAM-based computational fluid dynamics
- Stage-wise aerodynamic comparison
- Drag coefficient estimation
- Flow-field visualization

## Parachute Deployment Stages
The descent sequence is divided into representative stages:

1. Reefed Drogue Parachute
2. Full-Open Drogue Parachute
3. Main Parachute Reef Stage 1
4. Main Parachute Reef Stage 2
5. Full-Open Main Parachute

## MATLAB Analysis
MATLAB is used to model:
- Altitude variation
- Velocity profile
- Dynamic pressure
- Drag force
- Deployment-state transition
- Monte Carlo uncertainty propagation

Uncertainty sources include:
- Atmospheric density variation
- Drag coefficient variation
- Wind disturbance
- Descent condition variation

## OpenFOAM CFD Analysis
OpenFOAM is used to generate simplified 3D canopy models and extract aerodynamic flow-field characteristics.

Generated outputs include:
- Velocity contours
- Pressure distributions
- Streamlines
- Computational mesh views
- Drag coefficient estimates

## Results Summary
The OpenFOAM-derived drag coefficients are compared with MATLAB target drag coefficient values.

The results show that main parachute reefed stages demonstrate closer agreement with the target model, while drogue stages show higher deviation due to simplified solid-canopy geometry and limited representation of:
- Fabric porosity
- Inflation dynamics
- Fluid-structure interaction
- Real parachute flexibility

## Future Scope
Future improvements may include:
- Real canopy geometry
- Transient inflation modelling
- Porosity effects
- Fluid-structure interaction
- Experimental validation
- Flight-test data comparison

## Tools Used
- MATLAB
- OpenFOAM
- ParaView
- Python
- GitHub

## Author
Ayush Bhatt  
B.Tech Aerospace Engineering  
UPES, Dehradun
