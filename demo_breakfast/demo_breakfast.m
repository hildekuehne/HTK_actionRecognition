%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Environment ....

clear;

% root folder with this script
path_root = '/media/data/Work/eclipse workspace/HTK_release/demo_breakfast'
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
tic;run_htk(config);toc

%% change back
cd(path_root);

% evaluation of sequences
[accuracy_seq, confmat_seq, test_label_seq, predicted_label_seq]  = get_results_seq(config);

% evaluation of units
vis_on = 0;
[accuracy_units, acc_unit_parsing, acc_unit_rec, acc_units_perFrames, res_all] = get_results_units(config, vis_on);

% clean up
system(['del /Q "',pwd,'/label/*.*"']);
system(['del /Q "',pwd,'/tmp/*.lab"']);

