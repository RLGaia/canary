# Print every item with an id in IDS inside a box x0..x1, y0..y1, all floors (with nesting parents).
import sys, struct
data=open(sys.argv[1],'rb').read()
x0,y0,x1,y1=map(int,sys.argv[2].split(','))
ids=set(int(x) for x in sys.argv[3].split(','))
n=len(data); i=4; area=(0,0,0); tile=None
def props(j):
    out=bytearray()
    while j<n:
        b=data[j]
        if b==0xFD: out.append(data[j+1]); j+=2
        elif b in (0xFE,0xFF): break
        else: out.append(b); j+=1
    return bytes(out), j
SIZES={4:2,5:2,9:2,10:2,12:1,14:1,15:1,16:4,17:1,18:4,20:4,21:4,22:2,8:5}
def attrs(p):
    d={}; k=2
    while k<len(p):
        a=p[k]; k+=1
        if a in (6,7,19):
            l=struct.unpack_from('<H',p,k)[0]; d[a]=p[k+2:k+2+l].decode('latin1'); k+=2+l
        elif a in SIZES:
            s=SIZES[a]; d[a]=int.from_bytes(p[k:k+s],'little'); k+=s
        else: break
    return d
stack=[]
while i<n:
    b=data[i]
    if b==0xFE:
        t=data[i+1]; p,j=props(i+2)
        info=None
        if t==4 and len(p)>=5: area=struct.unpack_from('<HHB',p,0)
        elif t in (5,14) and len(p)>=2:
            tile=(area[0]+p[0],area[1]+p[1],area[2])
            # tile-level item ids (attr 9)
            k=2+(4 if t==14 else 0)
            while k<len(p):
                at=p[k]; k+=1
                if at==3: k+=4
                elif at==9:
                    iid=struct.unpack_from('<H',p,k)[0]; k+=2
                    if iid in ids and x0<=tile[0]<=x1 and y0<=tile[1]<=y1: print(iid,{},tile,'inline')
                else: break
        elif t==6 and len(p)>=2:
            iid=struct.unpack_from('<H',p,0)[0]; a=attrs(p); info=iid
            if iid in ids and tile and x0<=tile[0]<=x1 and y0<=tile[1]<=y1:
                print(iid,a,tile,'in',[s for s in stack if s])
        stack.append(info if t==6 else None)
        i=j
    elif b==0xFF:
        stack.pop(); i+=1
    else: i+=1
