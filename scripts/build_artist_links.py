"""Materialize AAA artist-event relationships from both public catalogs.

Identity is never inferred from spelling alone. Explicit IDs are catalog
relationships; name-only credits remain unresolved until independently verified.
"""
import argparse, collections, json, pathlib, unicodedata

def normalize(value):
    return ''.join(c for c in unicodedata.normalize('NFKD', str(value or '')) if not unicodedata.combining(c)).lower().strip()

def build():
    datasets = [(key,json.loads(pathlib.Path(path).read_text())) for key,path in [('madrid','agenda.json'),('world','catalog/world-events.json')]]
    profiles, events, credits, unresolved = {}, {}, [], []
    by_artist, by_event, by_name = collections.defaultdict(list), collections.defaultdict(list), collections.defaultdict(list)
    by_venue, by_promoter, by_series = collections.defaultdict(list), collections.defaultdict(list), collections.defaultdict(list)
    for key,d in datasets:
        for a in d.get('artists',[]):
            if a.get('id') and not a.get('isCandidate'):
                profiles.setdefault(a['id'], {'id':a['id'],'name':a.get('name'),'source':a.get('source'),'identityStatus':a.get('identityStatus'),'aliases':a.get('aliases') or []})
    for key,d in datasets:
        venues = {v['id']:v for v in d.get('venues',[])}
        for e in d.get('events',[]):
            eid=e['id']
            if eid in events: raise ValueError('Duplicate event '+eid)
            vid=e.get('venueId') or e.get('venue')
            if vid not in venues: raise ValueError('Missing venue '+str(vid))
            v=venues[vid]
            events[eid]={'id':eid,'title':e.get('title'),'date':e.get('date'),'endDate':e.get('endDate'),'venueId':vid,'venueName':v.get('name'),'country':e.get('country') or v.get('country') or ('ES' if key=='madrid' else None),'city':e.get('city') or v.get('city') or ('Madrid' if key=='madrid' else None),'status':e.get('status'),'source':e.get('source') or e.get('ticket')}
            by_venue[vid].append(eid)
            for promoter in set(p for p in [e.get('promoter'),*(e.get('promoters') or [])] if isinstance(p,str) and p.strip()):
                by_promoter[normalize(promoter)].append(eid)
            if e.get('seriesId'): by_series[e['seriesId']].append(eid)
            explicit=set(e.get('artistIds') or [])
            for aid in sorted(explicit):
                if aid not in profiles:
                    unresolved.append({'eventId':eid,'artistId':aid,'reason':'profile_missing'})
                    continue
                row={'eventId':eid,'artistId':aid,'name':profiles[aid]['name'],'status':'catalog_id','source':events[eid]['source']}
                credits.append(row);by_artist[aid].append(eid);by_event[eid].append(row)
                for alias in [profiles[aid]['name'],*profiles[aid]['aliases']]:
                    if isinstance(alias,str) and normalize(alias): by_name[normalize(alias)].append(eid)
            linked_names={normalize(profiles[aid]['name']) for aid in explicit if aid in profiles}
            for name in dict.fromkeys(e.get('artists') or []):
                if not isinstance(name,str) or not normalize(name): continue
                n=normalize(name)
                by_name[n].append(eid)
                if n in linked_names: continue
                row={'eventId':eid,'artistId':None,'name':name,'status':'name_only','source':events[eid]['source']}
                credits.append(row);by_event[eid].append(row)
    for aid,profile in profiles.items():
        profile['eventIds']=sorted(set(by_artist.get(aid,[])),key=lambda eid:(events[eid]['date'],eid))
    assert all(eid in events for ids in by_artist.values() for eid in ids)
    assert all(eid in events for ids in by_name.values() for eid in ids)
    assert all(row in by_event[row['eventId']] for row in credits)
    assert sum(map(len,by_venue.values()))==len(events)
    return {'schemaVersion':'1.1.0','policy':'Explicit catalog IDs and unresolved names are separate. Historical listing does not establish performance.','artists':list(profiles.values()),'events':list(events.values()),'artistEvents':credits,'byArtist':dict(by_artist),'byEvent':dict(by_event),'byName':{k:sorted(set(v)) for k,v in by_name.items()},'byVenue':dict(by_venue),'byPromoter':dict(by_promoter),'bySeries':dict(by_series),'unresolvedIds':unresolved,'stats':{'events':len(events),'profiles':len(profiles),'relationships':len(credits),'explicit':sum(r['status']=='catalog_id' for r in credits),'nominal':sum(r['status']=='name_only' for r in credits),'unresolvedIds':len(unresolved),'profilesWithoutExplicitEvents':sum(not p['eventIds'] for p in profiles.values()),'venuesWithEvents':len(by_venue),'promotersWithEvents':len(by_promoter),'seriesWithEvents':len(by_series)}}

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    graph=build()
    target=pathlib.Path(args.output);target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(graph,ensure_ascii=False,separators=(',',':')))
    print(json.dumps(graph['stats']))
