import sys
def varint(b,i):
    r=0;s=0
    while True:
        c=b[i];i+=1;r|=(c&0x7f)<<s;s+=7
        if c<0x80:return r,i
def parse(b):
    i=0;out=[]
    while i<len(b):
        k,i=varint(b,i);f=k>>3;t=k&7
        if t==0:v,i=varint(b,i)
        elif t==2:
            l,i=varint(b,i);v=b[i:i+l];i+=l
        elif t==5:v=int.from_bytes(b[i:i+4],'little');i+=4
        elif t==1:v=int.from_bytes(b[i:i+8],'little');i+=8
        else: raise ValueError('wt%d'%t)
        out.append((f,t,v))
    return out
def tryparse(b):
    try:
        r=parse(b)
        return r if r else None
    except Exception: return None
def show(b,depth=0,maxitems=12,maxdepth=6):
    items=parse(b)
    for n,(f,t,v) in enumerate(items):
        if n>=maxitems: print('  '*depth+'... %d more'%(len(items)-n));break
        if t==2:
            s=None
            try:
                s=v.decode('utf-8')
                if not s.isprintable(): s=None
            except: pass
            sub=tryparse(v) if depth<maxdepth else None
            if s is not None and (sub is None or len(v)<60):
                print('  '*depth+f'{f}: "{s[:80]}"')
            elif sub:
                print('  '*depth+f'{f}: {{ ({len(v)} bytes)');show(v,depth+1,maxitems,maxdepth);print('  '*depth+'}')
            else: print('  '*depth+f'{f}: bytes[{len(v)}]')
        else: print('  '*depth+f'{f}: {v}')
if __name__=='__main__':
    show(open(sys.argv[1],'rb').read(),0,int(sys.argv[2]) if len(sys.argv)>2 else 12)
