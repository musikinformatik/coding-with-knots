#!/usr/bin/env python
# A Quipu database parser
# Copyright (C) 2015 Dave Griffiths
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

import sys
import xlrd
import os
import math

# functions for parsing the string data

def has_parent(s):
    return s.find("s") != -1

def get_parent_pendant(s):
    if has_parent(s):
        return s[0:s.rfind("s")]
    else: return ""

# a knot is complicated enough to make a class for
class knot:
    def __init__(self,value,type,position,spin):
        self.value = value
        self.type = type
        self.position = position
        self.spin = spin

    def values(self):
        return 'knot_value="'+str(self.value)+'", '+\
            'knot_type="'+str(self.type)+'", '+\
            'knot_position="'+str(self.position)+'", '+\
            'knot_spin="'+str(self.spin)+'"'

    # render the knot to ascii format!
    def render(self):
        direction = "?"
        # + 90 degrees
        if self.spin=="S": direction = "/"
        if self.spin=="Z": direction = "\\\\"

        r=""
        if self.type == "S":
            for i in range(0,self.value):
                r+=direction+"O"
        elif self.type == "L":
            r+="("
            for i in range(0,self.value):
                r+=direction+"o"
            r+=")"
        elif self.type == "E":
            r+=direction+"8"
        return r

# build a knot from it's text representation
def parse_knot(s):
    value = 1
    position = 0
    try:
        value = int(s[0:1])
        position = float(s[s.find("(")+1:s.find("/")])
    except Exception:
        #print("error parsing knot: "+s)
        pass
    return knot(value,
                s[1:s.find("(")],
                position,
                s[s.find("/")+1:s.find(")")])

# render a list of knots
def parse_knots(s):
    if s == "": return []
    return map(parse_knot,s.split(" "))

# multicolour codes
# B-G twisted together (barber pole)
# B:G interspersed (mottled)
# B/G colour change with distance

# partially from here: http://tx4.us/nbs-iscc.htm
colour_lookup = {
    "W": "#777777",
    "SR":  "#BF2233",
    "MB" : "#673923",
    "GG" : "#575E4E",
    "KB" : "#35170C",
    "AB" : "#A86540",
    "HB" : "#5A3D30",
    "RL" : "#AA6651",
    "BG" : "#4A545C",
    "PG" : "#8D917A",
    "B" : "#7D512D",
    "0B" : "#64400F",
    "RM" : "#AB343A",
    "PR" : "#490005",
    "FR" : "#7F180D",
    "DB" : "#4D220E",
    "YB" : "#BB8B54",
    "MG" : "#817066",
    "GA" : "#503D33",
    "LB" : "#593315",
    "RB" : "#712F26",
    "YG" : "#313830",
    'G'  : "#48442D",
    'LG' : "#BAAF96",
    'G0' : "#52442C",
    '0G' : "#8B734B",
    'R'  : "#9B2F1F",
    'BY' : "#B48764",
    'NB' : "#95500C",
    'BL' : "#C1CACA",
    'LK' : "#131313",
    'CB' : "#32221A",
    'BB' : "#3F2512",
    'PB' : "#002F55",
    'VR' : "#4F0014",
    'FB' : "#140F0B",
    'LC' : "#2C3337",
    'VB' : "#022027"
}

unknown_colours = {}

def parse_one_colour(s):
    if "(" in s: s = s[0:s.find("(")]
    s = s.strip(" ")

    if s in colour_lookup:
        return '"'+colour_lookup[s]+'"'
    else:
        if s!="":
            if s in unknown_colours:
                unknown_colours[s]+=1
            else:
                print("don't know this colour: ["+s+"]")
                unknown_colours[s]=1
        return '"#000000"'

# we don't differenciate between colour effects yet :(
def parse_colour(s):
    #print s
    if ":" in s: return map(parse_one_colour,s.split(":"))
    elif "-" in s: return map(parse_one_colour,s.split("-"))
    elif "/" in s: return map(parse_one_colour,s.split("/"))
    elif "%" in s: return map(parse_one_colour,s.split("%"))
    else: return [parse_one_colour(s)]

# unit tests for the parsing functions
def unit_test():
    assert(has_parent("X1")==False)
    assert(has_parent("X1s1")==True)
    assert(get_parent_pendant("X1s1")=="X1")
    assert(get_parent_pendant("X1s6s1")=="X1s6")
    assert(len(parse_knots("1S(5.0/Z) 2S(14.0/Z) 1E(25.0/Z)"))==3)
    ks = parse_knots("1S(5.0/Z) 2S(14.0/Z) 1E(25.0/Z)")
    assert(ks[0].type=="S")
    assert(ks[0].position==5.0)
    assert(ks[0].spin=="Z")
    assert(len(parse_knots(""))==0)
    assert(parse_colour("foo")==['"#000000"'])
    assert(parse_colour("MB")==['"#673923"'])
    assert(parse_colour("MB:MG")==['"#673923"','"#817066"'])

# run em...
unit_test()

# have a look at the data a bit, return some stats
def process_quipu(quipu):
    count = 0
    highest = 0
    # skip the gumpf at the top, start on the 6th line
    for curr_row in range(6,quipu.nrows):
        knots = parse_knots(quipu.cell_value(curr_row, 3))
        value = str(quipu.cell_value(curr_row, 8))
        if len(knots)>highest:
            highest=len(knots)

    return highest

# convert a database spreadsheet into a dot file for visualisation
def parse_to_dot(quipu):
    out = "graph {\n graph [rankdir=LR]\n"
    # skip the gumpf at the top, start on the 6th line
    for curr_row in range(6,quipu.nrows):
        # get the stuff from the row
        pid = quipu.cell_value(curr_row, 0)
        if quipu.cell_type(curr_row, 0)==2: # convert a number to text
            pid = str(int(pid))
        ply = quipu.cell_value(curr_row, 1)
        attach = quipu.cell_value(curr_row, 2)
        knots = parse_knots(quipu.cell_value(curr_row, 3))
        length = quipu.cell_value(curr_row, 4)
        if quipu.cell_type(curr_row, 4)==2: # convert a number to text
            length = str(length)
        colours = parse_colour(quipu.cell_value(curr_row, 7))
        value = quipu.cell_value(curr_row, 8)


        # generate graphviz colour list
        clist = ""
        for i,c in enumerate(colours):
            if i==0:
                clist+=c[1:-1]
            else:
                clist+=":"+c[1:-1]

        pendant_values = 'pendant_colors="'+clist+'", '+\
                         'pendant_ply="'+ply+'", '+\
                         'pendant_attach="'+attach+'", '+\
                         'pendant_length="'+length+'"'

        fontcolour = "#000000"
        if getLum(colours[0]) <= 100: fontcolour = "#ffffff"

        penwidth="5"
        if len(colours)>1: penwidth="2"

        # no parent, attach to the primary node
        parent = 'primary'
        if has_parent(pid):  parent=get_parent_pendant(pid)

        # describe the node details
        out+='"'+pid+'" [qtype="pendant_node", '+pendant_values+', label="'+ply+" "+attach+'", style=filled, fillcolor="'+clist+'", fontcolor="'+fontcolour+'"]\n'
        # connection to parent
        out += '"'+parent+'" -- "'+pid+'" [qtype="pendant_link",penwidth='+penwidth+',color="'+clist+'"]\n'

        # stick the knots on the end of the pendant node
        p = pid
        pos = 0
        for i,knot in enumerate(knots):
            kid = pid+':'+str(i)
            pos+=knot.position
            out+='"'+kid+'" [qtype="knot_node", '+knot.values()+', label="'+knot.render()+'", style=filled, fillcolor="'+clist+'" , fontcolor="'+fontcolour+'"]\n'
            out+='"'+p+'" -- "'+kid+'" [qtype="knot_link",penwidth='+penwidth+',color="'+clist+'"]\n'
            p = kid

    out+="}\n"
    return out

def getLum(hex_color):
    rgb_int = int("0x" + str(hex_color)[2:-1], 0)
    blue = rgb_int & 255
    green = (rgb_int >> 8) & 255
    red = (rgb_int >> 16) & 255
    lum = math.sqrt((0.299 * (red ** 2)) + (0.587 * (green ** 2)) + ( 0.144 * (blue ** 2)))
    return int(lum)

# get some stats
def process(filename):
    # open the spreadsheet
    try:
        workbook = xlrd.open_workbook(filename)
        quipu = workbook.sheet_by_name('Pendant Detail')
    except Exception:
        return
    print (filename+" "+str(process_quipu(quipu)))

# create the dotfile
def run(filename):
    print filename
    # open the spreadsheet
    try:
        workbook = xlrd.open_workbook(filename)
        quipu = workbook.sheet_by_name('Pendant Detail')
    except Exception:
        print "problem"
        return False

    with open(filename+'.dot', 'w') as f:
        f.write(parse_to_dot(quipu))
    return True

high = 0

def check_all():
    for i in range(0,200):
        num = ("%03d"%i)
        filename = "data/xls/UR"+num+".xls"
        check(filename)
    for i in range(0,200):
        num = ("%03d"%i)
        filename = "data/xls/UR1"+num+".xls"
        check(filename)
    for i in range(0,200):
        num = ("%03d"%i)
        filename = "data/xls/HP"+num+".xls"
        check(filename)

def run_all():
    for i in range(0,200):
        num = ("%03d"%i)
        filename = "data/xls/UR"+num+".xls"
        if run(filename):
            os.system("dot "+filename+".dot -Tpng > "+filename+".png")
    for i in range(0,200):
        num = ("%03d"%i)
        filename = "data/xls/UR1"+num+".xls"
        if run(filename):
            os.system("dot "+filename+".dot -Tpng > "+filename+".png")
    for i in range(0,200):
        num = ("%03d"%i)
        filename = "data/xls/HP"+num+".xls"
        if run(filename):
            os.system("dot "+filename+".dot -Tpng > "+filename+".png")

run_all()


#run(sys.argv[1])
#run("data/xls/UR006.xls")

print(unknown_colours)


#uk = {u'BD': 17, u'BB': 342, u'BL': 203, u'DG': 9, u'DB -W': 1, u'ABB': 1, u'YG': 369, u'FB': 47, u'MB-W': 2, u'AB-W': 1, u'GG%AB': 3, u'BY': 131, u'WGSRMG': 3, u'LG': 105, u'W-MB': 3, u'BLRL': 1, u'LB': 848, u'LC': 63, u'MB-MB': 4, u'LA': 15, u'BS': 24, u'NB': 163, u'GLSRYBMG': 1, u'ABMB': 1, u'LK': 206, u'GLSRYBWMG': 1, u'PB': 28, u'MB-CB': 3, u'RG': 24, u'RB': 484, u'PK': 50, 'foo': 1, u'GGAB': 1, u'WGG': 1, u'R0': 8, u'GR': 5, u'G': 96, u'VG': 15, u'CB': 340, u'-': 1, u'LD': 3, u'GY': 23, u'EB': 24, u'VR': 32, u'R': 126, u'0G': 112, u'0D': 7, u'ABW': 1, u'WMB': 1, u'GL': 22, u'0L': 13, u'LG-AB': 1, u'SY': 18, u'MBW': 8, u'KG': 16, u'LBW': 1, u'G0': 107, u'W-W': 30, u'KB-GG': 1, u'VB': 64, u'TG': 10, u'DB W': 1, u'LK-W': 36, u'SB': 6, u'D0': 2, u'GB': 8}
#import operator
#sorted_uk = sorted(uk.items(), key=operator.itemgetter(1))
#print (sorted_uk)
