#!/bin/bash
set -e
set -u
set -o pipefail

strat_park="/Volumes/MRI/STRAT-PARK"

for dir in $strat_park/*
do
    for subject_dir in $dir/DICOM/*
    do
    
        patient_id=$(basename $subject_dir)
            
        echo "Processing subject with patient_id: $patient_id"
        
        fsleyes -vl 90 98 56 -no $subject_dir/FSL/STAGE_T1WE_reg_mni.nii.gz $subject_dir/FSL/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/FSL/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1
        
    done
done
    