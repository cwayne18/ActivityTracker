#!/usr/bin/python3

import gpxpy
import datetime
import time
import os
import gpxpy.gpx
import sqlite3
import pl

DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'

def create_gpx(lat,lng,elev):
    
# Creating a new file:
# --------------------

    gpx = gpxpy.gpx.GPX()

# Create first track in our GPX:
    gpx_track = gpxpy.gpx.GPXTrack()
    gpx.tracks.append(gpx_track)

# Create first segment in our GPX track:
    gpx_segment = gpxpy.gpx.GPXTrackSegment()
    gpx_track.segments.append(gpx_segment)

# Create points:
    return gpx

def write_gpx(gpx,name,act_type):
# You can add routes and waypoints, too...
    tzname=None
    npoints=None

    # polyline encoder default values
    numLevels = 18;
    zoomFactor = 2;
    epsilon = 0.0;
    forceEndpoints = True;

  ##print('Created GPX:', gpx.to_xml())
    ts = int(time.time())
    filebase = os.environ["XDG_DATA_HOME"]+"/"+os.environ["APP_ID"].split('_')[0]
    filename = "%s/%i.gpx" % (filebase,ts)
    a = open(filename, 'w')
    a.write(gpx.to_xml())
    a.close()
    cent = gpx.tracks[0].get_center()
    gpx.simplify()
    trk = pl.read_gpx_trk(gpx.to_xml(),tzname,npoints,2,None)
    polyline=pl.print_gpx_google_polyline(trk,numLevels,zoomFactor,epsilon,forceEndpoints)
    print(cent)
    #polyline="polyline"

    add_run(gpx,name,act_type,filename,polyline)


def add_point(gpx,lat,lng,elev):
    gpx.tracks[0].segments[0].points.append(gpxpy.gpx.GPXTrackPoint(lat, lng, elevation=elev,time=datetime.datetime.now()))


def add_run(gpx, name,act_type,filename,polyline):
    filebase = os.environ["XDG_DATA_HOME"]+"/"+os.environ["APP_ID"].split('_')[0]
    conn = sqlite3.connect('%s/activities.db' % filebase)
    cursor = conn.cursor()
    cursor.execute("""CREATE TABLE if not exists activities
                  (id INTEGER PRIMARY KEY AUTOINCREMENT,name text, act_date text, distance text, 
                   speed text, act_type text,filename text,polyline text)""")
    sql = "INSERT INTO activities VALUES (?,?,?,?,?,?,?,?)"
    start_time, end_time = gpx.get_time_bounds()
    l2d='Distance: {:.3f}km'.format(gpx.length_2d() / 1000.)
    moving_time, stopped_time, moving_distance, stopped_distance, max_speed = gpx.get_moving_data()
    print(max_speed)
    #print('%sStopped distance: %sm' % stopped_distance)
    maxspeed = 'Max speed: {:.2f}km/h'.format(max_speed * 60. ** 2 / 1000. if max_speed else 0)
    duration = 'Duration: {:.2f}min'.format(gpx.get_duration() / 60)

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
        print(er)
    conn.close()

def get_runs():
    #add_run("1", "2", "3", "4")
    filebase = os.environ["XDG_DATA_HOME"]+"/"+os.environ["APP_ID"].split('_')[0]
    conn = sqlite3.connect('%s/activities.db' % filebase)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("""CREATE TABLE if not exists activities
                  (id INTEGER PRIMARY KEY AUTOINCREMENT,name text, act_date text, distance text, 
                   speed text, act_type text,filename text,polyline text)""")
    ret_data=[]
    sql = "SELECT * FROM activities LIMIT 30"
    for i in cursor.execute(sql):
        ret_data.append(dict(i))

    conn.close()
    return ret_data