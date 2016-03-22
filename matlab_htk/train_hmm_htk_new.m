function hmm = train_hmm_htk(trdata, label, hmm, niter, verb, CVPRIOR)
% hmmparams = train_hmm_htk(trdata, hmm_template, niter, verb, cvprior);
%
%  Train a Hidden Markov Model using HTK.  hmm_template defines the
%  initial HMM parameters (number of states, emission type, initial
%  transition matrix...).  
%
% Inputs:
% trdata  - training data (cell array of training sequences, each
%                          column of the sequences arrays contains a
%                          data point in the time series)
% hmm_template - structure defining the initial HMM parameters:
%        .nstates       -  number of states.  Defaults to 2
%        .emission_type - 'gaussian' or 'GMM'.  Defaults to
%                         'gaussian'
%        .transmat      - initial transition matrix (log
%                          probabilities).  Defaults to fully
%                          connected 
% niter   - number of EM iterations to perform.  Defaults to 10
% verb    - set to 1 to output loglik at each iteration
%
% Outputs:
% hmmparams - structure containing hmm parameters learned from the training
%             data 
%
% 2006-06-16 ronw@ee.columbia.edu

% Copyright (C) 2006-2007 Ron J. Weiss
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

if nargin < 3
  hmm.nstates = 2;
end

if nargin < 4
  niter = 10;
end

if nargin < 5
  verb = 0;
end

% prior on observation covariances to avoid overfitting:
if nargin < 6
  CVPRIOR = 1;
end

% Temporary file to use
if exist('hmm.ind_nr', 'var') || isempty(hmm.ind_nr)
    rnd = num2str(round(10000*rand(1)));
else
    rnd = num2str(hmm.ind_nr);
end

% initial HTK HMM: HInit/HCompV? 
hmmfilename = ['./tmp/',label,'_htkhmm_' rnd];

if ~isempty(dir(hmmfilename))
    % read in hmm:
    disp(['read in hmm: ', hmmfilename])
    hmm = read_htk_hmm(hmmfilename);
    return;
end

if ~iscell(trdata)
  trdata = {trdata};
end
nseq = length(trdata);
[ndim, nobs(1)] = size(trdata{1});

% HInit support is currently broken
use_hinit = 1;


% default hmm parameters
nstates = hmm.nstates;
if ~isfield(hmm, 'emission_type')
  hmm.emission_type = 'gaussian';
end
if ~isfield(hmm, 'transmat')
  hmm.transmat = log(ones(nstates)/nstates);
end
if ~isfield(hmm, 'start_prob')
  hmm.start_prob = log(ones(1, nstates)/nstates);
end
if ~isfield(hmm, 'end_prob')
  hmm.end_prob = log(ones(1, nstates)/nstates);

  % normalize transmat and end_prob properly
  if size(hmm.end_prob, 2) == 1
    hmm.end_prob = hmm.end_prob';
  end
  norm = log(exp(logsum(hmm.transmat, 2)) + exp(hmm.end_prob'));
  hmm.transmat = hmm.transmat - repmat(norm, 1, nstates);
  hmm.end_prob = hmm.end_prob - norm';
end
if strcmp(hmm.emission_type, 'gaussian') 
  if ~isfield(hmm, 'means')
    % init using k-means:
    hmm.means = kmeans(cat(2, trdata{:}), nstates, niter/2);
  end
  if ~isfield(hmm, 'covars')
    hmm.covars = ones(ndim, nstates);
  end
end
if strcmp(hmm.emission_type, 'GMM') 
  if ~isfield(hmm, 'gmms')
%     hmm.gmms = cell(nstates);
    hmm.gmms = struct;
  end
  if ~isfield(hmm.gmms(1), 'nmix')
    nmix = 3;
    for x = 1:nstates
      hmm.gmms(x).nmix = nmix;
    end
  else
    nmix = hmm.gmms(1).nmix;
  end
  if ~isfield(hmm.gmms(1), 'priors')
    priors = log(ones(1, nmix)/nmix);
    for x = 1:nstates
      hmm.gmms(x).priors = priors;
    end
  end
  if ~isfield(hmm.gmms(1), 'means')
    means = kmeans(cat(2, trdata{:}), nmix, niter/2);
    for x = 1:nstates
      hmm.gmms(x).means = means;
    end
  end
  if ~isfield(hmm.gmms(1), 'covars')
    covars = ones(ndim, nmix);
    for x = 1:nstates
      hmm.gmms(x).covars = covars;
    end
  end
end


% write temp files for each sequence
count = 1;
for n = 1:length(trdata)
    
    if size(trdata{n}, 2) >  nstates + 1
    %   datafilename{n} = ['./tmp/matlabtmp_htkdat_' rnd '_' num2str(n), '.dat']; 
      datafilename{count} = ['./tmp/',label,'_htkdat_' rnd '_' num2str(n), '.dat']; 

      % custom data format:
      htkcode = 9;  % USER
      %htkcode = 6;  % MFCC
      htkwrite(trdata{n}', datafilename{count}, htkcode);
      count = count + 1;
    end
end
scpfilename = ['./tmp/',label,'_htkdatafiles_' rnd '.scp'];
write_text_file(scpfilename, datafilename);

% initial HTK HMM: HInit/HCompV? 
hmmfilename = ['./tmp/',label,'_htkhmm_' rnd];
hmm.name = [label,'_htkhmm_' rnd];
write_htk_hmm(hmmfilename, hmm); 

if use_hinit
  args = ['-i ' num2str(niter) ' -v ' num2str(CVPRIOR)];
  args = [args ' -T 1'];
  if verb > 1
    args = [args ' -A -V -D'];
  end
  disp('running HInit...');
  datestr(now)
  disp([get_htk_path 'HInit ' args ' ' hmmfilename ' ' sprintf('%s ', datafilename{:})])
  system([get_htk_path 'HInit ' args ' ' hmmfilename ' ' sprintf('%s ', datafilename{:})]);
  datestr(now)
  disp('done.');
end 

% run HRest to train:
disp('Run HRest to train:');
%system(['HRest -A -D -T 1777 -t -v 0.000001 ' hmmfilename ' ' sprintf('%s ', datafilename{:})]);
args = ['-t -M ./tmp -i ' num2str(niter) ' -v ' num2str(CVPRIOR)];
if verb
  args = [args ' -T 3'];
  if verb > 1
    args = [args ' -A -V -D'];
  end 
end

disp([get_htk_path 'HRest ' args ' ' hmmfilename ' ' sprintf('%s ', datafilename{:})])
[retval, txt] = system([get_htk_path 'HRest ' args ' ' hmmfilename ' ' sprintf('%s ', datafilename{:})]);
txt

if retval ~= 0
  error('HTK error!');
end

% % Creating Tied-State Triphones 
% disp('Creating Tied-State Triphones');
% disp([get_htk_path 'HHEd -B -H hmm12/macros -H hmm12/hmmdefs -M hmm13 \tree.hed triphones1 > log']);
% [retval, txt] = system([get_htk_path 'HHEd -B -H hmm12/macros -H hmm12/hmmdefs -M hmm13 \tree.hed triphones1 > log']);
% txt

if retval ~= 0
  error('HTK error!');
end

if verb
  disp(['******** DONE ********'])
end


% read in hmm:
hmm = read_htk_hmm(hmmfilename);

% clean up:
% delete(hmmfilename);
for n = 1:length(datafilename);
  delete(datafilename{n});
end
% done.
