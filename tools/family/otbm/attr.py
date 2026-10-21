# Gaia Family server: find map items by unique/action id or by item id,
# with the containers they are in. Scans the whole map (about 1 minute).
# Usage: python3 -I tools/family/otbm/attr.py <map.otbm> "<uid/aid,...>" "<item id,...>"
import sys, struct
data=open(sys.argv[1],'rb').read()
wantuid=set(int(x) for x in sys.argv[2].split(',')) if sys.argv[2] else set()
wantid=set(int(x) for x in sys.argv[3].split(',')) if len(sys.argv)>3 and sys.argv[3] else set()
n=len(data); i=4
area=(0,0,0); tile=None
stack=[]  # (type, info)
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
            l=struct.unpack_from('<H',p,k)[0]; d[a]=p[k+2:k+2+l]; k+=2+l
        elif a in SIZES:
            s=SIZES[a]; d[a]=int.from_bytes(p[k:k+s],'little'); k+=s
        else: break
    return d
cur=[]
while i<n:
    b=data[i]
    if b==0xFE:
        t=data[i+1]; p,j=props(i+2)
        info=None
        if t==4 and len(p)>=5: area=struct.unpack_from('<HHB',p,0)
        elif t in (5,14) and len(p)>=2: tile=(area[0]+p[0],area[1]+p[1],area[2])
        elif t==6 and len(p)>=2:
            iid=struct.unpack_from('<H',p,0)[0]; a=attrs(p)
            info=(iid,a.get(5),a.get(4))
            parents=[s for s in stack if s and s[0]=='item']
            if a.get(5) in wantuid or a.get(4) in wantuid: print('UID',info,tile)
            if iid in wantid: print('ID',info,tile,'in',[x[1] for x in parents])
        stack.append(('item',info) if t==6 else None)
        i=j
    elif b==0xFF:
        stack.pop(); i+=1
    else: i+=1
