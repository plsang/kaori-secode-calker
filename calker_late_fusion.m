function calker_late_fusion(proj_name, exp_name, suffix)

	if ~exist('suffix', 'var'),
		suffix = '';
	end
	
	addpath('/net/per900a/raid0/plsang/tools/kaori-secode-calker/support');
	addpath('/net/per900a/raid0/plsang/tools/libsvm-3.17/matlab');
	addpath('/net/per900a/raid0/plsang/tools/vlfeat-0.9.16/toolbox');

	events = {'assembling_shelter', 'batting_in_run', 'making_cake'};
	events = {'E006', 'E007', 'E008', 'E009', 'E010', 'E011', 'E012', 'E013', 'E014', 'E015', };

	%ker_names = {'dense6.sift.Soft-4000-VL2.trecvidmed10.devel.kcb.l2',
	%			'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed10.devel.kcb.l2',
	%			'mfcc.Soft-4000-VL2.trecvidmed10.devel.kcb.l2'
	%			};
	
	%ker_names = {'dense6.sift.Soft-4000-VL2.trecvidmed11.devel.kcb.l2',
	%			'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed11.devel.kcb.l2',
	%			'mfcc.Soft-4000-VL2.trecvidmed11.devel.kcb.l2'
	%			};
	ker_names = {'covdet.dog.sift.Soft-4000-VL2.trecvidmed10.devel.kcb.l2',
				...%'covdet.hessian.sift.Soft-500-VL2.trecvidmed10.devel.spm.kcb.l2',
				...%'dense6.sift.Soft-4000-VL2.trecvidmed11.devel.kcb.l2',
				'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed10.devel.kcb.l2',
				'mfcc.Soft-4000-VL2.trecvidmed10.devel.kcb.l2',
				'fusion.video-based.ch.cm.eoh.lbp.trecvidmed10.devel.kcb.l2'
				};
		
	ker_names = {'covdet.dog.sift.cb256.trecvidmed11.devel.accumulate.pca.fc.l2',
				'densetrajectory.mbh.trecvidmed11.cb256.devel.fc.l2',
				'mfcc.rastamat.cb256.trecvidmed11.devel.fisher.l2_w5',
				%'mfcc.Soft-4000-VL2.trecvidmed11.devel.kcb.l2'
				};
				
	ker_names = {'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed11.devel.kcb_v1.0.l2',
				'covdet.dog.sift.Soft-4000-VL2.trecvidmed11.devel.kcb.l2',
				'mfcc.Soft-4000-VL2.trecvidmed11.devel.kcb.l2'};
				
				
	calker_exp_dir = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s-calker', proj_name, exp_name);
	
	%fusion_name = 'fusion.video-based.global.local.motion.audio.trecvidmed10.devel.kcb.l2';
	fusion_name = 'fusion.mbh.sift.mfcc.Soft-4000-VL2.MBH.trecvidmed11.devel.kcb';
	
	output_file = sprintf('%s/%s%s/scores/%s.scores.mat', calker_exp_dir, fusion_name, suffix, fusion_name);
	if ~exist(fullfile(calker_exp_dir, [fusion_name, suffix], 'scores'), 'file'),
		mkdir(fullfile(calker_exp_dir, [fusion_name, suffix], 'scores'));
	end
	fused_scores = struct;
	for ii=1:length(events),
		event_name = events{ii};
		fprintf('Fusing for event [%s]...\n', event_name);
		for jj = 1:length(ker_names),
			ker_name = ker_names{jj};
			fprintf(' -- [%d/%d] kernel [%s]...\n', jj, length(ker_names), ker_name);
			scorePath = sprintf('%s/%s%s/scores/%s.video.scores.mat', calker_exp_dir, ker_name, suffix, ker_name);
			
			if ~exist(scorePath, 'file');
				scorePath = sprintf('%s/%s%s/scores/%s.scores.mat', calker_exp_dir, ker_name, suffix, ker_name);
			end
			
			if ~exist(scorePath, 'file');
				error('File not found! [%s]', scorePath);
			end
			
			scores = load(scorePath);
			if isfield(fused_scores, event_name),			
				fused_scores.(event_name) = [fused_scores.(event_name); scores.(event_name)];
			else
				fused_scores.(event_name) = scores.(event_name);
			end
		end
		fused_scores.(event_name) = mean(fused_scores.(event_name)); %scores: 1 x number of videos
	end
	
	ssave(output_file, '-STRUCT', 'fused_scores');
	
	ker.feat = fusion_name;
	ker.name = fusion_name;
	ker.suffix = suffix;
	
	fprintf('Calculating MAP...\n');
	calker_cal_map(proj_name, exp_name, ker, events);
end