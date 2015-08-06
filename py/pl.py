#!/usr/bin/env python
# vim: set fileencoding=utf8 ts=4 sw=4 noexpandtab:
#
# (c) Sergey Astanin <s.astanin@gmail.com> 2008
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

"""usage: gpxplot.py [action] [options] track.gpx

Analyze GPS track and plot elevation and velocity profiles.

Features:
	* using haversine formula to calculate distances (spherical Earth)
	* support of multi-segment (discontinuous) tracks
	* gnuplot support:
		- generate plots if gnuplot.py is available
		- generate gnuplot script if gnuplot.py is not available
		- plot interactively and plot-to-file modes
	* Google Chart API support:
        - print URL or the plot
	* tabular track profile data can be generated
	* metric and English units
	* timezone support

Actions:
-g            plot using gnuplot.py
--gprint      print gnuplot script to standard output
--google      print Google Chart URL
--table       print data table (default)
--polyline    print Google maps polyline data
--output-file file to store the resultant GPX data in

Options:
-h, --help    print this message
-E            use English units (metric units used by default)
-x var        plot var = { time | distance } against x-axis
-y var        plot var = { elevation | velocity } against y-axis
-o imagefile  save plot to image file (supported: PNG, JPG, EPS, SVG)
-t tzname     use local timezone tzname (e.g. 'Europe/Moscow')
-n N_points   reduce number of points in the plot to approximately N_points
-f window     apply window filter to the data.
-s filename   store the final GPX data in the specified file.
-e epsilon    'very small' value used for line smoothing
-z zoomf      zoom factor - the change in magnification between different levels of magnification
-L levels     indicate how many different levels of magnification the polyline has
"""

import sys
import datetime
import getopt
import string
import copy
from math import sqrt,sin,cos,asin,pi,ceil,pow

from os.path import basename
from re import sub

import logging
#logging.basicConfig(level=logging.DEBUG,format='%(levelname)s: %(message)s')
debug=logging.debug

try:
	import pytz
except:
	pass

GPX10='{http://www.topografix.com/GPX/1/0}'
GPX11='{http://www.topografix.com/GPX/1/1}'
URI='{http://www.w3.org/2001/XMLSchema-instance}'
dateformat='%Y-%m-%dT%H:%M:%SZ'

R=6371.0008 # Earth volumetric radius
milesperkm=0.621371192
feetperm=3.2808399

strptime=datetime.datetime.strptime

var_lat = 0
var_lon = 1
var_time= 2
var_alt = 3
var_dist= 4
var_vel = 5

var_names={ 't': var_time,
			'time': var_time,
			'd': var_dist,
			'dist': var_dist,
			'distance': var_dist,
			'ele': var_alt,
			'elevation': var_alt,
			'a': var_alt,
			'alt': var_alt,
			'altitude': var_alt,
			'v': var_vel,
			'vel': var_vel,
			'velocity': var_vel,
			'lat': var_lat,
			'latitude': var_lat,
			'lon': var_lon,
			'longitude': var_lon,
			}

EXIT_EOPTION=1
EXIT_EDEPENDENCY=2
EXIT_EFORMAT=3

def haversin(theta):
	return sin(0.5*theta)**2

def distance(p1,p2):
	lat1,lon1=[a*pi/180.0 for a in p1]
	lat2,lon2=[a*pi/180.0 for a in p2]
	deltalat=lat2-lat1
	deltalon=lon2-lon1
	h=haversin(deltalat)+cos(lat1)*cos(lat2)*haversin(deltalon)
	dist=2*R*asin(sqrt(h))
	return dist

def read_all_segments(trksegs,tzname=None,ns=GPX10,pttag='trkpt'):
	trk=[]
	for seg in trksegs:
		s=[]
		prev_ele,prev_time=0.0,None
		trkpts=seg.findall(ns+pttag)
		for pt in trkpts:
			lat=float(pt.attrib['lat'])
			lon=float(pt.attrib['lon'])
			time=pt.findtext(ns+'time')
			def prettify_time(time):
				time=sub(r'\.\d+Z$','Z',time)
				time=strptime(time,dateformat)
				if tzname:
					time=time.replace(tzinfo=pytz.utc)
					time=time.astimezone(pytz.timezone(tzname))
				return time
			if time:
				prev_time=time
				time=prettify_time(time)
			elif prev_time: # timestamp is missing, use the prev point
				time=prev_time
				time=prettify_time(time)
			ele=pt.findtext(ns+'ele')
			if ele:
				ele=float(ele)
				prev_ele=ele
			else:
				ele=prev_ele # elevation data is missing, use the prev point
			s.append([lat, lon, time, ele])
		trk.append(s)
	return trk

"""
 Calculate the average point for the array
"""
def calc_avg_point(seg):
	p_avg = copy.deepcopy(seg[0])
	p_prev = seg[0]
	time_delta = p_prev[var_time]-p_prev[var_time]
	for p in seg[1:]:
		p_avg[var_alt] += p[var_alt]
		p_avg[var_lat] += p[var_lat]
		p_avg[var_lon] += p[var_lon]
		time_delta = time_delta + (p[var_time]-p_prev[var_time])  # datetile supports only addition with a delta
		p_prev = p

	p_avg[var_alt] /= len(seg)
	p_avg[var_lat] /= len(seg)
	p_avg[var_lon] /= len(seg)
	time_delta = time_delta // len(seg)
	p_avg[var_time] = p_avg[var_time] + time_delta
	return p_avg

"""
 Run the average filter on the tracks
"""
def filter_points(trk,filter_window=None):
	if (filter_window <= 1):
		return trk;

	newtrk=trk
	half_window=int(filter_window/2)
	for s in range(len(newtrk)):
		oldseg = newtrk[s]
		newseg = oldseg[half_window:-half_window]
		if (len(oldseg) >= filter_window):
			for p in range(len(newseg)):
				p_avg = calc_avg_point(oldseg[p:p+filter_window-1]);
				newseg[p] = p_avg;

			newtrk[s] = newseg

	return newtrk

"""
 Reduce the number of points on the tracks
"""
def reduce_points(trk,npoints=None):
	count=sum([len(s) for s in trk])
	if npoints:
		ptperpt=1.0*count/npoints
	else:
		return trk

	skip=int(ceil(ptperpt))
	debug('ptperpt=%f skip=%d'%(ptperpt,skip))
	newtrk=[]
	for seg in trk:
		if len(seg) > 0:
			newseg=seg[:-1:skip]+[seg[-1]]
			newtrk.append(newseg)
	debug('original: %d pts, filtered: %d pts'%\
			(count,sum([len(s) for s in newtrk])))
	return newtrk

def eval_dist_velocity(trk):
	dist=0.0
	newtrk=[]
	for seg in trk:
		if len(seg)>0:
			newseg=[]
			prev_lat,prev_lon,prev_time,prev_ele=None,None,None,None
			for pt in seg:
				lat,lon,time,ele=pt
				if prev_lat and prev_lon:
					delta=distance([lat,lon],[prev_lat,prev_lon])
					if time and prev_time:
						try:
							vel=3600*delta/((time-prev_time).seconds)
						except ZeroDivisionError:
							vel=0.0 # probably the point lacked the timestamp
					else:
						vel=0.0
				else: # new segment
					delta=0.0
					vel=0.0
				dist=dist+delta
				newseg.append([lat,lon,time,ele,dist,vel])
				prev_lat,prev_lon,prev_time=lat,lon,time
			newtrk.append(newseg)
	return newtrk

def load_xml_library():
	try:
		import xml.etree.ElementTree as ET
	except:
		try:
			import elementtree.ElementTree as ET
		except:
			try:
				import cElementTree as ET
			except:
				try:
					import lxml.etree as ET
				except:
					print ('this script needs ElementTree (Python>=2.5)')
					sys.exit(EXIT_EDEPENDENCY)

	return ET;

def parse_gpx_data(gpxdata,tzname=None,npoints=None,filter_window=None,output_file_name=None):
	ET = load_xml_library();

	def find_trksegs_or_route(etree, ns):
		trksegs=etree.findall('.//'+ns+'trkseg')
		if trksegs:
			return trksegs, "trkpt"
		else: # try to display route if track is missing
			rte=etree.findall('.//'+ns+'rte')
			return rte, "rtept"

	# try GPX10 namespace first
	try:
		ET.register_namespace('', GPX11.strip('{}'))
		ET.register_namespace('', GPX10.strip('{}'))
		etree = ET.XML(gpxdata)
	except ET.ParseError as v:
		row, column = v.position
		print ("error on row %d, column %d:%d" % row, column, v)

	trksegs,pttag=find_trksegs_or_route(etree, GPX10)
	NS=GPX10
	if not trksegs: # try GPX11 namespace otherwise
		trksegs,pttag=find_trksegs_or_route(etree, GPX11)
		NS=GPX11
	if not trksegs: # try without any namespace
		trksegs,pttag=find_trksegs_or_route(etree, "")
		NS=""

	trk=read_all_segments(trksegs,tzname=tzname,ns=NS,pttag=pttag)
	trk=filter_points(trk,filter_window)
	trk=reduce_points(trk,npoints=npoints)
	trk=eval_dist_velocity(trk)

	# Store the results if requested
	if output_file_name:
		store_gpx_trk(etree,trk,NS,pttag,output_file_name)

	return trk

"""
 Read the data from the specified GPX file
"""
def read_gpx_trk(input_file_name,tzname,npoints,filter_window,output_file_name):
	if input_file_name == "-":
		gpx=sys.stdin.read()
		debug("length(gpx) from stdin = %d" % len(gpx))
	else:
		#gpx=open(input_file_name).read()
		#print(gpx)
		gpx=input_file_name
		debug("length(gpx) from file = %d" % len(gpx))
	return parse_gpx_data(gpx,tzname,npoints,filter_window,output_file_name)

"""
 Store the updated track in the specified file
"""
def store_gpx_trk(etree,trk,ns=GPX10,pttag='trkpt',output_file_name="-"):
	ET = load_xml_library();
	if output_file_name == "-":
		gpx=sys.stdout;
	else:
		gpx=open(output_file_name, 'w');

	print("\n== This feature isn't working yet ==\n")
	for node in etree.iterfind('.//'+ns+'trkseg'):
		print (node.tag, node.attrib, node.text)
	print("\n===========================\n")

	ET.ElementTree(etree).write("D:/temp/output.gpx")
#	ET.ElementTree(element).write(output_file_name, xml_declaration=True)

	gpx.write(ET.tostring(trk));
	return gpx.close();

def google_ext_encode(i):
	"""
	Google Charts' extended encoding,
	see http://code.google.com/apis/chart/mappings.html#extended_values
	"""
	enc='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	enc=enc+enc.lower()+'0123456789-.'
	i=int(i)%4096 # modulo 4096
	figure=enc[int(i/len(enc))]+enc[int(i%len(enc))]
	return figure

def google_text_encode_data(trk,x,y,min_x,max_x,min_y,max_y,metric=True):
	if metric:
		mlpkm,fpm=1.0,1.0
	else:
		mlpkm,fpm=milesperkm,feetperm
	xenc=lambda x: "%.1f"%x
	yenc=lambda y: "%.1f"%y
	data='&chd=t:'+join([ join([xenc(p[x]*mlpkm) for p in seg],',')+\
				'|'+join([yenc(p[y]*fpm) for p in seg],',') \
			for seg in trk if len(seg) > 0],'|')
	data=data+'&chds='+join([join([xenc(min_x),xenc(max_x),yenc(min_y),yenc(max_y)],',') \
			for seg in trk if len(seg) > 0],',')
	return data

def google_ext_encode_data(trk,x,y,min_x,max_x,min_y,max_y,metric=True):
	if metric:
		mlpkm,fpm=1.0,1.0
	else:
		mlpkm,fpm=milesperkm,feetperm
	if max_x != min_x:
		xenc=lambda x: google_ext_encode((x-min_x)*4095/(max_x-min_x))
	else:
		xenc=lambda x: google_ext_encode(0)
	if max_y != min_y:
		yenc=lambda y: google_ext_encode((y-min_y)*4095/(max_y-min_y))
	else:
		yenc=lambda y: google_ext_encode(0)

	data='&chd=e:'+join([ join([xenc(p[x]*mlpkm) for p in seg],'')+\
				','+join([yenc(p[y]*fpm) for p in seg],'') \
			for seg in trk if len(seg) > 0],',')
	return data

def google_chart_url(trk,x,y,metric=True):
	if x != var_dist or y != var_alt:
		print ('only distance-elevation profiles are supported in --google mode')
		return
	if not trk:
		raise ValueError("Parsed track is empty")
	if metric:
		ele_units,dist_units='m','km'
		mlpkm,fpm=1.0,1.0
	else:
		ele_units,dist_units='ft','miles'
		mlpkm,fpm=milesperkm,feetperm

	urlprefix='http://chart.apis.google.com/chart?chtt=gpxplot.appspot.com&chts=cccccc,9&'
	url='chs=600x400&chco=9090FF&cht=lxy&chxt=x,y,x,y&chxp=2,100|3,100&'\
			'chxl=2:|distance, %s|3:|elevation, %s|'%(dist_units,ele_units)
	min_x=0
	max_x=mlpkm*(max([max([p[x] for p in seg]) for seg in trk if len(seg) > 0]))
	max_y=fpm*(max([max([p[y] for p in seg]) for seg in trk if len(seg) > 0]))
	min_y=fpm*(min([min([p[y] for p in seg]) for seg in trk if len(seg) > 0]))
	range='&chxr=0,0,%s|1,%s,%s'%(int(max_x),int(min_y),int(max_y))
	data=google_ext_encode_data(trk,x,y,min_x,max_x,min_y,max_y,metric)
	url=urlprefix+url+range+data
	if len(url) > 2048:
		raise OverflowError("URL too long, reduce number of points: "+(url))
	return url

def print_gpx_trk(trk,file=sys.stdout,metric=True):
	f=file
	if metric:
		f.write('# time(ISO) elevation(m) distance(km) velocity(km/h)\n')
		km,m=1.0,1.0
	else:
		f.write('# time(ISO) elevation(ft) distance(miles) velocity(miles/h)\n')
		km,m=milesperkm,feetperm
	if not trk:
		return
	for seg in trk:
		if len(seg) == 0:
			continue
		for p in seg:
			f.write('%s %f %f %f\n'%\
				((p[var_time].isoformat(),\
				m*p[var_alt],km*p[var_dist],km*p[var_vel])))
		f.write('\n')

def gen_gnuplot_script(trk,x,y,file=sys.stdout,metric=True,savefig=None):
	if metric:
		ele_units,dist_units='m','km'
	else:
		ele_units,dist_units='ft','miles'
	file.write("unset key\n")
	if x == var_time:
		file.write("""set xdata time
		set timefmt '%Y-%m-%dT%H:%M:%S'
		set xlabel 'time'\n""")
	else:
		file.write("set xlabel 'distance, %s'\n"%dist_units)
	if y == var_alt:
		file.write("set ylabel 'elevation, %s'\n"%ele_units)
	else:
		file.write("set ylabel 'velocity, %s/h\n"%dist_units)
	if savefig:
		import re
		ext=re.sub(r'.*\.','',savefig.lower())
		if ext == 'png':
			file.write("set terminal png; set output '%s';\n"%(savefig))
		elif ext in ['jpg','jpeg']:
			file.write("set terminal jpeg; set output '%s';\n"%(savefig))
		elif ext == 'eps':
			file.write("set terminal post eps; set output '%s';\n"%(savefig))
		elif ext == 'svg':
			file.write("set terminal svg; set output '%s';\n"%(savefig))
		else:
			print ('unsupported file type: %s'%ext)
			sys.exit(EXIT_EFORMAT)
	file.write("plot '-' u %d:%d w l\n"%(x-1,y-1,))
	print_gpx_trk(trk,file=file,metric=metric)
	file.write('e')

def get_gnuplot_script(trk,x,y,metric,savefig):
	import StringIO
	script=StringIO.StringIO()
	gen_gnuplot_script(trk,x,y,file=script,metric=metric,savefig=savefig)
	script=script.getvalue()
	return script

def plot_in_gnuplot(trk,x,y,metric=True,savefig=None):
	script=get_gnuplot_script(trk,x,y,metric,savefig)
	try:
		import Gnuplot
		if not savefig:
			g=Gnuplot.Gnuplot(persist=True)
		else:
			g=Gnuplot.Gnuplot()
		g(script)
	except: # python-gnuplot is not available or is broken
		print ('gnuplot.py is not found')

def print_gnuplot_script(trk,x,y,metric=True,savefig=None):
	script=get_gnuplot_script(trk,x,y,metric,savefig)
	print ("%s" % script)

"""
This computes the appropriate zoom level of a point in terms of it's
distance from the relevant segment in the DP algorithm.
"""
def find_zoom_level(value,zoomLevelBreaks):
	level = 0;
	for zoom in zoomLevelBreaks:
		if (value >= zoom):
			break;
		level += 1;

	return level;

"""
Convert a value into a polyline encoded level string
http://code.google.com/apis/maps/documentation/utilities/polylinealgorithm.html
"""
def polyline_encode_level(value):
	level_str = [];
	nextValue = 0;
	while (value >= 0x20):
		nextValue = (0x20 | (value & 0x1f)) + 63;
		level_str.append(nextValue);
		value >>= 5;

	finalValue = value + 63;
	level_str.append(finalValue);

	# Convert each value to its ASCII equivalentlevel_str
	level_str = [chr(l) for l in level_str]

	return level_str

"""
Convert a value into a polyline encoded point string
http://code.google.com/apis/maps/documentation/utilities/polylinealgorithm.html
"""
def polyline_encode_point(value):
	# Get the two's compliment for negatives
	if (value < 0):
		value = ~(-1*value) + 1;

	# Left-shift the binary value one bit:
	value = value << 1;

	# If the original decimal value is negative, invert this encoding
	if (value < 0):
		value = ~value;

	# Break the binary value out into 5-bit chunks (starting from the right hand side)
	# This will put the values in reverse order
	value_str = [];
	# while there are more than 5 bits left (that aren't all 0)...
	while value >= 32:  # 32 == 0xf0 == 100000
		value_str.append(value & 31)  # 31 == 0x1f == 11111
		value = value >> 5

	# OR each value with 0x20 if another bit chunk follows
	value_str = [(l | 0x20) for l in value_str]
	value_str.append(value)

	# Add 63 to each value
	value_str = [(l + 63) for l in value_str]

	# Convert each value to its ASCII equivalent
	value_str = [chr(l) for l in value_str]

	return value_str

"""
Create static encoded polyline
http://code.google.com/apis/maps/documentation/utilities/polylinealgorithm.html
"""
def print_gpx_google_polyline(trk,numLevels,zoomFactor,epsilon,forceEndpoints):
	import rdp

	zoomLevelBreaks = []
	for i in range (0,numLevels):
		zoomLevelBreaks.append(epsilon*pow(zoomFactor, numLevels-i-1));

	word_segments = 6;
	for seg in trk:
		if len(seg) == 0:
			continue;

        # Perform the RDP magic on the data
		if (epsilon > 0):
			seg = rdp.rdp(seg, epsilon);

		segment_polyline = "";
		segment_point = 0;
        # Encode the points
		for p in seg:
            # Get the first point full value,
			# then the difference between points
			if (segment_point == 0):
				lat = (int)(1e5 * p[var_lat]);
				lon = (int)(1e5 * p[var_lon]);
			else:
				lat = (int)(1e5 * (p[var_lat]) - (int)(1e5 * seg[segment_point-1][var_lat]));
				lon = (int)(1e5 * (p[var_lon]) - (int)(1e5 * seg[segment_point-1][var_lon]));
			segment_point += 1;

			segment_polyline += ''.join(polyline_encode_point(lat));
			segment_polyline += ''.join(polyline_encode_point(lon));

		print ("polyline: %s\n" % segment_polyline)

        # Encode the levels
		segment_levels = "";
		segment_point = 0;
		for p in seg:
			distance = rdp.point_line_distance(p, seg[0], seg[-1]);

			if ((forceEndpoints == 1) and (segment_point == 0 or segment_point == len(seg))):
				level = numLevels - 1;
			else:
				level = numLevels - find_zoom_level(distance, zoomLevelBreaks) - 1;

			segment_levels += ''.join(polyline_encode_level(level));
			segment_point += 1;

		print ("levels: %s\n" % segment_levels)

	print ("\n");
	return segment_polyline

def main():
	metric=True
	xvar=var_dist
	action='printtable'
	yvar=var_alt
	imagefile=None
	tzname=None
	npoints=None

	# polyline encoder default values
	numLevels = 18;
	zoomFactor = 2;
	epsilon = 0.0;
	forceEndpoints = True;

    # filter parameters
	filter_window=None
	output_file_name=None

	def print_see_usage():
		print ('see usage: ' + basename(sys.argv[0]) + ' --help')

	try: opts,args=getopt.getopt(sys.argv[1:],'hgEx:y:o:t:n:e:z:L:f:s:',
			['help','gprint','google','table','polyline','output-file='])

	except Exception as e:
		print ("Exception: %s" % e)
		print_see_usage()
		sys.exit(EXIT_EOPTION)
	for o, a in opts:
		if o in ['-h','--help']:
			print ("%s" % __doc__)
			sys.exit(0)
		if o == '-E':
			metric=False
		if o == '-g':
			action='gnuplot'
		if o == '--gprint':
			action='printgnuplot'
		if o == '--google':
			action='googlechart'
		if o == '--table':
			action='printtable'
		if o == '--polyline':
			action='polyline'
		if o == '-x':
			if var_names.has_key(a):
				xvar=var_names[a]
			else:
				print ("unknown x variable")
				print_see_usage()
				sys.exit(EXIT_EOPTION)
		if o == '-y':
			if var_names.has_key(a):
				yvar=var_names[a]
			else:
				print ("unknown y variable")
				print_see_usage()
				sys.exit(EXIT_EOPTION)
		if o == '-o':
			imagefile=a
		if o == '-t':
			if not globals().has_key('pytz'):
				print ("pytz module is required to change timezone")
				sys.exit(EXIT_EDEPENDENCY)
			tzname=a
		if o == '-n':
			npoints=int(a)
		if o == '-f':
			filter_window=int(a)
		if o in ('-s','--output-file'):
			output_file_name=a
		if o == '-e':
			epsilon=float(a)
		if o == '-z':
			zoomFactor=float(a)
		if o == '-L':
			numLevels=int(a)

	if len(args) > 1:
		print ("only one GPX file should be specified")
		print_see_usage()
		sys.exit(EXIT_EOPTION)
	elif len(args) == 0:
		print ("please provide a GPX file to process.")
		print_see_usage()
		sys.exit(EXIT_EOPTION)

	input_file_name=args[0]
	trk=read_gpx_trk(input_file_name,tzname,npoints,filter_window,output_file_name)
	if action == 'gnuplot':
		plot_in_gnuplot(trk,x=xvar,y=yvar,metric=metric,savefig=imagefile)
	elif action == 'printgnuplot':
		print_gnuplot_script(trk,x=xvar,y=yvar,metric=metric,savefig=imagefile)
	elif action == 'printtable':
		print_gpx_trk(trk,metric=metric)
	elif action == 'googlechart':
		print ("%s" % google_chart_url(trk,x=xvar,y=yvar,metric=metric))
	elif action == 'polyline':
		print_gpx_google_polyline(trk,numLevels,zoomFactor,epsilon,forceEndpoints)

if __name__ == '__main__':
	main()
