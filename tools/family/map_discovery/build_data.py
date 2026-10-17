#!/usr/bin/env python3
"""Builds data/scripts/lib/family_map_discovery_data.lua from the client's map file and the
point-of-interest candidates generated on the server (see poi_candidates.lua)."""
import sys,re,json,os
sys.path.insert(0,os.path.dirname(__file__))
from client_map import load
def main(client_assets, candidates, out):
    areas,npcs,masks=load(client_assets)
    cand={}
    for m in re.finditer(r'\[(\d+)\]=\{name="([^"]*)",area=(\d+),tiles=(\d+),reach=(\d+),poi=\{(.*?)\}\},',open(candidates).read()):
        cand[int(m.group(1))]=[tuple(map(int,p)) for p in re.findall(r'\{(\d+),(\d+),(\d+)\}',m.group(6))]
    ach={1:"Elven Woods",2:"Mummy's Dearest",3:"Long Live the Queen",4:"Daraman's Footsteps",7:"Stronghold of Edron",8:"Lizard Kingdom",9:"Realms of Dreams",11:"Trip to the Beach",14:"Dwarven Mines",16:"The Ogre Steppe",17:"Liberty Bay Watch",19:"King of the Jungle",20:"Glooth Punk",22:"Twisted Dreams",23:"Race to the Pole",24:"All Hail the King",25:"Jewel in the Swamp",27:"Ancient Splendor",355:"The Empire's Glory",434:"Snake Pit"}
    L=['-- Gaia Family server: Cyclopedia map discovery data (generated). Ours, not upstream.','--',
    "-- Areas and subareas come from the 15.11 client's map file (assets/map-*.dat): ids and names",
    '-- as the client knows them, and which subareas the client can draw (only those can be',
    '-- selected for "Start Discovering"). Points of interest: up to 16 evenly spread tiles per',
    '-- subarea, picked on our map among tiles that can be walked to from a temple or an NPC',
    '-- (stairs, ladders, rope spots, ordinary doors and teleports followed; houses, quest and',
    '-- level doors excluded), on the ground floor when possible. Regenerate with',
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
    L+=['\t},','}','']
    open(out,'w').write('\n'.join(L))
    print('subareas',len(inc))
if __name__=='__main__': main(*sys.argv[1:4])
