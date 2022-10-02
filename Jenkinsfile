pipeline {
  
  // DIY Lab
  // let's build an image and then immmediately create an SBOM
  
  environment {
    //
    // this should be fairly unique, it doesn't need to be perfect
    // since we're not going to push this image anywhere
    //
    IMAGE = "${JOB_BASE_NAME}:${BUILD_NUMBER}"
  } // end environment
  
  agent any
  stages {
    
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"

    stage('Install and Verify Tools') {
      steps {
        sh '''
          ### if docker isn't available, just bail 
          ### (correcting this is a bigger problem outside the scope of this workshop)
          which docker   
          ### make sure syft is available, and if not, download and install 
          if [ ! $(which syft) ]; then
            curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b ${HOME}/.local/bin
          fi
          PATH=${HOME}/.local/bin:${PATH}
          # setting PATH here isn't really necessary since we're just going to exit this sh step anyway but it's
          # a good reminder that it needs to be done when we actually need syft and grype
          #
          # also, we can go ahead and sanity check that the tools were installed correctly:
          which syft
          # finally, let's make sure there's no old sboms laying around (just so our build artifacts are clean)
          rm -f *sbom* 
        '''
      } // end steps
    } // end stage "install and verify tools"
        
    stage('Build image and tag with build number') {
      steps {
        sh '''
          docker build --pull --no-cache --network=host --file Dockerfile -t ${IMAGE} .
        '''  
      } // end steps
    } // end stage "build image and tag w build number"
    
    
    stage('Analyze with syft') {
      steps {
        // run syft, output in both json and text formats
        //
        // note: setting PATH here like this will work regardless of whether syft/grype 
        // were installed before we ran this pipeline or during the pipeline execution
        sh '''
          # set the PATH just to be sure
          PATH=${HOME}/.local/bin:${PATH}
          # run syft and output both json and text files.
          syft --output json=${IMAGE}-syft-sbom.json --output table=${IMAGE}-syft-sbom.txt --output spdx-json=${IMAGE}-spdx-sbom.json --output cyclonedx-json=${IMAGE}-cyclonedx-sbom.json ${IMAGE} 
        '''
      } // end steps
    } // end stage "analyze with syft"

  } // end stages
  
  post {
    always {
      // archive the sbom
      archiveArtifacts artifacts: '*sbom*'
      // and, just to be sure, let's clean up after ourselves, 
      // remove any sboms we've created from the workspace
      sh 'rm -f *sbom*'
    } // end always
  } //end post

} //end pipeline
