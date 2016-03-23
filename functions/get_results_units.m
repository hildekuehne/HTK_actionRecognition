function [acc_activity, acc_sequence_all, acc_units_all, acc_units_perFrames, acc_units_MeanClass, res_all] = get_results_units(config, visualisation_on)
%GET_RESULTS_UNITS computes accuracy of unit recognition 
%
% Input:
% config - the config struct
% visualisation_on - visualisation_flag 
%
% Output:
% acc_activity - the overall activity (sequence recognition) accuracy 
% acc_sequence_all - the sequence parsing accuracy (how many units have been recognized correctly after dtw, without evaluation of insertions, substitutions and deletions)
% acc_units_all - the unit accuracy based on unit error rate including insertions, substitutions and deletions)
% acc_units_perFrames - the frame accuracy as mean over frames 
% acc_units_MeanClass - the frame accuracy as mean over class
% res_all - a struct with all results and labels:
% 		res_all.test_label_units - the test units for each sequence  
% 		res_all.predicted_label_units - the predicted units for each sequence  
% 		res_all.accuracy_units_dtw - the unit accuracy based on unit error rate (1 - unit_error_rate) after alignment by DTW 
% 		res_all.test_label_sequence_dtw - the test units for each sequence after alignment by DTW 
% 		res_all.predicted_label_sequence_dtw - the predicted units for each sequence after alignment by DTW 
% 		res_all.accuracy_sequence_dtw - the accuracy of units per sequence after alignment by DTW 
% 		res_all.test_label_units_perFrames - the test frames (in unit lables) for each sequence 
% 		res_all.predicted_label_units_perFrames - the recognized frames (in unit lables) for each sequence 
% 		res_all.accuracy_units_perFrames - the per frame accuracy of each sequence 
% 		res_all.accuracy_action - accuraccy for sequence recognition 
% 		res_all.test_label_action - test sequence labels 
% 		res_all.predicted_label_action - recognized sequence labels 
%

% Copyright (C) 2014 H. Kuehne
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

if ~exist('visualisation_on', 'var') || isempty(visualisation_on)
    visualisation_on = 0;
end

try
    
% get activity accuracy
[accuracy_action , confmat_action, test_label_action, predicted_label_action ] =  ...
    get_results_seq( config);

% get the unit list from the dictionary
[unit_list] = textread(config.dict_file , '%s');
unit_list = unit_list(1:3:end);

% now the details
[units_ref_perFrame, config.ref_file_ref] = get_units_per_frame_from_file(unit_list, config.ref_file);
[units_recog_perFrame, config.ref_file_recog]  = get_units_per_frame_from_file(unit_list, config.recog_file);

% test for same length
test1= cellfun(@length, units_ref_perFrame);
test2= cellfun(@length, units_recog_perFrame);

disp(['Found ', num2str(size(units_ref_perFrame, 2)), ' files']);

test_label_units = {};
predicted_label_units = {};
accuracy_units_dtw = [];

test_label_sequence_dtw = {};
predicted_label_sequence_dtw = {};
accuracy_sequence_dtw = [];

test_label_units_perFrames = {};
predicted_label_units_perFrames = {};
accuracy_units_perFrames = [];

for i_files = 1:1:size(units_ref_perFrame, 2)

    % evaluate accuracy per sequence
    test_label_units{i_files} = [units_ref_perFrame{i_files}(units_ref_perFrame{i_files}(1:end-1)~=units_ref_perFrame{i_files}(2:end)), units_ref_perFrame{i_files}(end)];
    predicted_label_units{i_files} = [ units_recog_perFrame{i_files}(units_recog_perFrame{i_files}(1:end-1)~=units_recog_perFrame{i_files}(2:end)), units_recog_perFrame{i_files}(end)];
    % remove leading and trailing SIL
    if test_label_units{i_files}(1) == 1
        test_label_units{i_files} = test_label_units{i_files}(2:end);
    end
    if test_label_units{i_files}(end) == 1
        test_label_units{i_files} = test_label_units{i_files}(1:end-1);
    end
    if predicted_label_units{i_files}(1) == 1
        predicted_label_units{i_files} = predicted_label_units{i_files}(2:end);
    end
    if predicted_label_units{i_files}(end) == 1
        predicted_label_units{i_files} = predicted_label_units{i_files}(1:end-1);
    end
    if visualisation_on == 1
        figure(1)
        title('Predicted units')
        ax1 = subplot(2,1,1); imagesc([predicted_label_units{i_files}]);
        caxis manual;
        caxis([1 50]);
        for i_tmp = 1:1:length(predicted_label_units{i_files})
            text(i_tmp, 1, num2str(predicted_label_units{i_files}(i_tmp)), 'BackgroundColor', [0.9, 0.9, 0.9] );
        end
        ax2 = subplot(2,1,2); imagesc([test_label_units{i_files}]);
        title('Test units');
        caxis manual;
        caxis([1 50]);
        for i_tmp = 1:1:length(test_label_units{i_files})
            text(i_tmp, 1, num2str(test_label_units{i_files}(i_tmp)), 'BackgroundColor', [0.9, 0.9, 0.9] );
        end

        h = colorbar;
        set(h, 'Position', [0.8, 0.1, 0.05, 0.8]);
        pos=get(ax1, 'Position');
        set(ax1, 'Position', [pos(1), pos(2), 0.8*pos(3), pos(4)]);
        pos=get(ax2, 'Position');
        set(ax2, 'Position', [pos(1), pos(2), 0.8*pos(3), pos(4)]);
    end

    % evaluate accuracy per sequence
    [Dist,D,k,w]=dtw(predicted_label_units{i_files},test_label_units{i_files});
    test_label_sequence_dtw{i_files} = test_label_units{i_files}(w(:, 2)');
    predicted_label_sequence_dtw{i_files} = predicted_label_units{i_files}(w(:, 1)');
    accuracy_sequence_dtw(i_files) = (sum(test_label_sequence_dtw{i_files} == predicted_label_sequence_dtw{i_files})) / size(w, 1);

    if visualisation_on == 1
        figure(2)
        ax1 = subplot(2,1,1); imagesc([predicted_label_sequence_dtw{i_files}]);
        title('Predicted units after dtw');
        caxis manual;
        caxis([1 50]);
        for i_tmp = 1:1:length(predicted_label_sequence_dtw{i_files})
            text(i_tmp, 1, num2str(predicted_label_sequence_dtw{i_files}(i_tmp)), 'BackgroundColor', [0.9, 0.9, 0.9] );
        end
        ax2 = subplot(2,1,2); imagesc([test_label_sequence_dtw{i_files}]);
        title('Test units after dtw');
        caxis manual;
        caxis([1 50]);
        for i_tmp = 1:1:length(test_label_sequence_dtw{i_files})
            text(i_tmp, 1, num2str(test_label_sequence_dtw{i_files}(i_tmp)), 'BackgroundColor', [0.9, 0.9, 0.9] );
        end

        h = colorbar;
        set(h, 'Position', [0.8, 0.1, 0.05, 0.8]);
        pos=get(ax1, 'Position');
        set(ax1, 'Position', [pos(1), pos(2), 0.8*pos(3), pos(4)]);
        pos=get(ax2, 'Position');
        set(ax2, 'Position', [pos(1), pos(2), 0.8*pos(3), pos(4)]);

%             figure(3)
%             imagesc(D)
%             colormap gray;
%             hold on     
%             plot(w(:, 2), w(:, 1));
%             hold off
    end

    accuracy_units_dtw(i_files) = get_unit_acc(test_label_sequence_dtw{i_files}, predicted_label_sequence_dtw{i_files}, w);


    % evaluate accuracy per frame
    test_label_units_perFrames{i_files} = units_ref_perFrame{i_files};
    predicted_label_units_perFrames{i_files} = units_recog_perFrame{i_files};
    if visualisation_on == 1
        figure(4);
        imagesc([predicted_label_units_perFrames{i_files}; ...
            test_label_units_perFrames{i_files}; ...
            (predicted_label_units_perFrames{i_files} == test_label_units_perFrames{i_files}) ...
            ]);
    end
    accuracy_units_perFrames(i_files) = (sum(test_label_units_perFrames{i_files} == predicted_label_units_perFrames{i_files}))/length(predicted_label_units_perFrames{i_files});

end

accuracy_sequence_dtw_tmp  = mean(accuracy_sequence_dtw);
accuracy_units_dtw_tmp  = mean(accuracy_units_dtw);
accuracy_units_perFrames_all  = (sum(cell2mat(test_label_units_perFrames) == cell2mat(predicted_label_units_perFrames)))/length(cell2mat(predicted_label_units_perFrames));

[ confMat_units_perFrames, order ] = get_conf_matrix( cell2mat(predicted_label_units_perFrames), cell2mat(test_label_units_perFrames)  );
confMat_units_perFrames_all  = confMat_units_perFrames; 
accuracy_units_perClass_all = mean(diag(confMat_units_perFrames_all))

% save the details
res_all.test_label_units  = test_label_units;
res_all.predicted_label_units  = predicted_label_units;
res_all.accuracy_units_dtw  = accuracy_units_dtw;

res_all.test_label_sequence_dtw  = test_label_sequence_dtw;
res_all.predicted_label_sequence_dtw  = predicted_label_sequence_dtw;
res_all.accuracy_sequence_dtw  = accuracy_sequence_dtw;

res_all.test_label_units_perFrames  = test_label_units_perFrames;
res_all.predicted_label_units_perFrames  = predicted_label_units_perFrames;
res_all.accuracy_units_perFrames  = accuracy_units_perFrames;

catch ME
    getReport(ME)
    accuracy_action  = 0;
    accuracy_sequence_dtw_tmp  = 0;
    accuracy_units_dtw_tmp  = 0;
    accuracy_units_perFrames_all  = 0;
    accuracy_units_perClass_all  = 0;
    keyboard;
end

    
res_all.accuracy_action = accuracy_action;
res_all.confmat_action = confmat_action;
res_all.test_label_action = test_label_action;
res_all.predicted_label_action = predicted_label_action;

acc_activity = mean(accuracy_action);
acc_sequence_all = mean(accuracy_sequence_dtw_tmp);
acc_units_all = mean(accuracy_units_dtw_tmp);
acc_units_perFrames = mean(accuracy_units_perFrames_all);
acc_units_MeanClass = mean(accuracy_units_perClass_all);


end

