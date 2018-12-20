%% Test Frequency Based Motion Effect with Single Actuator
% Created on 12/14/2018 based on 'SWindow.m'
% -------------------------------------------------------------------------
close all
clearvars
% -------------------------------------------------------------------------
% Global variable
global isStarting isChoosing currChoice outQueue sNI text_h2 expData subjectID
% -------------------------------------------------------------------------
% Experiment Configuration 
figSize = [20,100,1880,800];

TrialNum = 2;

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
ampDec = 0.1; 

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
for i = 1:numSigs
    winLen = winLenArray(i); % Windowing a sin with certain lengths
    
    winSig = gausswin(winLen)'; % Gaussian window
    
    carrier = sinSig(1:winLen);
    
    temp = AmpScale * ampProfile(i)*carrier.*winSig; 
    
    temp = highpass(temp,hpFreq,Fs); % High-pass filtering
    
    sigSeg{i,1} = temp;
    sigSeg{i,2} = sprintf('%.0fHz',freqArray(i));
end

% Signal A: Concentrating to the tip of index finger
sigA = [];
wnA = [];
for i = 1:numSigs
    temp = randn(size(sigSeg{i,1}));    
    temp = (rms(sigSeg{i,1})/rms(temp)).*temp;
    wnA = [wnA, temp, zeroSig];
    
    sigA = [sigA, sigSeg{i,1}, zeroSig];
end
sigA = [pauseSig, sigA, pauseSig];
wnA = [pauseSig, wnA, pauseSig];

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

% Randomization -----------------------------------------------------------
% 1 = SigA, 2 = SigB, 3 = wnA, 4 = wnB, 5 = rsA, 6 = rsB
trialOrder = [ones(1,TrialNum),2*ones(1,TrialNum),3*ones(1,TrialNum),...
    4*ones(1,TrialNum),5*ones(1,TrialNum),6*ones(1,TrialNum)];

totalTrialNum = length(trialOrder);
trialOrder = trialOrder(randperm(totalTrialNum));

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
    'Position', [550 120 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseLeft, 'BusyAction','cancel');

% Textbox for message
text_h = uicontrol('Style','text','BackgroundColor','w',...
    'Position',[760 700 300 50], 'String',[],'FontSize',24);
text_h2 = uicontrol('Style','text','BackgroundColor','w',...
    'Position',[20 660 400 30], 'String',[],'FontSize',18);

% Right subplot
subplot('Position',[0.5 0.4 0.3 0.4]);
pic_right = imshow([]);

% Right button
bt_right = uicontrol('Style', 'pushbutton', 'String', choiceStr{2},...
    'FontSize',20,...
    'Position', [950 120 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseRight, 'BusyAction','cancel');

% Play signal button
bt_play = uicontrol('Style', 'pushbutton', 'String', 'Play',...
    'FontSize',20,...
    'Position', [770 220 160 80], 'BackgroundColor',[0.98,0.98,0.98],...
    'Callback', @playSignal, 'BusyAction','cancel');

% Submit button
bt_submit = uicontrol('Style', 'pushbutton', 'String', 'Submit',...
    'FontSize',20,...
    'Position', [770 20 160 80], 'BackgroundColor',[1,1,1],...
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
        case 5 % rsA (Random Sequence with both ends same as sigA)
            rs = [];
            rand_ind = (1+randperm(numSigs-2));
            for j = rand_ind
                rs = [rs, sigSeg{j,1}, zeroSig];
            end
            outQueue = [pauseSig, sigSeg{1,1}, zeroSig,...
                rs, sigSeg{numSigs,1}, zeroSig, pauseSig];
            expData.Additional(i) = {[1,rand_ind,numSigs]};
        case 6 % rsB (Random Sequence with both ends same as sigB)
            rs = [];
            rand_ind = (1+randperm(numSigs-2));
            for j = rand_ind
                rs = [rs, sigSeg{j,1}, zeroSig];
            end
            outQueue = [pauseSig, sigSeg{numSigs,1}, zeroSig,...
                rs, sigSeg{1,1}, zeroSig, pauseSig];
            expData.Additional(i) = {[numSigs,rand_ind,1]};
        otherwise
            error('Unidentified Trial')          
    end
    text_h2.String = 'Playing the signal ...';
    bt_play.BackgroundColor = [0.5,1,0.4];
    queueOutputData(sNI,outQueue');
    sNI.startForeground;    
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
                text_h2.String = sprintf('Your choice: %s',choiceStr{1});
                bt_right.BackgroundColor = [0.98,0.98,0.98];
                bt_left.BackgroundColor = [1,0.5,0.5];
            elseif currChoice == 2 % Right button pushed
                text_h2.String = sprintf('Your choice: %s',choiceStr{2});
                bt_left.BackgroundColor = [0.98,0.98,0.98];
                bt_right.BackgroundColor = [1,0.5,0.5];
            else
                text_h2.String = 'Play again or make your choice';
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

save(sprintf('%s.mat',subjectID),'expData');

figure('Name','Experiment Ended','Position',[500 200 820 500],'Color','w');
uicontrol('Style','text','BackgroundColor','w',...
    'Position',[10 300 800 50], 'FontSize',18,'String',...
    'Data saved. Experiment completed. Thanks for your participation!');

%% GUI Callback Functions
function startExp(~, ~, etf)
    global isStarting subjectID;
    subjectID = etf.String;
    isStarting = 0;
end

function chooseLeft(hObject, ~) 
    global currChoice sNI;
    if ~sNI.IsLogging
        button_state = get(hObject,'Value');
        if button_state == get(hObject,'Max')
            currChoice = 1; % Left button pushed
        end
    end
end

function chooseRight(hObject, ~) 
    global currChoice sNI;
    if ~sNI.IsLogging
        button_state = get(hObject,'Value');
        if button_state == get(hObject,'Max')
            currChoice = 2; % Right button pushed
        end
    end
end

function playSignal(hObject, ~)
    global outQueue sNI text_h2;
    if ~sNI.IsLogging
        text_h2.String = 'Playing the signal ...';
        hObject.BackgroundColor = [0.5,1,0.4];
        queueOutputData(sNI,outQueue');
        sNI.startForeground; 
    end
end

function submitAnswer(~, ~)
    global isChoosing currChoice sNI text_h2;
    while sNI.IsLogging
        pause(0.1);
    end
    if currChoice > 0
        isChoosing = 0;
    else
        text_h2.String = 'Make your choice first!';
        pause(0.8);
    end
end

% Figure Close button
function closeReq(~, ~, fig_h)
    global expData;
    disp('---------- Program forced shutdown ----------')
    save('IncompleteExperiment.mat','expData');
    delete(fig_h);
end