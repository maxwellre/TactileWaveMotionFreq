%% Pilot Study Analysis - 1P2F (One Play Two Figures)
% Created on 01/18/2018 
% -------------------------------------------------------------------------
% StimulusType:
% 1 = sigA (Concentrating)
% 2 = sigB (Spreading)
% 5 = rsA (Random Sequence with both ends same as sigA)
% 6 = rsB (Random Sequence with both ends same as sigB)
StimulusLabel = {'Concentrating (A)','Spreading (B)',...
    'Reordered Sequence (A)','Reordered Sequence (B)'};

distinctColor = [
         0         0    1.0000
    1.0000         0         0
         0    1.0000         0
         0         0    0.1724
    1.0000    0.1034    0.7241
    1.0000    0.8276         0
         0    0.3448         0
    0.5172    0.5172    1.0000
    0.6207    0.3103    0.2759
         0    1.0000    0.7586
         0    0.5172    0.5862
         0         0    0.4828
    0.5862    0.8276    0.3103
    0.9655    0.6207    0.8621
    0.8276    0.0690    1.0000
    0.4828    0.1034    0.4138
    0.9655    0.0690    0.3793
    1.0000    0.7586    0.5172
    0.1379    0.1379    0.0345
    0.5517    0.6552    0.4828];
% -------------------------------------------------------------------------
% Pair Type ID:
% 17: sigA - rsA
% 33: sigA - rsB
% 18: sigB - rsA
% 34: sigB - rsB
% -------------------------------------------------------------------------
Data_Path = 'Data/';
pathInfo = dir([Data_Path,'*/Subject*.mat']);
sbj_num = length(pathInfo);
pairType = [17,33,18,34];
pairTypeLabels = {'sigA - rsA','sigA - rsB','sigB - rsA','sigB - rsB'};
pairType_num = length(pairType);

AllData = cell(sbj_num,6);
CFRate = NaN(sbj_num,pairType_num);

for i = 1:sbj_num
    a_name = pathInfo(i).name;
    load([pathInfo(i).folder,'\',a_name]);
    AllData{i,1} = expData;
    AllData{i,2} = str2double(a_name(regexp(a_name,'\d')));
    
    totalTrialNum = size(AllData{i,1},1); % Total number of trials
    pairTypeBinary = zeros(totalTrialNum,8); % Pair Type ID in binary format
    for j = 1:8
    pairTypeBinary(:,j) =...
        (expData.StimulusTypeLeft == j) | (expData.StimulusTypeRight == j);
    end
    AllData{i,3} = bi2de(pairTypeBinary); % Pair Types (ID of signal pairs)
    
    dispType1_ind = (expData.DisplayType == 1); % Display figure 1
    dispType2_ind = (expData.DisplayType == 2); % Display figure 2
    
%     dispType1_ind(1:20) = 0;
%     dispType2_ind(1:20) = 0;
    
    pairAA_ind = dispType1_ind & (AllData{i,3} == pairType(1));
    pairAB_ind = dispType1_ind & (AllData{i,3} == pairType(2));
    
    pairBA_ind = dispType2_ind & (AllData{i,3} == pairType(3));
    pairBB_ind = dispType2_ind & (AllData{i,3} == pairType(4));
    
    CFRate(i,1) = 100*sum(expData.SubmittedAnswer(pairAA_ind) ==...
        expData.DisplayType(pairAA_ind))/sum(pairAA_ind);
    CFRate(i,2) = 100*sum(expData.SubmittedAnswer(pairAB_ind) ==...
        expData.DisplayType(pairAB_ind))/sum(pairAB_ind);
    CFRate(i,3) = 100*sum(expData.SubmittedAnswer(pairBA_ind) ==...
        expData.DisplayType(pairBA_ind))/sum(pairBA_ind);
    CFRate(i,4) = 100*sum(expData.SubmittedAnswer(pairBB_ind) ==...
        expData.DisplayType(pairBB_ind))/sum(pairBB_ind);
    
    % Random walk model
    AllData{i,4} = double(expData.SubmittedAnswer == expData.DisplayType);
    AllData{i,4}(AllData{i,4} == 0) = -1;
    
    % Response time analysis
    AllData{i,5} = expData.ResponseTime;
    
    AllData{i,6} = [pairAA_ind,pairAB_ind,pairBA_ind,pairBB_ind];
end

%% Boxplot of all results
figure('Position',[150,150,700,680],'Color','w');
% boxplot(CFRate,'Colors','kkkk'); box off; 
boxplot(CFRate); box off; 
ylabel('Rate matching target signal to figure (%)');
xticklabels(pairTypeLabels);
xlabel('Target signal - control signal');
set(gca,'FontSize',20,'LineWidth',0.75);
ylim([0 105])

%% Analysis of performance of individual subject
% meanScore = mean(CFRate,2);
% [reorder_meanScore,sbj_reorder_ind] = sort(meanScore,'descend');
% % CFRate = CFRate(sbj_reorder_ind,:);
% 
% figure('Position',[50,50,1800,800],'Color','w');
% subplot(1,2,1)
% barh(CFRate(:,1),'EdgeColor','None'); box off;
% hold on
% barh(-CFRate(:,2),'EdgeColor','None'); box off;
% hold off
% legend(pairTypeLabels(1:2));
% xticklabels(abs(xticks))
% xlabel('Rate of identifying sigA as concentrating (%)')
% ylabel('Subject #')
% set(gca,'FontSize',16);
% ylim([0.5 17.5])
% 
% subplot(1,2,2)
% barh(CFRate(:,3),'EdgeColor','None'); box off;
% hold on
% barh(-CFRate(:,4),'EdgeColor','None'); box off;
% hold off
% legend(pairTypeLabels(3:4));
% xticklabels(abs(xticks))
% xlabel('Rate of identifying sigB as spreading (%)')
% ylabel('Subject #')
% set(gca,'FontSize',16);
% ylim([0.5 17.5])

%% Random walk model
dispTrialNum = 80;

figure('Position',[50,50,1860,800],'Color','w');
subplot(1,2,1);
hold on
for i = 1:sbj_num
    plot(0:dispTrialNum,[0; cumsum(AllData{i,4}(1:dispTrialNum))],...
        'Color',distinctColor(i,:),'LineWidth',2);  
end
yRange = ylim();
% plot([80 80],yRange,'k--');
plot([0 80],[0 0],'k--');
legend(sprintfc('Sbj%d',1:sbj_num),'location','northeast','box','off');
box off;
xlim([0 dispTrialNum+19])
xlabel('Trial #');
ylabel('Accumulated score');
title('If successfully identify the target signal +1, otherwise -1');
set(gca,'FontSize',16);

% Response time
respTime = [];
for i = 1:sbj_num
    respTime = [respTime,AllData{i,5}(1:80)];
end

subplot(1,2,2);
boxplot(respTime); box off;
xlabel('Trial #');

% hold on
% for i = 1:sbj_num
%     plot(AllData{i,5}(1:80),'Color',distinctColor(i,:));   
% end
% legend(sprintfc('Sbj%d',1:sbj_num),'location','northeast','box','off');
% box off;
% xlim([0 99])
% xlabel('Trial #');
ylim([0 60])
ylabel('Response Time (secs)');
set(gca,'FontSize',16);

%% Random walk per pair group
if 0

dispTrialNum = 20;

%distinctColor = distinguishable_colors(15);
figure('Position',[50,50,1860,800],'Color','w');
for pair_i = 1:4
subplot(2,2,pair_i);
hold on
for i = 1:sbj_num
    plot(0:dispTrialNum,(0.05*i)+[0; cumsum(AllData{i,4}(AllData{i,6}(:,pair_i)))],...
        'Color',distinctColor(i,:), 'LineWidth',0.75);   
end
plot([0 dispTrialNum],[0 0],'k--');
box off;
xlim([0 dispTrialNum+9])
xlabel('Trial #');
ylabel('Accumulated score');
title(pairTypeLabels{pair_i});
legend(sprintfc('Sbj%d',1:sbj_num),'location','northeast','box','off');
set(gca,'FontSize',8);
end

end
%% ------------------------------------------------------------------------
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

