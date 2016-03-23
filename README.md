```
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
```

# HTK_actionRecognition
Matlab demo for action recognition with HTK

This package contains a set of helper-functions to support action recognition with HTK in Matlab. A detailed description of the system i.e. how activity classification, temporal video segmentation and action detection works with ASR enignes is given here:

http://pages.iai.uni-bonn.de/kuehne_hilde/projects/end2end/index.html

and here:

http://serre-lab.clps.brown.edu/resource/breakfast-actions-dataset/

If you use this code in your project, please cite:
```
@InProceedings{Kuehne16end,
author = {Hilde Kuehne and Juergen Gall and Thomas Serre},
title = {An end-to-end generative framework for video segmentation and recognition},
booktitle = {Proc. IEEE Winter Applications of Computer Vision Conference (WACV 16)},
year = {2016},
month = {Mar},
address = {Lake Placid},
}
```
The code is free for any personal or academic use under GNU-GPL without any warranty. Please regard licensing of third-party packages.

The functions have been tested under Win (with HTK 3.4) and Linux (HTK 3.5). Any questions, comments and recommendations are always welcome. Please contact me under kuehne @ iai . uni-bonn . de

-------------------------------------- 
CONTENT:
-------------------------------------- 

Part 0 : Short Version

Part I : Installation

Part II : Set environmental variables

Part III : Run the demo

Part IV : Evaluation

Part V : Parameter adaption 

Part VI : Run your own data


-------------------------------------- 
Part 0 : Short Version
-------------------------------------- 

Step 1) Install HTK : http://htk.eng.cam.ac.uk/ (please make sure it works by running some examples) 

Step 2) Download the repository. 

Step 3) Download the  training and test data ( https://uni-bonn.sciebo.de/index.php/s/lqj3GNVQWXaX1WC ) and unpack them into ./HTK_actionRecognition/demo_breakfast/breakfast_data

Step 4) Adapt the path in the ./HTK_actionRecognition/matlab_wrapper/get_htk_path.m function to your HTK local configuration.  

Step 5) Adapt the path in the ./HTK_actionRecognition/demo_breakfast/demo_breakfast.m (line 7) script to the full path of your local configuration   
```
path_root = '<YouPathHere>/HTK_actionRecognition/demo_breakfast'; 
```
Step 6) Run the demo by simply running the script ./HTK_actionRecognition/demo_breakfast/demo_breakfast.m : 
> demo_breakfast

-------------------------------------- 
Part I : Installation
-------------------------------------- 

To run the demo you need to:

Step 1) Install HTK : http://htk.eng.cam.ac.uk/ (please make sure it works by running some examples) 

Step 2) Download the repository. 

Step 3) Download the corresponding training and test data and unpack them in the related demo directory:

- For demo_breakfast: 

  Download breakfast_data.tar.gz (~1 GB) under https://uni-bonn.sciebo.de/index.php/s/lqj3GNVQWXaX1WC
  
  Unpack to ./HTK_actionRecognition/demo_breakfast/breakfast_data
  
  File structure should be: 
```  
  ./HTK_actionRecognition/demo_breakfast/breakfast_data/s1/cereals/...
  ./HTK_actionRecognition/demo_breakfast/breakfast_data/s1/coffee/...
  ./HTK_actionRecognition/demo_breakfast/breakfast_data/s1/freidegg/...  etc.
```

Step 4) The path to the HTK binaries is hardcoded in the function ./HTK_actionRecognition/matlab_wrapper/get_htk_path.m . Please adapt this function to your local configuration.

-------------------------------------- 
Part II : Set environmental variables
--------------------------------------

For the following steps or in case you want to adapt the system to your local configuration, it’s highly recommended to use full path names (!) as the script switches between different directories. You can use relative path names, but make sure, you know what you do. 

Step 5) Adjust the script demo_breakfast.m by setting the full path of your local configuration (demo_breakfast.m, line 7)
```
% root folder with this script
path_root = '<YouPathHere>/HTK_actionRecognition/demo_breakfast';
```

### Optional Settings: (skip this part if you just want to run the demo)


Step 5.1)  Adapt folder with the input data (demo_breakfast.m, line 23)
```
% folder with the input data
path_input = fullfile(path_root, 'breakfast_data');
```

Step 5.2)  Adapt folder for temporary files and output  (demo_breakfast.m, line 26)
```
% folder to write temprorary files and output:
path_output = fullfile(path_root, 'htk_output');
```

In this folder two subfolders, 'generated' and 'output' will be created:

- 'generated' : contains the htkhmm-files and is used for all temporary files needed for and/or generated by HTK. htkhmm-files are store in case the training is interrupted and will be loaded by default if it's resumed afterwards. 

- 'output' contains:
	
	- the HTK hmm file, containing hmm descriptions for each unit: e.g. breakfast_-2sts_1mix_s1.hmms (contains: name_<numberOfStates>sts_<numberOfMixtures>mix_s<split>.hmms)
	
	- the reference file, containing the original (loaded) annotations: e.g. demo_breakfast_ref_s1.ref.mlf (contains: name_s<split>.ref.mlf)
	
	- the recognition file, containing the recognized units: e.g. demo_breakfast_output_s1.reco.mlf (contains: name_s<split>.reco.mlf)
	
	
	- the dictionary list: e.g. breakfastlist.txt
	
	- the test file list: e.g. breakfasttest.list

You can modify the naming of the output by adapting the related variables in the config struct in the get_breakfast_demo_config.m or by overwriting them. 

Step 5.3) Set directory with segmentations (demo_breakfast.m, line 51)
```
% folder with segmentation files (xml-style)
config.features_segmentation = fullfile(path_root, '/segmentation');
```

Step 5.4) Set dictionary and grammar file (demo_breakfast.m, line 53 + 55). 
```
% dictionary file
config.dict_file = fullfile(path_root, '/breakfast.dict');
% grammar file
config.grammar_file = fullfile(path_root, '/breakfast.grammar');
```

... and you should be good to go!
If you want to change anything else, just have a look at the config struct.

-------------------------------------- 
Part III : Run the demo
--------------------------------------

Step 6) Run the demo by simply running the script:

> demo_breakfast

which calls the function:
```
run_htk(config);  %  (demo_breakfast.m, line 62)
```

If all paths are correct, you should see the list of loaded files and the output of htk training and recognition.

The overall runtime for one test and training was ~3.2h on a 3.30 GHz Intel i5.

The demo runs only the first split (s1) for testing and the other three (s2-s4) for training (see also http://serre-lab.clps.brown.edu/resource/breakfast-actions-dataset/ for details on the dataset). If you want a full cross validation, you need to adapt the 'config.pattern_test' and 'config.pattern_train'  (e.g. get_breakfast_demo_config.m, line 35 + 37) and the split number 'use_split'  (e.g. get_breakfast_demo_config.m, line 30) for proper out file names.


-------------------------------------- 
Part IV : Evaluation
--------------------------------------

The recognized sequences are listed in the output files under ./HTK_actionRecognition/demo_breakfast/output/breakfast_out/demo_breakfast_output_s1.reco.mlf. 

For the evaluation on sequence and unit level you can run:
```
% evaluation of sequences
[accuracy_seq, confmat_seq, test_label_seq, predicted_label_seq]  = get_results_seq(config);

% evaluation of units
vis_on = 0;
[accuracy_units, acc_unit_parsing, acc_unit_rec, acc_units_perFrames, res_all] = get_results_units(config, vis_on);
```

The output is the overall sequence recognition accuracy, the confusion matrix as well as the test and predicted labels of each sequence.

Input for both is the config and, for the unit evaluation a visualization flag showing the test and recognized sequences on unit level.
Output of the unit evaluation is as follows:
```
	- acc_activity - the accuracy of sequence labels
	- acc_sequence_all - the accuracy of unit parsing
	- acc_units_perFrames - the accuracy of frame-based unit evaluation (segmentation accuracy)
	- res_all - contains the following evaluation of test and reference data:
		res_all.test_label_units - the test units for each sequence  
		res_all.predicted_label_units - the predicted units for each sequence  
		res_all.accuracy_units_dtw - the unit accuracy based on unit error rate (1 - unit_error_rate) after alignment by DTW 
		res_all.test_label_sequence_dtw - the test units for each sequence after alignment by DTW 
		res_all.predicted_label_sequence_dtw - the predicted units for each sequence after alignment by DTW 
		res_all.accuracy_sequence_dtw - the accuracy of units per sequence after alignment by DTW 
		res_all.test_label_units_perFrames - the test frames (in unit labels) for each sequence 
		res_all.predicted_label_units_perFrames - the recognized frames (in unit labels) for each sequence 
		res_all.accuracy_units_perFrames - the per frame accuracy of each sequence 
		res_all.accuracy_action - accuracy for sequence recognition 
		res_all.test_label_action - test sequence labels 
		res_all.predicted_label_action - recognized sequence labels 
```

HTK output details in general:

- The output folder ./HTK_actionRecognition/demo_breakfast/output/breakfast_out contains:
	
	- the HTK hmm file with hmm descriptions for each unit: e.g. breakfast_-2sts_1mix_s1.hmms (syntax:  name_<numberOfStates>sts_<numberOfMixtures>mix_s<split>.hmms)
	
	- the reference file, containing the original (loaded) annotations: e.g. demo_breakfast_ref_s1.ref.mlf (syntax:  name_s<split>.ref.mlf)
	
	- the recognition file, containing the recognized units: e.g. demo_breakfast_output_s1.reco.mlf (syntax:  name_s<split>.reco.mlf)
	
	- the dictionary list: e.g. breakfastlist.txt
	
	- the test file list: e.g. breakfasttest.list


For a further analysis of the htk output, please consider the htk book. 


-------------------------------------- 
Part V : Parameter adaption 
--------------------------------------

If you want to run HTK on new data, it might be necessary to adapt various elements to improve the overall performance.
Most settings are accessible via the config struct. You can either override the values or adapt them in the get_breakfast_demo_config.m files.

- Number of states:
```
config.defnumstates = [ -1 = median length of frames, -2 = median linear divided by 10, > 0 fix number of states ]
```
- Number of Gaussians:
```
config.numberOfMixtures = [ 1 ... n ]  
```
- Normalization:
```
config.normalization =
	'none' = no normalization;
	'full' = scales all values in the sequence from [0 .. 1];
	'frame' = scales all values of a frame from [0 .. 1];
	'std' = standard score (or Z-score) over all values in the sequence, mean = 0 and standard deviation = 1
	'std_frame' = standard score (or Z-score) for each frame, mean = 0 and standard deviation = 1
```	
- Number of min / max samples to use (classes with fewer number of samples are filled by minority over sampling, classes with more samples are reduced, adapt this to avoid imbalanced training)
```
config.min_number_samples = xxx;
config.max_number_samples = xxx;
```

- Read the htk book. You can find a lot of usefull hints how to interpret the results and adapt the system to different data corpora and domains.


-------------------------------------- 
Part VI : Run your own data
--------------------------------------

If you want to run HTK with different input data or on a new dataset, you will have to provide the input data and, if you want to try a different dataset, the segmentation information for each video, a related grammar and a dictionary.

1) Input files

The input files are plain ascii txt-files. Each line contains the input vector of one frame. The first line is zeros, and the first entry of each line is the frame number. E.g. if you got a 16 dimensional input vector and 330 frames, the overall file would have 331 lines (first line zeros) with 17 entries per line (frame number + input vector): 
```
0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0  
1  <values ...
2  ... 
3  ...
4  ...
5
6
.
.
330 ...
```

If you want try your input (e.g. different features, quantization etc.), you just have to convert your frame based representation to the related structure and save it as ascii .txt file.


2) Segmentation 

The segmentation files are based on the following xml-structure:
```
<MotionLabeling author=" ... " motionFile=" ... " motionFilePathType=" ... " motionFileType=" ... " motionSequenceName=" ... " segType=" ... " segmentationCriteria=" ... "> 
<Limb name="whole_body"> 
<MotionLabel name=" ... " startPoint=" ... " endPoint=" ... "/> 
.
.
.

</Limb> 
</MotionLabeling> 
```


The additional header tags are not used and can be omitted if necessary.
The child node 'MotionLabel' comprises the relevant information: 

- 'name' is the name of the unit and has to be identical to the unit names listed in the dictionary and grammar. 

- 'startPoint' is the first frame of the unit 

- 'endPoint' is the last frame of the unit. If no end point is set, it is assumed that the unit ends at the last frame before the beginning of the next unit.  

Segmentation files need to have the same folder structure + file names as the corresponding data files.


3) Dictionary and grammar

If you want to change or write your own dictionary and grammar, please follow the instructions in the HTK book and change the source links in the config. If you need help adapting the code to your system, please contact me under  kuehne @ iai . uni-bonn . de .
