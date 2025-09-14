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
  }
  agent { label 'linux' }
  stages {
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
        withCredentials([file(credentialsId: 'key-build', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build'
          }
        }
        withCredentials([file(credentialsId: 'key-build.pub', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build.pub'
          }
        }
        withCredentials([file(credentialsId: 'key-build.ucert', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build.ucert'
          }
        }
        withCredentials([file(credentialsId: 'key-build.ucert.revoke', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build.ucert.revoke'
          }
        }
      }
    }
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
            def targets1 = targets_string.tokenize('\n')
            def targets = ['ath79-generic','ipq40xx-generic'] // override for testing purposes
            def build_stages = [:]

            targets.each { target_name ->
              build_stages[target_name] = {
                stage("Build ${target_name}") {
                  echo "${target_name}"
                  def built = build(job: "nightly-wireguard", wait: true, propagate: false, parameters: [
                    string(name: 'GLUON_TARGET', value: "${target_name}"),
                    string(name: 'GLUON_COMMIT', value: "${env.gluon_commit}"),
                    string(name: 'SITE_COMMIT', value: "${env.site_commit}")
                  ])
                }
              }
            }
            parallel build_stages
          }
        }
      }
    }
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
            sh "make -j${nproc_plus_one} GLUON_TARGET=${params.GLUON_TARGET}"
          }
        }
      }
    }
  }
  post {
    always {
      script {
        if (params.GLUON_TARGET != 'ALL') {
          archiveArtifacts artifacts: 'gluon/output/images/**/*', fingerprint: true
          archiveArtifacts artifacts: 'gluon/output/meta/**/*', fingerprint: true
        }
      }
    }
  }
}
