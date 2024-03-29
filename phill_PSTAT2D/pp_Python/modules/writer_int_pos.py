####################################################################
# Writes the coordinates (x,y) of a set of interpolating grid points
#   Input: `../inputs_phill_pp.in`
#   Output: `../../pp_Nek/DATA/int_pos`
####################################################################
#
import sys
import struct
import numpy as np
sys.path.append('./')
from interface import read_pp_inputs

class point:
    """class defining point variables"""
    def __init__(self,ldim):
        self.pos = np.zeros((ldim))

class pset:
    """class containing data of the point collection"""
    def __init__(self,ldim,npoints):
        self.ldim = ldim
        self.npoints = npoints
        self.pset = [point(ldim) for il in range(npoints)]

def set_pnt_pos(data,il,lpos):
    """set position of the single point"""
    lptn = data.pset[il]
    data_pos = getattr(lptn,'pos')
    for jl in range(data.ldim):
            data_pos[jl] =  lpos[jl]

def write_int_pos(fpath,fname,wdsize,emode,data):
    """ write point positions to the file"""
    # open file
    outfile = open(fpath+fname, 'wb')

    # word size
    if (wdsize == 4):
        realtype = 'f'
    elif (wdsize == 8):
        realtype = 'd'

    # header
    header = '#iv1 %1i %1i %10i ' %(wdsize,data.ldim,data.npoints)
    header = header.ljust(32)
    outfile.write(header.encode('utf-8'))

    # write tag (to specify endianness)
    #etagb = struct.pack(emode+'f', 6.54321)
    #outfile.write(etagb)
    outfile.write(struct.pack(emode+'f', 6.54321))

    #write point positions
    for il in range(data.npoints):
        lptn = data.pset[il]
        data_pos = getattr(lptn,'pos')
        outfile.write(struct.pack(emode+data.ldim*realtype, *data_pos))

# part defining periodic hill geometry
# copied from Nicolas's matlab script
def phill(x,w,h):
    def phill_(xs,h):
        if (xs <= 0.0):
           ph = h
        elif (xs <= 9.0/54.0):
             ph = h*min(1.0,1.0+0.705575248*xs**2-11.947737203*xs**3)
        elif(xs <= 14.0/54.0):
             ph = h*(0.895484248+1.881283544*xs-10.582126017*xs**2+10.627665327*xs**3)
        elif(xs <= 20.0/54.0):
             ph = h*(0.92128609+1.582719366*xs-9.430521329*xs**2+9.147030728*xs**3)
        elif(xs <= 30.0/54.0):
            ph = h*(1.445155365-2.660621763*xs+2.026499719*xs**2-1.164288215*xs**3)
        elif(xs <= 40.0/54.0):
            ph = h*(0.640164762+1.6863274926*xs-5.798008941*xs**2+3.530416981*xs**3)
        elif(xs <= 1.0):
            ph = h*(2.013932568-3.877432121*xs+1.713066537*xs**2+0.150433015*xs**3)
        else:
            ph = 0.0
        return ph    
    
    xs = x/w
    if np.isscalar(x):
       ph=phill_(xs,h)
    else:  #if x is a numpy array
       ph=np.zeros_like(xs)
       n_=xs.shape[-1]
       for i in range(n_):
           ph[i]=phill_(xs[i],h)

    return ph
#
#    
if __name__ == "__main__":
    # initialise variables
    fpath = '../../pp_Nek/DATA/'
    fname = 'int_pos'
    wdsize = 8
    # little endian
    emode = '<'
    # big endian
    #emode = '<'

    # post-processing parameters
    params=read_pp_inputs('../inputs_phill_pp.in')
    h = params['h']
    w = params['w']
    l = params['l']
    hMax = params['hMax']
    leps = 0.001
    betay = 1.0

    # vertical lines
    # number of points in a line
    npvrt = params['npvrt']
    # horisontal line positions
    xpvrt = params['xpvrt']
    # line number
    nlvrt = xpvrt.size

    # set of points along bottom wall
    npwall = params['npwall']

    # allocate space
    ldim = 2
    npoints = npvrt*nlvrt + npwall
    data = pset(ldim,npoints)
    print('Allocated {0} points'.format(npoints))

    # initialise point positions
    lpos = np.zeros(data.ldim)

    # start counting points
    npoints = 0
    # vertical lines
    # scaled point distribution
    ptdst = np.linspace(0.0,1.0,npvrt)
    ptdst = 0.5*(np.tanh(betay*(2.0*ptdst-1.0))/np.tanh(betay)+1.0)
    # max vertical line position
    ymax = hMax - leps
    for il in range(nlvrt):
        # min vertical line position
        ymin = phill(xpvrt[il],w,h) + phill(l-xpvrt[il],w,h) + leps
        # x coordinate
        lpos[0] = xpvrt[il]
        for jl in range(npvrt):
            lpos[1] = ymin + (ymax-ymin)*ptdst[jl]
            set_pnt_pos(data,npoints,lpos)
            npoints = npoints +1

    # set of points along bottom wall
    ptdst = np.linspace(2.0,7.0,npwall)
    lpos[1] = leps
    for il in range(npwall):
        lpos[0] = ptdst[il]
        set_pnt_pos(data,npoints,lpos)
        npoints = npoints +1

    # write points to the file
    write_int_pos(fpath,fname,wdsize,emode,data)
