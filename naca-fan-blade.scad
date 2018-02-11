use <scad-utils/transformations.scad>
use <MCAD/array/along_curve.scad>
use <MCAD/general/sweep.scad>
use <MCAD/shapes/cylinder.scad>
include <MCAD/units/metric.scad>

use <Naca4.scad>

no_of_blades = 10;
wall_thickness = 2;
hub_id = 55;
hub_od = 74;
propeller_d = 143.8;
wingspan = propeller_d - hub_od;

blade_height = 35 - 0.5;
hub_thickness = 35;


magnet_thickness = 20.8;
magnet_d = 55.4;
shaft_coupler_d = 11;
shaft_coupler_depth = 26.5;
shaft_coupler_h = 7;

blade_pitch = 20;

$fs = 0.4;
$fa = 1;

module basic_hub ()
{
    flat_h = hub_thickness - 5;
    sloped_h = hub_thickness - flat_h;

    *cylinder (d = hub_od, h = flat_h);

    *translate ([0, 0, flat_h - epsilon])
    cylinder (d1 = hub_od, d2 = hub_od - sloped_h * 2, h = sloped_h);

    mcad_rounded_cylinder (d = hub_od, h = hub_thickness, round_r2 = 5);
}

module wings ()
{
    length = blade_height;
    radius = propeller_d / 2;
    airfoil_points = airfoil_data (
        naca = 1410, L = length, N = 81, open = false);
    slices = 30;

    function blade_twist (r) = blade_pitch + asin (r / radius * 0.5);
    function blade_scale (r) = length / (cos (blade_twist (r)) * length);
    function blade_transformation (r) = (
        translation ([0, 0, r]) *
        rotation ([0, 0, blade_twist (r)]) *
        scaling ([1, 1, 1] * blade_scale (r))
    );

    module one_blade ()
    {
        render ()
        intersection () {
            difference () {
                translate ([0, 0, length])
                rotate (90, Y)
                sweep (airfoil_points,
                       [
                           for (t = [0 : 1.0 / slices : 1.00001])
                               blade_transformation (t * radius)
                       ]);

                /* avoid intersecting blades */
                cylinder (d = hub_od * 0.5, h = length * 2.5, center = true);
            }

            cylinder (d = propeller_d, h = length * 2.5, center = true);
        }
    }

    mcad_rotate_multiply (no_of_blades)
    one_blade ();
}

module hub_cavity ()
{
    translate ([0, 0, -epsilon])
    mcad_rounded_cylinder (d = magnet_d, h = magnet_thickness,
                           round_r2 = 2);
}

module shaft_hub ()
{
    translate ([0, 0, shaft_coupler_depth])
    mirror (Z)
    cylinder (d = shaft_coupler_d + 4, h = shaft_coupler_h);
}

module shaft_cutout ()
{
    /* shaft access hole cutout */
    cylinder (d = shaft_coupler_d - 2, h = hub_thickness + epsilon * 2);

    /* shaft coupler cutout */
    cylinder (d = shaft_coupler_d, h = shaft_coupler_depth);
}

render ()
difference () {
    union () {
        render ()
        difference () {
            render ()
            union () {
                basic_hub ();
                wings ();
            }

            hub_cavity ();
        }

        shaft_hub ();
    }

    shaft_cutout ();
}
