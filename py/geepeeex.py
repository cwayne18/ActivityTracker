#!/usr/bin/python3

import gpxpy
import datetime
import time
import os
import gpxpy.gpx
import sqlite3
import pl
import re

DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'
filebase = os.environ["XDG_DATA_HOME"]+"/"+os.environ["APP_ID"].split('_')[0]


def create_gpx():
    
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

def visu_gpx(file):
    temp = []
    GPXFILE = file
    gpx_file = open(GPXFILE, 'r')
    gpx = gpxpy.parse(gpx_file)
# Load the GPS coordinates
    for track in gpx.tracks:
        for segment in track.segments:
            for point in segment.points:
                #print '{{ latitude: {0}, longitude: {1}}},'.format(point.latitude, point.longitude)
                element = {
                'latitude': point.latitude,
                'longitude': point.longitude,
                }
                temp.append(element)
    zip(temp)
    return temp
# Ajouter le transfert dans une liste comme umark


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
    filename = "%s/%i.gpx" % (filebase,ts)
    a = open(filename, 'w')
    a.write(gpx.to_xml())
    a.close()
    gpx.simplify()
    #gpx.reduce_points(1000)
    trk = pl.read_gpx_trk(gpx.to_xml(),tzname,npoints,2,None)
    try:
    	polyline=pl.print_gpx_google_polyline(trk,numLevels,zoomFactor,epsilon,forceEndpoints)
    except UnboundLocalError as er:
    	print(er)
    	print("Not enough points to create a polyline")
    	polyline=""
    #polyline="polyline"

    add_run(gpx,name,act_type,filename,polyline)


def add_point(gpx,lat,lng,elev):
    gpx.tracks[0].segments[0].points.append(gpxpy.gpx.GPXTrackPoint(lat, lng, elevation=elev,time=datetime.datetime.utcnow()))


def add_run(gpx, name,act_type,filename,polyline):
    conn = sqlite3.connect('%s/activities.db' % filebase)
    cursor = conn.cursor()
    cursor.execute("""CREATE TABLE if not exists activities
                  (id INTEGER PRIMARY KEY AUTOINCREMENT,name text, act_date text, distance text, 
                   speed text, act_type text,filename text,polyline text)""")
    sql = "INSERT INTO activities VALUES (?,?,?,?,?,?,?,?)"
    start_time, end_time = gpx.get_time_bounds()
    l2d='{:.3f}'.format(gpx.length_2d() / 1000.)
    moving_time, stopped_time, moving_distance, stopped_distance, max_speed = gpx.get_moving_data()
    print(max_speed)
    #print('%sStopped distance: %sm' % stopped_distance)
    maxspeed = 'Max speed: {:.2f}km/h'.format(max_speed * 60. ** 2 / 1000. if max_speed else 0)
    duration = '{:.2f}'.format(gpx.get_duration() / 60)

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
    os.makedirs(filebase, exist_ok=True)
    conn = sqlite3.connect('%s/activities.db' % filebase)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("""CREATE TABLE if not exists activities
                  (id INTEGER PRIMARY KEY AUTOINCREMENT,name text, act_date text, distance text, 
                   speed text, act_type text,filename text,polyline text)""")
    ret_data=[]
    sql = "SELECT * FROM activities ORDER BY id DESC"
    for i in cursor.execute(sql):
        ret_data.append(dict(i))

    conn.close()
    return ret_data

def get_units():
    os.makedirs(filebase, exist_ok=True)
    conn = sqlite3.connect('%s/activities.db' % filebase)
    cursor = conn.cursor()
    cursor.execute("""CREATE TABLE if not exists settings
                  (units text)""")
    ret_data=[]
    sql = "SELECT units FROM settings"
    cursor.execute(sql)
    data=cursor.fetchone()
    if data is None:
    	print("NONESIES")
    	cursor.execute("INSERT INTO settings VALUES ('kilometers')")
    	conn.commit()
    	conn.close()
    	return "kilometers"
    return data

def set_units(label):
    os.makedirs(filebase, exist_ok=True)
    conn = sqlite3.connect('%s/activities.db' % filebase)
    cursor = conn.cursor()
    cursor.execute("UPDATE settings SET units=? WHERE 1", (label,))
    conn.commit()
    conn.close()

def onetime_db_fix():
    os.makedirs(filebase, exist_ok=True)
    filename = "%s/%s" % (filebase,".dbfixed")
    if not os.path.exists(filename):
        print("Fixing db")
        conn = sqlite3.connect('%s/activities.db' % filebase)
        numonly = re.compile("(\d*\.\d*)")
        cursor = conn.cursor()
        a=get_runs()
        sql="UPDATE activities SET distance=? WHERE id=?"
        for i in a:
            print(i["distance"])
            b=numonly.search(i["distance"])
            print(b.group(0))
            print(b)
            cursor.execute(sql, (b.group(0), i["id"]))
            
        conn.commit()
        conn.close()
        dotfile=open(filename, "w")
        dotfile.write("db fixed")
        dotfile.close
    else:
        print("db already fixed")

def onetime_db_fix_again_cus_im_dumb():
    os.makedirs(filebase, exist_ok=True)
    filename = "%s/%s" % (filebase,".dbfixed2")
    if not os.path.exists(filename):
        print("Fixing db again")
        conn = sqlite3.connect('%s/activities.db' % filebase)
        numonly = re.compile("(\d*\.\d*)")
        cursor = conn.cursor()
        a=get_runs()
        sql="UPDATE activities SET speed=? WHERE id=?"
        for i in a:
            print(i["speed"])
            b=numonly.search(i["speed"])
            cursor.execute(sql, (b.group(0), i["id"]))
            
        conn.commit()
        conn.close()
        dotfile=open(filename, "w")
        dotfile.write("db fixed")
        dotfile.close
    else:
        print("db already fixed")

def rm_run(run):
    conn = sqlite3.connect('%s/activities.db' % filebase)
    cursor = conn.cursor()
    sql = "DELETE from activities WHERE id=?"
    try:
        cursor.execute(sql, [run])
        conn.commit()
    except sqlite3.Error as er:
        print("-------------______---_____---___----____--____---___-----")
        print(er)
    conn.close()

def km_to_mi(km):
	return km * 0.62137

def current_distance(gpx):
    l2d='{:.3f}'.format(gpx.length_2d() / 1000.)
    print(l2d)
    return l2d

def stopwatchery(secs):
        #Format Seconds
    sec = int(secs % 60);
    if len(str(sec))<2:
        sec = "0" + str(sec)
    else:
        sec = str(sec)
    
    #Format Minutes
    mins = int(((secs / (60)) % 60));
    if len(str(mins))<2:
        mins = "0" + str(mins)
  ##  if len(str(mins))>1:
    #    mins = str(mins)
     #   aux = len(mins)
      #  mins = mins[aux-1]
    else:
        mins = str(mins)


    #Format hours
    hr = int(((secs / (60*60)) % 60));
    if hr == 0:
        hr = ""
    else:
        hr = str(hr)+":"
    print(hr + mins+":"+sec)
    return hr + mins+":"+sec

