# RBAC Management Pipeline

## Intention

The intention behind **RBAC Management Pipeline** is to provide a self-managing, Infrastructure-as-Code, CI/CD pipeline for managing RBAC roles across your AWS accounts. I created this, and a series of posts, to help me managed the RBAC infrastructure in my personal AWS Accounts.

The posts can be found here:

* Part 1 - [CloudFormation all the way down - Debug Guide](https://www.surrealsoftware.com.au/posts/2020-10-12.html)
* Part 2 - [CloudFormation all the way down - StackSets for Role Management](https://www.surrealsoftware.com.au/posts/2020-10-19.html)
* Part 3 - [CloudFormation all the way down - Designing RBAC](https://www.surrealsoftware.com.au/posts/2020-10-26.html)
* Part 4 - [CloudFormation all the way down - With Code!](https://www.surrealsoftware.com.au/posts/2020-11-09.html)

All feedback and PR's are gratefully received!

## Prerequisites

1. Review the [first blog post](https://www.surrealsoftware.com.au/posts/2020-10-12.html) to ensure your accounts are ready to deploy this project.
2. Have all the accounts you want to manage under an OU (and have it's OrgId)
3. Install the following tools:
   1. Git
   2. AWS CLI
4. Make sure you have Admin permissions in the management (formerly known as master) account. **Note** This must be run from the master account or it wont work (I've tried, and failed :) )
5. Clone this repository and remove the `.git/` folder:

   ```bash
   git clone https://github.com/mechanicalpete/rbac-management-pipeline.git
   cd rbac-management-pipeline
   rm -rf .git/
   ```

## Deploy

1. Search and replace values between `@@`

   | Key                         | Example                    | Description                                                                                                            |
   | --------------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
   | @@camel-case-name@@         | MyRbacAccountManagement    | CameCase name, can be a mix of upper and lower alphabetic characters only. Also used for naming things.                |
   | @@kebab-case-name@@         | my-rbac-account-management | Kebab-case name, needs to be all lowercase alphabetic characters and dashes. Used in naming resources like S3 Buckets. |
   | @@aws-profile@@             | admin                      | The AWS CLI profile to use to deploy everything.                                                                       |
   | @@aws-region@@              | ap-southeast-2             | Which region you would like to deploy everything into.                                                                 |
   | @@aws-organisational-unit@@ | ou-1234-56781246           | The organisational unit to deploy the CloudFormation StackSet which deploys cross-account roles.                       |
   | @@aws-child-accountid@@     | 111111111111               | The AWS Account ID of a child account                                                                                  |
   | @@aws-rolename-assumer@@    | RbacAssumer                | The name to give the cross-account role which is assumed to deploy resources                                           |
   | @@aws-rolename-deployer@@   | RbacDeployer               | The name to give the cross-account role which deploys the resources                                                    |

2. Setup your [preferred access](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up.html) to CodeCommit. If you use the `credential-helper` add this snippet into `~\.gitconfig`.

   ```code
   [credential "https://git-codecommit.@@aws-region@@.amazonaws.com/v1/repos/@@camel-case-name@@"]
      helper = !aws --profile @@aws-profile@@ codecommit credential-helper $@
      UseHttpPath = true
   ```

3. Run `./init.sh`

## Postrequisites

Due to a chicken-and-egg relationship between several permissions stanzas, the following lines need to be uncommented in `pipelines/aws_seed.yml`:

1. S3 Bucket Policy

   ```yaml
                # - !Sub "arn:aws:iam::${ParamChild1AccountId}:role/${ParamAssumerRoleName}"
                # - !Sub "arn:aws:iam::${ParamChild1AccountId}:role/${ParamDeployerRoleName}"
   ```

2. CodePipeline Stage and Action:

   ```yaml
        # - Name: 'AdministerAccounts'
        #   Actions:
        #     - Name: 'ChildAccount1'
        #       ActionTypeId:
        #         Category: Deploy
        #         Owner: AWS
        #         Provider: CloudFormation
        #         Version: '1'
        #       Configuration:
        #         ActionMode: REPLACE_ON_FAILURE
        #         Capabilities: CAPABILITY_NAMED_IAM
        #         ParameterOverrides: !Sub |
        #           {
        #             "ParamBucketName": "${CodePipelineBucket}",
        #             "ParamPrimaryAccountId": "${AWS::AccountId}",
        #             "ParamAdministratorRoleName": "${ParamAdministratorRoleName}",
        #             "ParamReadOnlyRoleName": "${ParamReadOnlyRoleName}"
        #           }
        #         RoleArn: !Sub "arn:aws:iam::${ParamChild1AccountId}:role/${ParamDeployerRoleName}"
        #         StackName: !Sub '${ParamPipelineName}-Rbac'
        #         TemplateConfiguration: 'CodeCommitSource::pipeline/resource_tags.json'
        #         TemplatePath: 'CodeCommitSource::infrastructure/iam_rbac_account_child1.yml'
        #       RoleArn: !Sub "arn:aws:iam::${ParamChild1AccountId}:role/${ParamAssumerRoleName}"
        #       InputArtifacts:
        #         - Name: 'CodeCommitSource'
        #       RunOrder: 1
   ```

3. KMS Key Resource Policy:

   ```yaml
               # - !Sub "arn:aws:iam::${ParamChild1AccountId}:role/${ParamAssumerRoleName}"
               # - !Sub "arn:aws:iam::${ParamChild1AccountId}:role/${ParamDeployerRoleName}"
   ```

Commit and push the changes...
