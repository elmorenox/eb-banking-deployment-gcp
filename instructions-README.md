# Kura Labs Cohort 5- Deployment Workload 2
## CICD with AWS CLI:

Welcome to Deployment Workload 2!  In the first deployment workload, we manually uploaded the source code to AWS EB.  Let’s start automating more of that pipeline.  

Be sure to document each step in the process and explain WHY each step is important to the pipeline.

## Instructions

1. Clone this repo to your GitHub account

2. Create AWS Access Keys:

   a. Navigate to the AWS servce: IAM (search for this in the AWS console)

   b. Click on "Users" on the left side navigation panel

   c. Click on your User Name

   d. Underneath the "Summary" section, click on the "Security credentials" tab

   e. Scroll down to "Access keys" and click on "Create access key"

   f. Select the appropriate "use case", and then click "Next" and then "Create access key"

 ACCESS KEYS CAN ONLY BE VIEWED ONCE! 
 
 Be sure to save them somewhere (you will need these later) and NEVER upload the keys to any public repository.  

NOTE: What are access keys and why would sharing them be dangerous? 


3. Create a t2.micro EC2 for your Jenkins Server (IMPORTANT: include ALL commands from Workload 1 step 3b to do so)

4. Create a BASH script called "system_resources_test.sh" that checks for system resources (can be memory, cpu, disk, all of the above and/or more) and push it to the GH repo. IMPORTANT: make sure you use conditional statements and exit codes (0 or 1) if any resource exceeds a certain threshold.

SEE: https://www.geeksforgeeks.org/how-to-use-exit-code-to-read-from-terminal-from-script-and-with-logical-operators/ for more information

Note: Why are exit codes important? Especially if running the script through a CICD Pipeline?

5. Create a MultiBranch Pipeline and connect your GH repo to it (build should start automatically)

6. Back in the Jenkins Server Terminal- Install AWS CLI on the Jenkins Server with the following commands:

```
$curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
$unzip awscliv2.zip
$sudo ./aws/install
$aws --version 
```

If AWS CLI was installed properly the version number will output to the terminal.

7. Switch to the user "jenkins"

    a. create a password for the user "jenkins" by running: 
  
  ```
  $sudo passwd jenkins
  ```

  b. switch to the jenkins user by running:

  ```
  sudo su - jenkins
  ```

8. Navigate to the pipeline directory within the jenkins "workspace"

```
cd workspace/[name-of-multibranch-pipeline]
```

you should be able to see the application source code from this directory

9. Activate the Python Virtual Environment

```
source venv/bin/activate
```
NOTE: Python Virtual Environments are usually created by running the command `python3 -m venv [name-of-environment]`.  What is a virtual environment? Why is it important/necessary? and when was this one (venv) created? HINT: See step 13 below.


10. Install AWS EB CLI on the Jenkins Server with the following commands:

```
$pip install awsebcli
$eb --version
```
If AWS EB CLI was installed properly the version number will output to the terminal

11. Configure AWS CLI with the folling command:

```
$aws configure
```
   a. Enter your access key

   b. Enter your secret access key

   c. region: "us-east-1"

   d. output format" "json"

   e. check to see if AWS CLI has been configured by entering:

``` 
$aws ec2 describe-instances 
```


12. Initialize AWS Elastic Beanstalk CLI

    a. run the following command:
  ```
  eb init
  ```
  
   b. Set the default region to: us-east-1

   c. Enter an application name (or leave it as default)

   d. Select python3.7

   e. Select "no" for code commit

   f. Select "yes" for SSH and select a "KeyPair"

13. Add a "deploy" stage to the Jenkinsfile 

    a. use your text editor of choice to edit the "jenkinsfile"

    b. add the following code block (modify the code with your environment name and remove the square brackets) AFTER the "Test" Stage:

  ```
  stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
                source venv/bin/activate
                eb create [enter-name-of-environment-here] --single
                '''
            }
        }
  ```
IMPORTANT: THE SYNTAX OF THE JENKINSFILE IS VERY SPECIFIC! MAKE SURE THAT THE STAGES AND CURLY BRACKETS ARE IN THE CORRECT ORDER OTHERWISE THE PIPELINE WILL NOT BUILD!
See https://www.jenkins.io/doc/book/pipeline/syntax/ for more information.

  c. Push these changes to the GH Repository

14. Navigate back to the Jenkins Console and build the pipeline again.

If the pipeline sucessfully completes, navigate to AWS Elastic Beanstalk in the AWS Console and check for the environment that is created. The application should be running at the domain created by Elastic Beanstalk.

15. Document! All projects have documentation so that others can read and understand what was done and how it was done. Create a README.md file in your repository that describes:

	  a. The "PURPOSE" of the Workload,

  	b. The "STEPS" taken (and why each was necessary/important,

  	c. A "SYSTEM DESIGN DIAGRAM" that is created in draw.io,

	  d. "ISSUES/TROUBLESHOOTING" that may or may have occured,

  	e. An "OPTIMIZATION" section for that answers the question: How is using a deploy stage in the CICD pipeline able to increase efficiency of the buisiness?  What issues, if any, can you think of that might come with automating source code to a production environment? How would you address/resolve this?

    f. A "CONCLUSION" statement as well as any other sections you feel like you want to include.
