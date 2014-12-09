function main(proj_name, exp_id, feature_ext, suffix, feat_dim, ker_type, cross, open_pool)

addpath('/net/per900a/raid0/plsang/tools/kaori-secode-calker/support');
addpath('/net/per900a/raid0/plsang/tools/libsvm-3.17/matlab');
%addpath('/net/per610a/export/das11f/plsang/softwares/libsvm-316/matlab');
%addpath('/net/per900a/raid0/plsang/tools/libsvm-3.12/matlab');
%addpath('/net/per900a/raid0/plsang/tools/vlfeat-0.9.16/toolbox');

run('/net/per900a/raid0/plsang/tools/vlfeat-0.9.16/toolbox/vl_setup');
% run vl_setup with no prefix
% vl_setup('noprefix');


%proj_name = 'trecvidmed11';
%exp_name = 'trecvidmed11-100000';
%kf_name = 'keyframe-100000';
exp_name = [proj_name, '-', exp_id];
kf_name = ['keyframe-', exp_id];

if isequal(proj_name, 'trecvidmed10'),
	events = {'assembling_shelter', 'batting_in_run', 'making_cake'};
elseif isequal(proj_name, 'trecvidmed11'),
	events = {'E006', 'E007', 'E008', 'E009', 'E010', 'E011', 'E012', 'E013', 'E014', 'E015', };
else
	error('Unknown project name !!!\n');
end

%feature_ext = 'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed11.devel.kcb.l2';
%feature_ext = 'mfcc.Soft-4000-VL2.trecvidmed11.devel.kcb.l2';
%feature_ext = 'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed11.devel.fc.l2';
%feature_ext = 'dense6.sift.Soft-4000-VL2.trecvidmed11.devel.kcb.l2';

if ~exist('suffix', 'var'),
	suffix = '';
end

if ~exist('feat_dim', 'var'),
	feat_dim = 4000;
end

if ~exist('ker_type', 'var'),
	ker_type = 'echi2';
end

if ~exist('cross', 'var'),
	cross = 0;
end

if ~exist('open_pool', 'var'),
	open_pool = 0;
end


if isempty(strfind(suffix, '-v5')),
	warning('Suffix does not contain v5...\n');
end

ker = calker_build_kerdb(proj_name, exp_name, feature_ext, ker_type, feat_dim, cross, suffix);

calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
if ~exist(calker_exp_dir, 'file'),
	mkdir(calker_exp_dir);
	mkdir(fullfile(calker_exp_dir, 'metadata'));
	mkdir(fullfile(calker_exp_dir, 'kernels'));
	mkdir(fullfile(calker_exp_dir, 'scores'));
	mkdir(fullfile(calker_exp_dir, 'models'));
end

videolevel = strcmp('100000', exp_id);

calker_create_database(proj_name, exp_name, kf_name, ker);
calker_create_traindb(proj_name, exp_name, ker);

%open pool
if matlabpool('size') == 0 && open_pool > 0, matlabpool(open_pool); end;
calker_cal_train_kernel(proj_name, exp_name, ker);
calker_train_kernel(proj_name, exp_name, ker, events);
calker_cal_test_kernel(proj_name, exp_name, ker);
calker_test_kernel(proj_name, exp_name, ker, events);
calker_cal_map(proj_name, exp_name, ker, events, videolevel);
calker_cal_rank(proj_name, exp_name, ker, events);

%close pool
if matlabpool('size') > 0, matlabpool close; end;
