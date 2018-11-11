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


def print_gpx_part_info(gpx_part, indentation='    '):
    """
    gpx_part may be a track or segment.
    """
    length_2d = gpx_part.length_2d()
    length_3d = gpx_part.length_3d()
    print('%sLength 2D: %s' % (indentation, format_long_length(length_2d)))
    print('%sLength 3D: %s' % (indentation, format_long_length(length_3d)))

    moving_time, stopped_time, moving_distance, stopped_distance, max_speed = gpx_part.get_moving_data()
    print('%sMoving time: %s' % (indentation, format_time(moving_time)))
    print('%sStopped time: %s' % (indentation, format_time(stopped_time)))
    print('%sMax speed: %s' % (indentation, format_speed(max_speed)))
    print('%sAvg speed: %s' % (indentation, format_speed(moving_distance / moving_time) if moving_time > 0 else "?"))

    uphill, downhill = gpx_part.get_uphill_downhill()
    print('%sTotal uphill: %s' % (indentation, format_short_length(uphill)))
    print('%sTotal downhill: %s' % (indentation, format_short_length(downhill)))

    start_time, end_time = gpx_part.get_time_bounds()
    print('%sStarted: %s' % (indentation, start_time))
    print('%sEnded: %s' % (indentation, end_time))

    points_no = len(list(gpx_part.walk(only_points=True)))
    print('%sPoints: %s' % (indentation, points_no))

    if points_no > 0:
        distances = []
        previous_point = None
        for point in gpx_part.walk(only_points=True):
            if previous_point:
                distance = point.distance_2d(previous_point)
                distances.append(distance)
            previous_point = point
        print('%sAvg distance between points: %s' % (indentation, format_short_length(sum(distances) / len(list(gpx_part.walk())))))

    print('')


def print_gpx_info(gpx, gpx_file,gpx_name,act_type):
    print('File: %s' % gpx_file)

    if gpx.name:
        print('  GPX name: %s' % gpx.name)
    if gpx.description:
        print('  GPX description: %s' % gpx.description)
    if gpx.author_name:
        print('  Author: %s' % gpx.author_name)
    if gpx.author_email:
        print('  Email: %s' % gpx.author_email)

    print_gpx_part_info(gpx)
    add_run(gpx,gpx_name,act_type,gpx_file,"")

def add_run(gpx_part,name,act_type,filename,polyline):
    conn = sqlite3.connect('%s/activities.db' % filebase)
    cursor = conn.cursor()
    cursor.execute("""CREATE TABLE if not exists activities
                  (id INTEGER PRIMARY KEY AUTOINCREMENT,name text, act_date text, distance text,
                   speed text, act_type text,filename text,polyline text)""")
    sql = "INSERT INTO activities VALUES (?,?,?,?,?,?,?,?)"
    start_time, end_time = gpx_part.get_time_bounds()
    #l2d='{:.3f}'.format(gpx.length_2d() / 1000.)
    l2d = '{:.3f}'.format(gpx_part.length_2d() / 1000.)
    moving_time, stopped_time, moving_distance, stopped_distance, max_speed = gpx_part.get_moving_data()
    print(max_speed)
    #print('%sStopped distance: %sm' % stopped_distance)
    maxspeed = 'Max speed: {:.2f}km/h'.format(max_speed * 60. ** 2 / 1000. if max_speed else 0)
    duration = '{:.2f}'.format(gpx_part.get_duration() / 60)

    print("-------------------------")
    print(name)
    print(start_time)
    print(l2d)
    print(maxspeed)
    print("-------------------------")
    try:
        cursor.execute(sql, [None, name,start_time,l2d,duration,act_type,filename,polyline])
        conn.commit()
    except sqlite3.Error as er:
        print("-------------______---_____---___----____--____---___-----")
        print(er)
    conn.close()


def Import_run(gpx_file,gpx_name,act_type):
#Clean url
    gpx_file= gpx_file[7:]
    gpx_filename = gpx_file.split('/', 8 )[7]
#build of the newlocation file
    newlocation="/home/phablet/.local/share/activitytracker.cwayne18/{}".format(gpx_filename)
#move GPX file to /home/phablet/.local/share/activitytracker.cwayne18/
    copyfile(gpx_file, newlocation)
#use the new location to load into the database
    gpx_file=newlocation

    if not gpx_file:
        print('No GPX files given')
        mod_sys.exit(1)

    try:
        gpx = mod_gpxpy.parse(open(gpx_file))
        print_gpx_info(gpx, gpx_file,gpx_name,act_type)
    except Exception as e:
        mod_logging.exception(e)
        print('Error processing %s' % gpx_file)
        mod_sys.exit(1)
