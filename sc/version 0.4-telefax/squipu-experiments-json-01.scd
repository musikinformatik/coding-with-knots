/*

Sonifications using the json format

*/

(
loadRelative("scquipu-lib.scd");
loadRelative("scquipu-load-all.scd");


SynthDef(\sin, { |out, freq = 440, sustain = 1, pan, amp = 0.1, ply|
	var attack = blend(0.01, 0.99, ply);
	var release = blend(1, 0, ply);
	var env = EnvGen.ar(Env.perc(attack, release, amp * 3), timeScale: sustain * (440/freq), doneAction:2);
	var son = SinOsc.ar(freq);
	OffsetOut.ar(out, Pan2.ar(son, pan, env * AmpCompA.kr(freq)));
}).add;


SynthDef(\gabor, { |out, freq = 440, sustain = 1, pan, amp = 0.1, width = 0.3|
	var env = LFGauss.ar(sustain * (440/freq), width, loop:0, doneAction:2).range;
	var son = SinOsc.ar(freq);
	OffsetOut.ar(out, Pan2.ar(son, pan, env * (amp * 2 * AmpCompA.kr(freq))));
}).add;


~data = ~get.(\UR006);
)


/*
~data = ~get.(\UR004);
~data = ~get.(\HP019);
~data = ~get.(\UR019);

// boring quipu
~data = ~get.(\UR046);

// astronomical quipu
~data = ~get.(\UR006);
~data = ~get.(\UR009);

// variants of administrative quipus
~data = ~get.(\UR066);
~data = ~get.(\UR067);
~data = ~get.(\UR068);

~data = ~get.(\UR051);
~data = ~get.(\UR015);
*/

~traverse.(~data, { |x| x[\colours].postln }); "";
~traverse.(~data, { |x, l| x[\knots].size.post; " ".post; }); "";


// which data fields are there?
~postInfo.(~data);
~allValues.(~data).keys;

~data = ~get.(\UR139);




// SONIFICATIONS


// 1. COLOUR //


// inka telefax: traversal
(
Tdef(\x, {
	~traverse.(~data, { |x|
		var note = x[\colours] / 255 * 32;
		if(note.notEmpty) {
			(note:note.flat, sustain: 0.13, instrument: \sin).play;
		};
		0.12.wait;
	})
}).play
)

// faster
(
Tdef(\x, {
	~traverse.(~data, { |x|
		var note = x[\colours] / 255 * 32;
		if(note.notEmpty) {
			(note:note.flat, sustain: 0.13, instrument: \sin).play;
		};
		0.05.wait;
	})
}).play
)

// different frequency scaling
(
Tdef(\x, {
	~traverse.(~data, { |x|
		var note = x[\colours] / 255 * 32;
		if(note.notEmpty) {
			(note:note.flat, octaveRatio: 2.3, sustain: 0.13, instrument: \sin).play;
		};
		0.05.wait;
	})
}).play
)


(
Tdef(\x, {
	~traverse.(~data, { |x, level|
		var c = x[\colours].collect(~coloursHSV).flop;
		var hues = c.at(0);
		var sat = c.at(1);
		var note = hues.expexp(0.001, 1, 1, 25) - 1;
		var sustain = (30/(note + 60).midicps) * (sat * 2 + 1);
		if(note.notEmpty) {
			(
				note:note,
				sustain: sustain,
				instrument: \sin, pan: level.linlin(0, 7, -1, 1), strum:0.04).play;
		};
		0.14.wait;
	})
}).play
)




// mapped colours
(
Tdef(\x, {
	~colDict = ~mapValues.(~data, \colours);
	~traverse.(~data, { |x|
		var note = x[\colours].collect { |c| ~colDict.at(c) };
		if(note.notEmpty) {
			(degree:note,  scale: Scale.at(\hexMajor7), sustain: 0.13, instrument: \sins).play;
		};
		0.05.wait;
	})
}).play
)

// with knots
(
Tdef(\x, {
	~colDict = ~mapValues.(~data, \colours);
	~traverse.(~data, { |x|
		var note = x[\colours].collect { |c| ~colDict.at(c) };
		var harmonics = if(x[\knots].notEmpty) { x[\knots].collect(_[\value]) ? 1 } { 1 }.postln;
		if(note.notEmpty) {
			(degree:note, harmonic:harmonics, sustain: 0.13, instrument: \sin, scale: Scale.at(\hexMajor7)).play;
		};
		0.05.wait;
	})
}).play
)


// with knots, slowly, and sorted colours
// adding ply
(
Tdef(\x, {
	var plyi = ('S': -1, 'Z': 1, 'U': 0);
	~colDict = ~mapValues.(~data, \colours, { |a, b| ~coloursHSV.(a).first >~coloursHSV.(b).first } );
	~satDict = ~colDict.collect { |note, col| ~coloursHSV.(col).at(1) };
	~traverse.(~data, { |x, level|
		var note = x[\colours].collect { |c| ~colDict.at(c) };
		var sat =  x[\colours].collect { |c| ~satDict.at(c) }.postln;
		var harmonics = if(x[\knots].notEmpty) { x[\knots].collect(_[\value]) ? 1.0 };
		harmonics = if(harmonics.isNil) { 1 } { if(harmonics.includes(1.0)) { harmonics } { harmonics ++ 1 }};
		"note: %, harmonics: %\n".postf(note, harmonics);
		if(note.notEmpty) {
			(
				degree:note,
				harmonic:harmonics,
				//ctranspose: level,
				sustain: 0.3,
				scale: Scale.at(\hexMajor7),
				amp: sat * 0.5,
				instrument: \sin,
				pan: plyi[x[\ply]]
			).play;
		};
		0.12.wait;
		//(0.5 / (2 ** level)).wait;
	})
}).play
)




// a short travel
(
Tdef(\x, {
	~all.scramble.do { |d|
		~postInfoFor.(d[\quipuName]);
		~traverse.(d, { |x, level|
			var note = x[\colours] / 255 * 32;
			if(note.notEmpty) {
				(
					note:note,
					octaveRatio: 2.3,
					sustain: 0.03,
					root:-5,
					instrument: \gabor,
					width: 0.4,
					amp: 0.2,
					pan: level.linlin(0, 4, -1, 1)
				).play;
			};
			0.02.wait;
		});
		rrand(4, 2.0).wait;
	};
}).play
)

// a short travel 2
(
Tdef(\x, {
	~all.scramble.do { |d|
		~postInfoFor.(d[\quipuName]);
		~traverse.(d, { |x, level|
			var note = x[\colours] / 255 * 32;
			if(note.notEmpty) {
				(note:note, octaveRatio: 2.3, sustain: 0.03, root:-5, instrument: \gabor, width: 0.1, pan: level / 5).play;
			};
			0.02.wait;
		});
		rrand(4, 2.0).wait;
	};
}).play
)




~startTelefax.value;

~stopTelefax.value;


(
Tdef(\x, {
	var pani = ('R':-1, 'V':1, 'U':0);
	var plyi = ('S': 0, 'Z': 1, 'U': 0.5);
	~traverse.(~data, { |x, level|
		var colours = x[\colours], note, pan, ply, len;
		var dur;
		//x[\value].postln;
		dur = 1/2 ** (level - 1);
		dur = (dur / 10);
		dur.wait;

		//x.postcs;
		//String.fill(level, Char.space).post; level.postln;
		if(colours.notEmpty) {
			pan = pani[x[\attach]];
			ply = plyi[x[\ply]];
			note = x[\colours] / 255 * 36 + 12;
			(
				note:note,
				dur: dur,
				instrument: \sin,
				amp: 0.1/3,
				pan: pan,
				legato: 1.5,
				ply: ply
			).play;
		};

	})
}).play
)





// KNOTS ////////////


(
Tdef(\x, {
	~traverse.(~data, { |x, level|
		var knots = x[\knots];
		knots.do { |k|
			var note, pan;
			note = k[\value];
			pan = k[\spin];
			(
				note:note,
				harmonic: k[\position],
				sustain: 0.01,
				instrument: \sin,
				sustain: 0.4,
				pan: pan
			).play;
		};
		0.1.wait;
	})
}).play
)


(
Tdef(\x, {
	~traverseWidthFirst.(~data, { |x, level|
		var knots = x[\knots];
		knots.do { |k|
			var note, pan;
			note = k[\value];
			pan = k[\spin];
			(
				note:note,
				harmonic: k[\position],
				sustain: 0.01,
				instrument: \sin,
				sustain: 0.4,
				pan: pan
			).play;
		};
		0.1.wait;
	})
}).play
)




(
Tdef(\x, {
	var dict = (
		'S': (note: 0, octave: 4, sustain: 0.01, instrument: \sin, sustain: 0.4),
		'Z': (note: 0, octave: 5, sustain: 0.01, instrument: \sin, sustain: 0.4),
		'U': (note: 0, octave: 6, sustain: 0.01, instrument: \sin, sustain: 0.4)
	);
	var noSpin = (note: \rest, sustain: 0.01, instrument: \sin, sustain: 0.04);
	~traverse.(~data, { |x, level|
		var knots = x[\knots];
		knots.do { |k|
			var event, spin;
			spin = k[\spin];
			event = dict[spin] ? noSpin;
			event = event.copy;
			event.put(\harmonic, k[\position] * 0.01 + 1);
			event.play;
			0.1.wait;
			//event[\dur].wait;
		};
		0.2.wait;
	});
}).play
)




