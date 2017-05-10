
/*

SuperCollider functions for loading Quipu dotfile Datasets

version 0.3 based on the new json file format

NOTE: not all functions from previous versions have moved yet.


The json file is structured as follows:

each entry has a number of fields with properties, like ply ("S" or "Z"), colours (array of arrays), position (like 11.5).
It has also possibly an array of "children", which contains more entries.
It has possibly an array of "knots", which contains more entries.

*/

~readYaml = { |path|
	path.parseYAMLFile;
};
~couldBeNumberString = { |val|
	val.isString and: {
			val.every({ |item, i|  // from wslib
			((item.isDecDigit) or: (item == $.))
			or: ((item == $-) && (i == 0))
		}) and: { this != "-" };
	};
};
~parseDicts = { |dict|
	var res = IdentityDictionary.new;
	dict.pairsDo { |key, val|
		var couldBeNumber;
		if(key.isString.not) { "not a string".warn; key.postcs; };
		key = key.asSymbol;

		switch(key,

			\colours, {
				val = val.collect { |triple| triple.collect(_.asInteger) } // convert to 0..1 range
			},

			\children, {
				val = val.collect { |dict| ~parseDicts.(dict) }
			},

			\knots, {
				val = val.collect { |dict| ~parseDicts.(dict) }
			},
			{
				val = if(~couldBeNumberString.(val)) { val.asFloat } { val.asSymbol }
			}
		);
		res.put(key, val)
	};
	res
};

~getQuipuData = ~parseDicts <> ~readYaml;


~isLeaf = { |dict| dict[\children].isEmpty };



/*

Information Theory

*/


~entropy = { |list|
	var histogram = list.as(Bag);
	var contributions = histogram.contents.values / list.size;
	contributions.sum { |c| neg(c) * log2(c) }
};


/*

Other methods

*/

// depth first traversal
(
~traverse = { |dict, func, level = 0, index = 0, returnFromParents|
	returnFromParents = func.value(dict, level, index, returnFromParents);
	dict[\children].do { |each, i| ~traverse.(each, func, level + 1, i, returnFromParents) };
};

// traverse only at a specific level
~traverseAtLevel = { |dict, func, level = 0, index = 0, returnFromParents|
	~traverse.(dict, { |dict, theLevel|
		if(theLevel == level) { func.value(dict, level, index, returnFromParents) }
	});
};

// width first traversal
~traverseWidthFirst = { |dict, func, level = 0, index = 0, returnFromParents|
	(level..~maxLevel.(dict)).do { |i|
		~traverseAtLevel.(dict, func, i, index, returnFromParents)
	}
};

// number of children at a given depth
~numChildrenAt = { |dict, level=0|
	var n = 0;
	~traverseAtLevel.(dict, { n = n + 1 }, level);
	n
};

// number of children below a given depth
~numChildren = { |dict, depth=inf|
	var n = 0;
	~traverse.(dict, { |dict, level| if(depth > level) { n = n + 1 } });
	n
};

// maximal depth of the tree
~maxLevel = { |dict|
	var max = 0;
	~traverse.(dict, { |dict, theLevel| if(theLevel > max) { max = theLevel } });
	max
};

// for each depth, how many children
~dimensions = { |dict|
	~maxLevel.(dict).collect { |i| ~numChildrenAt.(dict, i) }
};

~allValues = { |dict|
	var values = IdentityDictionary.new;
	~traverse.(dict, { |x|
		x.keysValuesDo { |key, val|
			var set;
			if(key != \children) {
				set = values.at(key);
				if(set.isNil) { set = IdentitySet.new; values.put(key, set) };
				set.addAll(val)
			}
		};
	});
	values
};


~mapValues = { |dict, key, sortFunc|
	var all = Set.new, z = Dictionary.new;
	~traverse.(dict, { |x|
		x[key].asArray.do { |c| all.add(c) }
	});
	if(sortFunc.notNil) {
		all = all.asArray.sort(sortFunc)
	};
	all.do { |x, i| z[x] = i };
	z
};

~get = { |key|
	var dict = ~allQuipus.at(key);
	if(dict.isNil) { Error("Quipu % not found".format(key)).throw };
	dict
};

~coloursHSV = { |x|
	x = Color.fromArray(x).asHSV;
	x.collect { |c| if(c.isNaN) { 0 } { c } }
};

~postInfo = {
	"NAME ('number of total nodes', 'number of first level nodes' x 'number of levels')".postln;
	"-------------------------------------------------------".postln;
	~allQuipus.keys.as(Array).sort.do(~postInfoFor);
	"";
};

~postInfoFor = { |name|
	var data = ~allQuipus.at(name);
	var numNodes = 0;
	var numLevels = 0;
	var firstLevelPendants;
	~traverse.(data, { |d, l|
		numNodes = numNodes + 1;
		numLevels = max(numLevels, l);
		firstLevelPendants ?? { firstLevelPendants = d[\children].size }
	});
	"% (%, % x %)\n".postf(name, numNodes, firstLevelPendants, numLevels);
};
);



