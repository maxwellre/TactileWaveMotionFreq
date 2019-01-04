%% Test Frequency Based Motion Effect with Single Actuator
% 1P2F (One Play Two Figures)
% Created on 12/14/2018 based on 'SWindow.m'
% -------------------------------------------------------------------------
close all
clearvars
% -------------------------------------------------------------------------
% Global variable
global isStarting isChoosing isPlayed currChoice outQueue sNI text_h2 expData subjectID
% -------------------------------------------------------------------------
% Experiment Configuration 
figSize = [20,100,1880,800];

TrialNum = 10;

% -------------------------------------------------------------------------
Fs = 20000; % 20 kS/sec sampling frequency

% Signal Configuration ----------------------------------------------------
% Overall Amplitude Scaling Factor
AmpScale = 1; 
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
hpFreq = 0.8*cFreq; % 0.8*carrierFrequency
lpFreq = 1.5*eFreq;
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
% winLenArray = [919 919 919 919 68 68 68 68 68 68];

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

% Signal A: Concentrating to the tip of index finger
sigA = [];
wnA = [];
for i = 1:numSigs  
    temp = randn(size(sigSeg{i,1}));    
    temp = (rms(sigSeg{i,1})/rms(temp)).*temp;

    wnA = [wnA, temp, zeroSig];
    
    sigA = [sigA, sigSeg{i,1}, zeroSig];
    sigA = noiseAmp * randn(size(sigA)) + sigA;
end
sigA = [pauseSig, sigA, pauseSig];

wnA = [pauseSig, wnA, pauseSig];

wnA = highpass(wnA,hpFreq,Fs); % High-pass filtering
wnA = 2*lowpass(wnA,1000,Fs,'Steepness',0.5); % Low-pass filtering

% Signal B: Spreading to the whole hand.
sigB = [];
wnB = [];
for i = 1:numSigs  
    temp = randn(size(sigSeg{numSigs-i+1,1}));    
    temp = (rms(sigSeg{numSigs-i+1,1})/rms(temp)).*temp;
    
    wnB = [wnB, temp, zeroSig];
    
    sigB = [sigB, sigSeg{numSigs-i+1,1}, zeroSig];
end
sigB = [pauseSig, sigB, pauseSig];

wnB = [pauseSig, wnB, pauseSig];

wnB = highpass(wnB,hpFreq,Fs); % High-pass filtering
wnB = 2*lowpass(wnB,lpFreq,Fs,'Steepness',0.5); % Low-pass filtering

% Signal reordered sequence
%rs_ind = [4, 8, 1, 7, 3, 6, 10, 2, 9, 5];
rs_ind = [5, 8, 2, 9, 4, 6, 3, 10, 1, 7, 0, 0, 0, 0, 0, 0, 0];
% this balances spec in 1st, 2nd half and df considerations
rsA = [];
rsB = [];
wnC = [];
wnD = [];

for i = 1:numSigs    
    rsA = [rsA, sigSeg{rs_ind(i),1}, zeroSig];
    rsB = [rsB, sigSeg{rs_ind(numSigs-i+1),1}, zeroSig];
    
    temp = randn(size(sigSeg{rs_ind(i),1}));    
    temp = (rms(sigSeg{rs_ind(i),1})/rms(temp)).*temp;
    wnC = [wnC, temp, zeroSig];
    
    temp = randn(size(sigSeg{rs_ind(numSigs-i+1),1}));    
    temp = (rms(sigSeg{rs_ind(numSigs-i+1),1})/rms(temp)).*temp;
    wnD = [wnD, temp, zeroSig];
end
rsA = [pauseSig, rsA, pauseSig];
rsB = [pauseSig, rsB, pauseSig];

wnC = [pauseSig, wnC, pauseSig];
wnC = highpass(wnC,hpFreq,Fs); % High-pass filtering
wnC = 2*lowpass(wnC,lpFreq,Fs,'Steepness',0.5); % Low-pass filtering

wnD = [pauseSig, wnD, pauseSig];
wnD = highpass(wnD,hpFreq,Fs); % High-pass filtering
wnD = 2*lowpass(wnD,1000,Fs,'Steepness',0.5); % Low-pass filtering

%% initialize the NI terminal
outQueue = [];
sNI = daq.createSession('ni');
addAnalogOutputChannel(sNI,'Dev3','ao0','Voltage');
sNI.Rate = Fs;

%% Initialize the GUI -----------------------------------------------------
fig_h = figure('Name','Experiment Starting...','Position',figSize,...
    'Color','w');
img0 = imread('figs/HandPose-01.jpg');
subplot('Position',[0.05 0.05 0.4 0.9]);
imshow(img0);
fileID = fopen('InstructionToSubject.txt','r');
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
isPlayed = 0;

% Randomization -----------------------------------------------------------
% 1 = SigA, 2 = SigB, 3 = wnA, 4 = wnB, 5 = rsA, 6 = rsB, 7 = wnC, 8 = wnD

trialOrder1 = [ones(1,TrialNum),2*ones(1,TrialNum)];
% trialOrder1 = trialOrder1(randperm(length(trialOrder1)));

trialOrder2 = [3*ones(1,TrialNum),4*ones(1,TrialNum)];
% trialOrder2 = trialOrder2(randperm(length(trialOrder2)));

trialOrder3 = [5*ones(1,TrialNum),6*ones(1,TrialNum)];
% trialOrder3 = trialOrder3(randperm(length(trialOrder3)));

% trialOrder4 = [7*ones(1,TrialNum),8*ones(1,TrialNum)];
% trialOrder4 = trialOrder4(randperm(length(trialOrder4)));
% 
% trialOrder = [trialOrder1,trialOrder2,trialOrder3];

% trialOrder1 = [ones(1,TrialNum),2*ones(1,TrialNum),5*ones(1,TrialNum),6*ones(1,TrialNum)];
% trialOrder1 = trialOrder1(randperm(length(trialOrder1)));
% % % % % 
% % % % % trialOrder2 = [3*ones(1,TrialNum),4*ones(1,TrialNum),7*ones(1,TrialNum),8*ones(1,TrialNum)];
% % % % % trialOrder2 = trialOrder2(randperm(length(trialOrder2)));

% trialOrder = [trialOrder1,trialOrder2];
% trialOrder = trialOrder1;
% 
% trialOrder = trialOrder(randperm(length(trialOrder)));

trialOrder = [1,2,1,2];
totalTrialNum = length(trialOrder);

% GUI ---------------------------------------------------------------------
imgChoice{1} = imread('figs/Concentrating.png'); % Choice 1 (A)
imgChoice{2} = imread('figs/Spreading.png'); % Choice 2 (B)
choiceStr = {'Concentrating','Spreading'};

fig_h = figure('Name','Experiment Running...','Position',figSize,...
    'Color','w');
% Left subplot
subplot('Position',[0.2 0.4 0.3 0.4]);
pic_left = imshow([]);

% Left button
bt_left = uicontrol('Style', 'pushbutton', 'String', choiceStr{1},...
    'FontSize',20,...
    'Position', [550 220 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseLeft, 'BusyAction','cancel');

% Textbox for message
text_h = uicontrol('Style','text','BackgroundColor','w',...
    'Position',[740 700 300 50], 'String',[],'FontSize',24);
text_h2 = uicontrol('Style','text','BackgroundColor','w',...
    'Position',[20 660 400 30], 'String',[],'FontSize',18);

% Right subplot
subplot('Position',[0.5 0.4 0.3 0.4]);
pic_right = imshow([]);

% Right button
bt_right = uicontrol('Style', 'pushbutton', 'String', choiceStr{2},...
    'FontSize',20,...
    'Position', [990 220 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseRight, 'BusyAction','cancel');

% Play signal button
bt_play = uicontrol('Style', 'pushbutton', 'String', 'Play',...
    'FontSize',20,...
    'Position', [790 220 160 80], 'BackgroundColor',[0.98,0.98,0.98],...
    'Callback', @playSignal, 'BusyAction','cancel');

% Submit button
bt_submit = uicontrol('Style', 'pushbutton', 'String', 'Submit',...
    'FontSize',20,...
    'Position', [790 100 160 80], 'BackgroundColor',[1,1,1],...
    'Callback', @submitAnswer, 'BusyAction','cancel');

% Figure close button (end the program)
set(fig_h, 'CloseRequestFcn',{@closeReq, fig_h});

varTypes = {'uint8','uint8','uint8','uint8','double','cell'};
columnNum = length(varTypes);
varNames = {'StimulusType','LeftDisplay','RightDisplay','SubmittedAnswer',...
    'ResponseTime','Additional'};
expData = table('Size',[totalTrialNum columnNum],'VariableTypes',varTypes,...
    'VariableNames',varNames);

for i = 1:totalTrialNum    
    isPlayed = 0;
    
    text_h.String = sprintf('Trial %d',i);
    
    choiceInd = randperm(2); % Randomize the left and right options
    
    expData.LeftDisplay(i) = choiceInd(1);
    bt_left.String = choiceStr{choiceInd(1)};
    pic_left.CData = imgChoice{choiceInd(1)};
    
    expData.RightDisplay(i) = choiceInd(end);
    bt_right.String = choiceStr{choiceInd(end)};
    pic_right.CData = imgChoice{choiceInd(end)};
       
    outQueue = [];
    expData.StimulusType(i) = trialOrder(i);

    switch trialOrder(i)
        case 1 % sigA (Concentrating)
            outQueue = sigA;
        case 2 % sigB (Spreading)
            outQueue = sigB;
        case 3 % wnA (White noise with same length as sigA)
            outQueue = wnA;
        case 4 % wnB (White noise with same length as sigB)
            outQueue = wnB;
        case 5 % Reordered Sequence A
            outQueue = rsA;
        case 6 % Reordered Sequence B
            outQueue = rsB;    
        case 7 % wnC (White noise with same length as rsA)
            outQueue = wnC;
        case 8 % wnD (White noise with same length as rsB)
            outQueue = wnD;     
% % %         case 5 % rsA (Random Sequence with both ends same as sigA)
% % %             rs = [];
% % %             rand_ind = (1+randperm(numSigs-2));
% % %             for j = rand_ind
% % %                 rs = [rs, sigSeg{j,1}, zeroSig];
% % %             end
% % %             outQueue = [pauseSig, sigSeg{1,1}, zeroSig,...
% % %                 rs, sigSeg{numSigs,1}, zeroSig, pauseSig];
% % %             expData.Additional(i) = {[1,rand_ind,numSigs]};
% % %         case 6 % rsB (Random Sequence with both ends same as sigB)
% % %             rs = [];
% % %             rand_ind = (1+randperm(numSigs-2));
% % %             for j = rand_ind
% % %                 rs = [rs, sigSeg{j,1}, zeroSig];
% % %             end
% % %             outQueue = [pauseSig, sigSeg{numSigs,1}, zeroSig,...
% % %                 rs, sigSeg{1,1}, zeroSig, pauseSig];
% % %             expData.Additional(i) = {[numSigs,rand_ind,1]};
        otherwise
            error('Unidentified Trial')          
    end
    text_h2.String = 'Playing the signal ...';
    bt_play.BackgroundColor = [0.5,1,0.4];
% % %     queueOutputData(sNI,outQueue'); % Remove the auto play feature
% % %     sNI.startForeground;    
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
            bt_play.BackgroundColor = [0.98,0.98,0.98];
            
            if currChoice == 1 % Left button pushed
                text_h2.String = sprintf('Your choice: %s',bt_left.String);
                bt_right.BackgroundColor = [0.98,0.98,0.98];
                bt_left.BackgroundColor = [1,0.5,0.5];
            elseif currChoice == 2 % Right button pushed
                text_h2.String = sprintf('Your choice: %s',bt_right.String);
                bt_left.BackgroundColor = [0.98,0.98,0.98];
                bt_right.BackgroundColor = [1,0.5,0.5];
            else
                text_h2.String = 'Play the signal or make your choice';
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
        expData.SubmittedAnswer(i) = choiceInd(currChoice);
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
        if isPlayed
            button_state = get(hObject,'Value');
            if button_state == get(hObject,'Max')
                currChoice = 1; % Left button pushed
            end
        else
            text_h2.String = 'Play the signal first!'; pause(0.8);
        end
    end
end

function chooseRight(hObject, ~) 
    pause(0.01);
    global currChoice sNI isPlayed text_h2;
    if ~sNI.IsLogging
        if isPlayed
            button_state = get(hObject,'Value');
            if button_state == get(hObject,'Max')
                currChoice = 2; % Right button pushed
            end
        else
            text_h2.String = 'Play the signal first!'; pause(0.8);
        end
    end
end

function playSignal(hObject, ~)
    pause(0.01);
    global outQueue sNI text_h2 isPlayed;
    if ~sNI.IsLogging
        text_h2.String = 'Playing the signal ...';
        hObject.BackgroundColor = [0.5,1,0.4];
        queueOutputData(sNI,outQueue');
        sNI.startForeground; 
        isPlayed = 1;
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