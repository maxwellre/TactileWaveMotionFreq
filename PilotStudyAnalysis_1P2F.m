%% Pilot Study Analysis 
% 1P2F (One Play Two Figures)
% Load the data manually
% StimulusType:
% 1 = sigA (Concentrating)
% 2 = sigB (Spreading)
% 3 = wnA (White noise with same length as sigA)
% 4 = wnB (White noise with same length as sigB)
% 5 = rsA (Random Sequence with both ends same as sigA)
% 6 = rsB (Random Sequence with both ends same as sigB)
StimulusLabel = {'Concentrating (A)','Spreading (B)','White Noise (A)',...
    'White Noise (B)','Reordered Sequence (A)','Reordered Sequence (B)',...
    'White Noise (C)','White Noise (D)'};
% -------------------------------------------------------------------------
% totalTrialNumber = size(expData,1);
% oneTypeTrialNumber = totalTrialNumber/6;
% 
% rate1 = sum(expData.SubmittedAnswer == expData.StimulusType)/...
%     (2*oneTypeTrialNumber); % Compare answer with stimulus type 1 and 2
% 
% rate2 = sum(expData.SubmittedAnswer == (expData.StimulusType-2))/...
%     (2*oneTypeTrialNumber); % Compare answer with stimulus type 3 and 4
% 
% % rate3 = sum(expData.SubmittedAnswer == (expData.StimulusType-4))/...
% %     (2*oneTypeTrialNumber); % Compare answer with stimulus type 5 and 6
% Z = expData.SubmittedAnswer(expData.StimulusType == 5);
% rate3 = sum(Z == 1)/length(Z);
% Z = expData.SubmittedAnswer(expData.StimulusType == 6);
% rate4 = sum(Z == 1)/length(Z);
% 
% fprintf('sigA-sigB pair identification rate = %.1f %%\n',100*rate1);
% fprintf('wnA-wnB pair identification rate = %.1f %%\n',100*rate2);
% % fprintf('rsA-rsB pair identification rate = %.1f %%\n',100*rate3);
% fprintf('Rate of rs identified as A = %.1f %%\n',100*rate3);
% fprintf('Rate of rs identified as A = %.1f %%\n',100*rate4);

for i = 1:8
    temp = expData.SubmittedAnswer(expData.StimulusType == i);
    temp = mod(temp-1,2)+1;
    rateA = sum(temp == 1)/length(temp);
    rateB = sum(temp == 2)/length(temp);
    fprintf('%s identified as Concentrating = %.1f%% and as Spreading = %.1f%%\n',...
        StimulusLabel{i},100*rateA,100*rateB);
end

% -------------------------------------------------------------------------
% figure('Position',[50,150,1200,600]);
% histEdges = linspace(min(expData.ResponseTime),max(expData.ResponseTime),...
%     50);
% for i = 1:8
%     subplot(4,2,i)
%     resTime = expData.ResponseTime(expData.StimulusType == i);
%     histogram(resTime,histEdges,'EdgeColor','none');
%     xlabel('Response Time (secs)')
%     title(StimulusLabel{i})
%     box off
% end
% StimulusLabel = {'Concentrating (A)','Spreading (B)','White Noise (A)',...
%     'White Noise (B)','Random Sequence (A)','Random Sequence (B)'};
% figure('Position',[50,150,1200,600]);
% histEdges = linspace(min(expData.ResponseTime),max(expData.ResponseTime),...
%     50);
% for i = 1:6
%     subplot(3,2,i)
%     resTime = expData.ResponseTime(expData.StimulusType == i);
%     histogram(resTime,histEdges,'EdgeColor','none');
%     xlabel('Response Time (secs)')
%     title(StimulusLabel{i})
%     box off
% end

