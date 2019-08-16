#!/bin/bash

# TODO: Change this
UNIQUE_SUFFIX="90210-rob-chen"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        help)
            usage
            shift
            shift
            ;;
        --environment)
            STAGE="$2"
            shift # past argument
            shift # past value
            ;;
        -p|--profile)
            PROFILE="$2"
            shift # past argument
            shift # past value
            ;;
    esac
done

function usage {
    echo "Usage: $0 [--environment dev] [--profile robtest]"
    exit 0
}

# Default stage to dev
STAGE=${STAGE:-dev}
# Append stage to project
PROJECT=sam-tutorial-$STAGE-$UNIQUE_SUFFIX

# Set profile if it was provided
if [[ -n ${PROFILE} ]]; then
    export AWS_PROFILE=${PROFILE}
fi

# Change the suffix on the SAM deploy bucket to something unique!
BUCKET=$PROJECT-${UNIQUE_SUFFIX}

# set the region
function getdefaultregion {
    echo -n $(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | python -c "import sys, json; print json.load(sys.stdin)['region']")
}
export AWS_REGION=$(getdefaultregion)

# make a build directory to store artifacts
rm -rf build
mkdir build

# make the deployment bucket in case it doesn't exist
aws s3 mb s3://$BUCKET

# generate next stage yaml file
aws cloudformation package                   \
    --template-file template.yaml            \
    --output-template-file build/output.yaml \
    --s3-bucket $BUCKET


# the actual deployment step
aws cloudformation deploy                     \
    --template-file build/output.yaml         \
    --stack-name $PROJECT                     \
    --capabilities CAPABILITY_IAM             \
    --parameter-overrides Environment=$STAGE  \
    --region ${AWS_REGION}


