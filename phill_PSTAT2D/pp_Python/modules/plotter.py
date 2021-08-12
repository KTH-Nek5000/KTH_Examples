###################################################################################
# A set of plotters for post-processing the 2D statsitics of the periodic hill case
###################################################################################
# Saleh Rezaeiravesh, salehr@kth.se
#----------------------------------------------------------------------------------

import sys
import numpy as np
import matplotlib.pyplot as plt
sys.path.append("./")
from interface import read_pp_inputs
from writer_int_pos import phill

def phill_walls():
    """
    Coordinates of a set of points on the top and bottom walls of the phill
    (for plotting the walls)
    """
    #Read post-processing input parameters
    params=read_pp_inputs('./inputs_phill_pp.in')
    h = params['h']
    w = params['w']
    l = params['l']
    hMax = params['hMax']
    xWall=np.linspace(0,l,500)
    yBotWall=phill(xWall,w,h)+phill(l-xWall,w,h)
    yTopWall=np.ones_like(xWall)*hMax
    return xWall,yBotWall,yTopWall

def profiles_xpvrt(dbProfs,qoiName,zoomFactor=1.):
    """
    Plot the profiles of different time-averaged quantities at 'xpvrt' streamwise locations.
    Each profile covers the distance between the two walls.

    Args:
       `dbProfs`: dictionary of the post-processed statistics
       `qoiName`: key of the quantity whose profile is plotted
       `zoomFactor`: float, factor by which the profiles are magnified for better visibility
    """
    #check if the qoiName is valid
    if qoiName not in dbProfs.keys():
       print('Available Quantities:',dbProfs.keys())
       raise KeyError("%s is not a valid quantity!" %qoiName) 

    nx=dbProfs['x'].shape[0]  #number of streamwise locations at which profiles are extracted
    
    #plot
    plt.figure(figsize=(12,5))
    for i in range(nx):
        plt.plot(dbProfs['x'][i,:]+zoomFactor*dbProfs[qoiName][i,:],dbProfs['y'][i,:])
        plt.plot(dbProfs['x'][i,:],dbProfs['y'][i,:],'--k',alpha=0.2)

    xWall,yBotWall,yTopWall=phill_walls()
    plt.plot(xWall,yBotWall,'-k',lw=3)
    plt.plot(xWall,yTopWall,'-k',lw=3)
    plt.xlabel(r'$x/h$',fontsize=17)
    plt.ylabel(r'$y/h$',fontsize=17)
    if zoomFactor==1:
       plt.title('Profiles of %s' %qoiName,fontsize=15)
    else:   
       plt.title('Profiles of %s multiplied by %g' %(qoiName,zoomFactor),fontsize=15)

    #Read post-processing input parameters
    params=read_pp_inputs('./inputs_phill_pp.in')
    xticks_=np.arange(0,int(params['l'])+1)
#    xticks_=params['xpvrt']
#    plt.xticks(ticks=xticks_,fontsize=16)
    plt.xticks(fontsize=16)
    plt.yticks(fontsize=16)
    plt.show()


