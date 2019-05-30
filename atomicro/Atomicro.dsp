declare name "Capture 2.0";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

record = checkbox ("h:sfCapture/RECORD");
play = checkbox ("h:sfCapture/PLAY");


// max size of buffer to be recorded
size = 846720; //19.2 seconds


// COUNTER LOOP //////////////////////////////////////////
// sah is like latch but reverse input for a expression
sah(x,c) = x * s : + ~ *(1-s)
with { s = ((c'<=0)&(c>0)); };

speed = vslider ("speed",1,0.25,2,0.001):fi.lowpass(1,1):max(0.25):min(2);

id_count_rec = (0):+~(+(1): * ((fade_in)>0)): min(size+1); // increment de 1 (max = size+1) tant que fade_in > 0

id_count_play =  fmod(_,max(1,int(fin_rec)))~(+(speed): *(play));
//id_count_play = speed : (+ : fmod(_,size)) ~ _  :  int * play;

fin_rec = sah(id_count_rec:mem,fade_in==0);// fin record si le fade est == O
/* envoie un stream de 0
	qd fade in passe de 1 à 0 envoie une impulse de la valeur de l'increment id_count_rec -1 (max = size)
	puis back to stream de 0
*/
			
// FADER IN & OUT ////////////////////////////////////////////////
// define the level of each step increase or decrease to create fade in/out

time_fade = 0.1;

// version linear fade = 0.00023
base_amp = 1,(ma.SR)*(time_fade):/;

fade_in = select2(record,(-1)*(base_amp),base_amp):+~(min((1)-base_amp):max(base_amp));
/*
==> si record = 0 renvoie 0
==> si record = 1 incrément jusqu'à 1 (0,9997)
==> retour à 0 = décrément jusqu'à 0
*/


// BUFFER SEQUENCER //////////////////////////////////////////
wr_index = rwtable(size+1, 0., windex,_, rindex) // le 0. dans rwtable est la valeur de l'init et son type défini le type de la table
	with {
			
			rindex = id_count_play:int;
			windex = id_count_rec:int;
		};


idelay 	= ((+ : de.sdelay(N, interp, dtime)) ~ *(fback))
	with	{
				N = int(2^19); // => max delay = number of sample 
				interp = (75)*ma.SR*(0.001);
				dtime	= vslider("delay", 0, 0, 10000, 0.01)*ma.SR/1000.0;
				fback 	= vslider("feedback",0,0,100,0.1)/100.0; 
			};

dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = vslider("dry_wet",0,0,100,0.01):*(0.01):si.smooth(0.998);
					};

idelay_drywet =  _<: _ , idelay : dry_wet;



process =_,(fade_in):*:wr_index:idelay_drywet:*(volume)
			with {
				volume = hslider("volume",1,-0.1,1,0.001):max(0):min(1):fi.lowpass(1,1);
				};
			
			

//------------------Player type 2 ------------//
//Lecture en boucle avec possibilité de timeStretch et granulation du son
//sampleSize = table size index (i.e given out by waveform 1st output)
//readTable = 'rdtable' object associated with 'waveform'

playType_02(sampleSize,readTable) = hgroup("Player",player_type_02(sampleSize,readTable));

player_type_02(sampleSize,readTable) = index(sampleSize) : readTable;// : sampleCut;

timeStretch(speed, size) = speed : (+ : fmod(_,size)) ~ _  :  int ;
speedVar = hslider("Speed[hidden:1][acc:1 1 -10 0 10]", 1, 0.6, 1.2, 0.01):max(0.2):min(1.5):si.smooth(0.995);
index(sampleSize) =  timeStretch(speedVar, sampleSize);//variation de vitesse de lecture

/*
sampleCut(x) = x*(counter>0.0):si.smooth(0.97) with{
trig = button("Play");
decayTime = hslider("grainSize",sampleSize,0,sampleSize,1);
upfront(x) = (x-x')>0.0;
decay(x) = x - (x>0.0)/decayTime;
decrease = +~decay;
counter = trig : upfront : decrease;
};
*/
// ---------------- Non utilisé ---------------

//sampleSize = I_have_a_dream_one_day_2;
//sizeVar(y) = sampleSize - y : max(200) : min(sampleSize):int;//Variation de la taille du sample => raccourcit le sample
//index =  timeStretch(speedVar, sizeVar(lengthSample));//variation de vitesse de lecture
//indexVar(x) = index + x : max(0) : min(sampleSize - 200):int; //variation de début et fin de lecture
//lengthSample = (sampleSize - (hslider("v:/[2]Size",sampleSize,0,sampleSize,1))):int;//modifie la taille du sample
//positionSample = hslider("v:/[1]Position tete de lecture", 0, 0, (sampleSize-200),1):int;//Deplace le debut de la lecture du sample
//player = I_have_a_dream_one_day_2_rtable_0(indexVar(positionSample)):sampleCut;


//top(s) = select2(reset,1,s);//%1 car division par 1 reste 0 => pour redemarrer l'increment
//top(s) = select2(start,s,1);
//reset = abs(button("[2]Reset")-1);//Inversion 0 et 1
/*start = check : trigger : counter >(0) with{
  check = checkbox("Play/Pause");
  trigger(x) = abs(x-x')>0.5;
  counter(g) = (+(1):*(1-g))~_;
};*/

//switch = checkbox("[1]ON/OFF"):int;//Pour incrementer +1 ou +0, figer la lecture
//indexVar = hslider("Variation", 0, 0, 100000, 1):int;
//index = %(I_have_a_dream_one_day_2:top)~+(switch):+(indexVar);