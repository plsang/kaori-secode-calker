function eval_generate_detection_csv(proj_name, exp_name, feature_ext, norm_type)
	
	% eval_generate_detection_csv('trecvidmed11', 'trecvidmed11-100000', 'densetrajectory.mbh.Soft-4000-VL2.MBH.trecvidmed11.devel.kcb', 'l2')
	
	addpath('/net/per900a/raid0/plsang/tools/kaori-secode-calker-tmp2/support');
	
	f_trial_index = '/net/per900a/raid0/plsang/dataset/MED13/MED13DRYRUN_Files/MED13DRYRUN_20130501_TrialIndex.csv';
	
	fh = fopen(f_trial_index);
	trial_indexes = textscan(fh, '%s %s %s', 'delimiter', ',');
	fclose(fh);
	
	trial_ids = trial_indexes{1}(2:end);
	video_num_ids = trial_indexes{2}(2:end);
	event_ids = trial_indexes{3}(2:end);
	
	feature_name = sprintf('%s.%s', feature_ext, norm_type);
	
	calker_exp_dir = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s-calker/%s', proj_name, exp_name, feature_name);

	
	videoScorePath = sprintf('%s/scores/%s.scores.mat', calker_exp_dir, feature_name);
	calker_gtdir = sprintf('/net/per900a/raid0/plsang/%s/annotation/calker_groundtruth', proj_name);

	db_file = fullfile(calker_gtdir, ['database_new_test.mat']);
	db_file
	
	fprintf('Loading groundtruth...\n');
	load(db_file, 'database');
	fprintf('Loading and scale scores...\n');
	scores_ = load(videoScorePath);
	events  = fieldnames(scores_);
	
	scores = struct;
	
	for ii=1:length(events),
		scores.(events{ii}) = scaledata(scores_.(events{ii}), 0, 1);
	end
	
	f_detection_csv = sprintf('%s/scores/%s.detection.csv', calker_exp_dir, feature_name);
	f_detection_csv
	
	if exist(f_detection_csv, 'file'),
		fprintf('File already exist! skipped!\n');
		return;
	end
	
	fprintf('Saving detection scores...\n');
	fh = fopen(f_detection_csv, 'w');
	fprintf(fh, '"TrialID","Score"\n');
	
	for jj=1:length(trial_ids),
		if ~mod(jj, 1000),
			fprintf('%d ', jj);
		end
		event_id = strrep(event_ids{jj}, '"', '');
		
		video_num_id = strrep(video_num_ids{jj}, '"', '');
		
		video_name = ['HVC', video_num_id];
		
		if isfield(database.vindex, video_name),
			vidx = database.vindex.(video_name);
			score = scores.(event_id)(vidx);
		else
			score = 0;
		end
						
		fprintf(fh, '%s,"%f"\n', trial_ids{jj}, score);
	end	
	fprintf('Done...\n');
	fclose(fh);

end