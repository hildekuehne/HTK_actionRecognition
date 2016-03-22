function [ frames_start, frames_end, names ] = get_segmentation_frames( filename )
%GET_SEGMENTATION_FRAMES reads the segmentation information from an
%xml-file. For a detailed description of the xml structure, please read the
%README file
%
% Input:
% filename - xml-file
%
% Output:
% frames_start - first frame of the units 
% frames_end - last frame of the units 
% names - unit names
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

s = parseXML(filename);
frames_start = [];
frames_end = [];
names = {};
if  strcmp(s.Children(1, 2).Name, 'MotionLabel')
    for c = s.Children
        if strcmp(c.Name, 'MotionLabel')
            found_frame = false;
            found_name = false;
            for a = c.Attributes
                if strcmp(a.Name, 'startPoint')
                    frames_start(end+1) = str2num(a.Value);
                    found_frame = true;
                elseif strcmp(a.Name, 'endPoint')
                    frames_end(end+1) = str2num(a.Value);
                    found_frame = true;
                elseif strcmp(a.Name, 'name')
                    names{end+1} = a.Value;
                    found_name = true;
                end
            end
            if ~found_name || ~found_frame
                filename
                error
            end
        end
    end
elseif strcmp(s.Children(1, 2).Children(1, 2).Name, 'MotionLabel')
    for c = s.Children(1, 2).Children
        if strcmp(c.Name, 'MotionLabel')
            found_frame = false;
            found_name = false;
            for a = c.Attributes
                if strcmp(a.Name, 'startPoint')
                    frames_start(end+1) = str2num(a.Value);
                    found_frame = true;
                elseif strcmp(a.Name, 'endPoint')
                    frames_end(end+1) = str2num(a.Value);
                    found_frame = true;
                elseif strcmp(a.Name, 'name')
                    names{end+1} = a.Value;
                    found_name = true;
                end
            end
            if ~found_name || ~found_frame
                filename
                error
            end
        end
    end
end

end

function theStruct = parseXML(filename)
% PARSEXML Convert XML file to a MATLAB structure.
try
   tree = xmlread(filename);
catch
   error('Failed to read XML file %s.',filename);
end

% Recurse over child nodes. This could run into problems 
% with very deeply nested trees.
try
   theStruct = parseChildNodes(tree);
catch
   error('Unable to parse XML file %s.',filename);
end
end


% ----- Subfunction PARSECHILDNODES -----
function children = parseChildNodes(theNode)
% Recurse over node children.
children = [];
if theNode.hasChildNodes
   childNodes = theNode.getChildNodes;
   numChildNodes = childNodes.getLength;
   allocCell = cell(1, numChildNodes);

   children = struct(             ...
      'Name', allocCell, 'Attributes', allocCell,    ...
      'Data', allocCell, 'Children', allocCell);

    for count = 1:numChildNodes
        theChild = childNodes.item(count-1);
        children(count) = makeStructFromNode(theChild);
    end
end
end

% ----- Subfunction MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.

nodeStruct = struct(                        ...
   'Name', char(theNode.getNodeName),       ...
   'Attributes', parseAttributes(theNode),  ...
   'Data', '',                              ...
   'Children', parseChildNodes(theNode));

if any(strcmp(methods(theNode), 'getData'))
   nodeStruct.Data = char(theNode.getData); 
else
   nodeStruct.Data = '';
end
end

% ----- Subfunction PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
% Create attributes structure.

attributes = [];
if theNode.hasAttributes
   theAttributes = theNode.getAttributes;
   numAttributes = theAttributes.getLength;
   allocCell = cell(1, numAttributes);
   attributes = struct('Name', allocCell, 'Value', ...
                       allocCell);

   for count = 1:numAttributes
      attrib = theAttributes.item(count-1);
      attributes(count).Name = char(attrib.getName);
      attributes(count).Value = char(attrib.getValue);
   end
end
end