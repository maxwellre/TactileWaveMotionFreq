%% Pilot Study Analysis 
% 1P2F (One Play Two Figures)
% Created on 01/04/2018 based on 'PilotStudyAnalysis_1P2F.m'
% -------------------------------------------------------------------------
% Load the data manually
% StimulusType:
% 1 = sigA (Concentrating)
% 2 = sigB (Spreading)
% 3 = wnA (White noise with same length as sigA)
% 4 = wnB (White noise with same length as sigB)
% 5 = rsA (Random Sequence with both ends same as sigA)
% 6 = rsB (Random Sequence with both ends same as sigB)
% 7 = wnC 
% 8 = wnD 
StimulusLabel = {'Concentrating (A)','Spreading (B)','White Noise (A)',...
    'White Noise (B)','Reordered Sequence (A)','Reordered Sequence (B)',...
    'White Noise (C)','White Noise (D)'};
% -------------------------------------------------------------------------
% Pair Type ID:
% 3: sigA - sigB
% 17: sigA - rsA
% 33: sigA - rsB
% 18: sigB - rsA
% 34: sigB - rsB
% 48: rsA - rsB
% -------------------------------------------------------------------------
sbj_id = 4:7;
sbj_num = length(sbj_id);

sigIdentifyAccuracy = NaN(2,sbj_num);

for sbj_i = 1:sbj_num
    data_name = sprintf('Subject%02d.mat',sbj_id(sbj_i));
    load(data_name);
    fprintf('\n---------------------------\n%s loaded:\n',data_name);

    totalTrialNum = size(expData,1); % Total number of trials

    pairTypeBinary = zeros(totalTrialNum,8); % Pair Type ID in binary format
    for i = 1:8
    pairTypeBinary(:,i) =...
        (expData.StimulusTypeLeft == i) | (expData.StimulusTypeRight == i);
    end
    pairType = bi2de(pairTypeBinary); % Pair Types (ID of signal pairs)

    disp('===================================================================')
    fprintf('Overall accuracy of identifying experimental group = %.0f %%\n',...
    100*sum(expData.SubmittedAnswer == expData.DisplayType)/...
    (totalTrialNum - sum(pairType == 48)));

    % -------------------------------------------------------------------------
    disp('-------------------------------------------------------------------')
    disp('Pairs that contain both sigA and sigB:')
    indExp = (pairType == 3);
    ind1 = indExp & (expData.DisplayType == 1);
    ind2 = indExp & (expData.DisplayType == 2);
    fprintf('Accuracy of identifying sigA (from sigA - sigB pair) = %.0f %%\n',...
    100*sum(expData.SubmittedAnswer(ind1) == expData.DisplayType(ind1))/sum(ind1));
    fprintf('Accuracy of identifying sigB (from sigA - sigB pair) = %.0f %%\n',...
    100*sum(expData.SubmittedAnswer(ind2) == expData.DisplayType(ind2))/sum(ind2));

    disp('-------------------------------------------------------------------')
    disp('Pairs that contain either sigA or sigB')
    indExp2 = logical(1 - (indExp | indCtrl));
    ind1 = indExp2 & (expData.DisplayType == 1);
    ind2 = indExp2 & (expData.DisplayType == 2);

    sigIdentifyAccuracy(1,sbj_i) = 100*sum(expData.SubmittedAnswer(ind1) ==...
        expData.DisplayType(ind1))/sum(ind1);
    sigIdentifyAccuracy(2,sbj_i) = 100*sum(expData.SubmittedAnswer(ind2) ==...
        expData.DisplayType(ind2))/sum(ind2);
    
    fprintf('Accuracy of identifying sigA = %.0f %%\n',...
    sigIdentifyAccuracy(1,sbj_i));
    fprintf('Accuracy of identifying sigB = %.0f %%\n',...
    sigIdentifyAccuracy(2,sbj_i));
end

%% ------------------------------------------------------------------------
figure('Position',[50,350,1200,400],'PaperOrientation','landscape');
bar(sigIdentifyAccuracy,0.8,'EdgeColor','none')
ylabel('Identification Accuracy (%)')
xticklabels({'sigA','sigB'});
box off;
legend(sprintfc('Subject %d',1:4))



