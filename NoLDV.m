close all
clearvars

sNI = daq.createSession('ni');

Fs = 20000; % 40 kS/sec
Ts = 1/Fs; % Sampling duration
%t = 0:Ts:40; % 20 sec total length

sFreq=30;
eFreq=150;
numSigs=9;

freqArray = fliplr(logspace(log10(sFreq),log10(eFreq),numSigs));  % Logarithmic spacing, 3 steps within each octave, from 20-160Hz
% We can tweak this array to edit the perceived pattern
% freqArray = logspace(log10(sFreq),log10(eFreq),5);

cycleNum = 2*ones(1,numSigs); % Number of cycles for each BP Noise
% We can edit cycleNum to a custom array to change the relative lengths of
% each individual signal
cycDec = -.02;

interSpac=.060*ones(1,numSigs); % spacing/zero-padding between signals
spacDec = -.04;

ampProfile = ones(1,numSigs); % Amplitude profile for each substituent signal
ampDec = -.03;

winFact = 1.4;

cycleNum = cycleNum.*freqArray/(1*sFreq);   % Each signal has same length
cycleNum = cycleNum.*exp(cycDec*(1:numSigs));   % Each signal has changing length
ampProfile=ampProfile.*exp(ampDec*(1:numSigs));   % Exponential profile to make it more comfortable
%interSpac=interSpac.*exp(spacDec*(1:numSigs));


zeroSig=zeros(1,round(interSpac(1)*Fs));
outSig=zeroSig;
endSig=zeros(1,0.6*Fs);

sinSig=sin((1/Fs:1/Fs:.3)*2*pi*20); % 20Hz sin to window for the spread
rectSig=ones(.3*Fs);

for i=1:length(freqArray)

% Method 1
    band_width = (0.1*freqArray(i));
    RN_sig = randn(round(cycleNum(i)*Fs/freqArray(i)),1)';
    temp = bandpass(RN_sig,[freqArray(i)-band_width,...
                freqArray(i)+band_width],Fs,...
                'ImpulseResponse','iir','Steepness',0.8);
    temp = ampProfile(i)*temp/max(temp);    % Normalizing and setting the amplitude profile
   

% % Method 2  
%    time=linspace(0,cycleNum(i)/freqArray(i),round(cycleNum(i)*Fs/freqArray(i)));
%    temp=ampProfile(i)*sin(time*2*pi*freqArray(i));   % sine signals instead of BP Noise
   
   
% %Method 3
%     winLen=round(winFact*Fs*1*(1/freqArray(i)));    % Windowing a sin with certain lengths
%     temp=ampProfile(i)*sinSig(1:winLen).*gausswin(winLen)';  %gausswin, blackman, hann seem to work best
%     
%     temp=[temp zeros(1,Fs*.015)]+[zeros(1,Fs*.015) temp];
     
    zeroSig=zeros(1,round(interSpac(i)*Fs));
    outSig=[outSig temp zeroSig];
end
outSig=[outSig endSig];

t=Ts:Ts:length(outSig)/Fs;
figure; plot(t,outSig);xlabel('Seconds');ylabel('Voltage')

figure; spectrogram(outSig,2048,1024,4096,Fs,'yaxis');


% your signal: outQueue
signalAmp = 1; % Referenced to 10V

%x = ((0.5*sineP2PAmp)*sin(2*pi*50*t)+(0.5*sineP2PAmp))';
reps=25;
outQueue = signalAmp*repmat(outSig,[1,reps]);
%outQueue(x>0.5*sineP2PAmp)=1;

addAnalogOutputChannel(sNI,'Dev3','ao0','Voltage');

sNI.Rate = Fs;

queueOutputData(sNI,outQueue');

sNI.startForeground; 

sNI.stop;

% Audio amp alternative to NI card - connect to 3.5 mm jack
% audPlayer = audioplayer(outQueue,Fs);
% play(audPlayer);
