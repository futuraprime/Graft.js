#	Graft 0.1
#	(c) 2011 Evan Hensleigh
#	
#	A relational data extension for Backbone.js
#	(in case you want one)
#	
#	Freely distributed under a "don't be evil" license



# Graft can only run if Backbone is present
if Backbone? then return false

Graft = Backbone.Graft = {};

# Create a home for the original (reference) implementations
# in case we opt to overwrite them later.
R = Graft.Reference = {}
R.Model = Backbone.Model
R.Collection = Backbone.Collection

# Graft.Joined is a new model that handles Join results.
# A Graft.Joined has some special, modified methods.
Graft.Joined = R.Model.extend
	join		:	false
	
	# Graft.Joined stores data across joins as JSON data--this means
	# your result set will have data nested behind the joins
	initialize	:	( startModel, options ) ->
		if startModel? and not startModel instanceof R.Model then return false				# must be a model
		if not options or not options.as? then return false									# as is required
	
		as = options.as
		this.join ?= options.join
	
		data = {}
		data[as] = startModel.toJSON()												# pour the data in
		this.set data

	# Slightly tweaked version of get here.
	# This version of get lets us pull nested data.
	# Really, this is how the get function should work by default,
	# since nested data is handy in other instances as well.
	get			:	( attrName ) ->
		attrs = attrName.split '.'													# break on dots!
		result = R.Model.prototype.get.call this, attrs.shift()						# call the straight object
	
		result = result[attr] for attr in attrs										# now we get down to the heart of the matter
	
		return result

	# This will merge another Joined's data into this one, for handling
	# multiple joins.
	mergeIn		:	( joinModel, name ) ->
		if joinModel instanceof Graft.Joined
			_.each joinModel, ( member ) =>
				if not member in this.toJSON()
					throw "Can't join."
					return false


# Graft.Collection is a modified version of the standard collection
# that allows you to run joins. If you plan to use Graft, all of your
# collections should be Graft collections, not Backbone collections.
Graft.Collection = R.Collection.extend
	
	_findByAttribute	:	( attr, value ) ->
		ret = this.select ( member ) -> member.get( attr ) is value
		return ret
		
	filterByAttribute	:	( attr, value ) ->
		ret = new Graft.Collection
		
		ret.add element.toJSON() for element in this._findByAttribute(attr, value)
		
		return ret
	
	# This is an INNER JOIN
	# joinOrders take the form of:  
	# { linkCollection: Collection, as: name, fromName: name, fromKey: keyname, linkKey: keyname }  
	# - _linkCollection_ is what you're bringing in  
	# - _as_ is its alias -- note that as is **required**  
	# - _fromName_ is the alias of the set in the join you're connecting to - it defaults to the starting set  
	# - _fromKey_ is the join key for the set in the join  
	# - _linkKey_ is the join key for the set you're bringing in
	#
	# Be sure that all of your aliases across the join are unique, or the join
	# will fail.
	join		: ( as, joinOrders... ) ->
		
		aliases = _.pluck(joinOrders, 'as').push as								# make sure our aliases are all unique
		if not _.unique( aliases ).length is aliases.length 
			throw "All aliases in the join must be unique."						# no good!
			return false
		
		joined = new Graft.Collection											# the result collection
		
		# Start by dumping the current collection in.
		# We'll do this iteratively to shift everything into Graft.Joined models.
		this.each ( member ) ->
			joined.add new Graft.Joined member, as: as, join: true
		
		for order in joinOrders													# iterate over the join orders
			do ( order ) =>														# make sure we have a well-formed join order
				if not order.linkCollection? or not order.linkCollection instanceof Graft.Collection then return false
				if not order.fromKey? or not order.linkKey? or not order.as? then return false
			
				_joined_ = new Graft.Collection									# we're going to be writing over the join soon
				
				name = order.fromName ? as										# default the fromName
			
				joined.each ( member ) ->										# great! let's get joining
					
					# First we pull all the elements that match this element
					# out of the collection we're bringing in.
					matches = order.linkCollection._findByAttribute order.linkKey, member.get name+'.'+order.fromKey
					
					memberItems = member.toJSON()
					
					# Now iterate over the matches and create unified result join models.
					# We append it to the preexisting "joined" collection.
					for match in matches
						do ( match ) ->
							joinMember = new Graft.Joined
							
							joinData = memberItems								# start with the join set
							joinData[order.as] = match.toJSON()					# add in the new join data
							joinMember.set joinData
							
							_joined_.add joinMember
							
				joined = _joined_												# overwrite the old joined
				
		return joined															# and finally, return the join

# This sends Graft into "overrun" mode, which makes Graft overwrite the standard
# model and controller. This lets you write more convenient code, but it could screw
# other things up, if they depend on the standard implementations of Backbone's
# model and controller. Use at your own risk.
#
# Note that if you use overrun mode, you can still access the reference implementations
# at Backbone.Graft.Reference.Model and Backbone.Graft.Reference.Collection
Graft.Overrun = ->
	Backbone.Model = Graft.Joined
	Backbone.Collection = Graft.Collection