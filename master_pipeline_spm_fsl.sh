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
mni="$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz"

results_file="$HOME/masterproject/results_spm_fsl.csv"

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

        subject_dir="$dir/DICOM/$patient_id"

        if [ ! -d "$subject_dir" ]
        then
            echo "Directory does not exist"
            continue
        fi

        mean=("${personal_id#???????????},$patient_id")

        if grep -q $patient_id $results_file
        then
            continue
        fi
        
        if [ ! -d "$subject_dir/results" ]
        then
            mkdir $subject_dir/results
        fi
        result_dir="$subject_dir/results"
        
        if [ ! -d "$subject_dir/results/STAGE" ]
        then
            mkdir $subject_dir/results/STAGE
        fi

        if [ ! -d "$subject_dir/results/SPM_FSL" ]
        then
            mkdir $subject_dir/results/SPM_FSL
        fi
        
        
        # Convert STAGE images from DICOM to NIFTI
        if [ ! -f "$result_dir/STAGE/STAGE_tSWIhpf_ECHO-3_e3.nii" ]
        then
            /Applications/MRIcroGL.app/Contents/Resources/dcm2niix -f %p -o $result_dir/STAGE $subject_dir/STAGE
        fi
        t1we="$result_dir/STAGE/STAGE_T1WE.nii"


        # Convert MPRAGE from DICOM to NIFTI
        if [ ! -f "$result_dir/t1_mprage_sag_p2_iso_PACS.nii" ]
        then
            /Applications/MRIcroGL.app/Contents/Resources/dcm2niix -f %p -o $result_dir $subject_dir/*t1_mprage_sag_p2_iso_PACS
        fi
        mprage="$result_dir/t1_mprage_sag_p2_iso_PACS.nii"


        # Register T1WE to MPRAGE
        if [ ! -f "$result_dir/t1we2mprage.mat" ]
        then
            flirt -in $t1we -ref $mprage -omat $result_dir/t1we2mprage.mat -out $result_dir/t1we_reg_mprage
        fi
        t1we_reg_mprage="$result_dir/t1we_reg_mprage.nii.gz"
        

        # Register MPRAGE to MNI with SPM
        if [ ! -f "$result_dir/reg_t1_mprage_sag_p2_iso_PACS.nii" ]
        then
            matlab -nodisplay -r "reg_spm('$mprage'),exit";
        fi
        mprage_reg_mni_spm="$result_dir/reg_t1_mprage_sag_p2_iso_PACS.nii"

        # Register MPRAGE to MNI with FSL
        if [ ! -f "$result_dir/mprage2mni.mat" ]
        then
            flirt -in $mprage_reg_mni_spm -ref $mni -omat $result_dir/mprage2mni.mat -out $result_dir/mprage_reg_mni
        fi
        
        header=("personal_id,patient_id")
        
        for image in $result_dir/STAGE/STAGE_*.nii
        do
            [ -f "$image" ] || break

            name=$(basename $image .nii)

            echo "${name#??????}"

            header+=",SN ${name#??????}"
            header+=",SN_R ${name#??????}"
            header+=",SN_L ${name#??????}"
            header+=",LC ${name#??????}"
            header+=",LC_R ${name#??????}"
            header+=",LC_L ${name#??????}"
            
            # Register STAGE images to MPRAGE
            if [ ! -f "$result_dir/${name}_reg_mprage.nii.gz" ]
            then
                flirt -in $image -ref $mprage -out $result_dir/${name}_reg_mprage -init $result_dir/t1we2mprage.mat -applyxfm
            fi
            image_reg_mprage="$result_dir/${name}_reg_mprage.nii.gz"
            
            # Register STAGE images to MNI with SPM
            if [ ! -f "$result_dir/STAGE/reg_${name}.nii" ]
            then
                matlab -nodisplay -r "write_job('$result_dir/y_t1_mprage_sag_p2_iso_PACS.nii','$image_reg_mprage'),exit";
            fi
            image_reg_mni_spm="$result_dir/STAGE/reg_${name}.nii"

            # Register STAGE images to MNI with FSL
            if [ ! -f "$result_dir/${name}_reg_mni.nii.gz" ]
            then
                flirt -in $image_reg_mni_spm -ref $mni -init $result_dir/mprage2mni.mat -out $result_dir/${name}_reg_mni -applyxfm
            fi
            image_reg_mni="$result_dir/${name}_reg_mni.nii.gz"
            
            
            # Make mask of SN
            if [ ! -f "$result_dir/SPM_FSL/${name}_sn.nii.gz" ]
            then
                fslmaths $image_reg_mni -mas $sn $result_dir/SPM_FSL/${name}_sn
            fi

            # Make mask of right SN
            if [ ! -f "$result_dir/SPM_FSL/${name}_sn_r.nii.gz" ]
            then
                fslmaths $image_reg_mni -mas $sn_r $result_dir/SPM_FSL/${name}_sn_r
            fi

            # Make mask of left SN
            if [ ! -f "$result_dir/SPM_FSL/${name}_sn_l.nii.gz" ]
            then
                fslmaths $image_reg_mni -mas $sn_l $result_dir/SPM_FSL/${name}_sn_l
            fi

            # Make mask of LC
            if [ ! -f "$result_dir/SPM_FSL/${name}_lc.nii.gz" ]
            then
                fslmaths $image_reg_mni -mas $lc $result_dir/SPM_FSL/${name}_lc
            fi

            # Make mask of right LC
            if [ ! -f "$result_dir/SPM_FSL/${name}_lc_r.nii.gz" ]
            then
                fslmaths $image_reg_mni -mas $lc_r $result_dir/SPM_FSL/${name}_lc_r
            fi

            # Make mask of left LC
            if [ ! -f "$result_dir/SPM_FSL/${name}_lc_l.nii.gz" ]
            then
                fslmaths $image_reg_mni -mas $lc_l $result_dir/SPM_FSL/${name}_lc_l
            fi

            # Mean of mask of SN
            mean+=","$(fslstats $result_dir/SPM_FSL/${name}_sn.nii.gz -M)

            # Mean of mask of right SN
            mean+=","$(fslstats $result_dir/SPM_FSL/${name}_sn_r.nii.gz -M)

            # Mean of mask of left SN
            mean+=","$(fslstats $result_dir/SPM_FSL/${name}_sn_l.nii.gz -M)
            
            # Mean of mask of LC
            mean+=","$(fslstats $result_dir/SPM_FSL/${name}_lc.nii.gz -M)

            # Mean of mask of right LC
            mean+=","$(fslstats $result_dir/SPM_FSL/${name}_lc_r.nii.gz -M)

            # Mean of mask of left LC
            mean+=","$(fslstats $result_dir/SPM_FSL/${name}_lc_l.nii.gz -M)
            
        done

        if [ ! -f $results_file ]
        then
            echo "$header" > $results_file
        fi

        # Write mean to file
        echo "$mean" >> $results_file
        
    done
done