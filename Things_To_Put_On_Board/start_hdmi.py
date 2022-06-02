#!/usr/bin/python3.6
# -*- coding: utf-8 -*-

"""This file holds the function we use to start the video system
"""

import sys
import os
import time
import numpy as np
import argparse

from pynq.overlays.base import BaseOverlay
from pynq import Overlay
from pynq.lib.video import *

HOME_PATH = "/home/xilinx/" # We cannot use os.path.expanduser("~") to get this
                            # as run the script as a super-user

def start_hdmi(params):
    """This functions will start the video system and allow you to write to a
    frame buffer which is used for the HDMI output

    Parameters
    ----------
    params : :obj:
        Script parameters
    """

    if params.download:
        print("Programming FPGA with bitfile")
    else:
        print("NOT Programming FPGA with bitfile")
        print("If this does not work, use the download option")

    # Use the default bitfile for the base overlay
    if params.bitfile is None:
        print("Using default bitfile base.bit")
        base = BaseOverlay(bitfile = "base.bit", download = params.download)

    # Use a custom bit file
    else:

        # Expand the path
        if "~/" in params.bitfile:
            params.bitfile = params.bitfile.replace("~/", HOME_PATH)

        print("Using bitfile located at {}".format(os.path.abspath(params.bitfile)))

        if "base.bit" in params.bitfile:
            base = BaseOverlay(bitfile = "base.bit", download = params.download)
        else:
            base = Overlay(bitfile_name = params.bitfile, download = params.download)


    print("Starting Video system with parameters")
    print("\tHeight", params.height)
    print("\tWidth", params.width)
    print("\tBits per pixel", params.bpp)

    video_mode = VideoMode(
        width          = params.width,
        height         = params.height,
        bits_per_pixel = params.bpp
    )

    hdmi_out = base.video.hdmi_out
    hdmi_out.configure(video_mode)
    hdmi_out.start()
    time.sleep(1)

    print("Initializing Video output frame")
    frame    = hdmi_out.newframe()
    frame[:] = 128
    hdmi_out.writeframe(frame)

    print("\tFrame physical address", hex(frame.physical_address))
    print("\tFrame cacheable", frame.cacheable)
    print("\tFrame coherent", frame.coherent)

    input("Press Enter for next frame...")

    frame[:] = 242
    hdmi_out.writeframe(frame)

    input("Press Enter to close the screen...")

    hdmi_out.close()

    print("Video system successfully closed (screen should become black again)")


def main(params):
    start_hdmi(params)


if __name__ == "__main__":

    if not (sys.version_info.major == 3):
        print("This script requires Python 3.6 on the Pynq!")
        print("You are using Python {}.{}.".format(sys.version_info.major, sys.version_info.minor))
        print("This script should be executed in one of the following ways")
        print("sudo python3 start_hdmi.py")
        print("sudo ./start_hdmi.py")
        print("The latter option requires you to do chmod +x start_hdmi.py")

        sys.exit(1)

    if not os.geteuid() == 0:
        sys.exit("\nOnly root can run this script\n")
        print("Execute as: sudo python3 start_hdmi.py")

        sys.exit(1)

    parser = argparse.ArgumentParser(description="Starts the video processing pipeline.")

    parser.add_argument("--height", dest="height", type=int, default=480, help="The display height")
    parser.add_argument("--width", dest="width", type=int, default=640, help="The display width")
    parser.add_argument("--bpp", dest="bpp", type=int, default=24, help="The number of bits per pixel")

    parser.add_argument("--bitfile", dest="bitfile", type=str, default=None, help="The path to the bit file. If this is not specified, we just use the default")
    parser.add_argument("--download", dest="download", type=int, default=1, help="If True, download the bitfile to the board")

    params, unknown = parser.parse_known_args()

    if unknown:
        raise ValueError("This argument {} in unknown".format(unknown))

    main(params)
