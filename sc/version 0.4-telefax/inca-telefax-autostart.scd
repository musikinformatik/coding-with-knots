// inca telefax autostart


(
// astronomical quipu

loadRelative("scquipu-lib.scd");

// later, I'd like to test this as a startup
//loadRelative("scquipu-load-all.scd");

//if(~all.asArray.isEmpty) { ~all = [~getQuipuData.("json/UR006.json".resolveRelative)] };

//~all = [~getQuipuData.("json/HP025.json".resolveRelative)];

/*
SynthDef(\sin, { |channel, freq = 440, sustain = 1, amp = 0.1, ply|
var pan = channel.linlin(0, 2, -1, 1);
var attack = blend(0, 1, ply) * sustain;
var release = blend(1, 0, ply) * sustain;
var env = EnvGen.ar(Env.new([0, amp * 3, 0], [attack, release]), doneAction:2);
var son = SinOsc.ar(freq);
Out.ar(0, Pan2.ar(son, pan, env * AmpCompA.kr(freq)));
}).add;
*/

~cable.release;
~cable = {
	var in = In.ar(0, ~numChannels);
	ReplaceOut.ar(0, HPF.ar(LPF.ar(in, 8000), 100))
}.play(s, 0, 0.1, addAction:\addAfter);



SynthDef(\sin, { |out, freq = 440, sustain = 1, amp = 0.1, ply|
	var env, son;
	var att = 5/freq;
	env = EnvGen.ar(
		Env.linen(Rand(1, 0.5) * att, sustain, Rand(1, 0.5) * att, amp * 10, -3),
		doneAction:2
	);
	freq = freq * Select.ar(ply, [DC.ar(1), XLine.ar(1.25, 1, sustain), XLine.ar(1, 1.25, sustain)]);
	son = SinOsc.ar(freq, 0.5pi);
	Out.ar(out, son * env * AmpCompA.kr(freq));
}).add;

/*
SynthDef(\knot, { |out, freq = 440, sustain = 1, amp = 0.1, ffreq, mod|
	var env = EnvGen.ar(Env.linen(0.01, sustain, 0.02, amp * 10, -3), doneAction:2);
	var son = SinOsc.ar(freq, 0.5pi) * SinOsc.ar(ffreq).range(0, min(mod, 1));
	Out.ar(out, son * env * AmpCompA.kr(freq));
}).add;
*/

SynthDef(\knot, { |out, freq = 440, sustain = 1, amp = 0.1, ffreq, mod|
	var env, son;
//	env = EnvGen.ar(Env.linen(0.001, sustain, 0.02, amp * 5, -3), doneAction:2);
	env = EnvGen.ar(Env.perc(0.001, sustain, amp * 5, -3), doneAction:2);
	son = SinOsc.ar(freq, 0.5pi + SinOsc.ar(ffreq, 0, mod));
	Out.ar(out, son * env * AmpCompA.kr(freq));
}).add;

SynthDef(\nothing, { |out, sustain = 1, amp = 1|
	var env = EnvGen.ar(Env.linen(0, sustain, 0, amp), doneAction:2);
	var son = GrayNoise.ar;
	Out.ar(out, son * env);
}).add;



/*
// this one will be for the three channel version
SynthDef(\sin3, { |channel, freq = 440, sustain = 1, amp = 0.1, ply|
var attack = blend(0, 1, ply) * sustain;
var release = blend(1, 0, ply) * sustain;
var env = EnvGen.ar(Env.new([0, amp * 3, 0], [attack, release]), doneAction:2);
var son = SinOsc.ar(freq);
Out.ar(channel, son * env * AmpCompA.kr(freq));
}).add;
*/



/*

data dimensions

ply: 'S', 'Z', 'U'
attach:
children
colours
knots
id


if there is a knot:

spin: 'S', 'N', 'DIR', 'Z', 'U' ... (?)
value: 1..9
type: 'S', 'EE', 'E', 'IR', .... (?)
position: 1.5 .. 60 cm

*/





Tdef(\x, {

	var numberOfChannels = ~numChannels;

	var timeLimit = 30; // scale to
	var speed = 4.2;

	var attach = ('R':0, 'V':1, 'U':2);
	var plyi = ('S': 0, 'Z': 1, 'U': 2);
	var knottype = ('S': 0, 'EE':3, 'E':2, 'IR':1);
	var timeFactor, totalTime;

	var f0 = 425 * [1, 2, 4].choose; // dial tone Europe transposed
	//var notebase = rrand(1.9, 2.3);
	var noterange = 3; // octaves
	var timebase = 2; //rrand(0.12, 0.2);
	var legato = 1; //rrand(0.9, 1.0);
	var data;
	var channelOffsets = (0..numberOfChannels-1).scramble.keep(2);
	var amp = 0.1 / 3;
	var prevLevel = 0;

	data = ~all.choose;


	// precalculate a time stretching factor
	// to play the part within the timeLimit

	totalTime = 0.0;

	~traverse.(data, { |x, level|
		totalTime = totalTime + (timebase ** (level - 1) / speed);
	});
	timeFactor = min(1.0, (timeLimit / totalTime));

	"--------------------------------------\n"
	"now playing quipu '%'.\n"
	"it will be playing for % sec,\nat a base frequency of % Hz\n"
	"lowest possible freq at % Hz\n"
	"---------------------------------------\n\n"
	.postf(data[\quipuName], timeFactor * totalTime, round(f0, 0.01), f0 / (noterange + 1 * (6 - 2)));


	// traverse the graph and play the nodes

	~traverse.(data, { |x, level, index|

		var colours = x[\colours];
		var knots = x[\knots];
		var channel = attach[x[\attach]] ? 0;
		var ply = plyi[x[\ply]];
		var len = min(1, x[\position] ? 30 / 30); // usually nil.
		var numBranches = x[\children].size;
		var dur, sustain, numColours;

		dur = timebase ** (level - 1) / speed;
		dur = (dur * timeFactor);
		sustain = len * dur * legato;

		if(ply == '?') {
			"----------------**********-------------".postln;
		};

		if(colours.notEmpty) {

			fork {
				//colours.postln;

				numColours = x[\colours].size;
				x[\colours].do { |colour|
					var dt = sustain / numColours;
					var note = colour / 255 * noterange;
					var freq = f0 / ( (note + 1) * (level - 2).max(1) );
					(
						freq: freq,
						sustain: dt,
						instrument: \sin,
						amp: amp,
						out: channelOffsets.wrapAt(level),
						ply: ply
					).play;
					//dt.wait;
				};
			};
		};

		if(knots.notEmpty) {
			fork {
				var positions, diffs, size;
				if(knots.notNil) {
					size = knots.size;
					// we use the relative distances between the knots
					// as time steps between short FM sounds
					positions = knots.collect { |x| x[\position] };
					diffs = positions.differentiate;

					knots.do { |knot, i|
						var pos = diffs @ i;
						var ppos = diffs |@| i;
						var pscale = min(1, pos / 30);
						var kdur = (pscale * sustain);
						//var moddepth = i / size;
						kdur.wait;
						(
							freq: f0 * 0.5 * (pscale * 2 + 1),
							mod: knottype[knot[\type]] ? 0,
							ffreq: f0 * 2 / ppos,
							out: channelOffsets.wrapAt(channel + level + 1),
							sustain: kdur,
							instrument: \knot,
							amp: amp * 4,
						).play;
					}
				};
			};
		};

		switch(sign(prevLevel - level),
			1, { (dur * 4).wait },
			0, { dur.wait },
			-1, { (dur * 2).wait }
		);

		prevLevel = level;

	});
	"---------- completed '%' ------------\n".postf(data[\quipuName])
}).play;

/*
Ndef(\noise, {
	PinkNoise.ar(0.1 ! 3)
}).play(numChannels:3);
*/

)

