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

        # if [ $patient_id == "0000FA9A" ]
        # then
        #     echo "right patient"
        #     fsleyes render -of ../T1WE_2802/new_${patient_id}.png -sz 150 150 -vl 90 98 56 -hc -zz 2300 -no -hl -xh -yh -hd $subject_dir/FSL/STAGE_T1WE_reg_mni.nii.gz $subject_dir/FSL/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/FSL/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1

        # fi
        
        if [ $patient_id == "00004943" ]
        then
            fsleyes render -of ../T1WE_2802/new_${patient_id}.png -sz 150 150 -vl 90 98 56 -hc -zz 2300 -no -hl -xh -yh -hd $subject_dir/results/STAGE/reg_STAGE_T1WE.nii $subject_dir/results/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/results/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1
        fi

    done
    
done