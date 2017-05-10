// startup file. Run when supercollider starts
// load this from the supercollider startup file

Server.default.options.numOutputBusChannels = 2; // INSTALLATION IS 3 CHANNEL, USE STEREO HERE
s.boot;

~numChannels = 2; // change this for the installation to 3

loadRelative("scquipu-lib.scd");
loadRelative("scquipu-load-all.scd");


/*

Startup and Remote Access

*/

(
~startTelefax = {
	loadRelative("inca-telefax-autostart.scd")
};

~stopTelefax = {
	CmdPeriod.run;
	SkipJack.stopAll;
};

// run this from remote OSC message to port 57125
// "/start"
(
OSCdef(\start, {

	~startTelefax.value

}, "/start", recvPort:57125).fix
);

(
OSCdef(\stop, {

	~stopTelefax.value

}, "/stop", recvPort:57125).fix
);

);


"------- * quipu startup finished * -----------".postln;"";

/*

scheduler

*/


// 9:59am, I guess this can be adjusted
// monday, wednesday, friday

// this should be the one
{
	var count = 0;
	SkipJack.stopAll;
	SkipJack({
		var date = Date.getDate;
		if(count % 120 == 0) { "----- %\nInca Telefax is waiting for the right moment -----\n".postf(date) };
		count = count + 1;
		// monday, wednesday, friday
		if(
			#[0, 2, 4].includes(date.dayOfWeek)
			and:
			{ date.hour == 9 }
			and:
			{ date.minute == 59 }
		) {

			loadRelative("inca-telefax-autostart.scd");

		};
	});
}.value


/*

to stop scheduler, call:

SkipJack.stopAll;

*/

