# Pong Game Project
## for the EPFL course Digital systems design [EE-334](https://isa.epfl.ch/imoniteur_ISAP/!itffichecours.htm?ww_i_matiere=2720138657&ww_x_anneeAcad=2021-2022&ww_i_section=48121016)


<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
* [Files](#files)
* [Contact](#contact)

<!-- ABOUT THE PROJECT -->
## About The Project
The project implements a single player pong game (in VHDL) that is displayed on a monitor via VGA connection. The background of the game is a random part of the Mandelbrot set that depends on the user input.


<!-- FILES -->
## Files
| **Name**            | **Comment**                                                          |
|---------------------|----------------------------------------------------------------------|
| dsd_prj_pkg.vhdl    | Parameters used for the VGA controller, pong and mandelbrot circuits |
| mandelbrot.vhdl     | Basic circuit for mandelbrot                                         |
| mandelbrot_top.vhdl | Toplevel of pong game, mandelbrot and rgb fadeout                    |
| pong_fsm.vhdl       | Finite state machine for pong game                                   |
| rgb_fade.vhdl       | Circuit for rgb fadeout algorithm                                    |
| vga_controller.vhdl | Circuit for VGA controller                                           |



<!-- CONTACT -->
## Contact
[lvuilleu](https://github.com/lvuilleu)    <br />
Samuel Bumann - samuel.bumann@epfl.ch
