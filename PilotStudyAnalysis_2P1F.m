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

% -------------------------------------------------------------------------
% disp('-------------------------------------------------------------------')
disp('Pairs that contain reordered sequence only:')
indCtrl = (pairType == 48);
% fprintf('Reordered sequence A identified as sigA = %.0f %%\n',...
%     100*sum((expData.SubmittedAnswer(indCtrl)==5)&...
%     (expData.DisplayType(indCtrl)==1))/sum(indCtrl));
% fprintf('Reordered sequence A identified as sigB = %.0f %%\n',...
%     100*sum((expData.SubmittedAnswer(indCtrl)==5)&...
%     (expData.DisplayType(indCtrl)==2))/sum(indCtrl));
% fprintf('Reordered sequence B identified as sigA = %.0f %%\n',...
%     100*sum((expData.SubmittedAnswer(indCtrl)==6)&...
%     (expData.DisplayType(indCtrl)==1))/sum(indCtrl));
% fprintf('Reordered sequence B identified as sigB = %.0f %%\n',...
%     100*sum((expData.SubmittedAnswer(indCtrl)==6)&...
%     (expData.DisplayType(indCtrl)==2))/sum(indCtrl));
% -------------------------------------------------------------------------
disp('-------------------------------------------------------------------')
disp('Pairs that contain either sigA or sigB')
indExp2 = logical(1 - (indExp | indCtrl));
ind1 = indExp2 & (expData.DisplayType == 1);
ind2 = indExp2 & (expData.DisplayType == 2);

fprintf('Accuracy of identifying sigA = %.0f %%\n',...
100*sum(expData.SubmittedAnswer(ind1) == expData.DisplayType(ind1))/sum(ind1));
fprintf('Accuracy of identifying sigB = %.0f %%\n',...
100*sum(expData.SubmittedAnswer(ind2) == expData.DisplayType(ind2))/sum(ind2));

% -------------------------------------------------------------------------
% % Response time analysis
% figure('Position',[50,350,1800,500]);
% histEdges = linspace(min(expData.ResponseTime),max(expData.ResponseTime),...
%     50);
% 
% for i = 1:3
%     subplot(1,3,i)
%     switch i
%         case 1
%             resTime = expData.ResponseTime(indExp);
%             titleStr = ('Pairs that contain both sigA and sigB');
%         case 2
%             resTime = expData.ResponseTime(indExp2);
%             titleStr = ('Pairs that contain either sigA or sigB');
%         case 3
%             resTime = expData.ResponseTime(indCtrl);
%             titleStr = ('Pairs that contain reordered sequence only');
%     end
%     histogram(resTime,histEdges,'EdgeColor','none');
%     xlabel('Response Time (secs)');
%     box off;
%     title(titleStr);
% end

