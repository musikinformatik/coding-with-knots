
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

