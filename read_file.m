
function list = read_file(gt_file)

    fid = fopen(gt_file, 'r');
    tline = fgets(fid);
    i = 1;
    while ischar(tline)
        %disp(tline)
        list{i} = strtrim(tline);
        i = i+1;
        tline = fgets(fid);
    end

    fclose(fid);

end

