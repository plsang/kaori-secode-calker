function convert_scores(proj_name, exp_name, kf_name, ker, events)

	result_dir = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s/results/%s', proj_name, exp_name, ker.resname );
	if ~checkFile(result_dir),
		mkdir(result_dir);
	end
	 	
	addpath('support');

	% loading labels
	meta_dir = sprintf('/net/per900a/raid0/plsang/%s/metadata', proj_name);
	db_file = fullfile(meta_dir, kf_name, 'database_test.mat');
	load(db_file, 'database');
	n_event = legnth(events);

	% event names

	fprintf('Scoring for feature %s...\n', ker.resname);

	scorePath = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s/kernels/%s.scores.mat', proj_name, exp_name, ker.name);
	if ~checkFile(scorePath), 
		error('File not found!! %s \n', scorePath);
	end


	scores = load(scorePath);

	for jj = 1:n_event,
		event_name = events{jj};
		fprintf('Scoring for feature %s , event %s...\n', ker.resname, event_name);
		feresult_dir = fullfile(result_dir, event_name);

		if ~checkFile(feresult_dir),
			mkdir(feresult_dir);
		end

		this_scores = scores.(event_name);
		p_scores = scaledata(this_scores, 0, 1);
		
		for kk=1:length(database.path),
			outFName = fullfile(feresult_dir, [database.cname{kk} '.' ker.resname '.svm.res']);
			fid = fopen(outFName, 'a');
			fprintf(fid, '%s #$# %f\n', database.cname{kk}, p_scores(kk));			
			fclose(fid);
		end
		
	end
	
end

	