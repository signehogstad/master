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
        
        if [ $patient_id == "00001573" ]
        then
            echo "Right subject"

            if [ ! -d ../Figures/brain_nomask_${patient_id} ]
            then
                mkdir ../Figures/brain_nomask_${patient_id}
            fi

            for image in $subject_dir/results/STAGE/reg_STAGE_*.nii
            do
                name=$(basename $image .nii)
                echo "${name#??????????}"

                # # Whole brain in three images
                # fsleyes render -of ../Figures/brain_${patient_id}/${name#??????????}_axial_brain_$patient_id.png -vl 86 105 56 -hc -no -hl -xh -yh -hd $image $subject_dir/results/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/results/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1
                # fsleyes render -of ../Figures/brain_${patient_id}/${name#??????????}_coronal_brain_$patient_id.png -vl 86 105 56 -hc -no -hl -xh -zh -hd $image $subject_dir/results/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/results/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1
                # fsleyes render -of ../Figures/brain_${patient_id}/${name#??????????}_sagittal_brain_$patient_id.png -vl 86 105 56 -hc -no -hl -yh -zh -hd $image $subject_dir/results/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/results/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1
            
                # Whole brain axial without masks
                fsleyes render -of ../Figures/brain_nomask_${patient_id}/${name#??????????}_brain_nomask_$patient_id.png -vl 86 105 56 -hc -no -hl -xh -yh -hd $image

                # # Whole brain in one image
                # fsleyes render -of ../Figures/multi_brain_${patient_id}/${name#??????????}_multi_brain_$patient_id.png -vl 86 105 56 -hc -no -hl -hd $image $subject_dir/results/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/results/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1

                # Midbrain
                #fsleyes render -of ../Figures/midbrain_${patient_id}/${name#??????????}_midbrain_$patient_id.png -sz 150 150 -vl 90 98 56 -hc -zz 2300 -no -hl -xh -yh -hd $image $subject_dir/results/STAGE_T1WE_sn.nii.gz -ot mask -o -mc 1 0 0 $subject_dir/results/STAGE_T1WE_lc.nii.gz -ot mask -o -mc 0 0.5 1
            done

        fi

    done
    
done