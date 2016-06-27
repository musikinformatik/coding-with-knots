/*

Sonifications using the json format

*/

loadRelative("scquipu-lib.scd");


// load one of the following data sets:
~data = ~getQuipuData.("../../json/UR004.json".resolveRelative);
~data = ~getQuipuData.("../../json/HP019.json".resolveRelative);
~data = ~getQuipuData.("../../json/UR019.json".resolveRelative);


// boring quipu
~data = ~getQuipuData.("../../json/UR046.json".resolveRelative);


// astronomical quipu
~data = ~getQuipuData.("../../json/UR006.json".resolveRelative);
~data = ~getQuipuData.("../../json/UR009.json".resolveRelative);

// variants of administrative quipus
~data = ~getQuipuData.("../../json/UR066.json".resolveRelative);
~data = ~getQuipuData.("../../json/UR067.json".resolveRelative);
~data = ~getQuipuData.("../../json/UR068.json".resolveRelative);

~data = ~getQuipuData.("../../json/UR051.json".resolveRelative);
~data = ~getQuipuData.("../../json/UR015.json".resolveRelative);


(
SynthDef(\sin, { |out, freq = 440, sustain = 1, pan, amp = 0.1, ply|
	var attack = blend(0, 1, ply) * sustain;
	var release = blend(1, 0, ply) * sustain;
	var env = EnvGen.ar(Env.perc(attack, release, amp * 3), doneAction:2);
	var son = SinOsc.ar(freq);
	Out.ar(out, Pan2.ar(son, pan, env * AmpCompA.kr(freq)));
}).add;
)
(
SynthDef(\gabor, { |out, freq = 440, sustain = 1, pan, amp = 0.1|
	var env = LFGauss.ar(sustain, 0.3, loop:0, doneAction:2).range;
	var son = SinOsc.ar(freq);
	Out.ar(out, Pan2.ar(son, pan, env * (amp * 2 * AmpCompA.kr(freq))));
}).add;
)

// depth first
(
~traverse = { |dict, func, level = 0, index = 0, returnFromParents|
	returnFromParents = func.value(dict, level, index, returnFromParents);
	dict[\children].do { |each, i| ~traverse.(each, func, level + 1, i, returnFromParents) };
};
)

~traverse.(~data, { |x| x[\colours].postln }); // test






// SONIFICATIONS


// inka telefax: traversal
(
Tdef(\x, {
	~traverse.(~data, { |x|
		var note = x[\colours] / 255 * 32;
		if(note.notEmpty) {
			(note:note, sustain: 0.1, instrument: \sin).play;
		};
		0.1.wait;
	})
}).play
)



(
Tdef(\x, {
	var pani = ('R':-1, 'V':1, 'U':0);
	var plyi = ('S': 0, 'Z': 1, 'U': 0.5);
	~traverse.(~data, { |x, level|
		var colours = x[\colours], note, pan, len, ply;
		var dur;
		//x[\value].postln;
		dur = 1/2 ** (level - 1);
		dur = (dur / 10);
		dur.wait;
		if(colours.notEmpty) {
			pan = pani[x[\pendant_attach]];
			ply = plyi[x[\pendant_ply]];
			len = x[\pendant_length] ? 25 / 25;
			note = x[\colours] / 255 * 36 + 12;
			(
				note:note,
				dur: dur,
				instrument: \sin,
				amp: 0.1/3,
				pan: pan,
				legato:len * 1.5,
				ply: ply
			).play;
		};

	})
}).play
)


// KNOTS


(
Tdef(\x, {
	~traverse.(~data, { |x, level|
		var knots = x[\knots];
		knots.do { |k|
			var note, pan;
			note = k[\value];
			pan = k[\spin];
			(note:note, harmonic: k[\position], sustain: 0.01, instrument: \sin, sustain: 0.4, pan: pan).play;
		};
		0.1.wait;
	})
}).play
)



// multichannel version
(
Tdef(\x, {
	~traverse.(~data, { |x, level|
		var knots = x[\knots];
		knots.do { |k|
			var note, pan;
			note = k[\value];
			pan = k[\spin];
			(note:note, out: k[\position] - 6, sustain: 0.01, instrument: \sin, sustain: 0.4, pan: pan).play;
		};
		0.1.wait;
	})
}).play
)




(
Tdef(\x, {
	var dict = (
		'S': (note: 0, sustain: 0.01, instrument: \sin, sustain: 0.04),
		'Z': (note: 6, sustain: 0.01, instrument: \sin, sustain: 0.04),
		'U': (note: 23, sustain: 0.01, instrument: \sin, sustain: 0.04)
	);
	~traverse.(~data, { |x, level|
		var knots = x[\knots];
		knots.do { |k|
			var event, spin;
			spin = k[\spin];
			event = dict[spin];
			event = event ?? { (note: -5, sustain: 0.01, instrument: \sin, sustain: 0.04) };
			event.play;
			0.1.wait;
			//event[\dur].wait;
		};
		0.2.wait;
	});
}).play
)












/* combinations */
Server.default.makeGui

(
Tdef(\x, {
	var pani = ('R':-1, 'V':1, 'U':0);
	var plyi = ('S': 0, 'Z': 1, 'U': 0.5);
	var dict = (
		'S': (note: 0, sustain: 0.01, instrument: \gabor, sustain: 0.04),
		'Z': (note: 6, sustain: 0.01, instrument: \gabor, sustain: 0.04),
		'U': (note: 23, sustain: 0.01, instrument: \gabor, sustain: 0.04)
	);
	var knotdict = (
		'8': (note: 0, sustain: 0.1, instrument: \gabor, sustain: 0.04),
		'L': (note: 6, sustain: 0.1, instrument: \gabor, sustain: 0.1),
		'S': (note: 23, sustain: 0.1, instrument: \gabor, sustain: 0.01)
	);
	~traverse.(~data, { |x, level|
		var colours = x[\colours], note, pan, len, ply;
		var dur;
		var knots = x[\knots];
		var knotpos = 0;

		//x[\value].postln;
		dur = 1/2 ** (level - 1);
		dur = (dur / 10);
		dur.wait;
		if(colours.notEmpty) {
			pan = pani[x[\pendant_attach]];
			ply = plyi[x[\pendant_ply]];
			len = x[\pendant_length] ? 25 / 25;
			note = x[\colours] / 255 * 36 + 12;
			(
				note:note,
				dur: dur,
				instrument: \sin,
				amp: 0.1/3,
				pan: pan,
				legato:len * 1.5,
				ply: ply
			).play;
		};

		"knots-------".postln;
		knots.do { |k|
			var event, spin;
			var pos = k[\position];
			pos = pos - knotpos;
			knotpos = pos;

			spin = k[\spin];
			event = knotdict[k[\type]];
			k[\type].postln;
			event = event ?? { (note: 10, sustain: 0.05, instrument: \gabor, sustain: 0.04) };
			event.play;
			(pos/100).wait;
		};

	})
}).play
)





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

