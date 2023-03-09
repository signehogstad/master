#!/bin/bash
set -e
set -u
set -o pipefail

strat_park="/Volumes/MRI/STRAT-PARK"
sn="$HOME/masterproject/SN_mask.nii.gz"
sn_r="$HOME/masterproject/SN_R_probatlas27_50.nii"
sn_l="$HOME/masterproject/SN_L_probatlas27_50.nii"
lc="$HOME/masterproject/LC_mask.nii.gz"
lc_r="$HOME/masterproject/LC_mask_R.nii.gz"
lc_l="$HOME/masterproject/LC_mask_L.nii.gz"

results_file="$HOME/masterproject/results_0000F810.csv"

export PATH=$PATH:/Applications/MATLAB_R2022b.app/bin

for dir in $strat_park/*
do
    xml_file="$dir/SECTRA/CONTENT.xml"
    pairs=$(xmlstarlet sel -t -m "//patient" -v "concat(@id,':',patient_data/personal_id,' ')" "$xml_file")
    for pair in $pairs
    do
        patient_id=$(echo "$pair" | cut -d: -f1)
        personal_id=$(echo "$pair" | cut -d: -f2)
        echo ""
        echo "Personal ID: ${personal_id#???????????}"
        echo "Patient ID: $patient_id"
        echo ""

        if [ $patient_id != "0000F810" ]
        then
            echo "Not right"
            continue
        fi

        echo "Yesssssssssss"

        subject_dir="$dir/DICOM/$patient_id"

        mean=("${personal_id#???????????},$patient_id")
        
        header=("personal_id,patient_id")
        
        for image in $subject_dir/STAGE/NIFTI/STAGE_*.nii.gz
        do
            [ -f "$image" ] || break

            name=$(basename $image .nii.gz) 

            echo "${name#??????}"

            header+=",SN ${name#??????}"
            header+=",SN_R ${name#?????}"
            header+=",SN_L ${name#??????}"
            header+=",LC ${name#??????}"
            header+=",LC_R ${name#??????}"
            header+=",LC_L ${name#??????}"
            
            
            # Make mask of SN
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $sn $subject_dir/${name}_sn

            # # Make mask of right SN
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $sn_r $subject_dir/${name}_sn_r

            # # Make mask of left SN
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $sn_l $subject_dir/${name}_sn_l

            # # Make mask of LC
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $lc $subject_dir/${name}_lc

            # # Make mask of right LC
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $lc_r $subject_dir/${name}_lc_r

            # # Make mask of left LC
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $lc_l $subject_dir/${name}_lc_l

            # # Mean of mask of SN
            mean+=","$(fslstats $subject_dir/${name}_sn.nii.gz -M)

            # Mean of mask of right SN
            mean+=","$(fslstats $subject_dir/${name}_sn_r.nii.gz -M)

            # Mean of mask of left SN
            mean+=","$(fslstats $subject_dir/${name}_sn_l.nii.gz -M)
            
            # Mean of mask of LC
            mean+=","$(fslstats $subject_dir/${name}_lc.nii.gz -M)

            # Mean of mask of right LC
            mean+=","$(fslstats $subject_dir/${name}_lc_r.nii.gz -M)

            # Mean of mask of left LC
            mean+=","$(fslstats $subject_dir/${name}_lc_l.nii.gz -M)
            
        done

        if [ ! -f $results_file ]
        then
            echo "$header" > $results_file
        fi

        # Write mean to file
        echo "$mean" >> $results_file
        
    done
done