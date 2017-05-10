

~allQuipus = Archive.at(\quipu, \allQuipus);
~all = Archive.at(\quipu, \all);

if(~all.notNil and: { ~all.size == Archive.at(\quipu, \allSize) }) {

	"\n\n\------------ using existing quipu data ---------------\n"
	"to reset, call Archive.put(\allQuipus, nil); then load again\n\n".postln;

} {

	"starting to read all files, this may take a while ...".postln;

	fork {
		var name;
		~all = [];
		~allQuipus = ();
		"json/*".resolveRelative.pathMatch.do { |path|
			var dict = ~getQuipuData.(path);
			dict[\quipuName] = name = path.basename.splitext.first.asSymbol;
			path.postln;
			~all = ~all.add(dict);
			~allQuipus.put(name, dict);
			0.2.wait;
		};
		" ------------ finished reading".postln;
		Archive.put(\quipu, \all, ~all);
		Archive.put(\quipu, \allQuipus, ~allQuipus);
		Archive.put(\quipu, \allSize, ~all.size);
	};


};

"";


/*

To reset, call this:

Archive.put(\quipu, nil);

*/