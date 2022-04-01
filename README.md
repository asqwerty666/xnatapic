# xnatapic

xnatapic stands for XNAT API Client. Fancy isn't it? It groups a set of API calls to XNAT platform written in Bash. General idea here is:

 - Easy to use
 - Easy to extend
 - Just a few dependencies
 - As fast as possible

### Dependencies

 -  curl
 - jq

### Install

Just copy the main bash script (bin/xnatapic) to a place where it can be found and executed (/usr/local/bin/ ?) and the operational scripts (share/\*.sh) to a place where they can be found by the main script (/usr/local/share/xnatapic/ ?).

Now you should configure the user access. Copy the file _share/xnat.conf_ to _$HOME/.xnatapic/xnat.conf_, edit it and change _URL_, _user_ and _password_ for your XNAT user data.

### Using it

Just ask for help!

```
$ xnatapic --help
xnatapic - call XNat procedures from the command line
 * append_pipeline - append a pipeline to a project (UNDOCUMENTED)
 * create_experiment - create an experiment and set its attributes
 * create_project - create a Xnat project
 * create_subject - create a subject in a project
 * define_pipeline - define a pipeline in Xnat from its path (UNDOCUMENTED)
 * delete_experiment - delete an experiment
 * delete_pipeline - delete a pipeline from a project (UNDOCUMENTED)
 * delete_project - delete a project owned by the user
 * delete_subject - delete a subject in a project
 * get_fsresults - gets freesurfer results archived in Xnat
 * get_jsession - get Xnat session to reuse in other calls to xnatapic
 * get_registration_report - gets PET registration results archived in Xnat
 * list_experiments - list experiments associated with a project
 * list_pipelines - list pipelines in a project
 * list_projects - list projects owned by the user
 * list_subjects - list subjects in a project
 * run_pipeline - run a project pipeline on an experiment (or on all the experiments) (UNDOCUMENTED)
 * undefine_pipeline - remove a pipeline definition from Xnat (UNDOCUMENTED)
 * upload_dicom - upload a DICOM folder to Xnat repository
 * upload_nifti - upload nifti files as Xnat experiment resources
 * append_pipeline - append a pipeline to a project
 * define_pipeline - define a pipeline in Xnat from its path
 * get_fbbcl - get the results of FBB Centiloid analysis
 * get_fsqc - get the results of Fresurfer QC
 * prepare_fsqc - create the structure for Fresurfer QC with visualQC
 * undefine_pipeline - remove a pipeline definition from Xnat
 * upload_fsqc - upload visualQC Freesurfer results
 ```
 
 Now you can also ask for help at any particular function. By example,
 
 ```
 $ xnatapic create_subject --help
create_subject - create a subject in a project
 --help: show this help
 --project_id <project id> [mandatory]
 --subject_id <subject ID> [mandatory either this or a label]
 --label <label>
 --gender <male,female>
 --handedness <right,left,ambidextrous,unknown>
 --age <YY>
```

### Extending it

You can create your own API call procedure by taking any of the existing ones as a template and placing it at _$HOME/.xnatapic/_ with a different name. Just, take a look, it is quite simple.


