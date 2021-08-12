###########################################################
# Construct database (dict) from the read-in `int_fld` data
###########################################################
# Saleh Rezaeiravesh, salehr@kth.se
#-----------------------------------------------------------

import numpy as np

def dbMaker(data,nx,ny,npwall):
    """
    Making database for fields 'F1', 'F2, ...,'D64', where,
      'F': statistics
      'D': derivatives
    For a complete list of these fields, see: 
    https://github.com/KTH-Nek5000/KTH_Examples/blob/master/pipe_PSTAT2D/pp_python/nom_fields.txt  

    Assumption: Two sets of interpolation points are included in the data 
       (also written with the same order as below):
       1. [Profs] A set of `nx` streamwise locations at each of which `ny` points are considered in 
       the vertical direction to extract different profiles.  
       2. [Wall] A set of `npwall` points at the flat part (between the hills) of the bottom wall.
      
    Args: 
      `data`: data
      `nx`: number of points in the streamwise direction [Profs]
      `ny`: number of points in the vertical direction [Profs]
      `npwall`: number of points at the bottom wall [Wall]

    Returns:
      `dbProfs`: a database containing the coordinates and "stats and derivatives" quantities 
      of the `nx`*`ny` profile points
         Ex.: dbProfs['F1'] is a numpy array of shape (`nx`,`ny`) containing the 'F1' field

      `dbWall`: a database containing coordinates and "stats and derivatives" quantities 
      of the `npwall` points at the wall
         Ex.: dbWall['F1'] is a numpy array of shape (npwall) containing the 'F1' field
    """
    nStats=data.nstat
    nDerivs=data.nderiv
    nPts=data.npoints
    f=np.zeros((nPts,nStats))
    g=np.zeros((nPts,nDerivs))
    pos_=np.zeros((nPts,2))
    dbProfs={}
    dbWall={}

    for j in range(nPts):
        lptn = data.pset[j]
        f[j,:] = getattr(lptn,'stat')
        g[j,:] = getattr(lptn,'deriv')
        pos_[j,:] = getattr(lptn,'pos')

    #coordinate of the interpolating points
    x_=np.reshape(pos_[:nx*ny,0],[nx,ny],'C')
    y_=np.reshape(pos_[:nx*ny,1],[nx,ny],'C')
    dbProfs.update({'x':x_,'y':y_})
    dbWall.update({'x':pos_[nx*ny:,0],'y':pos_[nx*ny:,1]})

    #F stats
    for i in range(nStats):
        fName='F'+str(i+1)
        f2=f[:,i]
        f2Profs=np.reshape(f2[:nx*ny],[nx,ny],'C')            
        dbProfs.update({fName:f2Profs})
        dbWall.update({fName:f2[nx*ny:]})

    #D Derivatives
    for i in range(nDerivs):
        fName='D'+str(i+1)
        f2=g[:,i]
        f2Profs=np.reshape(f2[:nx*ny],[nx,ny],'C')    
        dbProfs.update({fName:f2Profs})
        dbWall.update({fName:f2[nx*ny:]})
    return dbProfs,dbWall

def read_pp_inputs(filename):
    """
    Read the post-processing parameters from `inputs_phill_pp.in` 
    """ 
    params = {}
    f1=open(filename,'r')
    ain=f1.readlines()
    for i in range(len(ain)):
        ain_sep=ain[i].split()

        if len(ain_sep)>1 and ain_sep[1]=='=':
           key_=ain_sep[0] 
           if key_!='npvrt' and key_!='npwall' and key_!='xpvrt':
              val_=float(ain_sep[2])
           elif key_=='npvrt' or key_=='npwall':
              val_=int(ain_sep[2]) 
           elif key_=='xpvrt':
              tmp=[]
              for i in range(2,len(ain_sep)):
                  if ain_sep[i][0]!='#':
                     tmp.append(float(ain_sep[i]))
                  else:
                     break
              val_=np.asarray(tmp)    

           params.update({key_:val_}) 
    return params       
