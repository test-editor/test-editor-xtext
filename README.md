DEPRECATED  test-editor-xtext
=================

:warning: **WARNING** This project is deprecated because the Test-Editor Team decided to cut off the RCP functionality  for the sake of the Test-Editor-Web in October 2018 :warning:

The new test-editor-xtext-gradle repository for the project :star:Test-Editor-Web:star: can be found under [test-editor-xtext-gradle](https://github.com/test-editor/test-editor-xtext-gradle) 



[![License](http://img.shields.io/badge/license-EPL-blue.svg?style=flat)](https://www.eclipse.org/legal/epl-v10.html)
[ ![Download](https://api.bintray.com/packages/test-editor/maven/test-editor/images/download.svg) ](https://bintray.com/test-editor/maven/test-editor/_latestVersion)

An Xtext based editor to specify domain-driven acceptance tests.

## Users

The latest released version of the plugins can be found on [bintray](https://bintray.com/test-editor/maven/test-editor).

## Plugin-Users

When installing additional testeditor plugins, please provide an additional update site [Eclipse Source](http://hstaudacher.github.io/osgi-jax-rs-connector). This will allow additional dependencies to be resolved.

## Developers

Prerequisites:

- Maven 3.2.5
- JDK 1.8

After checking out the source code we first need to build the Eclipse target platform:

    mvn clean install -f "target-platform/pom.xml"
    
This will take some time for the first run but should be fast afterwards.

Now the Test-Editor Languages can simply be build with:

    mvn clean install
    
THE RCP OF THE TESTEDITOR IS CURRENTLY DISCONTINUED AND THUS DEPRECATED. ERRORS THEREIN ARE NOT FIXED.

DEPRECATED: The RCP contains some web based views, which are developed in a seperate cycle. They can be build with:

    gradlew preBuildWeb
    
DEPRECATED: The RCP and the eclipse plugins can then be built with:

    mvn clean install -Prcp

DEPRECATED: For building the full RCP product, add the Maven profiles "`rcp,product`":

    mvn clean install -Prcp,product
    
DEPRECATED: Executing the User Acceptance Tests for the rcp, add the Maven profile "`rcp,rcpuatest`":

    mvn clean install -Prcp,rcpuatest

## Troubleshooting

### The downloaded application won't start

The editor requires a JDK 1.8 in order to start. If your default system JVM is different, you can set the path to the JDK by opening the `testeditor.ini` file and placing the following **before** the `-vmargs` parameter:
 
    -vm
    <pathToYourJDK8>
    
The path depends on your operating system as described [here](https://wiki.eclipse.org/index.php?title=Eclipse.ini&redirect=no#Specifying_the_JVM). For example (Windows):

    C:\tools\jdk1.8.0_131\bin\javaw.exe

### Tests cannot be started from the RCP / IDE, complaining about missing environment variable TE_MAVEN_HOME

When using maven as test project build/run tool, please make sure to have the environment variable `TE_MAVEN_HOME` set to maven home.

## Release process

* merge develop into the master (via pullrequest)
* switch locally to the master branch
* execute `./gradlew release` (allows to set the release version and the new developversion)
  this will trigger the publishing process on travis (check [here][https://bintray.com/test-editor/maven/test-editor] whether publishing was really successful)
* merge master into develop to get the new development version into develop again
* execute maven to set all poms to the new versions
  ```
  mvn -f target-platform/pom.xml build-helper:parse-version org.eclipse.tycho:tycho-versions-plugin:set-version -Dartifacts=org.testeditor.releng.target.parent -DnewVersion=1.16.0-SNAPSHOT -Dtycho.mode=maven
  mvn -f pom.xml build-helper:parse-version org.eclipse.tycho:tycho-versions-plugin:set-version -Dartifacts=org.testeditor.releng.parent -DnewVersion=1.16.0-SNAPSHOT -Dtycho.mode=maven -Prcp,rcpuatest,product
  ```
