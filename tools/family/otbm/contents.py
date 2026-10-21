# Dump the nested contents of items with the given unique ids (or tiles x:y:z).
import sys, struct
data=open(sys.argv[1],'rb').read()
want=set(int(x) for x in sys.argv[2].split(',') if x)
tiles=set(tuple(map(int,t.split(':'))) for t in (sys.argv[3].split(',') if len(sys.argv)>3 else []) if t)
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
stack=[]; active=None  # depth at which dumping started
while i<n:
    b=data[i]
    if b==0xFE:
        t=data[i+1]; p,j=props(i+2)
        if t==4 and len(p)>=5: area=struct.unpack_from('<HHB',p,0)
        elif t in (5,14) and len(p)>=2:
            tile=(area[0]+p[0],area[1]+p[1],area[2])
            if tile in tiles: print('TILE',tile)
        elif t==6 and len(p)>=2:
            iid=struct.unpack_from('<H',p,0)[0]; a=attrs(p)
            d=len(stack)
            if active is None and (a.get(5) in want or tile in tiles):
                active=d
            if active is not None:
                print('  '*(d-active), iid, a, tile)
        stack.append(t)
        i=j
    elif b==0xFF:
        stack.pop()
        if active is not None and len(stack)<=active: active=None
        i+=1
    else: i+=1
