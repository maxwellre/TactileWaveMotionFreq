%% Test Frequency Based Apparent Motion Effect with Single Actuator
% Created on 12/14/2018 based on 'SWindow.m'
% -------------------------------------------------------------------------
close all
clearvars
% -------------------------------------------------------------------------
% Global variable
global isStarting isChoosing currChoice
% -------------------------------------------------------------------------
% Experiment Configuration 
figSize = [20,100,1880,800];

TrialNum = 20;

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

%% Initialize the GUI -----------------------------------------------------
% fig_h = figure('Name','Experiment Starting...','Position',figSize,...
%     'Color','w');
% img0 = imread('figs/HandPose-01.jpg');
% subplot('Position',[0.05 0.05 0.4 0.9]);
% imshow(img0);
% fileID = fopen('InstructionToSubject.txt','r');
% noteStr = fscanf(fileID,'%c'); fclose(fileID);
% annotation('textbox',[0.46 0.05 0.5 0.9], 'String',noteStr,...
%     'EdgeColor','none', 'FontSize',18);
% 
% % Set the staring flag
% isStarting = 1;
% 
% % Start button
% uicontrol('Style', 'pushbutton', 'String', 'START', 'FontSize',20,...
%     'Position', [800 100 200 80], 'BackgroundColor',[0.8,1,0.8],...
%     'Callback', @startExp);
% 
% while isStarting
%     pause(0.5);
% end
% close(fig_h);

%% Looping trials ---------------------------------------------------------
imgChoice{1} = imread('figs/Spreading-01.jpg'); % Choice 1
imgChoice{2} = imread('figs/Concentrating-01.jpg'); % Choice 2
choiceStr = {'Spreading','Concentrating'};

fig_h = figure('Name','Experiment Running...','Position',figSize,...
    'Color','w');
% Left subplot
subplot('Position',[0.2 0.4 0.3 0.5]);
pic_left = imshow(imgChoice{1});

% Left button
uicontrol('Style', 'togglebutton', 'String', choiceStr{1}, 'FontSize',20,...
    'Position', [500 120 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseLeft);

% Textbox for message
text_h = uicontrol('Style','text','BackgroundColor','w',...
    'Position',[50 700 400 30], 'String',[],'FontSize',18);

% Right subplot
subplot('Position',[0.5 0.4 0.3 0.5]);
pic_right = imshow(imgChoice{2});

% Right button
uicontrol('Style', 'togglebutton', 'String', choiceStr{2}, 'FontSize',20,...
    'Position', [1000 120 200 80], 'BackgroundColor',[0.95,0.95,0.95],...
    'Callback', @chooseRight);

% Play signal button
uicontrol('Style', 'pushbutton', 'String', 'Play', 'FontSize',20,...
    'Position', [750 220 200 80], 'BackgroundColor',[0.98,0.98,0.98],...
    'Callback', @playSignal);

% Submit button
uicontrol('Style', 'pushbutton', 'String', 'Submit', 'FontSize',20,...
    'Position', [750 20 200 80], 'BackgroundColor',[1,0.9,0.9],...
    'Callback', @submitAnswer);

varTypes = {'double','double','double','double','double','double'};
columnNum = length(varTypes);
varNames = {'StimulusType','LeftDisplay','RightDisplay','SubmittedAnswer',...
    'PlayNumber','ResponseTime'};
expData = table('Size',[TrialNum columnNum],'VariableTypes',varTypes,...
    'VariableNames',varNames);

for i = 1:TrialNum
    text_h.String = sprintf('Trial %d - Your Choice is: ',i);
    
    currChoice = 0;
    isChoosing = 1;
    while isChoosing
        if currChoice == 1 % Left button pushed
            
        elseif currChoice == 2 % Right button pushed
        end
        pause(0.1);
    end  
end

%% GUI Callback Functions
function startExp(~, ~)
    global isStarting;
    isStarting = 0;
end

function chooseLeft(hObject, ~) 
    global currChoice;
    button_state = get(hObject,'Value');
    if button_state == get(hObject,'Max')
        currChoice = 1; % Left button pushed
    end
end

function chooseRight(~, ~) 
    global currChoice;
    button_state = get(hObject,'Value');
    if button_state == get(hObject,'Max')
        currChoice = 2; % Right button pushed
    end
end

function playSignal(~, ~)
end

function submitAnswer(~, ~)
    global isChoosing;
    isChoosing = 0;
end