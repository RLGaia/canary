#!/usr/bin/env python3
"""Builds data/scripts/lib/family_map_discovery_data.lua from the client's map file and the
point-of-interest candidates generated on the server (see poi_candidates.lua)."""
import sys,re,json,os
sys.path.insert(0,os.path.dirname(__file__))
from client_map import load
import glob as _glob
from collections import Counter, defaultdict

BLOCK=4  # footprint lookup resolution (squares)

def footprint(areas, masks):
    """(x, y) -> subarea id for every square of every subarea shape."""
    import client_map
    own={}
    for sid,m in masks.items():
        if areas.get(sid,{}).get(3)!=2: continue
        d=client_map.cip(client_map.A+m[3]); off,w,h,bpp=client_map.bmp(d); x0,y0=m[2][1],m[2][2]
        for row in range(h):
            y=y0+h-1-row; r=d[off+row*w*4:off+(row+1)*w*4]
            for x in range(w):
                if r[x*4+3]: own[(x0+x,y)]=sid
    return own

def grid(own, keep):
    """Rows of BLOCK x BLOCK blocks: by -> [bx1, bx2, sid, ...] (majority subarea per block)."""
    cnt=defaultdict(Counter)
    for (x,y),s in own.items():
        if s in keep: cnt[(x//BLOCK,y//BLOCK)][s]+=1
    rows=defaultdict(list)
    for (bx,by),c in cnt.items(): rows[by].append((bx,c.most_common(1)[0][0]))
    out={}
    for by,l in rows.items():
        l.sort(); runs=[]
        for bx,s in l:
            if runs and runs[-1][1]==bx-1 and runs[-1][2]==s: runs[-1][1]=bx
            else: runs.append([bx,bx,s])
        out[by]=runs
    return out

def creatures(own, keep, server):
    """Per subarea: monster name -> occurrence (0 common, 1 rare, 2 raids)."""
    spawns=defaultdict(Counter); total=Counter()
    xml=open(os.path.join(server,'data-otservbr-global/world/otservbr-monster.xml'),encoding='utf-8',errors='ignore').read()
    for block in re.finditer(r'<monster centerx="(\d+)" centery="(\d+)" centerz="(\d+)"[^>]*>(.*?)</monster>\s*(?=<monster centerx|</monsters>)',xml,re.S):
        cx,cy=int(block.group(1)),int(block.group(2))
        for m in re.finditer(r'<monster name="([^"]+)" x="(-?\d+)" y="(-?\d+)"',block.group(4)):
            name=m.group(1); s=own.get((cx+int(m.group(2)),cy+int(m.group(3))))
            total[name]+=1
            if s in keep: spawns[s][name]+=1
    result=defaultdict(dict)
    for s,c in spawns.items():
        for name,n in c.items():
            result[s][name]=1 if total[name]<=5 else 0
    def raid(name,x,y):
        s=own.get((x,y))
        if s in keep and name.lower() not in {n.lower() for n in result[s]}: result[s][name]=2
    for f in _glob.glob(os.path.join(server,'data-otservbr-global/raids/**/*.xml'),recursive=True):
        t=open(f,encoding='utf-8',errors='ignore').read()
        for m in re.finditer(r'<singlespawn[^>]*name="([^"]+)"[^>]*x="(\d+)"[^>]*y="(\d+)"',t): raid(m.group(1),int(m.group(2)),int(m.group(3)))
        for m in re.finditer(r'<areaspawn[^>]*fromx="(\d+)"[^>]*fromy="(\d+)"[^>]*tox="(\d+)"[^>]*toy="(\d+)"[^>]*>(.*?)</areaspawn>',t,re.S):
            cx,cy=(int(m.group(1))+int(m.group(3)))//2,(int(m.group(2))+int(m.group(4)))//2
            for n in re.findall(r'name="([^"]+)"',m.group(5)): raid(n,cx,cy)
    for f in _glob.glob(os.path.join(server,'data-otservbr-global/scripts/raids/**/*.lua'),recursive=True):
        t=open(f,encoding='utf-8',errors='ignore').read()
        for m in re.finditer(r'name = "([^"]+)",[^}]*?Position\((\d+), (\d+), (\d+)\)',t,re.S): raid(m.group(1),int(m.group(2)),int(m.group(3)))
    return result

MAX_POINTS=48  # candidates per subarea; 10 are picked at each start/reset, so more = more varied resets

def main(client_assets, candidates, out, server='.'):
    areas,npcs,masks=load(client_assets)
    cand={}
    pts=lambda t:[tuple(map(int,p)) for p in re.findall(r'\{(\d+),(\d+),(\d+)\}',t)]
    for m in re.finditer(r'\[(\d+)\]=\{name="([^"]*)",area=(\d+),tiles=(\d+),reach=(\d+),real=\{(.*?)\},poi=\{(.*?)\}\},',open(candidates).read()):
        real,gen=pts(m.group(6)),pts(m.group(7))
        # real Tibia spots first; generated tiles fill up to MAX_POINTS, away from the real ones
        merged=list(real)
        for g in gen:
            if len(merged)>=MAX_POINTS: break
            if all(not(p[2]==g[2] and max(abs(p[0]-g[0]),abs(p[1]-g[1]))<=3) for p in merged):
                merged.append(g)
        cand[int(m.group(1))]=merged
    ach={1:"Elven Woods",2:"Mummy's Dearest",3:"Long Live the Queen",4:"Daraman's Footsteps",7:"Stronghold of Edron",8:"Lizard Kingdom",9:"Realms of Dreams",11:"Trip to the Beach",14:"Dwarven Mines",16:"The Ogre Steppe",17:"Liberty Bay Watch",19:"King of the Jungle",20:"Glooth Punk",22:"Twisted Dreams",23:"Race to the Pole",24:"All Hail the King",25:"Jewel in the Swamp",27:"Ancient Splendor",355:"The Empire's Glory",434:"Snake Pit"}
    L=['-- Gaia Family server: Cyclopedia map discovery data (generated). Ours, not upstream.','--',
    "-- Areas and subareas come from the 15.11 client's map file (assets/map-*.dat): ids and names",
    '-- as the client knows them, and which subareas the client can draw (only those can be',
    '-- selected for "Start Discovering"; a subarea is its shape on every floor, above and',
    '-- below ground). Points of interest: the spots where players found them in Tibia',
    "-- (TibiaMaps.io's points-of-interest markers, MIT licence) that can be walked to on our",
    '-- map, topped up to %d with evenly spread reachable tiles on any floor (reachable = walked' % MAX_POINTS,
    '-- to from a temple or an NPC through stairs, ladders, rope spots, ordinary doors and',
    '-- teleports; houses, quest and level doors excluded). Regenerate with',
    '-- tools/family/map_discovery/ (see its README) when the map or the client changes.',
    '-- Used by data/scripts/family/map_discovery.lua.','','FamilyDiscoveryData = {','\tareas = {']
    inc={}
    for aid,a in sorted(areas.items()):
        if a.get(3)!=1: continue
        subs=[sid for sid in a.get(4,[]) if sid in masks and areas.get(sid,{}).get(3)==2 and cand.get(sid)]
        for sid in subs: inc[sid]=aid
        L.append('\t\t[%d] = { name = %s, counted = %s,%s subareas = { %s } },'%(aid,json.dumps(a[2]),'false' if a.get(6) else 'true',(' achievement = %s,'%json.dumps(ach[aid])) if aid in ach else '',', '.join(map(str,subs))))
    L+=['\t},','\tsubareas = {']
    for sid in sorted(inc):
        L.append('\t\t[%d] = { name = %s, area = %d, points = { %s } },'%(sid,json.dumps(areas[sid][2]),inc[sid],', '.join('{ %d, %d, %d }'%p for p in cand[sid])))
    L+=['\t},']
    own=footprint(areas,masks)
    g=grid(own,set(inc))
    L.append('\t-- where each subarea is: block rows (y // %d) of runs { x1 // %d, x2 // %d, subarea }'%(BLOCK,BLOCK,BLOCK))
    L.append('\tblock = %d,'%BLOCK)
    L.append('\tgrid = {')
    for by in sorted(g):
        L.append('\t\t[%d] = { %s },'%(by,', '.join('%d, %d, %d'%tuple(r) for r in g[by])))
    L.append('\t},')
    cr=creatures(own,set(inc),server)
    L.append('\t-- creatures shown on the map for fully discovered areas: name = 0 common, 1 rare, 2 raids')
    L.append('\tcreatures = {')
    for sid in sorted(cr):
        L.append('\t\t[%d] = { %s },'%(sid,', '.join('[%s] = %d'%(json.dumps(n),o) for n,o in sorted(cr[sid].items()))))
    L+=['\t},','}','']
    open(out,'w').write('\n'.join(L))
    print('subareas',len(inc))
if __name__=='__main__': main(*sys.argv[1:5])
