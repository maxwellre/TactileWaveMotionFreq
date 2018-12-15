%% Test Frequency Based Apparent Motion Effect with Single Actuator
% Created on 12/14/2018 based on 'SWindow.m'
% -------------------------------------------------------------------------
close all
clearvars
% -------------------------------------------------------------------------
Fs = 20000; % 20 kS/sec sampling frequency

% Signal Configuration ----------------------------------------------------
% Overall Amplitude Scaling Factor
AmpScale = 1; 
% Window length, specified in Freq; Length = (1/Freq)*winFact
sFreq = 37; % Start at 37 Hz
eFreq = 500; % End at 500 Hz
winFact = 4; % 1.2 ~ 1.4 (or 4);

% Spacing between signals
spacingInSec = 0.1; % 0.1 (secs)

% Carrier Freq, 0 <= cFreq 
cFreq = 35; % ~30 +/- 5 Hz

% High-pass filter each signal
hpFreq = 0.8*cFreq; % 0.8*carrierFrequency

numSigs = 10; % Number of signals

pauseTimeInSec = 0.5; % Time between repetitions (secs)

% Parameters can linearly increase or decrease with freqency index by some proportion
ampDec = -.08; % -0.04;

% Add some white noise?
noise_level = 0.05;

%% Generate signals
% We can tweak this frequency array to edit the perceived pattern ---------
freqArray = (logspace(log10(sFreq),log10(eFreq),numSigs));  % Logarithmic spacing

% Amplitude tuning factor of the signals ----------------------------------
ampProfile = ones(1,numSigs); % Amplitude profile for each substituent signal
ampProfile = ampProfile.*exp(ampDec*(1:numSigs)); % Exponential profile to make it more comfortable

% Spacing (pause time) between signals ------------------------------------
zeroSig = zeros(1,round(spacingInSec*Fs)); 

% Carrier -----------------------------------------------------------------
phase_shift = 1.3*pi; % Shift the phase of the carrier to make it feel more natural
sinSig = cos((0:1/Fs:.6)*2*pi*cFreq + phase_shift); %  ? Hz sin to window for the spread

% Pause at the beginning and the end --------------------------------------
pauseSig = zeros(1,round(pauseTimeInSec*Fs));

% -------------------------------------------------------------------------
winLenArray = round(winFact.*(Fs./freqArray));  

sigSeg = cell(numSigs,2); % Segment of individual signals
for i = 1:numSigs
    winLen = winLenArray(i); % Windowing a sin with certain lengths
    
    winSig = gausswin(winLen)'; % Gaussian window
    
    carrier = sinSig(1:winLen);
    
    temp = AmpScale * ampProfile(i)*carrier.*winSig; 
    
    temp = highpass(temp,hpFreq,Fs); % High-pass filtering
    
    sigSeg{i,1} = temp;
    sigSeg{i,2} = sprintf('%.0fHz',freqArray(i));
end

% Signal A: Spreading to the whole hand -> Localized at tip of index finger
sigA = [];
for i = 1:numSigs
    sigA = [sigA, sigSeg{i,1}, zeroSig];
end
sigA = [pauseSig, sigA, pauseSig];

% Signal B: Localized at tip of index finger -> spreading to the whole hand.
sigB = [];
for i = 1:numSigs
    sigB = [sigB, sigSeg{numSigs-i+1,1}, zeroSig];
end
sigB = [pauseSig, sigB, pauseSig];

