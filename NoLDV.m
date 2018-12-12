close all
clearvars

sNI = daq.createSession('ni');

Fs = 20000; % 40 kS/sec
Ts = 1/Fs; % Sampling duration
%t = 0:Ts:40; % 20 sec total length
% Overall Amplitude Scaling Factor
AmpScale = 0.5;
% Window length, specified in Freq; Length = (1/Freq)*winFact
sFreq=500;%500
eFreq=30;%30
winFact = 1.2; %1.4;
% Spacing between signals
spacingInSec = 0.09;%.09
% Carrier Freq, 0 <= cFreq 
cFreq=30;%30

numSigs=7;%9
reps=3; % Number repetitions
pauseTimeInSec = 0.5; % Time between repetitions

% Parameters can linearly increas or decrease with freqency index by some proportion
cycDec = 0; %-.02;
spacDec = 0.05; %was .25 and before that .03;
ampDec = .05; %-.04;

%freqArray = (linspace(sFreq,eFreq,numSigs));  % Logarithmic spacing, 3 steps within each octave, from 20-160Hz
freqArray = (logspace(log10(sFreq),log10(eFreq),numSigs));  % Logarithmic spacing, 3 steps within each octave, from 20-160Hz
% We can tweak this array to edit the perceived pattern
% freqArray = logspace(log10(sFreq),log10(eFreq),5);

cycleNum = 2*ones(1,numSigs); % Number of cycles for each BP Noise
% We can edit cycleNum to a custom array to change the relative lengths of
% each individual signal

interSpac=spacingInSec*ones(1,numSigs); % spacing/zero-padding between signals

ampProfile = ones(1,numSigs); % Amplitude profile for each substituent signal


%cycleNum = cycleNum.*freqArray/(1*sFreq);   % Each signal has same length
cycleNum = cycleNum.*exp(cycDec*(1:numSigs));   % Each signal has changing length
ampProfile=ampProfile.*exp(ampDec*(1:numSigs));   % Exponential profile to make it more comfortable
%interSpac=interSpac.*exp(spacDec*(1:numSigs));


zeroSig=zeros(1,round(interSpac(1)*Fs));
%zeroSig = zeros(1,pauseTimeInSec * Fs);
outSig=zeroSig;
endSig=zeros(1,pauseTimeInSec*Fs);

%sinSig=sin((1/Fs:1/Fs:.3)*2*pi*cFreq); %  20Hz sin to window for the spread
sinSig=cos((1/Fs:1/Fs:.6)*2*pi*cFreq); %  20Hz sin to window for the spread

rectSig=ones(.3*Fs);

for i=1:length(freqArray)

% % Method 1
%     band_width = (0.1*freqArray(i));
%     RN_sig = randn(round(cycleNum(i)*Fs/freqArray(i)),1)';
%     temp = bandpass(RN_sig,[freqArray(i)-band_width,...
%                 freqArray(i)+band_width],Fs,...
%                 'ImpulseResponse','iir','Steepness',0.8);
%     temp = ampProfile(i)*temp/max(temp);    % Normalizing and setting the amplitude profile
   

% % Method 2  
%    time=linspace(0,cycleNum(i)/freqArray(i),round(cycleNum(i)*Fs/freqArray(i)));
%    temp=ampProfile(i)*sin(time*2*pi*freqArray(i));   % sine signals instead of BP Noise
   
   
%Method 3
    winLen=round(winFact*Fs*(1/freqArray(i)));    % Windowing a sin with certain lengths
%    temp=ampProfile(i)*sinSig(1:winLen).*gausswin(winLen)';  %gausswin, blackman, hann seem to work best
    %fade = round(winLen/4);
    %mywin = hann(2*fade); 
    %winSig = [mywin(1:fade)' ones(1,winLen-2*fade) mywin((fade+1):2*fade)'];
    winSig = gausswin(winLen)';
    %winSig = [linspace(0,1,fade) ones(1,winLen-2*fade) linspace(0,1,fade)];
    carrier = sinSig(1:winLen);
   % ic = carrier > 0; pc = carrier < 0; carrier = ic - pc;
   %carrier = abs(carrier).^(1/4) .* sign(carrier); 
   temp=AmpScale * ampProfile(i)*carrier.*winSig;  %gausswin, blackman, hann seem to work best
    
    % temp=[temp zeros(1,Fs*.015)]+[zeros(1,Fs*.015) temp];   % All pass filtering

    
    zeroSig=zeros(1,round(interSpac(i)*Fs));
    outSig=[outSig temp zeroSig];
end
outSig=[outSig endSig];

t=Ts:Ts:length(outSig)/Fs;
figure; plot(t,outSig);xlabel('Seconds');ylabel('Voltage')

%figure; spectrogram(outSig,2048,1024,4096,Fs,'yaxis');


% your signal: outQueue
signalAmp = 1; % Referenced to 10V

%x = ((0.5*sineP2PAmp)*sin(2*pi*50*t)+(0.5*sineP2PAmp))';
outQueue = signalAmp*repmat(outSig,[1,reps]);
%outQueue = signalAmp * 
%outQueue(x>0.5*sineP2PAmp)=1;

addAnalogOutputChannel(sNI,'Dev3','ao0','Voltage');
sNI.Rate = Fs;
queueOutputData(sNI,outQueue');
sNI.startForeground; 
sNI.stop;

% Audio amp alternative to NI card - connect to 3.5 mm jack
% audPlayer = audioplayer(outQueue,Fs);
% play(audPlayer);
