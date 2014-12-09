function calker_main(proj_name, exp_name, kf_name)

addpath('/net/per900a/raid0/plsang/tools/mkl/support');
addpath('/net/per900a/raid0/plsang/tools/libsvm-3.12/matlab');
addpath('/net/per900a/raid0/plsang/tools/vlfeat-0.9.13/toolbox');

% run vl_setup with no prefix
vl_setup('noprefix');

%events = {'assembling_shelter', 'batting_in_run', 'making_cake'};
events = {'E006', 'E007', 'E008', 'E009', 'E010', 'E011', 'E012', 'E013', 'E014', 'E015', };

feature_ext = 'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed11.devel.kcb.l2';
%feature_ext = 'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed11.devel.fc.l2';

calker_exp_dir = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s-calker/%s', proj_name, exp_name, feature_ext);
if ~exist(calker_exp_dir, 'file'),
	mkdir(calker_exp_dir);
	mkdir(fullfile(calker_exp_dir, 'metadata'));
	mkdir(fullfile(calker_exp_dir, 'kernels'));
	mkdir(fullfile(calker_exp_dir, 'scores'));
	mkdir(fullfile(calker_exp_dir, 'models'));
end

feat_dim = 4000;
ker_type = 'echi2';
ker = calker_build_kerdb(proj_name, exp_name, feature_ext, ker_type, feat_dim);

calker_create_database(proj_name, exp_name, kf_name, ker);
calker_create_traindb(proj_name, exp_name, ker);
calker_cal_kernel(proj_name, exp_name, ker);

calker_train_kernel(proj_name, exp_name, ker, events);
calker_test_kernel(proj_name, exp_name, ker, events);
calker_cal_map(proj_name, exp_name, ker, events);

end