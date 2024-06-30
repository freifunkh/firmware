pipeline {
  parameters {
    string(
      defaultValue: 'ALL',
      name: 'GLUON_TARGET',
      trim: true
    )
  }
  agent { label 'linux' }
  stages {
    stage('Clone gluon') {
      steps {
        dir('gluon') {
          checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/freifunk-gluon/gluon.git']])
        }
      }
    }
    stage('Clone site') {
      steps {
        dir('gluon/site') {
          checkout scmGit(branches: [[name: '*/master-wireguard']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/freifunkh/site.git']])
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
          sh 'git am site/patches/*'
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
              build_stages[target_name] = stage("Build ${target_name}") {
                echo "${target_name}"
                def built = build(job: "nightly-wireguard", wait: true, propagate: false, parameters: [
                  string(name: 'GLUON_TARGET', value: "${target_name}")
                ])
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
            def nproc_str = sh "nproc"
            def nproc = nproc_str as Integer
            def nproc_plus_one = nproc+1
            sh "make -j${nproc_plus_one} GLUON_TARGET=${params.GLUON_TARGET}"
          }
        }
      }
    }
  }
}
