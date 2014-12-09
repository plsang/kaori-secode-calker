function calker_cal_test_kernel(proj_name, exp_name, ker)
	
feature_ext = ker.feat;

calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

devHistPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, ker.histName);
if ~exist(devHistPath),
	error('File [%s] not found!\n');
end
dev_hists = load(devHistPath, 'dev_hists');
dev_hists = dev_hists.dev_hists;

testHistPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, ker.testHists);
scaleParamsPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, ker.scaleparamsName);
	
fprintf('\tLoading test features for kernel %s ... \n', feature_ext) ;
if exist(testHistPath),
    load(testHistPath);
else
    test_hists = calker_load_testdata(proj_name, exp_name, ker);
	
	if ker.feature_scale == 1,	
		fprintf('Feature scaling...\n');	
		if ~exist(scaleParamsPath, 'file'),
			error('Scale parameters [%s] not found!\n', scaleParamsPath);
		end
		load(scaleParamsPath, 'scale_params');;	
		test_hists = calker_feature_scale(test_hists, scale_params);	
	end
	
    save(testHistPath, 'test_hists', '-v7.3');
end

fprintf('\tLoading kernel info for heuristic mu... \n') ;
heu_kerPath = sprintf('%s/kernels/%s.heuristic.mat', calker_exp_dir, ker.devname);
heu_ker = load( heu_kerPath );
if strcmp(ker.type, 'echi2'),
	if ~isfield(heu_ker, 'mu'),
		error('Mu is not set in kernel info...\n');
	end
	ker.mu = heu_ker.mu;	
end

num_part = ceil(size(test_hists, 2)/ker.chunk_size);
cols = fix(linspace(1, size(test_hists, 2) + 1, num_part+1));

% cal test kernel using num_part partition

fprintf('-- Partitioning test kernel %s into %d partition(s) \n', feature_ext, num_part);
		
par_test_hists = cell(num_part, 1);

for jj = 1:num_part,
	sel = [cols(jj):cols(jj+1)-1];
	par_test_hists{jj} = test_hists(:, sel);
end
	
clear test_hists;		

fprintf('-- Calculating test kernel %s with %d partition(s) \n', feature_ext, num_part);

parfor jj = 1:num_part,
	sel = [cols(jj):cols(jj+1)-1];
	part_name = sprintf('%s_%d_%d', ker.testname, cols(jj), cols(jj+1)-1);
	kerPath = sprintf('%s/kernels/%s.%s.mat', calker_exp_dir, part_name, ker.type);

	if ~exist(kerPath, 'file')
		
		fprintf('\tCalculating test kernel %s [ker_type = %s] [range: %d-%d]... \n', feature_ext, ker.type, cols(jj), cols(jj+1)-1) ;
		testKer = calcKernel(ker, dev_hists, par_test_hists{jj});
		%save test kernel
		fprintf('\tSaving kernel ''%s''.\n', kerPath) ;
		par_save( kerPath, testKer ) ;
			
	else	
		fprintf('Skipped calculating test kernel %s [range: %d-%d] \n', feature_ext, cols(jj), cols(jj+1)-1);
	end

end


%% clean up
clear dev_hists;
clear test_hists;
clear kernel;
clear testKer;
end


function par_save( kerPath, testKer )
	ssave(kerPath, '-STRUCT', 'testKer', '-v7.3') ;
end
