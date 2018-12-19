%% Pilot Study Analysis
% Load the data manually
% StimulusType:
% 1 = sigA (Concentrating)
% 2 = sigB (Spreading)
% 3 = wnA (White noise with same length as sigA)
% 4 = wnB (White noise with same length as sigB)
% 5 = rs (Random Sequence)
% -------------------------------------------------------------------------
totalTrialNumber = size(expData,1);
oneTypeTrialNumber = totalTrialNumber/5;

rate1 = sum(expData.SubmittedAnswer == expData.StimulusType)/...
    (2*oneTypeTrialNumber);

rate2 = sum(expData.SubmittedAnswer == (expData.StimulusType-2))/...
    (2*oneTypeTrialNumber);

RandSeqAns = expData.SubmittedAnswer(expData.StimulusType == 5);
RandSeqRate = sum(RandSeqAns == 1)/length(RandSeqAns);

fprintf('sigA-sigB pair identification rate = %.1f %%\n',100*rate1);
fprintf('wnA-wnB pair identification rate = %.1f %%\n',100*rate2);
fprintf('Rate of random sequence identifed as sigA = %.1f %%\n',100*RandSeqRate);