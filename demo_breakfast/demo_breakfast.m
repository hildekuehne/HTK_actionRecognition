%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Environment ....

clear;

% root folder with this script
path_root = '/<YourPathHere>/demo_breakfast'
cd(path_root);

parent_dir = cd(cd('..'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set path and variables ....
% demo_bundle:
addpath(genpath(fullfile(parent_dir, '/functions')));
% htk wrapper:
addpath(genpath(fullfile(parent_dir, '/matlab_htk')));
% demo folder:
addpath(genpath(path_root));

%% Directories
% folder with the input data
path_input = fullfile(path_root, 'breakfast_data');

% folder to write temprorary files and output:
path_output = fullfile(path_root, 'htk_output');
if isempty(dir(path_output))
    mkdir(path_output);
end

% folder for hmms and temproary files:
path_gen = fullfile(path_output, 'generated/breakfast_gen');
if isempty(dir(path_gen))
    mkdir(path_gen);
end

% folder for textual output and results:
path_out = fullfile(path_output, 'output/breakfast_out');
if isempty(dir(path_out))
    mkdir(path_out);
end


%% Get config file:
% get the default configuration:
config = get_breakfast_demo_config(path_root, path_input, path_gen, path_out)

%% things you might want to overwrite:
% 
% % folder with segmentation files (xml-style)
% config.features_segmentation = fullfile(path_root, '/segmentation');
% % dictionary file
% config.dict_file = fullfile(path_root, '/breakfast.dict');
% % grammar file
% config.grammar_file = fullfile(path_root, '/breakfast.grammar');


%% Now we need to change the directory
cd(path_gen);

% run traing and testing:
run_htk(config);

%% change back
cd(path_root);

% evaluation of sequences
[accuracy_seq, confmat_seq, test_label_seq, predicted_label_seq]  = get_results_seq(config);

disp('Overall activity  accuracy (sequence recognition): ', num2str(accuracy_seq));

disp('ConfMat: ');

confmat_seq


% evaluation of units
vis_on = 0;
 [acc_activity, acc_sequence_all, acc_units_all, acc_units_perFrames, acc_units_MeanClass, res_all] = get_results_units(config, vis_on)

disp('Sequence parsing accuracy: ', num2str(acc_sequence_all));

disp('Unit accuracy based on unit error rate: ', num2str(acc_units_all));

disp('Frame accuracy (mean over frames): ', num2str(acc_units_perFrames));

disp('Frame accuracy (mean over class): ', num2str(acc_units_MeanClass));

if ispc
    % clean up
    system(['del /Q "',pwd,'/label/*.*"']);
    system(['del /Q "',pwd,'/tmp/*.lab"']);
elseif isunix
    system(['rm -r -f "',pwd,'/label/*.*"']);
    system(['rm -r -f "',pwd,'/tmp/*.lab"']);
end

