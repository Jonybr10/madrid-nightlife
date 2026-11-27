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
    # Reverse series references are explicit catalog links, not title guesses.
    series_edges=set()
    for key,d in datasets:
        for series in d.get('series',[]):
            sid=series.get('id')
            if not sid: continue
            for eid in series.get('eventIds') or []:
                if eid in events:
                    series_edges.add((sid,eid))
    for sid,eid in sorted(series_edges):
        if eid not in by_series[sid]: by_series[sid].append(eid)
    # Build territorial indexes and candidate identity edges without promoting names to verified IDs.
    by_country,by_city,by_region,by_genre,by_label=({} for _ in range(5))
    candidates=[]
    aliases=collections.defaultdict(set)
    for aid,p in profiles.items():
        for name in [p.get('name'),*p.get('aliases',[])]:
            if normalize(name): aliases[normalize(name)].add(aid)
    for row in credits:
        if row['status']=='name_only':
            matches=sorted(aliases.get(normalize(row['name']),set()))
            if matches: candidates.append({'eventId':row['eventId'],'name':row['name'],'candidateArtistIds':matches,'status':'needs_identity_review'})
    for key,d in datasets:
        venues={v['id']:v for v in d.get('venues',[])}
        for e in d.get('events',[]):
            eid=e['id']; v=venues[e.get('venueId') or e.get('venue')]
            country=events[eid].get('country')
            city=events[eid].get('city')
            region=e.get('regionId') or v.get('regionId') or ('ES-M' if key=='madrid' else None)
            if country: by_country.setdefault(country,[]).append(eid)
            if country and city: by_city.setdefault(country+'|'+normalize(city),[]).append(eid)
            if region: by_region.setdefault(region,[]).append(eid)
            events[eid]['regionId']=region
            for gid in sorted(set((e.get('music') or {}).get('ids') or [])):
                by_genre.setdefault(gid,[]).append(eid)
        for a in d.get('artists',[]):
            if a.get('id') in profiles:
                for lid in a.get('labelIds') or []:
                    by_label.setdefault(lid,set()).add(a['id'])
    for idx in (by_country,by_city,by_region,by_genre,by_series,by_venue,by_promoter):
        for k,ids in idx.items():
            idx[k]=sorted(set(ids),key=lambda eid:(events[eid]['date'],eid))
    for aid,profile in profiles.items():
        profile['eventIds']=sorted(set(by_artist.get(aid,[])),key=lambda eid:(events[eid]['date'],eid))
    assert all(eid in events for ids in by_artist.values() for eid in ids)
    assert all(eid in events for ids in by_name.values() for eid in ids)
    assert all(row in by_event[row['eventId']] for row in credits)
    assert sum(map(len,by_venue.values()))==len(events)
    return {'schemaVersion':'1.2.0','policy':'Explicit catalog IDs and unresolved names are separate. Historical listing does not establish performance.','artists':list(profiles.values()),'events':list(events.values()),'artistEvents':credits,'byArtist':dict(by_artist),'byEvent':dict(by_event),'byName':{k:sorted(set(v)) for k,v in by_name.items()},'byVenue':dict(by_venue),'byPromoter':dict(by_promoter),'bySeries':dict(by_series),'unresolvedIds':unresolved,'candidateArtistEvents':candidates,'byCountry':by_country,'byCity':by_city,'byRegion':by_region,'byGenre':by_genre,'artistsByLabel':{k:sorted(v) for k,v in by_label.items()},'stats':{'events':len(events),'profiles':len(profiles),'relationships':len(credits),'explicit':sum(r['status']=='catalog_id' for r in credits),'nominal':sum(r['status']=='name_only' for r in credits),'unresolvedIds':len(unresolved),'profilesWithoutExplicitEvents':sum(not p['eventIds'] for p in profiles.values()),'venuesWithEvents':len(by_venue),'promotersWithEvents':len(by_promoter),'seriesWithEvents':len(by_series),'candidateIdentityLinks':len(candidates),'countriesWithEvents':len(by_country),'citiesWithEvents':len(by_city),'regionsWithEvents':len(by_region),'genresWithEvents':len(by_genre),'labelArtistLinks':sum(map(len,by_label.values())),'eventsWithoutArtistCredits':sum(eid not in by_event for eid in events)}}

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    graph=build()
    target=pathlib.Path(args.output);target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(graph,ensure_ascii=False,separators=(',',':')))
    print(json.dumps(graph['stats']))
