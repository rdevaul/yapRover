# Interactive terrain visualization

The first version should demonstrate quasi-static suspension kinematics with
play/pause and a distance scrubber, selectable terrain profiles, chassis
pitch/roll, rocker/bogie angles, and an explicit infeasible-pose indication.
It should use the production link dimensions, differential closure, and physical
joint limits. It is a kinematic demonstration, not a traction prediction.

## Scope and rough effort

- Linkage view over continuous terrain: one or two focused working sessions.
- Detailed 3D view with lightweight CAD meshes and an orbit camera: several
  working sessions, including mesh export and transform verification.
- Contact forces, wheel lift, friction/slip, drive torque, and impacts: a
  multi-week physics project requiring physical calibration.

These are engineering scope estimates, not delivery commitments.

## Implementation approach

1. Extend the Python oracle to accept longitudinal rover position and terrain
   profiles for the left and right tracks. Reuse converged poses as initial
   guesses so playback follows a continuous branch.
2. Solve wheel contact against the profile using the wheel radius. Evaluating
   terrain only directly below the wheel center is insufficient on slopes or
   step edges; a circular wheel contacts an offset location. Start with a
   planar circular-wheel/profile contact model and document its roll/camber
   approximation before extending to full 3D wheel contact.
3. Validate flat ground, slopes, rounded bumps, and step edges. Reject poses
   outside joint travel, penetrating terrain, or without a converged contact
   solution. A six-contact kinematic solution does not prove positive wheel
   loads or stability.
4. Render a lightweight linkage view first. Keep the Python solver authoritative:
   either generate sampled playback trajectories or use a local solver service
   for live terrain edits. Any browser port must match Python regression cases.
5. Export lightweight meshes per rigid component from the CAD model and apply
   the solved assembly transforms. Retain the simple linkage overlay to make
   the differential and parent-relative bogie rotations inspectable.

Do not animate six arbitrary wheel heights and describe it as continuous
terrain contact. Do not compute exact BREP booleans on every animation frame;
use offline validation and lightweight display meshes.
