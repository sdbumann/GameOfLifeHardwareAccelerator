# Game Of Life Hardware Accelerator
## for the EPFL course Digital systems design [EE-390(a)](https://edu.epfl.ch/coursebook/en/lab-in-digital-systems-design-EE-390-A)


<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
* [Folders](#folders)
* [Video](#video)
* [Contact](#contact)
 
<!-- ABOUT THE PROJECT -->
## About The Project
The project implements John Conway’s Game of Life Accelerator (in VHDL) that is displayed on a monitor via HDMI connection. The hardware accelerator computes the Game of Life on a 1024 x 1024 grid. It is implemented using an ARM Cortex A9 processor on a PYNQ-Z2 Development Board. The memory content of the Game of Life Checkerboard is initialized in DRAM by the software. The VHDL accelerator communicates over a AXI slave and master with the processor. The grid is first initialized randomly by the processor, and the accelerator then either autonomously iterates through it or only does one iteration at a time, depending on user input. The accelerator computes an iteration, then sends the pixel data of a 640 x 480 window based on the grid to the framebuffer, from where it is displayed on the screen through the HDMI out port of the PYNQ-Z2 board. A white pixel corresponds to a dead cell, and a pink pixel corresponds to an alive cell. The accelerator can send the pixel data, as well as the grid itself via an AXI4 bus back to the processor. In software, the grid can then be adjusted (kill all alive cells on the screen, or invert all cells) and then be sent back to the accelerator to keep computing the Game of Life and the framebuffer. <br><br>

Note that a simple dual port RAM IP was used as a BRAM.


<!-- VIDEO -->
## Video
https://user-images.githubusercontent.com/58890541/172058959-2059d671-373a-4f50-828a-5410a56185cb.mp4


<!-- FOLDERS -->
## Folders
| **Name**                | **Comment**                                                          |
|-------------------------|----------------------------------------------------------------------|
| HDL                     | VHDL code                                                            |
| TB                      | Testbenches for the VHDL code                                        |
| C_Code                  | Code needed to run the Game Of Life Accelerator                      |
| Things_To_Put_On_Board  | Files that need to be put on the board                               |
| Vivado_Project          | Viviado Project of the Game Of Life Accelerator                      |

<!-- CONTACT -->
## Contact
Samuel Bumann - samuel.bumann@epfl.ch <br>
Mathias Arnold - mathias.arnold@epfl.ch<br>

<br>
Project Link: https://github.com/sdbumann/GameOfLifeHardwareAccelerator
