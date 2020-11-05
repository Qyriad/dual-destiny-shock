#!/usr/bin/env xonsh
# vim: filetype=python

import time


import evdev
from evdev import ecodes


# Determines how quickly we send events to the device, in seconds.
EVENT_THROTTLE_TIME = 0.01

SCALE_X = 0.5
SCALE_Y = 0.5


# Grab the controller's touchpad.
controller = evdev.InputDevice('/dev/input/event17')
controller.grab()


#
# Relative movement state.
# 
x = 0
y = 0

rel_x = 0
rel_y = 0

last_event_time = 0
last_sent_time = 0
set_just_started= False


#
# Helper functions.
#

def move(x, y):
    """ Move the mouse on the target android device. """
    adb shell \
        "sendevent /dev/input/event7 2 0 " @(x) ";" \
        "sendevent /dev/input/event7 2 1 " @(y) ";" \
        "sendevent /dev/input/event7 0 0 0;" \


def send_move_events():
    """ Helper; sends our pent-up move events. """
    global rel_x, rel_y

    # Don't send relative events if they're just adding zero; that would be silly.
    if (rel_x == 0) and (rel_y == 0):
        return

    move(rel_x * SCALE_X, rel_y * SCALE_Y)

    rel_x = 0
    rel_y = 0



#
# Event loop.
#

for event in controller.read_loop():

    # Convert absolute movement events into relative offsets.
    if event.type == ecodes.EV_ABS:

        if event.code == ecodes.ABS_X:
            rel_x += event.value - x
            x = event.value

        if event.code == ecodes.ABS_Y:
            rel_y += event.value - y
            y = event.value


    # Hlndle button presses.
    elif event.type == ecodes.EV_KEY:

        # If we're just seeing a finger touch down, that means we're starting movement.
        # At the end of this set, we'll want to reset or origin.
        set_just_started= True


    # Handle synthetic codes, which indicate a full set of EVDEV events is complete.
    # We'll use this as a our prompt to 
    elif event.type == ecodes.EV_SYN:

        # If we just started tracking a movement, reset our relative origin.
        if set_just_started:
            last_event_time = time.time()
            set_just_started = False
            rel_x = 0
            rel_y = 0
            continue


        last_event_time = time.time()

        # If it hasn't been long enough since the last event was sent, we'll wait, and let
        # relative events accrue. Since we're sending events over a slow connection, this prevents
        # us from overrunning our local event buffer.
        if (time.time() - last_sent_time) < EVENT_THROTTLE_TIME:
            continue


        # Keep track of the last event sent.
        last_sent_time = last_event_time
        send_move_events()



    # If long enoguh has passed since we've seen an event, send any pending movements.
    if (time.time() - last_event_time) > EVENT_THROTTLE_TIME:
        if not set_just_started:
            send_move_events()
