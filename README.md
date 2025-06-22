# L300 Challenge Lab Scripts for App Mod - 2025 Edition
These scripts are provided to solve the Challenge Labs for AppMod L300 - 2025 Edition

**NOTE:** *You can find the Challenge Labs [here.](https://www.cloudskillsboost.google/course_templates/789)* 

This README will help you get set up to run through the Challenge Lab in your Argolis environment as a dry run before attempting the real thing inside of QwikLabs using these scripts.

## Prerequisite Setup in Argolis
**Note:** If you are running the scripts in this repository inside of the QwikLabs environment, you can skip ahead to the [Running through the Lab](#running-through-the-lab-task-by-task) section.

Because we are running in Argolis, we need to set up some artifacts that will already exist in the QwikLab when you start it.

**Note:** These scripts all start with an underscore character to make them distinctive from the rest.

### Create a New Project
First thing is to create a new project within Argolis.

Once you have the new project, you'll want to do some stuff to make it "useable", namely:

1. Enable the most common needed APIs
2. Remove restrictive Org Policies
3. Create a `default` network
4. Create firewall rules for SSH and HTTP(S)

**Note:** You can find scripts to do these 4 things in [this repository](https://github.com/gfilicetti/gcp-scripts)

### Deploy Prerequisite Infrastructure
TBD

**Note:** You must remember to inspect every script before running it and looking at the variables at the top to modify any that need to be changed due to your specific environment. It is also necessary to read comments in the scripts and look for any warnings.

#### Enabling needed APIs
For each lab, run this script:

```shell
./_enable-apis.sh
```

This will enable any needed APIs

## Running Through the Labs Task by Task

At this point you'll be running each of the `lab1-task-nn.sh` scripts one by one to achieve each of the tasks in the QwikLabs.

Generally you'll want to keep these things in mind as you run these:
* **ALWAYS** read the code inside the script and understand what it is doing
* This includes the comments, some of which contain warnings and alternate code
* Some of the variables defined at the top of the script will need to be changed to match your environment.
* Some of the scripts will copy our template files on top of existing files in the BoA structure, be aware of this.
* There will be some git operations done in various tasks. These are used against a Google Source Repository, not GitHuc.
* Once again, if you don't understand what the scripts do and are not able to diagnose and debug any problems, you might have trouble with this. This is why doing dry runs in Argolis are highly suggested.

## Learning Links
These links were used to learn about the products and commands needed in each of the Tasks. They are provided here for your reference. You are highly encouraged to read these and learn what the scripts are doing:

### QwikLab and This Repo
<https://www.cloudskillsboost.google/course_templates/789>
<https://github.com/gfilicetti/L300-appmod-lab-scripts-2025>

### Reference material
<https://cloud.google.com/logging/docs/buckets#gcloud>
<https://cloud.google.com/sdk/gcloud/reference/logging/links/create>
<https://cloud.google.com/sdk/gcloud/reference/logging/sinks/create#DESTINATION>