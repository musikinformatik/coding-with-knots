




~data = ~getQuipuData.("../../json/HP001.json".resolveRelative);
~data.cs; // post compile string

// depth first
(
~traverse = { |dict, func, level = 0, index = 0|
	dict[\children].do { |each, i|
		~traverse.(each, func, level + 1, i)
	};
	func.value(dict, level, index);
}
);


~traverse.(~data, { |x| x[\colours].postcs });
~traverse.(~data, { |x| x[\knots].postln });


~traverse.(~data, { |x, level, i| [level, i].postln });


~allPaths = "../../json/*.json".resolveRelative.pathMatch;
~allData = ~allPaths.collect { |x| ~getQuipuData.(x) };

~traverse.(~allData.choose, { |x, level, i| [level, i].postln });

