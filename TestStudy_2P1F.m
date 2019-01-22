%% Test Frequency Based Motion Effect with Single Actuator
% 2P1F (Two Play One Figure)
% Created on 01/03/2018 based on 'PilotStudy_1P2F.m'
% -------------------------------------------------------------------------
close all
clearvars
% -------------------------------------------------------------------------
% Global variable
global isStarting isChoosing isPlayed currChoice outSig sNI text_h2 expData subjectID currInd
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
end

outSig = struct;

% Signal A: Concentrating to the tip of index finger
sigA = [];
wnA = [];
for i = 1:numSigs  
    temp = randn(size(sigSeg{i,1}));    
    temp = (rms(sigSeg{i,1})/rms(temp)).*temp;

    wnA = [wnA, temp, zeroSig];
    
    sigA = [sigA, sigSeg{i,1}, zeroSig];
%     sigA = noiseAmp * randn(size(sigA)) + sigA;
end
outSig.sigA = [pauseSig, sigA, pauseSig];

wnA = [pauseSig, wnA, pauseSig];

wnA = highpass(wnA,hpFreq,Fs); % High-pass filtering
wnA = 2*lowpass(wnA,lpFreq,Fs,'Steepness',0.5); % Low-pass filtering

% Signal B: Spreading to the whole hand.
sigB = [];
wnB = [];
for i = 1:numSigs  
    temp = randn(size(sigSeg{numSigs-i+1,1}));    
    temp = (rms(sigSeg{numSigs-i+1,1})/rms(temp)).*temp;
    
    wnB = [wnB, temp, zeroSig];
    
    sigB = [sigB, sigSeg{numSigs-i+1,1}, zeroSig];
end
outSig.sigB = [pauseSig, sigB, pauseSig];

wnB = [pauseSig, wnB, pauseSig];

wnB = highpass(wnB,hpFreq,Fs); % High-pass filtering
wnB = 2*lowpass(wnB,lpFreq,Fs,'Steepness',0.5); % Low-pass filtering

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

%% initialize the NI terminal
sNI = daq.createSession('ni');
addAnalogOutputChannel(sNI,'Dev3','ao0','Voltage');
sNI.Rate = Fs;

%% Initialize the GUI -----------------------------------------------------
fig_h = figure('Name','Experiment Starting...','Position',figSize,...
    'Color','w');
img0 = imread('figs/HandPose-01.jpg');
subplot('Position',[0.05 0.05 0.4 0.9]);
imshow(img0);
fileID = fopen('InstructionToSubject_2P1F.txt','r');
noteStr = fscanf(fileID,'%c'); fclose(fileID);
annotation('textbox',[0.46 0.05 0.5 0.9], 'String',noteStr,...
    'EdgeColor','none', 'FontSize',18);

% Set the staring flag
isStarting = 1;

% Input subject info
uicontrol('Style','text','BackgroundColor','w',...
    'Position',[1020 140 200 30], 'FontSize',18, 'String',...
    'Enter subject ID');
etf = uicontrol('Style','edit', 'Position',[1020 100 200 30],...
    'BackgroundColor',[0.98,0.98,0.98], 'FontSize',18);

% Start button
uicontrol('Style', 'pushbutton', 'String', 'START', 'FontSize',20,...
    'Position', [700 100 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', {@startExp, etf});

while isStarting && isvalid(fig_h) 
    pause(0.5);
end

if isvalid(fig_h) 
    close(fig_h);
else
    disp('---------- Program forced shutdown ----------')
    return
end

%% Looping trials 
isPlayed = struct;
isPlayed.Left = 0;
isPlayed.Right = 0;

% Randomization -----------------------------------------------------------
% 1 = SigA, 2 = SigB, 3 = wnA, 4 = wnB, 5 = rsA, 6 = rsB, 7 = wnC, 8 = wnD
% sigPairOrder = [ones(TrialNum,1),2*ones(TrialNum,1);
%     ones(TrialNum,1),5*ones(TrialNum,1);
%     ones(TrialNum,1),6*ones(TrialNum,1);
%     2*ones(TrialNum,1),5*ones(TrialNum,1);
%     2*ones(TrialNum,1),6*ones(TrialNum,1);
%     5*ones(TrialNum,1),6*ones(TrialNum,1)
%     ]; % Pair (1,2) (1,5) (1,6) (2,5) (2,6) (5,6)
sigPairOrder = [ones(TrialNum,1),5*ones(TrialNum,1);
    ones(TrialNum,1),6*ones(TrialNum,1);
    2*ones(TrialNum,1),5*ones(TrialNum,1);
    2*ones(TrialNum,1),6*ones(TrialNum,1)
    ]; % Pair (1,5) (1,6) (2,5) (2,6)

sigPairOrder = [sigPairOrder;sigPairOrder]; % Repeat twice (2 figures)
totalTrialNum = size(sigPairOrder,1);
sigPairRand = randi(2,totalTrialNum,1);

colInd1 = sub2ind([totalTrialNum,2], (1:totalTrialNum)', sigPairRand); % Left column
colInd2 = sub2ind([totalTrialNum,2], (1:totalTrialNum)', 3-sigPairRand); % Right column

sigPairOrder = [sigPairOrder(colInd1),sigPairOrder(colInd2)];

% trialOrder = [sigPairOrder,...
%     [ones(TrialNum,1);ones(TrialNum,1);ones(TrialNum,1); 
%     2*ones(TrialNum,1);2*ones(TrialNum,1);2*ones(TrialNum,1);
%     2*ones(TrialNum,1);ones(TrialNum,1);ones(TrialNum,1);
%     2*ones(TrialNum,1);2*ones(TrialNum,1);1*ones(TrialNum,1)]]; % Last column contains index of displayed figure
trialOrder = [sigPairOrder,...
    [ones(TrialNum,1);ones(TrialNum,1); 
    2*ones(TrialNum,1);2*ones(TrialNum,1);
    ones(TrialNum,1);ones(TrialNum,1);
    2*ones(TrialNum,1);2*ones(TrialNum,1)]];

trialOrder = trialOrder(randperm(totalTrialNum),:);

% Additional test ---------------------------------------------------------
TrialNum2 = 2*TrialNum;
sigPairOrder2 = [ones(TrialNum2,1),2*ones(TrialNum2,1)];
sigPairRand2 = randi(2,TrialNum2,1);
colInd1 = sub2ind([TrialNum2,2], (1:TrialNum2)', sigPairRand2); % Left column
colInd2 = sub2ind([TrialNum2,2], (1:TrialNum2)', 3-sigPairRand2); % Right column
sigPairOrder2 = [sigPairOrder2(colInd1),sigPairOrder2(colInd2)];
trialOrder2 = [sigPairOrder2,[ones(TrialNum,1);2*ones(TrialNum,1)]];
trialOrder2 = trialOrder2(randperm(TrialNum2),:);

trialOrder = [trialOrder;trialOrder2];
totalTrialNum = size(trialOrder,1);

% GUI ---------------------------------------------------------------------
imgChoice{1} = imread('figs/Concentrating.png'); % Figure A
imgChoice{2} = imread('figs/Spreading.png'); % Figure B

fig_h = figure('Name','Experiment Running...','Position',figSize,...
    'Color','w');
% Figure display
subplot('Position',[0.35 0.4 0.3 0.4]);
pic_h = imshow([]);

% Textbox for message
text_h = uicontrol('Style','text','BackgroundColor','w',...
    'Position',[740 700 300 50], 'String',[],'FontSize',24);
text_h2 = uicontrol('Style','text','BackgroundColor','w',...
    'Position',[80 660 400 30], 'String',[],'FontSize',18);

uicontrol('Style','text','BackgroundColor','w',...
    'Position',[540 280 200 50], 'String','Signal A','FontSize',24);
uicontrol('Style','text','BackgroundColor','w',...
    'Position',[990 280 200 50], 'String','Signal B','FontSize',24);

subplot('Position',[0.28 0.08 0.12 0.31],'Color','w','Box','on',...
    'xtick',[],'ytick',[]);
subplot('Position',[0.52 0.08 0.12 0.31],'Color','w','Box','on',...
    'xtick',[],'ytick',[]);

% Left button
bt_left = uicontrol('Style', 'pushbutton', 'String', 'Select',...
    'FontSize',20,...
    'Position', [540 80 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseLeft, 'BusyAction','cancel');

% Right button
bt_right = uicontrol('Style', 'pushbutton', 'String', 'Select',...
    'FontSize',20,...
    'Position', [990 80 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseRight, 'BusyAction','cancel');

% Play signal button (Left)
bt_play_left = uicontrol('Style', 'pushbutton', 'String', 'Play',...
    'FontSize',20,...
    'Position', [540 180 200 80], 'BackgroundColor',[0.98,0.98,0.98],...
    'Callback', @playLeft, 'BusyAction','cancel');

% Play signal button (Right)
bt_play_right = uicontrol('Style', 'pushbutton', 'String', 'Play',...
    'FontSize',20,...
    'Position', [990 180 200 80], 'BackgroundColor',[0.98,0.98,0.98],...
    'Callback', @playRight, 'BusyAction','cancel');

% Submit button
bt_submit = uicontrol('Style', 'pushbutton', 'String', 'Submit',...
    'FontSize',20,...
    'Position', [785 130 160 80], 'BackgroundColor',[1,1,1],...
    'Callback', @submitAnswer, 'BusyAction','cancel');

% Figure close button (end the program)
set(fig_h, 'CloseRequestFcn',{@closeReq, fig_h});

varTypes = {'uint8','uint8','uint8','uint8','double','cell'};
columnNum = length(varTypes);
varNames = {'StimulusTypeLeft','StimulusTypeRight','DisplayType','SubmittedAnswer',...
    'ResponseTime','Additional'};
expData = table('Size',[totalTrialNum columnNum],'VariableTypes',varTypes,...
    'VariableNames',varNames);

currInd = 0;
for i = 1:totalTrialNum    
    isPlayed.Left = 0;
    isPlayed.Right = 0;
    currInd = i;
    
    text_h.String = sprintf('Trial %d',i);
        
    expData.StimulusTypeLeft(i) = trialOrder(i,1);
    expData.StimulusTypeRight(i) = trialOrder(i,2);
    
    expData.DisplayType(i) = trialOrder(i,3);    
    pic_h.CData = imgChoice{expData.DisplayType(i)};    
  
    while sNI.IsLogging && isvalid(fig_h)      
        bt_right.BackgroundColor = [1,1,1];
        bt_left.BackgroundColor = [1,1,1];
        bt_submit.BackgroundColor = [1,1,1];
        pause(0.1);
    end
    tic
    
    currChoice = 0;
    isChoosing = 1;
    if isvalid(fig_h)
        bt_submit.BackgroundColor = [1,1,1];
    end
    while isChoosing && isvalid(fig_h)
        if sNI.IsLogging
            text_h2.String = 'Playing the signal ...';
            bt_right.BackgroundColor = [1,1,1];
            bt_left.BackgroundColor = [1,1,1];
            bt_submit.BackgroundColor = [1,1,1];
        else
            bt_play_left.BackgroundColor = [0.95,0.98,0.95];
            bt_play_right.BackgroundColor = [0.95,0.98,0.95];
            
            if currChoice == 1 % Left button pushed
                text_h2.String = 'Your choice: Signal A';
                bt_right.BackgroundColor = [0.98,0.98,0.98];
                bt_left.BackgroundColor = [1,0.5,0.5];
            elseif currChoice == 2 % Right button pushed
                text_h2.String = 'Your choice: Signal B';
                bt_left.BackgroundColor = [0.98,0.98,0.98];
                bt_right.BackgroundColor = [1,0.5,0.5];
            else
                text_h2.String = 'Play the signals or make your choice';
                bt_right.BackgroundColor = [0.98,0.98,0.98];
                bt_left.BackgroundColor = [0.98,0.98,0.98];
                bt_submit.BackgroundColor = [1,0.9,0.9];
            end

            if currChoice > 0
                bt_submit.BackgroundColor = [1,0,0];
            end
        end
        pause(0.1);
    end  
    
    if currChoice > 0
        expData.SubmittedAnswer(i) = trialOrder(i,currChoice);
        currChoice = 0;
    end
    expData.ResponseTime(i) = toc;
    
    if isvalid(fig_h)
        bt_right.BackgroundColor = [0.98,0.98,0.98];
        bt_left.BackgroundColor = [0.98,0.98,0.98];
        bt_submit.BackgroundColor = [1,1,1];
    end
    
    if ~isvalid(fig_h)
        break;
    end
end
delete(fig_h);

sNI.stop;

if (i == totalTrialNum)
save(sprintf('%s.mat',subjectID),'expData');

figure('Name','Experiment Ended','Position',[500 200 820 500],'Color','w');
uicontrol('Style','text','BackgroundColor','w',...
    'Position',[10 300 800 50], 'FontSize',18,'String',...
    'Data saved. Experiment completed. Thanks for your participation!');
else
    disp('Incomplete experiment!')
end

%% GUI Callback Functions
function startExp(~, ~, etf)
    pause(0.01);
    global isStarting subjectID;
    subjectID = etf.String;
    isStarting = 0;
end

function chooseLeft(hObject, ~) 
    pause(0.01);
    global currChoice sNI isPlayed text_h2;
    if ~sNI.IsLogging
        if (isPlayed.Left)&&(isPlayed.Right)
            button_state = get(hObject,'Value');
            if button_state == get(hObject,'Max')
                currChoice = 1; % Left button pushed
            end
        elseif (isPlayed.Left)||(isPlayed.Right)
            text_h2.String = 'You need to play both signals!'; pause(0.8);
        else
            text_h2.String = 'Play the signal first!'; pause(0.8);
        end
    end
end

function chooseRight(hObject, ~) 
    pause(0.01);
    global currChoice sNI isPlayed text_h2;
    if ~sNI.IsLogging
        if (isPlayed.Left)&&(isPlayed.Right)
            button_state = get(hObject,'Value');
            if button_state == get(hObject,'Max')
                currChoice = 2; % Right button pushed
            end
        elseif (isPlayed.Left)||(isPlayed.Right)
            text_h2.String = 'You need to play both signals!'; pause(0.8);
        else
            text_h2.String = 'Play the signal first!'; pause(0.8);
        end
    end
end

function playLeft(hObject, ~)
    pause(0.01);
    global outSig sNI text_h2 isPlayed expData currInd;
    if ~sNI.IsLogging
        text_h2.String = 'Playing the signal ...';
        hObject.BackgroundColor = [0.5,1,0.4];
        outQueue = [];
        switch expData.StimulusTypeLeft(currInd)
            case 1 % sigA (Concentrating)
                outQueue = outSig.sigA;
            case 2 % sigB (Spreading)
                outQueue = outSig.sigB;
            case 3 % wnA (White noise with same length as sigA)
                error('Unused Signal'); outQueue = wnA;
            case 4 % wnB (White noise with same length as sigB)
                error('Unused Signal'); outQueue = wnB;
            case 5 % Reordered Sequence A
                outQueue = outSig.rsA;
            case 6 % Reordered Sequence B
                outQueue = outSig.rsB;    
            case 7 % wnC (White noise with same length as rsA)
                error('Unused Signal'); outQueue = wnC;
            case 8 % wnD (White noise with same length as rsB)
                error('Unused Signal'); outQueue = wnD;     
            otherwise
                error('Unidentified Trial Index')          
        end
        queueOutputData(sNI,outQueue');
        sNI.startForeground; 
        isPlayed.Left = 1;
        hObject.BackgroundColor = [0.95,0.98,0.95];
    end
end

function playRight(hObject, ~)
    pause(0.01);
    global outSig sNI text_h2 isPlayed expData currInd;
    if ~sNI.IsLogging
        text_h2.String = 'Playing the signal ...';
        hObject.BackgroundColor = [0.5,1,0.4];
        outQueue = [];
        switch expData.StimulusTypeRight(currInd)
            case 1 % sigA (Concentrating)
                outQueue = outSig.sigA;
            case 2 % sigB (Spreading)
                outQueue = outSig.sigB;
            case 3 % wnA (White noise with same length as sigA)
                error('Unused Signal'); outQueue = wnA;
            case 4 % wnB (White noise with same length as sigB)
                error('Unused Signal'); outQueue = wnB;
            case 5 % Reordered Sequence A
                outQueue = outSig.rsA;
            case 6 % Reordered Sequence B
                outQueue = outSig.rsB;    
            case 7 % wnC (White noise with same length as rsA)
                error('Unused Signal'); outQueue = wnC;
            case 8 % wnD (White noise with same length as rsB)
                error('Unused Signal'); outQueue = wnD;     
            otherwise
                error('Unidentified Trial Index')          
        end
        queueOutputData(sNI,outQueue');
        sNI.startForeground; 
        isPlayed.Right = 1;
        hObject.BackgroundColor = [0.95,0.98,0.95];
    end
end

function submitAnswer(~, ~)
    pause(0.2);
    global isChoosing currChoice sNI text_h2;
    while sNI.IsLogging
        pause(0.1);
    end
    if currChoice > 0
        isChoosing = 0;
    else
        text_h2.String = 'Make your choice first!'; pause(0.8);
    end
end

% Figure Close button
function closeReq(~, ~, fig_h)
    pause(0.2);
    global expData;
    disp('---------- Program forced shutdown ----------')
    save('IncompleteExperiment.mat','expData');
    delete(fig_h);
end