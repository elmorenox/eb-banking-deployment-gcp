# Deployment Workload 2: CI/CD Pipeline with AWS CLI

## PURPOSE
The purpose of this workload is to automate the deployment process of our application using Jenkins CI/CD pipeline and AWS Elastic Beanstalk. In our previous workload, we manually uploaded the source code to AWS Elastic Beanstalk. This workload builds upon that by introducing automation through Jenkins pipelines and AWS CLI tools, reducing manual intervention and improving deployment consistency and efficiency.

## STEPS

1. **Cloned the repository to my GitHub account**
   - This gives me my own copy of the code to work with and enables source control for any changes I make.

2. **Created AWS Access Keys**
   - Access keys are essential for programmatic access to AWS services.
   - The keys allow Jenkins to interact with AWS services (like Elastic Beanstalk) without requiring manual login.
   - It's critical to keep these keys secure as they provide direct access to AWS resources.

3. **Created a t2.micro EC2 instance for Jenkins Server**
   - This provides the dedicated compute resources needed to run our Jenkins automation server.
   - Used t2.micro as it's suitable for development purposes while remaining cost-effective.

4. **Created system_resources_test.sh script**
   - This script monitors system resources (CPU, memory, disk) and returns appropriate exit codes.
   - Exit codes are crucial in CI/CD pipelines because they signal whether a step has passed or failed.
   - A failed test (exit code 1) can prevent deployment of code that might cause resource issues.

5. **Created a MultiBranch Pipeline and connected GitHub repository**
   - MultiBranch Pipelines automatically detect branches in our repository and run builds for each.
   - This enables feature branch development and continuous integration across all branches.

6. **Installed AWS CLI on the Jenkins Server**
   - The AWS CLI provides command-line access to AWS services from our Jenkins server.
   - This enables automation of AWS operations that previously required manual console interaction.

7. **Configured Jenkins user with necessary permissions**
   - Created password for the Jenkins user and switched to it.
   - This allows Jenkins to run commands with the appropriate permissions on the server.

8. **Navigated to the pipeline workspace**
   - This directory contains our application's source code as retrieved from our GitHub repository.
   - Working in this directory is essential for subsequent steps in the pipeline.

9. **Activated Python Virtual Environment**
   - Virtual environments isolate dependencies, preventing conflicts between different Python projects.
   - This environment was created during the build stage of our pipeline (via `python3 -m venv venv`).
   - Isolation ensures consistent builds across different environments and developers.

10. **Installed AWS EB CLI**
    - EB CLI provides specialized commands for managing Elastic Beanstalk applications.
    - This tool simplifies deployment compared to using the general AWS CLI.

11. **Configured AWS CLI with credentials**
    - This step links our AWS access keys to the CLI, enabling authenticated API requests.
    - Setting the region ensures we deploy to the correct AWS geographical area.

12. **Initialized AWS Elastic Beanstalk CLI**
    - The `eb init` command sets up our Elastic Beanstalk application configuration.
    - It configures essential parameters like region, application name, platform, and SSH access.

13. **Added a deploy stage to the Jenkinsfile**
    - This automates the deployment process as part of our CI/CD pipeline.
    - The deploy stage runs after the test stage, ensuring we only deploy code that has passed tests.
    - It creates a single-instance Elastic Beanstalk environment for our application.

14. **Pushed changes to the GitHub repository**
    - This triggers our pipeline to run with the newly added deployment stage.
    - Source control tracks changes, providing versioning and rollback capabilities.

15. **Verified deployment in AWS Console**
    - Confirmed that the application was successfully deployed to Elastic Beanstalk.
    - Accessed the application at the Elastic Beanstalk-provided domain to ensure it's working.

## SYSTEM DESIGN DIAGRAM
[!Digram](Diagram.jpg)

## ISSUES/TROUBLESHOOTING

1. **Jenkins Pipeline Syntax Errors**
   - The Jenkinsfile syntax is very specific and sensitive to formatting errors.
   - I had to carefully follow the documentation to ensure proper stage definitions and bracket placement.
   - Solution: Referenced the official Jenkins pipeline syntax documentation and validated the file.

2. **AWS CLI Credential Configuration**
   - Ensuring the Jenkins user had the proper AWS credentials configured was challenging.
   - Solution: Carefully followed the AWS CLI configuration steps and verified with a simple command.

3. **Python Virtual Environment Activation**
   - Initially had issues with the virtual environment not being found or activated correctly.
   - Solution: Made sure to use the correct path to the virtual environment and activation command.

4. **Elastic Beanstalk Platform Version**
   - Faced an error where Elastic Beanstalk couldn't find the specified Python version.
   - Solution: Verified available platform versions and updated the configuration to use a supported version.

## OPTIMIZATION

### How does a deploy stage in the CI/CD pipeline increase business efficiency?

Adding a deploy stage to the CI/CD pipeline dramatically increases business efficiency by:

1. **Reducing Manual Effort**: Deployments that previously required manual steps now happen automatically, freeing up developer time for more valuable tasks.

2. **Increasing Deployment Frequency**: The ease of automated deployments encourages more frequent, smaller updates, which reduces risk and gets features to users faster.

3. **Improving Consistency**: Every deployment follows the exact same process, eliminating human-induced variables and errors that can occur with manual deployments.

4. **Enabling Rapid Rollbacks**: If issues are detected, the pipeline can be configured to quickly roll back to a previous working version, minimizing downtime.

5. **Providing Deployment Traceability**: The pipeline records who initiated each deployment, what changes were included, and when it occurred, improving accountability and troubleshooting.

### Potential issues with automating deployments to production:

1. **Insufficient Testing**: Automated deployments might push untested or inadequately tested code to production if test coverage is poor.

2. **Security Vulnerabilities**: Without proper security gates, vulnerable code could be automatically deployed to production.

3. **Configuration Drift**: Differences between development and production environments can cause deployments to succeed in testing but fail in production.

4. **Credential Management**: CI/CD pipelines require access to production credentials, which increases security risk if not properly managed.

5. **Dependency on External Services**: If the pipeline relies on external services like GitHub or AWS, outages in those services can prevent deployments.

### How to address these issues:

1. **Implement Comprehensive Testing**: Include unit, integration, and security tests in the pipeline that must pass before deployment.

2. **Add Security Scanning**: Incorporate vulnerability scanning tools like OWASP dependency checks or SonarQube.

3. **Use Infrastructure as Code**: Define all environments using the same IaC tools to ensure consistency between development and production.

4. **Implement Credential Rotation**: Regularly rotate API keys and implement the principle of least privilege for service accounts.

5. **Create Approval Gates**: Add manual approval requirements for production deployments to maintain human oversight.

6. **Implement Feature Flags**: Use feature flags to gradually roll out changes to production users, limiting impact if issues occur.

7. **Set Up Monitoring and Alerting**: Implement robust monitoring to detect issues quickly after deployment, enabling fast response.

8. **Create Disaster Recovery Plans**: Document procedures for rolling back deployments and recovering from failures.

## CONCLUSION

This workload has successfully automated the deployment of our application to AWS Elastic Beanstalk through a CI/CD pipeline. By leveraging Jenkins, AWS CLI, and Elastic Beanstalk CLI, we've created a streamlined process that reduces manual effort, increases consistency, and improves overall deployment efficiency.

The CI/CD pipeline we've implemented follows industry best practices by:
1. Retrieving code from a version-controlled repository
2. Building the application in an isolated environment
3. Running tests to verify functionality and resource utilization
4. Automatically deploying to Elastic Beanstalk when tests pass

This automation represents a significant improvement over the manual deployment process used in Workload 1. It not only saves time but also reduces the potential for human error during the deployment process. The pipeline can be further enhanced by adding additional stages such as security scanning, performance testing, and staged deployments to different environments.

By continuing to refine and expand our CI/CD pipeline, we can further improve our development velocity while maintaining application quality and reliability.