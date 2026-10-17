#!/usr/bin/env python3
"""Exports the client's subarea shapes (and NPC positions, used as starting points) to a Lua
table for poi_generator.lua. Small stray pieces of a subarea (under 15% of its biggest piece)
are dropped so points are not placed there.

Real point of interest spots seen in Tibia (TibiaMaps.io's tibia-map-data,
extra/points-of-interest/markers.json, MIT licence; flag markers only) are assigned to the
subarea whose shape contains them.

usage: export_masks.py <client assets folder> <output masks.lua> <server npc xml> [<poi markers.json>]"""
import sys,os,re,json
sys.path.insert(0,os.path.dirname(__file__))
from client_map import load,cip,bmp
import client_map

def main(assets, out, npcxml=None, poijson=None):
    areas,npcs,masks=load(assets)
    L=['return {','subareas = {']
    owner={}
    for sid,m in sorted(masks.items()):
        d=cip(client_map.A+m[3]); off,w,h,bpp=bmp(d); x0,y0=m[2][1],m[2][2]
        pix=set()
        for row in range(h):  # bottom-up bitmap
            y=h-1-row; r=d[off+row*w*4:off+(row+1)*w*4]
            for x in range(w):
                if r[x*4+3]: pix.add((x0+x,y0+y))
        seen=set(); comps=[]
        for p in pix:
            if p in seen: continue
            st=[p]; seen.add(p); c=[]
            while st:
                q=st.pop(); c.append(q)
                for dx in (-1,0,1):
                    for dy in (-1,0,1):
                        n=(q[0]+dx,q[1]+dy)
                        if n in pix and n not in seen: seen.add(n); st.append(n)
            comps.append(c)
        for p in pix: owner[p]=sid
        big=max(len(c) for c in comps)
        keep=set()
        for c in comps:
            if len(c)>=0.15*big: keep.update(c)
        rows={}
        for (x,y) in keep: rows.setdefault(y,[]).append(x)
        spans=[]
        for y,xs in rows.items():
            xs.sort(); s=prev=xs[0]
            for x in xs[1:]+[None]:
                if x is None or x!=prev+1:
                    spans.append((y,s,prev))
                    if x is not None: s=x
                if x is not None: prev=x
        L.append('[%d]={name=%s,area=0,spans={%s}},'%(sid,json.dumps(areas[sid][2]),','.join('{%d,%d,%d}'%sp for sp in spans)))
    seeds=[(n[2][1],n[2][2],n[2].get(3,7)) for n in npcs]
    if npcxml:
        for m in re.finditer(r'<npc centerx="(\d+)" centery="(\d+)" centerz="(\d+)"',open(npcxml).read()):
            seeds.append(tuple(map(int,m.groups())))
    L.append('},')
    real={}
    if poijson:
        for f in json.load(open(poijson)):
            sid=owner.get((f['x'],f['y']))
            if f.get('icon')=='flag' and sid and areas.get(sid,{}).get(3)==2:
                real.setdefault(sid,[]).append((f['x'],f['y'],f['z']))
    L.append('real={'+','.join('[%d]={%s}'%(sid,','.join('{%d,%d,%d}'%p for p in pts)) for sid,pts in sorted(real.items()))+'},')
    L.append('npcs={'+','.join('{%d,%d,%d}'%p for p in seeds)+'},')
    L.append('}')
    open(out,'w').write('\n'.join(L))
if __name__=='__main__': main(*sys.argv[1:5])
