cacheLot = {}

getLot = (id,callback)->
	id = id+""
	if cacheLot[id]?
		callback cacheLot[id]
	else
		Lots.count (err,list)->
			console.log "get lot to cache"
			for a in list
				cacheLot[a._id] = a
			callback cacheLot[id]


