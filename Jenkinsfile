pipeline {
  agent { label 'linux' }
  stages {
    stage('Install dependencies') {
      steps {
        sh 'sudo apt update'
        sh 'sudo apt install git'
        sh 'sudo apt install python3'
        sh 'sudo apt install build-essential'
        sh 'sudo apt install ecdsautils'
        sh 'sudo apt install gawk'
        sh 'sudo apt install unzip'
        sh 'sudo apt install libncurses-dev'
        sh 'sudo apt install libz-dev'
        sh 'sudo apt install libssl-dev'
        sh 'sudo apt install libelf-dev'
        sh 'sudo apt install wget'
        sh 'sudo apt install rsync'
        sh 'sudo apt install time'
        sh 'sudo apt install qemu-utils'
      }
    }
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
  }
}
