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
            sh 'echo "83d504c4d622555a7c5911abfe04575391d4132957d2c4d6da58cad6e01e60f9  key-build" | sha256sum -c'
          }
        }
        withCredentials([file(credentialsId: 'key-build.pub', variable: 'FILE')]) {
          dir('gluon/openwrt') {
            sh 'cp $FILE key-build.pub'
            sh 'echo "f5acf9d95b0b77e96a81f17aba729aa57ff279c1393a1df3b9cce11dc0ccb10a  key-build.pub" | sha256sum -c'
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
            sh "make -j${nproc_plus_one} V=s GLUON_TARGET=${params.GLUON_TARGET}"
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
          sshPublisher(
            publishers: [
              sshPublisherDesc(
                configName: 'tonne.ffh.zone',
                transfers: [
                  sshTransfer(
                    cleanRemote: false,
                    excludes: '',
                    execCommand: '',
                    execTimeout: 120000,
                    flatten: false,
                    makeEmptyDirs: false,
                    noDefaultExcludes: false,
                    patternSeparator: '[, ]+',
                    remoteDirectory: '',
                    remoteDirectorySDF: false,
                    removePrefix: 'gluon/output',
                    sourceFiles: 'gluon/output/images/'
                  ),
                  sshTransfer(
                    cleanRemote: false,
                    excludes: '',
                    execCommand: '',
                    execTimeout: 120000,
                    flatten: false,
                    makeEmptyDirs: false,
                    noDefaultExcludes: false,
                    patternSeparator: '[, ]+',
                    remoteDirectory: '',
                    remoteDirectorySDF: false,
                    removePrefix: 'gluon/output',
                    sourceFiles: 'gluon/output/meta/'
                  )
                ],
                usePromotionTimestamp: false,
                useWorkspaceInPromotion: false,
                verbose: false
              )
            ]
          )
        }
      }
    }
  }
}
