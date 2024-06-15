pipeline {
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
  }
}
