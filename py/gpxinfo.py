#!/usr/bin/python3

"""
Command line utility to extract basic statistics from gpx file(s)
"""

import pdb
import sys as mod_sys
import logging as mod_logging
import math as mod_math
import argparse as mod_argparse
import gpxpy as mod_gpxpy
import sqlite3
import os
from shutil import copyfile

DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'
filebase = os.environ["XDG_DATA_HOME"]+"/"+os.environ["APP_ID"].split('_')[0]
KM_TO_MILES = 0.621371
M_TO_FEET = 3.28084


def format_time(time_s):
    if not time_s:
        return 'n/a'
    else:
        minutes = mod_math.floor(time_s / 60.)
        hours = mod_math.floor(minutes / 60.)
        return '%s:%s:%s' % (str(int(hours)).zfill(2), str(int(minutes % 60)).zfill(2), str(int(time_s % 60)).zfill(2))


def format_long_length(length):
    return '{:.3f}km'.format(length / 1000.)


def format_short_length(length):
    return '{:.2f}m'.format(length)


def format_speed(speed):
    if not speed:
        speed = 0
    else:
        return '{:.2f}m/s = {:.2f}km/h'.format(speed, speed * 3600. / 1000.)

def print_gpx_info2(gpx, gpx_file):
    indentation='    '
    info_display = "File: %s\n" % gpx_file

    if gpx.name:
        info_display += "GPX name: %s\n" % gpx.name
    if gpx.description:
        info_display += "GPX description: %s\n" % gpx.description
    if gpx.author_name:
        info_display += "Author: %s\n" % gpx.author_name
    if gpx.author_email:
        info_display += "Email: %s\n" % gpx.author_email

    """
    gpx_part may be a track or segment.
    """
    length_2d = gpx.length_2d()
    length_3d = gpx.length_3d()
    info_display += "%sLength 2D: %s\n" % (indentation, format_long_length(length_2d))
    info_display += "%sLength 3D: %s\n" % (indentation, format_long_length(length_3d))
    moving_time, stopped_time, moving_distance, stopped_distance, max_speed = gpx.get_moving_data()
    info_display += "%sMoving time: %s\n" %(indentation, format_time(moving_time))
    info_display += "%sStopped time: %s\n" %(indentation, format_time(stopped_time))
    info_display += "%sMax speed: %s\n" % (indentation, format_speed(max_speed))
    info_display += "%sAvg speed: %s\n" % (indentation, format_speed(moving_distance / moving_time) if moving_time > 0 else "?")

    uphill, downhill = gpx.get_uphill_downhill()
    info_display += "%sTotal uphill: %s\n" % (indentation, format_short_length(uphill))
    info_display += "%sTotal downhill: %s\n" % (indentation, format_short_length(downhill))

    start_time, end_time = gpx.get_time_bounds()
    info_display += "%sStarted: %s\n" % (indentation, start_time)
    info_display += "%sEnded: %s\n" % (indentation, end_time)

    points_no = len(list(gpx.walk(only_points=True)))
    info_display += "%sPoints: %s\n" % (indentation, points_no)

    if points_no > 0:
        distances = []
        previous_point = None
        for point in gpx.walk(only_points=True):
            if previous_point:
                distance = point.distance_2d(previous_point)
                distances.append(distance)
            previous_point = point
        info_display += "%sAvg distance between points: %s\n" % (indentation, format_short_length(sum(distances) / len(list(gpx.walk()))))

    zip(info_display)
    print(info_display)
    return(info_display)
    #print_gpx_part_info(gpx,info_display)

    #print_gpx_part_info(gpx)
    #mod_sys.exit(1)

def read_run(gpx_file):
    if not gpx_file:
        print('No GPX files given')
        mod_sys.exit(1)
    try:
        gpx = mod_gpxpy.parse(open(gpx_file))
        print_gpx_info2(gpx, gpx_file)
    except Exception as e:
        mod_logging.exception(e)
        print('Error processing %s' % gpx_file)
        mod_sys.exit(1)


def Info_run(run):
    print(run)
    conn = sqlite3.connect('%s/activities.db' % filebase)
    cursor = conn.cursor()
    sql = "SELECT filename from activities WHERE id=?"
    cursor.execute(sql, [run])
    result = cursor.fetchone()[0]
    conn.close()
    gpx_file = result
    print("printing info for ",gpx_file)
    if not gpx_file:
        print('No GPX files given')
        mod_sys.exit(1)
    try:
        gpx = mod_gpxpy.parse(open(gpx_file))
        #print_gpx_info2(gpx, gpx_file)
        indentation='    '
        info_display = "File: %s\n" % gpx_file

        if gpx.name:
            info_display += "GPX name: %s\n" % gpx.name
        if gpx.description:
            info_display += "GPX description: %s\n" % gpx.description
        if gpx.author_name:
            info_display += "Author: %s\n" % gpx.author_name
        if gpx.author_email:
            info_display += "Email: %s\n" % gpx.author_email

        """
        gpx_part may be a track or segment.
        """
        length_2d = gpx.length_2d()
        length_3d = gpx.length_3d()
        info_display += "%sLength 2D: %s\n" % (indentation, format_long_length(length_2d))
        info_display += "%sLength 3D: %s\n" % (indentation, format_long_length(length_3d))
        moving_time, stopped_time, moving_distance, stopped_distance, max_speed = gpx.get_moving_data()
        info_display += "%sMoving time: %s\n" %(indentation, format_time(moving_time))
        info_display += "%sStopped time: %s\n" %(indentation, format_time(stopped_time))
        info_display += "%sMax speed: %s\n" % (indentation, format_speed(max_speed))
        info_display += "%sAvg speed: %s\n" % (indentation, format_speed(moving_distance / moving_time) if moving_time > 0 else "?")

        uphill, downhill = gpx.get_uphill_downhill()
        info_display += "%sTotal uphill: %s\n" % (indentation, format_short_length(uphill))
        info_display += "%sTotal downhill: %s\n" % (indentation, format_short_length(downhill))

        start_time, end_time = gpx.get_time_bounds()
        info_display += "%sStarted: %s\n" % (indentation, start_time)
        info_display += "%sEnded: %s\n" % (indentation, end_time)

        points_no = len(list(gpx.walk(only_points=True)))
        info_display += "%sPoints: %s\n" % (indentation, points_no)

        if points_no > 0:
            distances = []
            previous_point = None
            for point in gpx.walk(only_points=True):
                if previous_point:
                    distance = point.distance_2d(previous_point)
                    distances.append(distance)
                previous_point = point
            info_display += "%sAvg distance between points: %s\n" % (indentation, format_short_length(sum(distances) / len(list(gpx.walk()))))

        zip(info_display)
        #print(info_display)
        return info_display
    except Exception as e:
        mod_logging.exception(e)
        print('Error processing %s' % gpx_file)
        mod_sys.exit(1)
