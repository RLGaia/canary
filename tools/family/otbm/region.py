# Gaia Family server: print every square of a map rectangle on one floor
# (ground id, flags, items with attributes: 4 = action id, 5 = unique id).
# Usage: python3 -I tools/family/otbm/region.py data-otservbr-global/world/otservbr.otbm x0,y0,x1,y1,z
import sys, struct
data=open(sys.argv[1],'rb').read()
x0,y0,x1,y1,z=map(int,sys.argv[2].split(','))
n=len(data); i=4
area=(0,0,0); tile=None; tflags=0
def props(j):
    out=bytearray()
    while j<n:
        b=data[j]
        if b==0xFD: out.append(data[j+1]); j+=2
        elif b in (0xFE,0xFF): break
        else: out.append(b); j+=1
    return bytes(out), j
SIZES={4:2,5:2,9:2,10:2,12:1,14:1,15:1,16:4,17:1,18:4,20:4,21:4,22:2,8:5}
def attrs(p,k):
    d={}
    while k<len(p):
        a=p[k]; k+=1
        if a in (6,7,19):
            l=struct.unpack_from('<H',p,k)[0]; d[a]=p[k+2:k+2+l]; k+=2+l
        elif a==8: d[8]=struct.unpack_from('<HHB',p,k); k+=5
        elif a in SIZES:
            s=SIZES[a]; d[a]=int.from_bytes(p[k:k+s],'little'); k+=s
        else: break
    return d
res={}
depth=[]
while i<n:
    b=data[i]
    if b==0xFE:
        t=data[i+1]; p,j=props(i+2)
        if t==4 and len(p)>=5: area=struct.unpack_from('<HHB',p,0)
        elif t in (5,14) and len(p)>=2:
            tile=(area[0]+p[0],area[1]+p[1],area[2])
            k=2+(4 if t==14 else 0); a=attrs(p,k) if False else {}
            # tile attrs: 3=flags(4), 9=item(2)
            fl=0; items=[]
            while k<len(p):
                at=p[k]; k+=1
                if at==3: fl=struct.unpack_from('<I',p,k)[0]; k+=4
                elif at==9: items.append(struct.unpack_from('<H',p,k)[0]); k+=2
                else: break
            if x0<=tile[0]<=x1 and y0<=tile[1]<=y1 and tile[2]==z:
                res[tile]={'flags':fl,'items':[(x,) for x in items],'house':t==14}
        elif t==6 and len(p)>=2 and tile in res and depth and depth[-1]=='tile':
            iid=struct.unpack_from('<H',p,0)[0]; a=attrs(p,2)
            res[tile]['items'].append((iid,{k:v for k,v in a.items()}))
        depth.append({4:'area',5:'tile',14:'tile',6:'item'}.get(t,'x'))
        i=j
    elif b==0xFF:
        depth.pop(); i+=1
    else: i+=1
for t in sorted(res,key=lambda t:(t[1],t[0])):
    print(t, res[t])
