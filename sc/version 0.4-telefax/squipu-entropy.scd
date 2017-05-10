
//////////////////////////////////////////////////////////



/*

ENTROPY

*/

~allPaths = "../../json/*.json".resolveRelative.pathMatch;
~allData = ~allPaths.collect { |x| ~getQuipuData.(x) };

(
~entropy = { |list|
	var histogram = list.as(Bag);
	var contributions = histogram.contents.values / list.size;
	contributions.sum { |c| neg(c) * log2(c) }
};
// contribution to the overall entropy of a single element (probably there is a better way to do this)
~entropyOf = { |item, list|
	~entropy.(list) - ~entropy.(list.removing(item))
};
~entropyAt = { |index, list|
	~entropyOf.(list.at(index), list)
};
);


(
~flatten = { |dict, key|
	var list;
	~traverse.(dict, { |x| var val = x[key]; if(val.notNil) { list = list.add(val) } });
	list
};
)

~flatten.(~allData[3], \colours);
~flatten.(~allData[3], \colours).do { |x| x.postln };

~entropy.(~flatten.(~allData[3], \colours));

// colour vs. ply entropies of all quipus
(
[
~allData.collect { |each| ~entropy.(~flatten.(each, \colours)) },
~allData.collect { |each| ~entropy.(~flatten.(each, \ply)) }
].plot
)


);
(
~allColours = ~allData.collect { |each|
	~flatten.(each, \colours)
}.flatten(1).collect(_.unbubble) // colour combinations count as single colour
.as(Set).as(Array)
)

~entropy.(~allColours); // -> 8.54
~entropyAt.(0, ~allColours);

~allData.collect { |each| ~entropy.(~flatten.(each, \colours)) };

~entropyOf.([ 187, 139, 84 ], ~allColours);
(0..100).collect { |i| ~entropyAt.(i, ~allColours) }.plot

