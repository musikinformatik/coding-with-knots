
a = [];
~allQuipus.values.do { |y|  ~traverse.(y, { |x| a = a.add(x) }) };

a.size
a.choose
a.count { |x| x[\position].notNil }

k = [];
~allQuipus.values.do { |y, i|  ~traverse.(y, { |x| if(x[\knots].notNil) { k = k.addAll(x[\knots].collect({ |x| x[\iid] = i; x })) } }) };
k.size
k.count { |x| x[\position].notNil }



(
Tdef(\x, {
	k.do { |x|
		(instrument: \gabor, note: x[\position] + x[\iid].postln, sustain: 0.006, width:0.3).play;
		0.003.wait;
	}
}).play
)



// dubious audification example

~positions = k.collect { |x| x[\position] };
~buf = Buffer.sendCollection(s, ~positions);
~buf.numFrames; // 25740 = 0.5 sec

~positions.as(IdentitySet).as(Array).sort.keep(-8)

(
Ndef(\x, {
	var pos;
	pos = PlayBuf.ar(1, ~buf, 1);
	Limiter.ar(pos, 0.1);
}).play;
)

(
Ndef(\x, {
	var pos;
	pos = PlayBuf.ar(1, ~buf, rate: MouseX.kr(0.001, 1, 1), loop:1).poll;
	SinOsc.ar(pos.linexp(0, 67, 400, 9000)) * 0.1
}).play;
)
