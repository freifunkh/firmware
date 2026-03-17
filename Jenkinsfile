pipeline {
  parameters {
    string(
      defaultValue: 'ALL',
      name: 'GLUON_TARGET',
      trim: true
    )
    string(
      defaultValue: '*/main',
      name: 'GLUON_COMMIT',
      trim: true
    )
    string(
      defaultValue: '*/master-wireguard',
      name: 'SITE_COMMIT',
      trim: true
    )
    string(
      defaultValue: '',
      name: 'MAIN_JOB_BUILD_IDENTIFIER',
      trim: true,
      description: 'Do not set this parameter manually! It is used to identify builds triggered by the main job.'
    )
    booleanParam(
      defaultValue: false,
      name: 'PUBLISH',
      description: 'Publish built images to firmware.ffh.zone'
    )
    booleanParam(
      defaultValue: false,
      name: 'ONLY_TEST_PIPELINE',
      description: 'Skip actual image build and only test the pipeline by generating some test files'
    )
    choice(
      name: 'GLUON_AUTOUPDATER_BRANCH',
      choices: ['wireguard', 'beta', 'experimental', 'nightly', 'nightly_wireguard', 'stable'],
      description: 'This does not define under which branch this image is actually distributed. It defines which branch is set up for the autoupdater after this image has been flashed.'
    )
    string(
      name: 'GLUON_RELEASE',
      defaultValue: 'vH41~1',
      trim: true,
      description: 'Use something like vH40, ... for actual releases and vH40~1 ... for the first pre-release, vH40~2 for the second pre-release, ...'
    )
    booleanParam(
      name: 'BROKEN',
      defaultValue: true,
      description: 'Set this to true if you want to build targets that are marked as broken in the site configuration.'
    )
  }
  agent { label 'linux' }
  stages {
    stage('Log time before build') {
      steps {
        sh 'echo Build started at:'
        sh 'date'
      }
    }
    stage('Clone gluon') {
      steps {
        dir('gluon') {
          checkout scmGit(branches: [[name: params.GLUON_COMMIT]], extensions: [], userRemoteConfigs: [[url: 'https://github.com/freifunk-gluon/gluon.git']])
          script {
             env.gluon_commit = sh(script: 'git rev-parse HEAD', returnStdout: true)
          }
        }
      }
    }
    stage('Clone site') {
      steps {
        dir('gluon/site') {
          checkout scmGit(branches: [[name: params.SITE_COMMIT]], extensions: [], userRemoteConfigs: [[url: 'https://github.com/freifunkh/site.git']])
          script {
             env.site_commit = sh(script: 'git rev-parse HEAD', returnStdout: true)
          }
        }
      }
    }
    stage('Configure git') {
      steps {
        dir('gluon') {
          sh 'git config user.email "jenkins@build.ffh.zone"'
          sh 'git config user.name "jenkins"'
        }
      }
    }
    stage('Apply site patches') {
      steps {
        dir('gluon') {
          sh 'git am site/patches/* --committer-date-is-author-date'
        }
      }
    }
    stage('Get other repos used by gluon') {
      steps {
        dir('gluon') {
          sh 'make update'
        }
      }
    }
    stage('Update OpenWrt signing keys') {
      steps {
        withCredentials([file(credentialsId: 'key-build.pub', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build.pub'
            sh 'cat key-build.pub'
            sh 'echo "f5acf9d95b0b77e96a81f17aba729aa57ff279c1393a1df3b9cce11dc0ccb10a  key-build.pub" | sha256sum -c'
          }
        }
        withCredentials([file(credentialsId: 'key-build', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build'
            sh 'echo "83d504c4d622555a7c5911abfe04575391d4132957d2c4d6da58cad6e01e60f9  key-build" | sha256sum -c'
          }
        }
        withCredentials([file(credentialsId: 'key-build.ucert', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build.ucert'
            sh 'echo "fb9e5f1d8f056c28aa84fd925bbba5d5de7d021076d470dd993e084f1add6b0a  key-build.ucert" | sha256sum -c'
          }
        }
        withCredentials([file(credentialsId: 'key-build.ucert.revoke', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build.ucert.revoke'
            sh 'echo "e2df2c116e3e91b64f5f2125a401cb44c65a6bb2d8f565a9d7cb59e7e6d5308c  key-build.ucert.revoke" | sha256sum -c'
          }
        }
      }
    }

    // ------------------------ MAIN JOB LOGIC ------------------------
    stage('Trigger target builds') {
      when {
        expression {
          return params.GLUON_TARGET == 'ALL'
        }
      }
      steps {
        dir('gluon') {
          script {
            def targets_string = sh(script: 'make list-targets', returnStdout: true)
            def targets = targets_string.tokenize('\n')
            def build_stages = [:]
            def main_job_build_identifier = UUID.randomUUID().toString()

            targets.each { target_name ->
              build_stages[target_name] = {
                stage("Build ${target_name}") {
                  echo "${target_name}"
                  def built = build(job: "nightly-wireguard", wait: true, propagate: false, parameters: [
                    string(name: 'GLUON_TARGET', value: "${target_name}"),
                    string(name: 'GLUON_COMMIT', value: "${env.gluon_commit}"),
                    string(name: 'SITE_COMMIT', value: "${env.site_commit}"),
                    string(name: 'MAIN_JOB_BUILD_IDENTIFIER', value: "${main_job_build_identifier}"),
                    booleanParam(name: 'PUBLISH', value: params.PUBLISH),
                    booleanParam(name: 'ONLY_TEST_PIPELINE', value: params.ONLY_TEST_PIPELINE),
                    string(name: 'GLUON_AUTOUPDATER_BRANCH', value: params.GLUON_AUTOUPDATER_BRANCH),
                    string(name: 'GLUON_RELEASE', value: params.GLUON_RELEASE),
                    booleanParam(name: 'BROKEN', value: params.BROKEN)
                  ])
                }
              }
            }
            parallel build_stages
          }
        }
      }
    }
    // ----------------------/ MAIN JOB LOGIC END /----------------------

    // --------------------- SINGLE TARGET JOB LOGIC ---------------------
    stage('Build gluon target') {
      when {
        expression {
          return params.GLUON_TARGET != 'ALL'
        }
      }
      steps {
        dir('gluon') {
          script {
            def nproc_str = sh(script: 'nproc', returnStdout: true)
            def nproc = nproc_str as Integer
            def nproc_plus_one = nproc+1
            def extra_args = ''

            if (params.BROKEN) {
              extra_args = 'BROKEN=1 '
            }

            if (params.ONLY_TEST_PIPELINE) {
              sh "mkdir -p output/images/${params.GLUON_TARGET}/"
              sh "echo 'This is a test file for target ${params.GLUON_TARGET}' > output/images/${params.GLUON_TARGET}/testfile.txt"
              sh "mkdir -p output/meta/${params.GLUON_TARGET}/"
              sh "echo 'This is a test meta file for target ${params.GLUON_TARGET}' > output/meta/${params.GLUON_TARGET}/testmeta.txt"
              return
            } else {
              sh "make -j${nproc_plus_one} GLUON_AUTOUPDATER_ENABLED=1 GLUON_AUTOUPDATER_BRANCH=${params.GLUON_AUTOUPDATER_BRANCH} GLUON_RELEASE=${params.GLUON_RELEASE} GLUON_TARGET=${params.GLUON_TARGET} ${extra_args} || make -j1 V=s GLUON_TARGET=${params.GLUON_TARGET}"
              sh "make manifest"
            }
          }
        }
      }
    }
    // -------------------/ SINGLE TARGET JOB LOGIC END /-------------------

  }
  post {
    always {
      dir('gluon') {
        dir('output') {
          script {
            sshagent(credentials: ['tonne_ssh_access']) {
              if (params.GLUON_TARGET == 'ALL') {
                // ---------------------------- MAIN JOB -----------------------------

                if (params.PUBLISH) {
                  sh "ssh -p 1337 firmware.ffh.zone 'echo hey > /var/www/tmp-firmware-before-merge/${MAIN_JOB_BUILD_IDENTIFIER}/finished'"
                }

                // -------------------------/ MAIN JOB END /--------------------------
              } else {

                // ------------------------ SINGLE TARGET JOB ------------------------

                sh "mkdir -p ~/.ssh/"
                sh "ssh-keyscan -p 1337 tonne.ffh.zone >> ~/.ssh/known_hosts"
                sh "rsync -rva ./images/* tonne.ffh.zone:/media/firmware/jenkins/${NODE_NAME}-${BUILD_ID}/images/ -e 'ssh -p 1337' --mkpath"
                sh "rsync -rva ./meta/* tonne.ffh.zone:/media/firmware/jenkins/${NODE_NAME}-${BUILD_ID}/meta/ -e 'ssh -p 1337' --mkpath"

                if (params.PUBLISH) {
                  sh '''
                    set -eu

                    echo "Lade vollständiges Jenkins-Konsolenlog von: ${BUILD_URL}consoleText"
                    curl -fsS "${BUILD_URL}consoleText" -o jenkins-console.log
                  '''

                  sh "ssh-keyscan -p 1337 firmware.ffh.zone >> ~/.ssh/known_hosts"
                  sh '''
                  lftp -p 1337 sftp://firmware.ffh.zone -e "
                    set sftp:auto-confirm yes;
                    mkdir -p /var/www/tmp-firmware-before-merge/${MAIN_JOB_BUILD_IDENTIFIER}/${NODE_NAME}-${BUILD_ID}-${GLUON_TARGET}/images;
                    mkdir -p /var/www/tmp-firmware-before-merge/${MAIN_JOB_BUILD_IDENTIFIER}/${NODE_NAME}-${BUILD_ID}-${GLUON_TARGET}/logs;
                    put jenkins-console.log -o /var/www/tmp-firmware-before-merge/${MAIN_JOB_BUILD_IDENTIFIER}/${NODE_NAME}-${BUILD_ID}-${GLUON_TARGET}/logs/jenkins-console.log;
                    mirror -R ./images /var/www/tmp-firmware-before-merge/${MAIN_JOB_BUILD_IDENTIFIER}/${NODE_NAME}-${BUILD_ID}-${GLUON_TARGET}/images;
                    bye
                  "
                    '''r
                }

                // ---------------------/ SINGLE TARGET JOB END /---------------------
              }
            }

            sh 'echo Build finished at:'
            sh 'date'
          }
        }
      }
    }
  }
}
