function run_htk(config)
%RUN_HTK this programm controls training and testing on htk 
%
% Input:
% config - the configuration struct
% Output:
% the outpout is written to the files named in the config. For an
% evaluation, please use get_results_seq.m and get_results_units.m 
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(dir(config.hmm_file_name))


%% Load features

if ~exist('features_train', 'var')
    [features_train, labels_train, seg, label_list, label_count, label_idx ] = load_features_with_segmentation(config.features_dir, config.features_segmentation, config.file_ending, config.normalization, [], config.pattern_train, config.noSIL);    
    disp(['found ' num2str(length(labels_train)) ' training sets']);
    
    
    if ~isfield(config, 'min_number_samples')
        config.min_number_samples = min(median(label_count(2:end)),  mean(label_count(2:end)));
    end
    if ~isfield(config, 'max_number_samples')
        config.max_number_samples = max(median(label_count(2:end)),  mean(label_count(2:end)));
    end
    
    
    ind_fill = find( label_count < config.min_number_samples )
    
    for i_fill = 1:1:length(ind_fill)
        
        disp(['Filling label: ', label_list{ind_fill(i_fill)}, ' ... has only ', num2str(label_count(ind_fill(i_fill))), ' samples']);
        disp(['Adding: ', num2str(12 - label_count(ind_fill(i_fill)))]);

        for j_fill = 1:1:config.min_number_samples - label_count(ind_fill(i_fill))
            % find samples 
            ind_samples = find(label_idx == ind_fill(i_fill));
            ind_samples = ind_samples( randperm(length(ind_samples)) );
            
            new_feature2 = features_train{ind_samples(1)} + (rand(size(features_train{ind_samples(1)}, 1), size(features_train{ind_samples(1)}, 2))*0.5 - 0.25) ;
            features_train{end+1} = new_feature2;
            
            labels_train{end+1} = label_list{ind_fill(i_fill)};
            label_count(ind_fill(i_fill)) = label_count(ind_fill(i_fill))+1;
            label_idx(end+1) = ind_fill(i_fill);          
            
        end

    end
    
    % Kill samples with more then 100 instances 
    if ~isfield(config, 'max_number_samples')
        config.max_number_samples = 100;
    end
    ind_kill = find( label_count > config.max_number_samples )
    for i_kill = 1:1:length(ind_kill)

        % find those features
        ind_samples = find(strcmp(labels_train, label_list(ind_kill(i_kill))));
        ind_samples = ind_samples(randperm(length(ind_samples)));
        ind_samples = ind_samples(1:(length(ind_samples)-config.max_number_samples));
        % empty cells
        features_train(ind_samples) = [];
        labels_train(ind_samples) = [];
        
        label_count(ind_kill(i_kill)) = label_count(ind_kill(i_kill))-length(ind_samples);
        label_idx(ind_samples) = [];          
    end

    % remove empty cells
    features_train(cellfun(@isempty,features_train)) = [];
    labels_train(cellfun(@isempty,labels_train)) = [];
    
    % fill too short samples 
    c = cell(1,size(features_train, 2));
    c(:) = {1};
    ind_fill = find( cellfun(@size, features_train, c) < config.defnumstates+2 )
    for i_fill = 1:1:length(ind_fill)
        features_train{ind_fill(i_fill)} = [features_train{ind_fill(i_fill)};  repmat( features_train{ind_fill(i_fill)}(end, :),   config.defnumstates+2 - size( features_train{ind_fill(i_fill)}, 1), 1 )]; 
    end

    disp(['using ' num2str(length(labels_train)) ' training sets']);

end

% find all possible action units
labels = {};
label_counts = [];
for i = 1:length(labels_train)
    found = -1;
    for j = 1:length(labels)
        if strcmp(labels{j}, labels_train{i})
            found = j;
            break;
        end
    end
    if found ~= -1
        label_counts(found) = label_counts(found)+1;
        continue;
    end
    label_counts(end+1) = 1;
    labels{end+1} = labels_train{i};
end
disp(['found ' num2str(length(labels)) ' labels']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate and train hmms

hmms = {};
hmmstates = ones(1, length(labels))*config.defnumstates;
for i = 1:length(labels)
    features = {};
    for j = 1:length(labels_train)
        if strcmp(labels{i}, labels_train{j})
            features{end+1} = features_train{j}';
        end
    end

    
    if isfield(config, 'defhmm')
        defhmm = config.defhmm;
    else
        defhmm = struct();
    end
        
    if ~isfield(defhmm, 'nstates') 
       [nrows, ncols] = cellfun(@size, features);
       median(ncols)
       if config.defnumstates == -1 %  median
            defhmm.nstates =  ceil(sqrt(median(ncols)));
       elseif config.defnumstates == -2 % linear scaling ... 
            defhmm.nstates =  ceil(median(ncols)/10)
       else
            defhmm.nstates =  config.defnumstates;
       end
       
       if defhmm.nstates < 3 %  minimum of 3 states
            defhmm.nstates = 3;
       end
       
       defhmm
    end

   if ~isfield(defhmm, 'emission_type') 
       defhmm.emission_type = 'GMM';
   end
   if ~isfield(defhmm, 'start_prob') 
       defhmm.start_prob = log([1, zeros(1, defhmm.nstates-1)]);
   end
   if ~isfield(defhmm, 'transmat') 
       defhmm.transmat = zeros(defhmm.nstates);
        for j=1:1:defhmm.nstates-1
            defhmm.transmat(j, j) = 0.6;
            defhmm.transmat(j, j+1) = 0.4;
        end
        defhmm.transmat(defhmm.nstates, defhmm.nstates) = 0.7;
        defhmm.transmat = log(defhmm.transmat);
   end
   if ~isfield(defhmm, 'end_prob') 
       defhmm.end_prob = log([zeros(1, defhmm.nstates-1), 0.3]);
   end

    if strcmp(defhmm.emission_type, 'GMM') 
      if ~isfield(defhmm, 'gmms')
        defhmm.gmms = struct;
      end
      if ~isfield(defhmm.gmms(1), 'nmix')
        nmix = config.numberOfMixtures;
        for x = 1:defhmm.nstates
          defhmm.gmms(x).nmix = nmix;
        end
      else
        nmix = defhmm.gmms(1).nmix;
      end
    end
    
     i
    hmm = train_hmm_htk(features, labels{i}, defhmm, 100, 2, 0.000001);

    hmm.name = labels{i};
    if i == 1
        hmms = hmm;
    else
        hmms(end+1) = hmm;
    end
    write_htk_hmm([config.dir_hmm_def, '/', labels{i}, '.hmm'], hmm)

end
write_htk_hmm(config.hmm_file_name, hmms);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Generate hmmlist from labels

% hmms that are to be used for recognition
f = fopen(config.hmm_list_file, 'w');
for i = 1:length(labels)
    fprintf(f, '%s\n', [labels{i}]);
end
fclose(f);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate Dictionary & Grammar (if needed)  

if isempty(dir(config.dict_file))
    % create dictionary
    f = fopen(config.dict_file, 'w');
    for i = 1:length(labels)
        fprintf(f, '%s [%s] %s\n', labels{i}, labels{i}, labels{i});
    end
    fclose(f);
end

if isempty(dir(config.grammar_file))
    % create grammar
    f = fopen(config.grammar_file, 'w');
    fprintf(f, '$ACT = <%s>', labels{1});
    for i = 2:length(labels)
        fprintf(f, ' | <%s>', labels{i});
    end
    fprintf(f, ';\n');
    fprintf(f, '([$ACT])');
    fclose(f);
end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compile grammar
disp('Compile grammar');
disp(['"', get_htk_path 'HParse" -A -D -T 1 "', config.grammar_file,'"  "', config.latice_file, '"'])
[res, txt] = system([get_htk_path 'HParse -A -D -T 1 "', config.grammar_file,'"  "', config.latice_file, '"']);

if res ~= 0
    txt
    error
end

% Test grammar
disp('Test grammar');
disp([get_htk_path 'HSGen -l -n 20 -s "', config.latice_file, '" "', config.dict_file, '"'])
[res, txt] = system([get_htk_path 'HSGen -l -n 20 -s "', config.latice_file, '" "', config.dict_file, '"']);
txt    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load test files

if ~exist('features_test', 'var')
    [features_test, labels_test, segfile] = load_features_with_segmentation(config.features_dir, config.features_segmentation, config.file_ending, config.normalization, 0, config.pattern_test, config.noSIL);
    disp(['found ' num2str(length(labels_test)) ' test sets']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare files
htkcode = 9;
tmpdir = tempname(config.tmp_dir);
mkdir(tmpdir);
f = fopen(config.test_list_file, 'w');
f2 = fopen(config.ref_file, 'w');
fprintf(f2, '#!MLF!#\n');
for i = 1:length(features_test)
    fname = [tmpdir, num2str(i), '_', labels_test{i}, '.lab'];
    fprintf(f2, '"%s"\n', fname);
    for j=1:1:length(segfile{i}.segment_name)
        
        if segfile{i}.segmentation(j) > segfile{i}.segmentation_end(j)
            disp('Wrong segmentation');
        end
        if j>1 && segfile{i}.segmentation(j) < segfile{i}.segmentation(j-1)
            disp('Wrong segmentation');
        end
            
        fprintf(f2, '%d %d %s \n', (segfile{i}.segmentation(j)) * 100000, (segfile{i}.segmentation_end(j)) * 100000, segfile{i}.segment_name{j});
    end
    fprintf(f2, '.\n');
    fprintf(f, '"%s"\n', fname);
    htkwrite(features_test{i}, fname, htkcode);
end
fclose(f);
fclose(f2);


%% prepare files
htkcode = 9;
for i = 1:length(features_test)
    fname = [strrep( tmpdir, config.tmp_dir,  config.label_dir), num2str(i), '_', labels_test{i}, '.lab']
    f2 = fopen(fname, 'w');
    for j=1:1:length(segfile{i}.segment_name)
        fprintf(f2, '%d %d %s \n', (segfile{i}.segmentation(j)) * 100000, (segfile{i}.segmentation_end(j)) * 100000, segfile{i}.segment_name{j});
    end
    fprintf(f2, '.\n');
    fclose(f2);
end

dos(['del /Q "',tmpdir,'"']);
dos(['rmdir /Q "',tmpdir,'"']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% run recognition

disp([get_htk_path 'HVite -A -D -T 1 -H "', config.hmm_file_name,'"  -i "', config.recog_file,'" -w "', config.latice_file, '" "', config.dict_file,'"  "', config.hmm_list_file,'" -S "', config.test_list_file,'" ']) % -d "', config.dir_hmm_def,'"
[res, txt] = system([get_htk_path 'HVite -A -D -T 1 -H "', config.hmm_file_name,'"  -i "', config.recog_file,'" -w "', config.latice_file, '" "', config.dict_file,'"  "', config.hmm_list_file,'" -S "', config.test_list_file,'" ']) % -d "', config.dir_hmm_def,'"

if res ~= 0
    disp(num2str(res));
    error(txt);
end


%% Error because confMat gets too large 
disp([get_htk_path 'HResults -f -h -n -t -u 10.0 -p -A -D -T 1 -L "', config.label_dir(1:end-1), '" "', config.hmm_list_file,'" "', config.recog_file,'"'])
[res, txt] = system([get_htk_path 'HResults -f -h -n -t -u 10.0 -p -A -D -T 1 -L "', config.label_dir(1:end-1), '" "', config.hmm_list_file,'" "', config.recog_file,'"'])
txt
if res ~= 0
    disp(num2str(res));
%     error(txt);
end
fid = fopen(config.output_file,'w');
fprintf(fid,'%s',txt);
fclose(fid);



end