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
AmpScale = 1; 
% Window length, specified in Freq; Length = (1/Freq)*winFact
sFreq = 500; % Start at 500 Hz
eFreq = 37; % End at 30 Hz
winFact = 4; % 1.2 ~ 1.4;

% Spacing between signals
spacingInSec = 0.11; % 0.09 (secs)

% Carrier Freq, 0 <= cFreq 
cFreq = 35; % ~30 +/- 5 Hz

% High-pass filter each signal
hpFreq = 0.8*cFreq; % 0.8*carrierFrequency

numSigs = 10; %9
reps = 2; % Number repetitions
pauseTimeInSec = 1.28; % Time between repetitions (0.5 secs)

% Parameters can linearly increase or decrease with freqency index by some proportion
% spacDec = 0.05; % was 0.25 and before that 0.03;
ampDec = -.08; % -0.04;

% Add some white noise?
noise_level = 0.05;

%% Generating signals

% We can tweak this frequency array to edit the perceived pattern ---------
%freqArray = (linspace(sFreq,eFreq,numSigs));  % Linear spacing, 3 steps within each octave, from 20-160Hz
freqArray = (logspace(log10(sFreq),log10(eFreq),numSigs));  % Logarithmic spacing, 3 steps within each octave, from 20-160Hz

% Amplitude tuning factor of the signals ----------------------------------
ampProfile = ones(1,numSigs); % Amplitude profile for each substituent signal
ampProfile = ampProfile.*exp(ampDec*(1:numSigs)); % Exponential profile to make it more comfortable

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
phase_shift = 1.3*pi;
sinSig = cos((0:1/Fs:.6)*2*pi*cFreq + phase_shift); %  ? Hz sin to window for the spread

% -------------------------------------------------------------------------
winLenArray = round(winFact.*(Fs./freqArray));  

outSig = zeroSig;
for i=1:length(freqArray) 
%Method 3
    winLen = winLenArray(i); % Windowing a sin with certain lengths
    
    %fade = round(winLen/4); mywin = hann(2*fade); % Hanning window
    %winSig = [mywin(1:fade)' ones(1,winLen-2*fade) mywin((fade+1):2*fade)'];
    
    winSig = gausswin(winLen)'; % Gaussian window
    %winSig = [linspace(0,1,fade) ones(1,winLen-2*fade) linspace(0,1,fade)];
    
    carrier = sinSig(1:winLen);
   % ic = carrier > 0; pc = carrier < 0; carrier = ic - pc;
   %carrier = abs(carrier).^(1/4) .* sign(carrier); 
   temp = AmpScale * ampProfile(i)*carrier.*winSig;  %gausswin, blackman, hann seem to work best

   temp = highpass(temp,hpFreq,Fs); % High-pass filtering
   
   temp = temp + noise_level*randn(size(temp)); % Add white Gaussian noise?
    
    % temp=[temp zeros(1,Fs*.015)]+[zeros(1,Fs*.015) temp];   % All pass filtering
    
    zeroSig=zeros(1,round(interSpac(i)*Fs));
    outSig=[outSig temp zeroSig];
end
outSig=[outSig endSig];

%% Add reversed part
if 1 % ------------------------------------------------------------- switch
freqArray2 = fliplr(freqArray); % Reverse the direction
ampProfile2 = fliplr(ampProfile);
interSpac2 = fliplr(interSpac);

winLenArray = round(winFact.*Fs.*(1./freqArray2)); 
for i=1:length(freqArray2) 
%Method 3
    winLen = winLenArray(i); % Windowing a sin with certain lengths
    
    winSig = gausswin(winLen)'; % Gaussian window
    %winSig = [linspace(0,1,fade) ones(1,winLen-2*fade) linspace(0,1,fade)];
    
    carrier = sinSig(1:winLen);
   % ic = carrier > 0; pc = carrier < 0; carrier = ic - pc;
   %carrier = abs(carrier).^(1/4) .* sign(carrier); 
   temp = AmpScale * ampProfile2(i)*carrier.*winSig;  %gausswin, blackman, hann seem to work best
   
   temp = highpass(temp,hpFreq,Fs); % High-pass filtering
   
   temp = temp + noise_level*randn(size(temp)); % Add white Gaussian noise?
    
    % temp=[temp zeros(1,Fs*.015)]+[zeros(1,Fs*.015) temp];   % All pass filtering
    
    zeroSig=zeros(1,round(interSpac2(i)*Fs));
    outSig=[outSig temp zeroSig];
end
outSig=[outSig endSig];
end % ---------------------------------------------------------- switch end

%% Visualize the output
t = Ts:Ts:length(outSig)/Fs;
figure('Position',[120,150,1600,760], 'Name',...
    ['Signal sequence: ',sprintf(' %.0f Hz ',[freqArray,freqArray2])]); 
subplot(1,2,1); plot(t,outSig); xlabel('Seconds'); ylabel('Voltage')
subplot(1,2,2); spectrogram(outSig,1024,960,1024,Fs,'yaxis'); ylim([0 1.6]);

%% Output the signal
signalAmp = 1; % Referenced to 10V
outQueue = signalAmp*repmat(outSig,[1,reps]);

sNI = daq.createSession('ni');
addAnalogOutputChannel(sNI,'Dev3','ao0','Voltage');
sNI.Rate = Fs;
queueOutputData(sNI,outQueue');
sNI.startForeground; 
sNI.stop;
