%-----------------------------------------------------------------------
% Job saved on 07-Feb-2023 15:20:21 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
function write_job(def, image)

matlabbatch{1}.spm.spatial.normalise.write.subj.def = {def};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {image};
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-91 -126 -72
                                                          90 91 109];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'reg_';
spm_jobman('run',matlabbatch);

end