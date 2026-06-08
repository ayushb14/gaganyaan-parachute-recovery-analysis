#!/usr/bin/env python3
"""
Generate closed 3D bluff/domed canopy STL geometries for OpenFOAM snappyHexMesh.
The generated body is a closed shallow spherical-cap/disc approximation of an inflated canopy.
It is not fabric FSI; it is a fixed CFD validation geometry for Cd/wake extraction.
"""
import math, csv, os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT/'stage_conditions'/'stage_conditions.csv'


def vec_sub(a,b): return (a[0]-b[0], a[1]-b[1], a[2]-b[2])
def cross(a,b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def norm(v):
    m = math.sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2])
    if m < 1e-16: return (0.0,0.0,0.0)
    return (v[0]/m, v[1]/m, v[2]/m)

def tri_normal(a,b,c): return norm(cross(vec_sub(b,a), vec_sub(c,a)))

def write_tri(f,a,b,c):
    n = tri_normal(a,b,c)
    f.write(f"  facet normal {n[0]:.8e} {n[1]:.8e} {n[2]:.8e}\n")
    f.write("    outer loop\n")
    for p in [a,b,c]:
        f.write(f"      vertex {p[0]:.8e} {p[1]:.8e} {p[2]:.8e}\n")
    f.write("    endloop\n  endfacet\n")


def generate_canopy(path, D_eff, depth_ratio, thickness_ratio, n_theta=96, n_radial=20):
    """Closed axisymmetric domed/bluff canopy body.
    Flow is +x. The upstream face is a shallow bluff/domed projected canopy centered near x=0.
    Radius is D_eff/2. Depth controls inflation/bluffness. Thickness keeps STL closed for snappy.
    """
    R = 0.5*D_eff
    depth = max(0.03*D_eff, depth_ratio*D_eff)
    thickness = max(0.01*D_eff, thickness_ratio*D_eff)
    # Upstream face: spherical/parabolic cap with highest point upstream at x=-depth.
    # Rim is near x=0. Back face offset downstream by thickness to create a closed solid.
    def x_front(r):
        rr = r/R if R > 0 else 0
        return -depth*(1.0 - rr*rr)
    def x_back(r):
        # downstream backing, slightly curved, closes the solid while keeping a blunt projected face
        rr = r/R if R > 0 else 0
        return thickness*(0.25 + 0.75*rr*rr)
    rings_front=[]; rings_back=[]
    for i in range(n_radial+1):
        r = R*i/n_radial
        ring_f=[]; ring_b=[]
        for j in range(n_theta):
            th = 2*math.pi*j/n_theta
            y = r*math.cos(th); z = r*math.sin(th)
            ring_f.append((x_front(r), y, z))
            ring_b.append((x_back(r), y, z))
        rings_front.append(ring_f); rings_back.append(ring_b)
    with open(path,'w') as f:
        f.write('solid canopy\n')
        # front cap
        center_f = (-depth,0,0)
        for j in range(n_theta):
            jp=(j+1)%n_theta
            write_tri(f, center_f, rings_front[1][jp], rings_front[1][j])
        for i in range(1,n_radial):
            for j in range(n_theta):
                jp=(j+1)%n_theta
                a=rings_front[i][j]; b=rings_front[i][jp]; c=rings_front[i+1][jp]; d=rings_front[i+1][j]
                write_tri(f,a,b,c); write_tri(f,a,c,d)
        # back face
        center_b = (thickness*0.25,0,0)
        for j in range(n_theta):
            jp=(j+1)%n_theta
            write_tri(f, center_b, rings_back[1][j], rings_back[1][jp])
        for i in range(1,n_radial):
            for j in range(n_theta):
                jp=(j+1)%n_theta
                a=rings_back[i][j]; b=rings_back[i+1][j]; c=rings_back[i+1][jp]; d=rings_back[i][jp]
                write_tri(f,a,b,c); write_tri(f,a,c,d)
        # rim side wall connecting front/back
        i=n_radial
        for j in range(n_theta):
            jp=(j+1)%n_theta
            a=rings_front[i][j]; b=rings_front[i][jp]; c=rings_back[i][jp]; d=rings_back[i][j]
            write_tri(f,a,b,c); write_tri(f,a,c,d)
        f.write('endsolid canopy\n')


def main():
    with open(CSV_PATH) as f:
        for row in csv.DictReader(f):
            case_dir = ROOT/'cases'/row['case']
            tri = case_dir/'constant'/'triSurface'
            tri.mkdir(parents=True, exist_ok=True)
            generate_canopy(tri/'canopy.stl', float(row['D_eff']), float(row['depth_ratio']), float(row['thickness_ratio']))
            print('generated', tri/'canopy.stl')

if __name__ == '__main__':
    main()
