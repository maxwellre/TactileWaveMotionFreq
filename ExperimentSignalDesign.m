%% Test Frequency Based Motion Effect with Single Actuator
% 2P1Anim (Two Play One Animation)
% Created on 01/21/2018 based on 'PilotStudy_2P1F.m'
% -------------------------------------------------------------------------
close all
clearvars
% -------------------------------------------------------------------------
% Global variable
global outSig
% -------------------------------------------------------------------------
% Experiment Configuration 
figSize = [20,100,1880,800];

TrialNum = 10;

% -------------------------------------------------------------------------
Fs = 20000; % 20 kS/sec sampling frequency

% Signal Configuration ----------------------------------------------------
% Overall Amplitude Scaling Factor
AmpScale = 2; 
% Window length, specified in Freq; Length = (1/Freq)*winFact
sFreq = 12.5; % Start at 37 Hz
eFreq = 340; % End at 500 Hz
winFact = 1; %4 1.2 ~ 1.4 (or 4);
noiseAmp = 0.001;

% Spacing between signals
spacingInSec = 0.095; % 0.1 (secs)

% Carrier Freq, 0 <= cFreq 
cFreq = 25; % ~30 +/- 5 Hz

% High-pass filter each signal
hpFreq = 0.8*cFreq; % 0.8*Carrier-Frequency
lpFreq = 1.5*eFreq; % 1.5*End-Frequency
numSigs = 10; % Number of signals

pauseTimeInSec = 0.5; % Time between repetitions (secs)

% Parameters can linearly increase or decrease with freqency index by some proportion
ampDec = 0.008; 

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
sinSig = cos((0:1/Fs:.6)*2*pi*cFreq + phase_shift); % ? Hz sin to window for the spread

% Pause at the beginning and the end --------------------------------------
pauseSig = zeros(1,round(pauseTimeInSec*Fs));

% -------------------------------------------------------------------------
winLenArray = round(winFact.*(Fs./freqArray));  

sigSeg = cell(numSigs,2); % Segment of individual signals
sigCenterFreq = NaN(numSigs,1);
sigPeakFreq = NaN(numSigs,1);

figure;
for i = 1:numSigs
    winLen = winLenArray(i); % Windowing a sin with certain lengths
    
    winSig = gausswin(winLen)'; % Gaussian window
    
    carrier = sinSig(1:winLen);
    
    temp = AmpScale * ampProfile(i)*carrier.*winSig; 
    
    temp = highpass(temp,hpFreq,Fs); % High-pass filtering 
    temp = lowpass(temp,1000,Fs,'Steepness',0.5); % Low-pass filtering
    
    sigSeg{i,1} = temp;
    sigSeg{i,2} = sprintf('%.0fHz',freqArray(i));
    
    % Compute spectral centroid of each signal
    [sp, f] = spectr(sigSeg{i,1}, Fs, [0 1000]);
    sigCenterFreq(i) = sum(sp.*f')./sum(sp);
    [~,max_ind] = max(sp);
    sigPeakFreq(i) = f(max_ind);
    
    subplot(2,5,i)
    plot(f,sp);
    yRange = ylim();
    hold on
    plot([sigCenterFreq(i) sigCenterFreq(i)],yRange,'r');
    plot([sigPeakFreq(i) sigPeakFreq(i)],yRange,'g');
end

outSig = struct;

% Signal A: Concentrating to the tip of index finger
sigA = [];

for i = 1:numSigs     
    sigA = [sigA, sigSeg{i,1}, zeroSig];
end
outSig.sigA = [pauseSig, sigA, pauseSig];

% Signal B: Spreading to the whole hand.
sigB = [];
for i = 1:numSigs     
    sigB = [sigB, sigSeg{numSigs-i+1,1}, zeroSig];
end
outSig.sigB = [pauseSig, sigB, pauseSig];

% Signal reordered sequence
rs_ind = [5, 8, 2, 9, 4, 6, 3, 10, 1, 7];
% this balances spec in 1st, 2nd half and df considerations

rsA = [];
rsB = [];
for i = 1:numSigs    
    rsA = [rsA, sigSeg{rs_ind(i),1}, zeroSig];
    rsB = [rsB, sigSeg{rs_ind(numSigs-i+1),1}, zeroSig];
end
outSig.rsA = [pauseSig, rsA, pauseSig];
outSig.rsB = [pauseSig, rsB, pauseSig];