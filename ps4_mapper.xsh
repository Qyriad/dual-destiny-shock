#!/usr/bin/env xonsh
# vim: filetype=python

import evdev
from evdev import ecodes


MAPPINGS = {
    315: (318, 78), # Save
    ecodes.BTN_TR: (1616, 81), # Court Record
    ecodes.BTN_TR2: (1527, 560), # CR Right
    ecodes.BTN_TL2: (391, 560), # CR Left
    ecodes.BTN_DPAD_RIGHT: (1583, 986), # Next
}


# for row in (425, 666):
    # MAPPINGS[




controller = evdev.InputDevice('/dev/input/event19')


def press(x, y):
    """ Send touch input to our android device. """
    adb shell input tap @(x) @(y)


for event in controller.read_loop():

    try:

        # Handle button presses.
        if event.type == evdev.ecodes.EV_KEY:

            # We'll only care about key releases, as those are where we'll inject events.
            if not event.value:
                press(*MAPPINGS[event.code])


        # Handle the D-PAD, because it's handled as hat switches.
        elif event.type == evdev.ecodes.EV_ABS:


            # code 16 is the L/R axis
            if event.code == 16:
                if event.value == -1:
                    press(*MAPPINGS[ecodes.BTN_DPAD_LEFT])
                elif event.value == 1:
                    press(*MAPPINGS[ecodes.BTN_DPAD_RIGHT])

            # code 17 is the U/D axis
            if event.code == 17:
                if event.value == -1:
                    press(*MAPPINGS[ecodes.BTN_DPAD_UP])
                elif event.value == 1:
                    press(*MAPPINGS[ecodes.BTN_DPAD_DOWN])


    except KeyError:
        pass
