%% Short Window
% Created on 12/12/2018 based on 'NoLDV.m'
% -------------------------------------------------------------------------
close all
clearvars
% -------------------------------------------------------------------------
Fs = 20000; % 20 kS/sec
Ts = 1/Fs; % Sampling duration

%% Configuration
% Overall Amplitude Scaling Factor
AmpScale = 0.5;
% Window length, specified in Freq; Length = (1/Freq)*winFact
sFreq = 500; % Start at 500 Hz
eFreq = 30; % End at 30 Hz
winFact = 1.2; %1.4;

% Spacing between signals
spacingInSec = 0.09; %.09

% Carrier Freq, 0 <= cFreq 
cFreq = 30; % 30 Hz

numSigs = 7; %9
reps = 3; % Number repetitions
pauseTimeInSec = 0.5; % Time between repetitions

% Parameters can linearly increase or decrease with freqency index by some proportion
spacDec = 0.05; %was .25 and before that .03;
ampDec = .05; %-.04;

%% Generating signals

% We can tweak this frequency array to edit the perceived pattern ---------
%freqArray = (linspace(sFreq,eFreq,numSigs));  % Linear spacing, 3 steps within each octave, from 20-160Hz
freqArray = (logspace(log10(sFreq),log10(eFreq),numSigs));  % Logarithmic spacing, 3 steps within each octave, from 20-160Hz

% Amplitude tuning factor of the signals ----------------------------------
ampProfile = ones(1,numSigs); % Amplitude profile for each substituent signal
ampProfile = ampProfile.*exp(ampDec*(1:numSigs));   % Exponential profile to make it more comfortable

% Spacing (pause time) between signals ------------------------------------
interSpac = spacingInSec*ones(1,numSigs); % spacing/zero-padding between signals
%interSpac=interSpac.*exp(spacDec*(1:numSigs));

% -------------------------------------------------------------------------
% Pause between signals
zeroSig=zeros(1,round(interSpac(1)*Fs)); 
%zeroSig = zeros(1,pauseTimeInSec * Fs);

% Pause at the end
endSig = zeros(1,pauseTimeInSec*Fs);

% Carrier 
sinSig=cos((0:1/Fs:.6)*2*pi*cFreq); %  ? Hz sin to window for the spread

% -------------------------------------------------------------------------

outSig = zeroSig;
for i=1:length(freqArray) 
%Method 3
    winLen=round(winFact*Fs*(1/freqArray(i)));    % Windowing a sin with certain lengths
%    temp=ampProfile(i)*sinSig(1:winLen).*gausswin(winLen)';  %gausswin, blackman, hann seem to work best

    %fade = round(winLen/4);
    %mywin = hann(2*fade); % Hanning window
    %winSig = [mywin(1:fade)' ones(1,winLen-2*fade) mywin((fade+1):2*fade)'];
    
    winSig = gausswin(winLen)'; % Gaussian window
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

%% Visualize the output
t = Ts:Ts:length(outSig)/Fs;
figure('Position',[120,150,1600,760]); 
subplot(1,2,1); plot(t,outSig); xlabel('Seconds'); ylabel('Voltage')
subplot(1,2,2); spectrogram(outSig,2048,1024,4096,Fs,'yaxis'); ylim([0 2]);

%% Output the signal
signalAmp = 1; % Referenced to 10V
outQueue = signalAmp*repmat(outSig,[1,reps]);

sNI = daq.createSession('ni');
addAnalogOutputChannel(sNI,'Dev3','ao0','Voltage');
sNI.Rate = Fs;
queueOutputData(sNI,outQueue');
sNI.startForeground; 
sNI.stop;
