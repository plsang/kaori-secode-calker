function [cl, maxacc] = calker_svmkernellearn(K, y, varargin)
% SVMKERNELLEARN  Train SVM with custom kernel
%  CL = SVMKERNELLEARN(K, Y) uses LIBSVM to train an SVM with custom
%  kernel K and labels Y. The result CL is a structure with fields:
%
%  CL.LIBBSVM_CL   : SVM (libsvm format)
%  CL.RBF          : Using RBF transformation? (0/1)
%  CL.GAMMA        : RBF parameter
%  CL.LABELS       : Category labels
%
%  Options:
%
%  Type ['C']
%    Set the SVM type to 'C' or 'nu'.
%
%  C [1]
%    Set the SVM C parameter. The C parameter trades-off maximizing
%    the margin missclassfying training data. A large C gives more
%    importance to reducing the number of mistakes, but may increase
%    overfitting.
%
%  Nu [.5]
%    Se the nu-SVM nu parameter.
%
%  RBF [0]
%    Enable RBF transformation. Assuming that the input argument K is
%    actually a metric, the kernel is defined as K' = EXP(- gamma K).
%
%  Gamma [[]]
%    GAMMA constant of the RBF transformation.
%
%  Balance [0]
%    Enable data balancing. Balancing reweights the data so that the
%    empirical error term (see C option) in the SVM cost functional is
%    computed assuming that the labels are equally probable. Balancing
%    affects the value of the C parameter for each sample, increasing
%    its value for the less represented labels.
%
%  Weights []
%    Specify labels weights directly.
%
%  CrossValidation [0]
%    Perform N-fold cross validation to determine the optimal value of
%    the paramter C. In this case specifying C has no effect.
%
%  Verbosity [0]
%    Set verbosity level.
%
%  Debug [0]
%    Print debugging informations.
%
%  LIMITATIONS. Currently, only C-SVM and binary classification are
%  supported.
%
%  See also SVMKERNELTEST().
%
%  Author:: Andrea Vedaldi

% AUTORIGHTS
% Copyright (C) 2008-09 Andrea Vedaldi
%
% This file is part of the VGG MKL Class and VGG MKL Det code packages,
% available in the terms of the GNU General Public License version 2.

nu      = .5 ;
C       = 1 ;
verb    = 0 ;
balance = 0 ;
cross   = 0 ;
gamma   = [] ;
rbf     = 0 ;
type    = 'C' ;
weights = [] ;
debug = 0;

for k=1:2:length(varargin)
  opt = lower(varargin{k}) ;
  arg = varargin{k+1} ;
  
  switch opt
    case 'type' 
      type = arg ;
    case 'c'
      C = arg ;
    case 'rbf' ;
      rbf = arg ;
    case 'gamma' ;
      gamma = arg ;
    case 'nu' ;
      nu = arg ;
    case 'balance' ;
      balance = arg ;
    case 'verbosity'
      verb = arg ;
    case 'weights'
      weights = arg ;
    case 'debug'
      debug = arg ;
    case 'crossvalidation'
      cross = arg ;
	 otherwise
      error(sprintf('Option ''%s'' unknown.', opt)) ;
  end  
end

% --------------------------------------------------------------------
%                                                              Balance
% --------------------------------------------------------------------

% basic libsvm options
svm_opts = ' -t 4 -b 1 -q' ;

switch type
  case 'C'
    svm_opts = [svm_opts ' -s 0'] ;
  case 'nu'
    svm_opts = [svm_opts ' -s 1'] ;
  otherwise
    error('Unknown SVM type.') ;
end

% count elements per category
cats = unique(y) ;
for c = cats
  n(find(c == cats)) = sum(y == c) ;
end
N = sum(n) ;

if balance
	balw = N ./ (2 * n) ;
%  balw = 1./balw ;
%balw(1) = balw(1) * 10000 ;
	for c=cats
		svm_opts = [svm_opts sprintf(' -w%d %f', c, balw(find(c==cats)))] ;
	end	
end

if weights
	for c=cats    
    widx = find(weights(1,:)==c) ;
		svm_opts = [svm_opts sprintf(' -w%d %g', c, weights(2,widx))] ;
	end	
end

if verb
  fprintf('svmkernellearn: # labels      %d\n', length(cats));
  fprintf('svmkernellearn: labels prop:  ') ;
  for c=cats
    fprintf('%d:%.2f ', c, 100 * n(find(c == cats)) / N) ;
  end  
  fprintf('\n') ;
	fprintf('svmkenrellearn: balance:      %d\n', balance) ; 
end

n  = numel(y) ;

% --------------------------------------------------------------------
%                                                 Gamma transformation
% --------------------------------------------------------------------

if rbf
  fprintf('svmkernellearn: RBF transformation.\n') ;

  D = K ;
  
  if isempty(gamma)
    fprintf('svmkernellearn: automatically setting RBF gamma!\n') 
    gamma = heuristic_gamma(K) ;
  end
  
  K = exp(- gamma * D) ;     

  if debug
    figure(600) ; clf ;
    subplot(2,2,1) ; imagesc(D ) ;     title('D') ;
    subplot(2,2,2) ; hist(D(:),100) ;  title('D hist') ;
    subplot(2,2,3) ; imagesc(K) ;      title('K') ;
    subplot(2,2,4) ; hist(K(:),100) ;  title('K hist') ;
    set(gcf,'name','svmkernellearn debug') ;
    subplot(2,2,2) ; 
    hndm=get(gca,'ylim') ;
    hnd=line(1/gamma * [1 1], hndm) ;
    set(hnd, 'linewidth', 3, 'color', 'r') ;
    text(1/gamma, hndm(2)*.8, '1/gamma') ;
    clear hnd hndm ;
  end
  fprintf('svmkernellearn: RBF custom kernel\n') ;      
  
end   
clear D ;

% --------------------------------------------------------------------
%                                                     Cross validation
% --------------------------------------------------------------------

zz=0 ;
if cross  
  if verb   
    fprintf('svmkernelleran: entering 10-fold cross validation ...\n') ;
  end
  switch lower(type)
    case 'c'
      val_range = logspace(-5,+5,11) ;
    case 'nu'
      val_range = logspace(-10,-0.0001,11) ;
  end
  N = size(K,1) ;
  
  figure(50) ; clf ;
  while true % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    fprintf('Iteration %d\n', zz)
    
    for t = 1:length(val_range)
      switch lower(type)
        case 'c'
          fprintf('svmkernellearn: setting C to %g\n', val_range(t)) ;
          svm_opts_ = [svm_opts sprintf(' -v %d -c %g', ...
                                        cross, val_range(t))] ;
        case 'nu'
          fprintf('svmkernellearn: setting nu to %g\n', val_range(t)) ;
          svm_opts_ = [svm_opts sprintf(' -v %d -nu %g', ...
                                        cross, val_range(t))] ;
      end
      
      try
        fprintf('svmkernellearn: svm opts ''%s''\n', svm_opts_) ;
        res = svmtrain(y(:), [(1:n)' K], svm_opts_) ;
      catch
      end
      if isempty(res)
        acc_range(t) = 0 ;
      else
        acc_range(t) = res ;
      end
    end
    
    % best C
    [maxacc,best] = max(acc_range) ;
    sel           = find(acc_range == maxacc) ;
    %pick          = (max(sel)+min(sel)) / 2 ;
    pick          = min(sel) ;
    val           = val_range(pick) ;
    
    switch lower(type)
      case 'c'
        C = val ;
      case 'nu'
        nu = val ;
    end

    semilogx(val_range, acc_range, '.-', 'Linewidth', 2*zz+1) ;
    hold on ;
    title('Cross validation') ; 
    xlabel('C value') ;
    ylabel('N-fold cross-validation error') ;
    grid on ;
    drawnow ;

    zz = zz + 1;
    % stop ?
    if min(acc_range) == max(acc_range),
      break ;
    end

    % max iterations
    if zz > 2
        break;
    end
    
    step = log10(val_range(2)) - log10(val_range(1)) ;
    val_range = logspace(log10(val) - 2*step, log10(val) + 2*step, 11) ;
    
  end
end

% --------------------------------------------------------------------
%                                                             Learning
% --------------------------------------------------------------------

if C < 0.0001,
	C
	C = 1;
end

switch lower(type)
  case 'c'
    svm_opts = [svm_opts sprintf(' -c %f', C)] ;
  case 'nu'
    svm_opts = [svm_opts sprintf(' -nu %f', nu)] ;
end

if verb 
	fprintf('svmkernellearn: C:            ') ;
  if isempty(C), fprintf('libsvm default\n') ;
  else fprintf('%g\n', C) ;
  end
	fprintf('svmkernellearn: lib SVM opts: ''%s''\n', svm_opts);
end

cl.libsvm_cl = svmtrain(y(:), [(1:n)' K], svm_opts) ;

cl.rbf       = rbf ;
cl.gamma     = gamma ;
cl.labels    =   cl.libsvm_cl.Label ;
cl.svind     =   cl.libsvm_cl.SVs ;
cl.alphay    =   cl.libsvm_cl.sv_coef ;
cl.b         = - cl.libsvm_cl.rho ;
cl.C 		 = C;

% ---------------------------------------------------------------------
function gamma=heuristic_gamma(D)
% ---------------------------------------------------------------------

[h,x] = hist(D(:),100) ;
h     = h / sum(h) ;
h     = cumsum(h) ;
sel   = find(h >= .5 / 2) ;
gamma = 1 / x(min(sel)) ;
