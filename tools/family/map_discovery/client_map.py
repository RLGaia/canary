import sys,os,struct,lzma,glob
sys.path.insert(0,os.path.dirname(__file__))
from pb import *
A=''
def load(assets=None):
    global A
    if assets: A=assets.rstrip('/')+'/'
    b=open(glob.glob(A+'map-*.dat')[0],'rb').read()
    areas={};npcs=[];masks={}
    for f,t,v in parse(b):
        if f==1:
            d={};
            for k,_,x in parse(v):
                if k==4: d.setdefault(4,[]).append(x)
                elif k==5: d[5]={kk:xx for kk,_,xx in parse(x)}
                elif k in(2,7): d[k]=x.decode()
                else: d[k]=x
            areas[d[1]]=d
        elif f==2:
            d={}
            for k,_,x in parse(v):
                if k==2: x={kk:xx for kk,_,xx in parse(x)}
                elif k==1: x=x.decode()
                d[k]=x
            npcs.append(d)
        elif f==3:
            d={}
            for k,_,x in parse(v):
                if k==2: x={kk:xx for kk,_,xx in parse(x)}
                elif k==3: x=x.decode()
                d[k]=x
            if d.get(1,0)==0: masks[d[6]]=d
    return areas,npcs,masks
def cip(path):
    b=open(path,'rb').read(); i=0
    while b[i]==0: i+=1
    i+=2
    for _ in range(2):
        while b[i]&0x80: i+=1
        i+=1
    props=b[i:i+5]; i+=13
    return lzma.decompress(props+b'\xff'*8+b[i:],format=lzma.FORMAT_ALONE)
def bmp(d):
    off=struct.unpack_from('<I',d,10)[0]; w,h=struct.unpack_from('<ii',d,18); bpp=struct.unpack_from('<H',d,28)[0]
    return off,w,h,bpp
