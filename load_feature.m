
function hists = load_feature(tarFile)
    tmpDir = '/net/per900a/raid0/plsang/tmp';
	try
    oFile = untar(tarFile, tmpDir);
	catch
		hists = [];
		return;
	end
    oFile = cell2mat(oFile);
    
    fid = fopen(oFile, 'r');
    tline = fgets(fid);
    
	hists = [];
	
    while ischar(tline)
        %skip comment lines, start with %
        if strfind(tline, '%') == 1, 
			tline = fgets(fid);
			continue; 
		end
		
        [szFea ~] = strread(tline, '%s %s', 'delimiter', '%');
        szFea = cell2mat(szFea);
        %szAnn = cell2mat(szAnn);
        
        fea = sscanf(szFea, '%f');
        % check if read corectly: numDim n1 n2 ... nDim
        if fea(1) ~= length(fea) - 1
            error('ERROR: Reading feature file [Feature Dim: %d / Actual Dim: %d]\n', ...
                fea(1), length(fea) - 1); 
        end
        
        hists = [hists fea(2:end)];
        
        % read next line
        tline = fgets(fid);
    end

    fclose(fid);
    delete(oFile);
end
