% this script convert a raw EMG data file from Delsys format to OTB format
% acceptable to MUedit package


function output = DelsysToOtbFormater()
     clc
     [signal,file] = openDelsysFile();


    % time is not used in the scipt. only take the first signal as a
    % reference
    [m n] =  size(signal.Time);
    output.Time = {(signal.Time(1,:))'};

    
     % print the signal names
     signalNames = table([1:m]',signal.Channels);
     disp(signalNames)

     % select the signal to be extracted
     prompt = 'Enter the index of the FORCE signal to be extracted: ';
     signalNumber1 = input(prompt);

     % extract the force signal 
     output.path = signal.Data(signalNumber1,:);


     % select the ref signal to be extracted
     prompt = 'Enter the index of the ref signal to be extracted: ';
     signalNumber2 = input(prompt);
     output.target = signal.Data(signalNumber2,:)';
     % the reference target signal need to be interpolated to match the force signal time
     output.target = interp1(signal.Time(signalNumber2,:),output.target,signal.Time(signalNumber1,:),'linear','extrap');

     % plot the signal to verify
     figure()
     plot(output.Time{1},output.path,"Color","b","LineWidth",1.5), hold on
     plot(output.Time{1},output.target,"Color","r","LineWidth",1.5), hold off
     title(['Force Signal: ', file],'Interpreter', 'none') , legend('Force','Ref')
     xlabel('Time (s)')
     ylabel('Force (N)')

     % delete extracted signal from the signal structure
     signal.Data([signalNumber1, signalNumber2],:) = [];
     output.data = signal.Data;

     % get the number of sensors
     output.nChan = size(output.data,1);
     output.ngrid = output.nChan/4;          % 4 sensors per grid for the Delsys Trigno

     % repeat te gird name for each sensor
     output.gridname = repelem({"Galileo"},1,output.ngrid);

     % remove two rows from the signal name table
     signalNames([signalNumber1, signalNumber2],:) = [];

     % get the muscle names
     for i = 1:output.ngrid
          k = strfind(signalNames.Var2((i-1)*4+1,:),':');
         output.muscle{i} = convertCharsToStrings(signalNames.Var2((i-1)*4+1,(1:k-1)));
     end
     
     output.fsamp = signal.Fs(1);


     % save the output
     saveOutput(output,file)

     
end

% Open Delsys Matlab file
function [S,file] = openDelsysFile()
     % get file location
    [file,path,fileType] = uigetfile({'*.mat';'*.txt'},'select .mat file or .txt file only');
    if isequal(file,0)
        disp('User selected Cancel');
    else
        disp(['User selected ', (file)]);
        disp(['In ', (path)]);
    end

     % load file
     if fileType == 1
          S = load(fullfile(path,file));
     end

end

% save the output in a .mat file
function saveOutput(signal,file)

     % default name concatenation with file
     dFileName = [file, '_OTBformat.mat'];
    % get file location
    [file,path,fileType] = uiputfile({'*.mat'},'Save the output as .mat', dFileName);
    if isequal(file,0)
        disp('User selected Cancel');
    else
        disp(['File saved in', fullfile(path,file)]);
    end

    % save file
    if fileType == 1
        save(fullfile(path,file),'signal');
    end
end